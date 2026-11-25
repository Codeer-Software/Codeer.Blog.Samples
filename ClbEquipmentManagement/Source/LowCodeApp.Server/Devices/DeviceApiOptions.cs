namespace LowCodeApp.Server.Devices
{
    /// <summary>
    /// appsettings の DeviceApi セクション (機器から計測値を受ける受信API の設定)。
    /// Keys (キーの名前・保存するユーザー・送ってよい管理番号) は appsettings.json に、
    /// Secrets (キーの名前 → キーの値) はユーザーシークレットや環境変数に置く。キーの値はリポジトリのファイルに書かない。
    /// </summary>
    public class DeviceApiOptions
    {
        public DeviceApiKey[] Keys { get; set; } = [];

        /// <summary>キーの名前 → キーの値。</summary>
        public Dictionary<string, string> Secrets { get; set; } = new();
    }

    /// <summary>
    /// 受信API のキー 1 つ分の設定 (値は持たない)。
    /// </summary>
    public class DeviceApiKey
    {
        /// <summary>キーの名前。ログに出してよいのはこの名前だけ。</summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>保存に使うユーザー。appsettings の ServiceAccounts の名前。</summary>
        public string ServiceAccount { get; set; } = string.Empty;

        /// <summary>このキーで送ってよい管理番号。"*" はすべて。</summary>
        public string[] AllowedAssets { get; set; } = [];
    }
}
