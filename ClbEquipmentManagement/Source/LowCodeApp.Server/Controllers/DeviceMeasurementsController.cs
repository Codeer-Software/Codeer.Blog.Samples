using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Security.Claims;
using Codeer.LowCode.Blazor.DataIO;
using Codeer.LowCode.Blazor.Repository.Data;
using Codeer.LowCode.Blazor.Repository.Match;
using LowCodeApp.Client.Shared.Modules;
using LowCodeApp.Server.Devices;
using LowCodeApp.Server.Infrastructure;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LowCodeApp.Server.Controllers
{
    /// <summary>
    /// 受信API: 機器から計測値を 1 件受け取り、計測値モジュール (Measurement) に保存する。
    /// 認証は X-Api-Key ヘッダーのキー (DeviceApiKey) だけ。機器は Cookie もトークンも持たないので AutoValidateAntiforgeryToken は付けない。
    /// 保存は ModuleDataIO を通し、キーの ServiceAccount のユーザーの権限で行う (CLB の認可が効く)。
    /// </summary>
    [ApiController]
    [Route("api/device/measurements")]
    [Authorize(AuthenticationSchemes = DeviceApiKeyAuthenticationHandler.SchemeName)]
    public class DeviceMeasurementsController : ControllerBase
    {
        //受け付ける計測項目と単位の組み合わせ
        static readonly Dictionary<string, string> UnitOfMetric = new(StringComparer.Ordinal)
        {
            ["temperature"] = "℃",
            ["flow"] = "L/min",
        };

        //時差付きの時刻 (ISO 8601。末尾は Z か +hh:mm / -hh:mm) だけを受ける
        static readonly string[] MeasuredAtFormats = ["yyyy-MM-dd'T'HH:mm:ssK", "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK"];

        readonly ILogger<DeviceMeasurementsController> _logger;

        public DeviceMeasurementsController(ILogger<DeviceMeasurementsController> logger)
            => _logger = logger;

        [HttpPost]
        public async Task<IActionResult> PostAsync(DeviceMeasurementRequest request)
        {
            //1. 計測時刻: 時差が付いているかを自分で調べてから DateTimeOffset に直し、すぐに UTC にする
            DateTime? measuredAtUtc = null;
            if (!HasOffset(request.MeasuredAt!))
            {
                ModelState.AddModelError("measuredAt", "計測時刻には時差 (末尾の Z か +hh:mm / -hh:mm) が必要です");
            }
            else if (!DateTimeOffset.TryParseExact(request.MeasuredAt, MeasuredAtFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var measuredAt))
            {
                ModelState.AddModelError("measuredAt", "計測時刻の形が正しくありません (例: 2026-11-30T10:00:00+09:00)");
            }
            else
            {
                measuredAtUtc = measuredAt.UtcDateTime;
            }

            //2. 計測項目と単位の組み合わせ (値の範囲は調べない)
            if (!UnitOfMetric.TryGetValue(request.Metric!, out var unit))
            {
                ModelState.AddModelError("metric", "計測項目は temperature か flow です");
            }
            else if (!string.Equals(unit, request.Unit, StringComparison.Ordinal))
            {
                ModelState.AddModelError("unit", $"{request.Metric} の単位は {unit} です");
            }

            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            //3. このキーで送ってよい管理番号か
            var allowedAssets = User.FindAll(DeviceApiKeyAuthenticationHandler.AllowedAssetClaim).Select(e => e.Value).ToList();
            if (!allowedAssets.Contains("*") && !allowedAssets.Contains(request.AssetNo!, StringComparer.Ordinal))
            {
                _logger.LogWarning("受信API: キー {KeyName} は {AssetNo} を送れません", KeyName, request.AssetNo);
                return Forbid(DeviceApiKeyAuthenticationHandler.SchemeName);
            }

            //4. キーの ServiceAccount のユーザーで DataService を作る (以降の読み書きはこのユーザーの権限)
            var userId = await ServiceAccountResolver.FindUserIdAsync(User.FindFirstValue(DeviceApiKeyAuthenticationHandler.ServiceAccountClaim) ?? string.Empty);
            await using var data = new DataService(userId);

            //5. 管理番号から設備を探す (読むのは Id だけ。設備の画面の設置履歴などは読まない)
            var assetNo = request.AssetNo!;
            var equipmentCondition = new SearchCondition<Equipment>()
                .Where(e => e.AssetNo!.Value == assetNo)
                .Select(e => e.Id!);
            var equipment = (await data.ModuleDataIO.GetListAsync(equipmentCondition)).FirstOrDefault();
            if (equipment == null)
            {
                ModelState.AddModelError("assetNo", $"管理番号 {assetNo} の設備がありません");
                return ValidationProblem(ModelState);
            }

            //6. 計測値を保存する (ModuleDataIO。画面から保存したときと同じ権限の判定とインターセプタを通る)
            var newId = IdFieldData.NewId();
            var measurement = new Measurement
            {
                Id = newId,
                Equipment = new LinkFieldData { Value = equipment.Id!.Value },
                MeasuredAt = new DateTimeFieldData { Value = measuredAtUtc },
                Metric = new SelectFieldData { Value = request.Metric },
                Value = new NumberFieldData { Value = request.Value },
                Unit = new TextFieldData { Value = request.Unit },
            };
            var submit = new ModuleSubmitData { ModuleName = nameof(Measurement), Id = newId.Value! };
            submit.Add.Add(ModuleData.Create(measurement));
            var results = await data.ModuleDataIO.SubmitWithTransactionAsync([submit]);

            //7. 失敗したら、全文をサーバーのログに出し、応答には詳しい内容を出さない
            var error = results.FirstOrDefault(e => !string.IsNullOrEmpty(e.ExceptionMessage))?.ExceptionMessage;
            if (error != null)
            {
                _logger.LogError("受信API: 計測値の保存に失敗しました (キー {KeyName}、{AssetNo}): {Error}", KeyName, assetNo, error);
                return Problem(statusCode: StatusCodes.Status500InternalServerError, title: "計測値を保存できませんでした");
            }

            //8. 成功: 201 と保存した Id
            var id = results.FirstOrDefault()?.DestinationId;
            _logger.LogInformation("受信API: 計測値を保存しました (キー {KeyName}、{AssetNo}、Id={Id})", KeyName, assetNo, id);
            return StatusCode(StatusCodes.Status201Created, new { id });
        }

        string KeyName => User.FindFirstValue(DeviceApiKeyAuthenticationHandler.KeyNameClaim) ?? string.Empty;

        //末尾が Z か +hh:mm / -hh:mm か
        static bool HasOffset(string text)
        {
            if (text.EndsWith('Z')) return true;
            if (text.Length < 6) return false;
            var tail = text[^6..];
            return (tail[0] == '+' || tail[0] == '-') && char.IsAsciiDigit(tail[1]) && char.IsAsciiDigit(tail[2]) && tail[3] == ':' && char.IsAsciiDigit(tail[4]) && char.IsAsciiDigit(tail[5]);
        }
    }

    /// <summary>
    /// 受信API が受ける計測値 1 件。計測時刻は string で受け、時差の有無を自分で調べる
    /// (DateTimeOffset で受けると、時差のない文字列もサーバーの時刻帯で補われて通ってしまうため)。
    /// </summary>
    public class DeviceMeasurementRequest
    {
        [Required] public string? AssetNo { get; set; }
        [Required] public string? MeasuredAt { get; set; }
        [Required] public string? Metric { get; set; }
        [Required] public decimal? Value { get; set; }
        [Required] public string? Unit { get; set; }
    }
}
