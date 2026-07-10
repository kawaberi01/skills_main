# iDrugStoreVariables Enum 定義 — idoz0804db 向け

`iDrugStoreVariables.Enums` 名前空間の enum 値まとめ。
idoz0804db の各カラムに格納される整数値を確定するために使用する。

---

## PeriodicalOrderLineItemStatus
**対応カラム**: `periodical_order_line_items.status` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | InActive | 無効（解約済み） |
| 1 | Active | 有効（継続中） |

> **SQL用途例**:  
> 有効中: `AND poli.status = 1`  
> 解約済み: `AND poli.status = 0`

---

## OrderType
**対応カラム**: `orders.order_type` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | UnDefined | 該当なし |
| 1 | Web | Web |
| 2 | Mobile | モバイル |
| 3 | Periodical | 定期購入 |
| 4 | Tel | 電話 |
| 6 | Yhvh | 電脳 |
| 7 | Fax | FAX |
| 8 | Mail | メール |
| 9 | EmsShipping | EMS |
| 10 | WebJointPurchase | Web共同購入 |
| 11 | MobileJointPurchase | モバイル共同購入 |
| 16 | Gmarket | Gマーケット |
| 17 | SmartPhone | スマホ |
| 18 | Amazon | アマゾン |
| 19 | EmployeeDiscountSales | 社販 |
| 100 | PeriodicalRetry | 定期購入再決済 |
| 101 | PeriodicalSubmit | 定期購入再決済完了 |
| 102 | SaveSubscriptionOnly | カード情報保存のみ |

---

## OrderTimeZone（配送時間帯）
**対応カラム**: `periodical_order_line_items.time_zone` (int) / `order_line_items.time_zone` 等

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | None | 指定なし |
| 1 | Morning | 午前中のお届け |
| 2 | Zone1214 | 12-14時のお届け |
| 3 | Zone1416 | 14-16時のお届け |
| 4 | Zone1618 | 16-18時のお届け |
| 5 | Zone1820 | 18-20時のお届け |
| 6 | Zone1921 | 19-21時のお届け |

---

## PaymentMethod（支払方法）
**対応カラム**: `periodical_order_line_items.payment_method` (varchar(32))  
> ⚠ **文字列として格納される**（整数ではなく enum 識別子の文字列）

| 識別子 | 表示名 |
|--------|--------|
| PelicanCashOnDelivery | 商品代引き |
| CreditCard | クレジットカード |
| CashOnDelivery | 代金引換 |
| Bank | 三菱UFJ銀行振込 |
| MizuhoBank | みずほ銀行振込 |
| SbiNetBank | 住信SBIネット銀行振込 |
| Postal | 郵便振替 |
| SevenEleven | セブンイレブン |
| Lawson | ローソン・ミニストップ |
| FamilyMart | ファミリーマート |
| NetProtections | 後払い |
| NetProtectionsSpot | 後払い(コンビニ・銀行・郵便局・PayPay) |
| OzPayment | 給与天引き |

> **SQL WHERE 例**: `AND poli.payment_method = 'CreditCard'`

---

## UserRank（ユーザーランク）
**対応カラム**: `users.rank` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | None | ランクなし |
| 1 | Bronze | ブロンズ |
| 2 | Silver | シルバー |
| 3 | Gold | ゴールド |
| 4 | Platinum | プラチナ |

---

## SiteType（サイト種別）
**対応カラム**: `orders.site_type` 等 (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | Web | PCサイト |
| 2 | Mobile | モバイルサイト |
| 6 | Yhvh | 電脳 |
| 9 | Ems | EMS送料 |
| 17 | SmartPhone | スマートフォンサイト |
| 20 | Affiliate | アフィリエイト |
| 99 | Callcenter | コールセンター |

---

## OtherChargeId（その他手数料ID）
**対応カラム**: `other_charges.id` (int)  
> ⚠ DBと値を同期する必要あり（コメントより）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | AddShipping | 送料 |
| 2 | CollectFee | 代引き手数料 |
| 3 | NewProductDiscount | 新商品割引 |
| 4 | Point | ポイント割引 |
| 5 | EmsShipping | EMS送料 |
| 6 | NpFee | 後払い手数料 |
| 7 | PeriodicalOrderBalance | 定期購入割引 |

---

## ProductShipment（商品発送方法）
**対応カラム**: `products.shipment` (int)  
※ `domain-idoz0804db.md` にも記載あり（重複参照）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | DomesticShipping | 国内発送商品 |
| 1 | OverseasShipping | 海外発送商品 |
| 2 | DomesticAndOverseasShipping | 国内＆海外発送商品 |

---

## ProductUnitOrdersShipping（配送業者）
**対応カラム**: `product_unit_orders.shipping` (文字列)  
> ⚠ Display名の値でDBに文字列として格納される

| 識別子 | Display名（DB格納値） |
|--------|----------------------|
| EMS | EMS |
| GPM | GPM |
| RGT | RGT |
| HK | 香港発送 |
| MPlus | Mプラス |
| Nittu | 日通代引 |
| FedEX | FedEX |
| EPeli | eぺリ |
| Yamato | ヤマト便 |
| MPlusCollect | Mプラス代引き |
| SGHGlobal | SGHグローバル |
| HikyakuMail | 飛脚メール便 |
| EPacketLight | 国際eパケットライト |
| ISAL | ISAL |
| YuPacket | ゆうパケット |
| OCS | OCS |

---

## ProductUnitPcaSending（PCA出荷区分）
**対応カラム**: `product_unit_pcas.sending` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 3 | Oz | 本社出荷 |
| 5 | Maker | メーカー直送 |
| 7 | Kanda | 国内倉庫出荷 |
| 9 | ForeignCountry | 海外出荷 |

---

## ProductTsuka（商品通貨）
**対応カラム**: `product_units.tsuka` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | JPY | 円 |
| 2 | USD | ドル(US) |
| 3 | GBP | ポンド |
| 4 | CAD | カナダドル |
| 5 | EUR | EUR |
| 6 | NZD | NZD |
| 7 | AUD | AUD |
| 8 | CHF | CHF |
| 9 | OZD | ドル(US特別レート) |

---

## ProductUnitStockAfter（在庫切れ後の動作）
**対応カラム**: `product_units.stock_after` (int)

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | PriceBackTo | 価格を戻す |
| 1 | Hide | 非表示にする |
| 2 | OutOfStock | 欠品表示（商品ID全体） |
| 3 | Discontinuation | このサイズを取り扱い中止にする |

---

## AgeType（年齢帯）
**対応カラム**: `users.age_type` 等 (int、0始まり連番)

| 値 | 表示名 |
|----|--------|
| 0 | ～19 |
| 1 | 20～24 |
| 2 | 25～29 |
| 3 | 30～34 |
| 4 | 35～39 |
| 5 | 40～44 |
| 6 | 45～49 |
| 7 | 50～54 |
| 8 | 55～59 |
| 9 | 60～64 |
| 10 | 65～69 |
| 11 | 70～ |
