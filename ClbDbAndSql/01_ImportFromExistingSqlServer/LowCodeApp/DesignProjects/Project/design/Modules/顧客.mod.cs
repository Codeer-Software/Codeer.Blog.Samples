// 新規登録の画面を開いたときの初期値。
// 取引中 は DB 側の既定値が 1 なので、画面の初期表示もチェックありにそろえる。
void OnNew()
{
    if (IsNewData)
    {
        取引中.Value = true;
    }
}
