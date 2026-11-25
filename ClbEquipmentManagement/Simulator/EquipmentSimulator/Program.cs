// 機器シミュレーター: 架空の設備 4 台の計測値を、CLB の受信API (POST /api/device/measurements) に HTTPS で送る。
// 機器の側は CLB を知らない、という形にするため、CLB のパッケージは参照しない (HTTP と JSON だけ)。
//
// 使い方: dotnet run --project Simulator/EquipmentSimulator -- [--url https://localhost:7137] [--count 5] [--interval 1] [--seed 42]
// キーは環境変数 CLB_DEVICE_API_KEY から読む (コマンドの引数やファイルには書かない)。
using System.Globalization;
using System.Net.Http.Json;
using System.Text;

Console.OutputEncoding = Encoding.UTF8;

// ---- 引数 ----
var url = "https://localhost:7137";
var count = 5;
var interval = 1.0;
var seed = 42;
for (var i = 0; i < args.Length; i += 2)
{
    var text = i + 1 < args.Length ? args[i + 1] : string.Empty;
    switch (args[i])
    {
        case "--url": url = text; break;
        case "--count" when int.TryParse(text, out var c) && c > 0: count = c; break;
        case "--interval" when double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var s) && s >= 0: interval = s; break;
        case "--seed" when int.TryParse(text, out var r): seed = r; break;
        default:
            Console.Error.WriteLine($"引数が正しくありません: {args[i]} {text}");
            Console.Error.WriteLine("使い方: EquipmentSimulator [--url https://localhost:7137] [--count 5] [--interval 1] [--seed 42]");
            return 2;
    }
}

// ---- キー (環境変数から。値は画面に出さない) ----
var apiKey = Environment.GetEnvironmentVariable("CLB_DEVICE_API_KEY");
if (string.IsNullOrEmpty(apiKey))
{
    Console.Error.WriteLine("環境変数 CLB_DEVICE_API_KEY がありません。送らずに終了します。");
    return 2;
}

// ---- 送り先 (HTTPS だけ。スキームの大文字小文字は Uri が小文字に直したあとで比べる) ----
if (!Uri.TryCreate(url, UriKind.Absolute, out var baseUri))
{
    Console.Error.WriteLine($"--url が URL ではありません: {url}");
    return 2;
}
if (baseUri.Scheme != Uri.UriSchemeHttps)
{
    Console.Error.WriteLine($"--url が https ではありません ({baseUri.Scheme})。キーを平文で送らないよう、送らずに終了します。");
    return 2;
}
var endpoint = new Uri(baseUri, "/api/device/measurements");

// ---- 架空の設備 4 台 (管理番号・計測項目・中心・ぶれ幅・単位) ----
Device[] devices =
[
    new("EQ-0001", "temperature", 25.0m, 0.5m, "℃"),
    new("EQ-0002", "temperature", 40.0m, 0.5m, "℃"),
    new("EQ-0003", "flow", 35.0m, 2.0m, "L/min"),
    new("EQ-0004", "temperature", 120.0m, 1.0m, "℃"),
];

using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
http.DefaultRequestHeaders.Add("X-Api-Key", apiKey);

var random = new Random(seed);
var failed = 0;
for (var round = 0; round < count; round++)
{
    if (round > 0) await Task.Delay(TimeSpan.FromSeconds(interval));
    foreach (var device in devices)
    {
        // 値は「中心 ± ぶれ幅」の範囲の乱数を小数 1 桁に丸めたもの
        var value = Math.Round(device.Center + device.Spread * (decimal)(random.NextDouble() * 2 - 1), 1, MidpointRounding.AwayFromZero);
        // 計測時刻は、送る時点の機器の時刻を時差付きで (例: 2026-11-30T10:00:00+09:00。秒より細かい部分は付けない)
        var measuredAt = DateTimeOffset.Now.ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture);
        var body = new { assetNo = device.AssetNo, measuredAt, metric = device.Metric, value, unit = device.Unit };

        string status;
        try
        {
            using var response = await http.PostAsJsonAsync(endpoint, body);
            status = $"{(int)response.StatusCode} {response.StatusCode}";
            if (!response.IsSuccessStatusCode) failed++;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            status = $"送信できませんでした ({ex.GetType().Name}: {ex.Message})";
            failed++;
        }
        Console.WriteLine($"{device.AssetNo}  {measuredAt}  {value.ToString(CultureInfo.InvariantCulture),6} {device.Unit,-5}  → {status}");
    }
}

Console.WriteLine(failed == 0 ? $"{count * devices.Length} 件を送りました。" : $"{count * devices.Length} 件のうち {failed} 件が失敗しました。");
return failed == 0 ? 0 : 1;

record Device(string AssetNo, string Metric, decimal Center, decimal Spread, string Unit);
