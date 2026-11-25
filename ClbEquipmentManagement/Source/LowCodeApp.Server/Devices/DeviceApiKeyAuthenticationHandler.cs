using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace LowCodeApp.Server.Devices
{
    /// <summary>
    /// 受信API の認証。X-Api-Key ヘッダーの値を DeviceApi:Secrets のキーと照合し、どの送り手 (キー) かを決める。
    /// わかるのは「どのキーか」だけ。送ってよい管理番号はキーの設定 (AllowedAssets)、計測値を書けるかは CLB の認可 (モジュールのユーザー権限) で決まる。
    /// </summary>
    public class DeviceApiKeyAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        public const string SchemeName = "DeviceApiKey";
        public const string HeaderName = "X-Api-Key";
        public const string KeyNameClaim = "device_api_key";
        public const string ServiceAccountClaim = "device_service_account";
        public const string AllowedAssetClaim = "device_allowed_asset";

        readonly IOptionsMonitor<DeviceApiOptions> _deviceApiOptions;

        public DeviceApiKeyAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            IOptionsMonitor<DeviceApiOptions> deviceApiOptions)
            : base(options, logger, encoder)
            => _deviceApiOptions = deviceApiOptions;

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            //ヘッダーが無い → 結果なし (この方式だけを求める受信API では 401 になる)
            if (!Request.Headers.TryGetValue(HeaderName, out var values)) return Task.FromResult(AuthenticateResult.NoResult());

            var presented = Encoding.UTF8.GetBytes(values.ToString());
            var options = _deviceApiOptions.CurrentValue;

            //すべてのキーと比べる (合うものが見つかっても途中で抜けない)。比較は、かかる時間が中身で変わらない FixedTimeEquals
            string? matchedName = null;
            foreach (var (name, secret) in options.Secrets)
            {
                if (string.IsNullOrEmpty(secret)) continue;
                if (CryptographicOperations.FixedTimeEquals(presented, Encoding.UTF8.GetBytes(secret))) matchedName = name;
            }

            //ログに出すのはキーの名前と HTTPS で来たかだけ (キーの値は出さない)
            if (matchedName == null)
            {
                Logger.LogWarning("受信API: どのキーとも合いません (IsHttps={IsHttps})", Request.IsHttps);
                return Task.FromResult(AuthenticateResult.Fail("キーが正しくありません"));
            }

            var key = options.Keys.FirstOrDefault(e => string.Equals(e.Name, matchedName, StringComparison.Ordinal));
            if (key == null)
            {
                Logger.LogWarning("受信API: キー {KeyName} の設定 (DeviceApi:Keys) がありません (IsHttps={IsHttps})", matchedName, Request.IsHttps);
                return Task.FromResult(AuthenticateResult.Fail("キーの設定がありません"));
            }

            Logger.LogInformation("受信API: キー {KeyName} で認証しました (IsHttps={IsHttps})", key.Name, Request.IsHttps);

            var claims = new List<Claim>
            {
                new(KeyNameClaim, key.Name),
                new(ServiceAccountClaim, key.ServiceAccount),
            };
            claims.AddRange(key.AllowedAssets.Select(e => new Claim(AllowedAssetClaim, e)));
            var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, Scheme.Name));
            return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(principal, Scheme.Name)));
        }
    }
}
