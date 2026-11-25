using Codeer.LowCode.Blazor.Extras.Server.Auth;
using LowCodeApp.Server.Infrastructure;

namespace LowCodeApp.Server.Devices
{
    /// <summary>
    /// サービスアカウントの名前からユーザーの Id を引く (Jobs/JobRuntimeHost.cs の FindUserIdAsync と同じ手順)。
    /// appsettings の ServiceAccounts で名前 → ログイン ID、LoginAccountStore でログイン ID → ユーザーの Id。
    /// 名前が ServiceAccounts に無い・ユーザーが見つからない (停止中を含む) ときは例外。
    /// </summary>
    public static class ServiceAccountResolver
    {
        public static async Task<string> FindUserIdAsync(string account)
        {
            var loginName = SystemConfig.Instance.ServiceAccounts.FirstOrDefault(e => string.Equals(e.Name, account, StringComparison.OrdinalIgnoreCase))?.User;
            if (string.IsNullOrEmpty(loginName)) throw new InvalidOperationException($"appsettings の ServiceAccounts に '{account}' がありません");

            await using var data = new DataService(string.Empty);
            var accounts = LoginAccountStore.Create(data.Design.DesignData, data.DbAccess);
            //ユーザーモジュールに LoginAccountContractField が無いアプリでは、User に書いた値をそのままユーザーの Id として使う (JobRuntimeHost と同じ)
            if (accounts == null) return loginName;
            return (await accounts.FindByLoginNameAsync(loginName))?.UserId
                ?? throw new InvalidOperationException($"ServiceAccounts の '{account}' の User が見つかりません");
        }
    }
}
