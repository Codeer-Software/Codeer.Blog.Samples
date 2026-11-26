void OnAfterInitialization()
{
    仕入先品番.IsEnabled = 品番確認済み.Value == true;
}

void 品番確認済み_OnDataChanged()
{
    if (品番確認済み.Value != true)
    {
        仕入先品番.Value = "";
    }
    仕入先品番.IsEnabled = 品番確認済み.Value == true;
}
