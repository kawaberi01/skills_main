# Search Patterns

PowerShell では `rg` を優先して使う。
パスにスペースが含まれる可能性があるため、検索対象パスは引用する。

## DB 候補の探索

```powershell
rg -n "idoz0804db|irxoz0804db|igeoz0805db|ibtoz0804db|masonpearson2|DbContext|ConnectionString|ConnectionStringName" "<target-project>"
```

## 値定義の探索

```powershell
rg -n "enum |Dictionary<|const |static readonly|readonly Dictionary|switch \\(|case " "<target-project>"
```

## 表示名・変換処理の探索

```powershell
rg -n "Display\\(|DisplayName|Description\\(|DescriptionAttribute|GetDisplayName|SelectList|ViewBag|ViewData|ToSelectList|ToDictionary" "<target-project>"
```

## 注文・支払・配送の探索

```powershell
rg -n "status|order_status|OrderStatus|cancel|Cancel|payment|Payment|shipping|Shipping|delivery|Delivery|supplier|Supplier" "<target-project>"
```

## 会員・商品区分の探索

```powershell
rg -n "user_type|UserType|doctor_type|DoctorType|product_type|ProductType|OTC|periodical|Periodical|subscription|Subscription" "<target-project>"
```

## 日本語表示文字列の探索

```powershell
rg -n "キャンセル|有効|売上対象|未入金|入金済|発送済|発送完了|退会|テスト|社内|医師|患者|OTC|定期購入|サプライヤー|配送|支払" "<target-project>"
```

## OZ-DatabaseEntities 側との照合

```powershell
rg -n "class .*Context|DbSet<|ToTable\\(|HasColumnName|HasForeignKey|HasConstraintName|enum |const " "<oz-database-entities>"
```

