// 単価、数量 が変わったら、金額 を計算して入れる。
void Recalc()
{
    if (単価.Value == null || 数量.Value == null)
    {
        金額.Value = null;
    }
    else
    {
        // 1円未満は四捨五入(0.5 は 0 から遠いほうへ)
        金額.Value = Math.Round(単価.Value * 数量.Value, 0, MidpointRounding.AwayFromZero);
    }
    ShowRounding();
}

// 丸め方ごとの結果を、比較用の フィールド(DB の列なし)に出す。
void ShowRounding()
{
    if (単価.Value == null || 数量.Value == null)
    {
        丸める前.Value = null;
        偶数丸め.Value = null;
        切り捨て.Value = null;
        切り上げ.Value = null;
        return;
    }
    var x = 単価.Value * 数量.Value;
    丸める前.Value = x;
    偶数丸め.Value = Math.Round(x, 0, MidpointRounding.ToEven);
    切り捨て.Value = Math.Round(x, 0, MidpointRounding.ToZero);
    切り上げ.Value = Math.Round(x, 0, MidpointRounding.ToPositiveInfinity);
}
