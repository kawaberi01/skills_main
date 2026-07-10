# ドメイン知識 — idoz0804db（iDrug Store）

## 会計期の計算ルール

- 3月始まり・2月末終わり
- `CASE WHEN MONTH(x) >= 3 THEN YEAR(x) - 1979 ELSE YEAR(x) - 1 - 1979 END`
- 例: 44期 = 2023-03-01〜2024-02-28 / 45期 = 2024-03-01〜2025-02-28 / 46期 = 2025-03-01〜2026-02-28

## products.shipment（ProductShipmentType）

| 値 | 識別子 | 意味 | SQL用途 |
|----|--------|------|---------|
| 0 | DomesticShipping | 国内発送のみ | 除外: `AND p.shipment <> 0` |
| 1 | OverseasShipping | 海外発送のみ | 対象 |
| 2 | DomesticAndOverseasShipping | 国内＆海外 | 対象 |

## orders.status（OrderStatus）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | PaymentNotConfirmed | 入金待ち |
| 2 | PaymentConfirmed | 入金完了(お手配待ち) |
| 3 | Arranged | お手配済み |
| 4 | Shipped | 発送済み |
| 9 | Cancel | キャンセル |

> 入金済み以降を対象とする場合: `AND o.status IN (2, 3, 4)`  
> キャンセル除外: `AND o.status <> 9`

## products.status（ProductStatus）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | Normal | 通常表示 |
| 1 | NoStock | 欠品 |
| 2 | NotShowNewProducts | 新商品非表示 |
| 4 | FinishedMaking | 廃番 |
| 5 | EnglishProducts | 英語商品 |
| 6 | Sample | サンプル商品 |
| 7 | WebDisable | その他商品(Web非表示で購入可能) |
| 8 | BeforeSale | 発売前 |
| 9 | EndOfSale | 販売終了 |

## products.product_type（ProductType）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | MedicalSupplies | 医薬品 |
| 1 | NotMedicalSupplies | 医薬品外 |
| 2 | ContactLenses | コンタクトレンズ |
| 3 | Otc | OTC |

## product_unit_orders.supplier_id（Suppliers）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | Kokunai | 【国内】倉庫 |
| 1 | Oz | 【国内】オズ |
| 2 | BK | 【海外】BK |
| 3 | WW | 【海外】WW |
| 4 | ISA | 【海外】ISA |
| 5 | ENDOR | 【海外】エンドア |
| 6 | Chalets | 【海外】シャレ |
| 7 | ReachFaith | 【海外】リーチフェイス |
| 8 | OtherOverseasSupplier | 【海外】上記以外の海外 |
| 9 | UPJ | 【国内】UPJ |
| 10 | OceaniaHealth | 【海外】オセアニアヘルス |
| 11 | CYNO | 【海外】CYNO |
| 12 | FM | 【海外】FM |
| 13 | HBW | 【海外】HBW |
| 14 | AZUSA | 【海外】AZUSA |
| 15 | HG | 【海外】HG |
| 16 | ALEX | 【海外】ALEX |
| 17 | NeoHorizon | 【海外】ネオホライズン |
| 18 | BeautyOrder | 【海外】ビューティー発注 |
| 19 | OverseasContact | 【海外】海外コンタクト |
| 20 | FTL | 【海外】FTL |
| 21 | CORENA | 【海外】CORENA |
| 22 | GenkiFactory | 【海外】元気ファクトリー |
| 23 | AndroMedical | 【海外】アンドロメディカル |
| 24 | Dennoh | 【海外】電脳 |
| 25 | Strawberry | 【海外】Strawberry |
| 26 | MerrySight | 【国内】メリーサイト(SHO-BI) |
| 27 | Aisei | 【国内】アイセイ |
| 28 | UnionMedical | 【国内】ユニオンメディカル |
| 29 | EKCom | 【国内】イー・ケイ・コム |
| 30 | NLS | 【国内】NLS |
| 31 | KuronekoBuyers | 【国内】クロネコバイヤーズ |
| 32 | OFT | 【国内】OFT |
| 33 | Sincere | 【国内】シンシア |
| 34 | IQuality | 【国内】アイクオリティ |
| 35 | MitsuiPharmaceutical | 【国内】三井薬品 |
| 36 | Hokoen | 【国内】芳香園製薬 |
| 37 | Akiba | 【国内】秋葉薬品 |
| 38 | Hawaii | 【海外】808HI |
| 39 | Cellway | 【海外】Cellway |
| 40 | HappyHealthy | 【海外】HappyHealthy |
| 41 | KashiwanohaPharmacy | 【国内】柏の葉薬局 |
| 42 | ToyoShanghai | 【海外】トーヨー上海 |
| 43 | EkimaePharmacy | 【国内】えきまえ薬局 |

## product_categories.main_category

| 値 | 意味 |
|----|------|
| 1 | メインカテゴリ（複数カテゴリ持ちの場合、重複JOIN防止に `= 1` で絞る） |

## 発送方法の解決順序

```sql
COALESCE(s.display_name, olit.shipping_way, N'（配送会社不明）')
```
- `olit.shipping_id` → `shippings.display_name` を優先
- なければ `olit.shipping_way`（テキスト直持ち、旧データ）

## よく使う結合パターン

### 標準チェーン（注文→商品→カテゴリ）

```sql
FROM idoz0804db.orders AS o
INNER JOIN idoz0804db.order_line_items          AS oli  ON o.id   = oli.order_id
INNER JOIN idoz0804db.order_line_item_trackings AS olit ON oli.id = olit.order_line_item_id
INNER JOIN idoz0804db.product_units             AS pu   ON oli.product_unit_id = pu.id
INNER JOIN idoz0804db.products                  AS p    ON pu.product_id = p.id
LEFT  JOIN idoz0804db.product_categories        AS pc   ON p.id = pc.product_id AND pc.main_category = 1
LEFT  JOIN idoz0804db.big_categories            AS bc   ON pc.big_category_id = bc.id
```

### サプライヤー取得（OUTER APPLY パターン）

```sql
OUTER APPLY (
    SELECT TOP 1 supplier_id
    FROM idoz0804db.product_unit_orders
    WHERE product_unit_id = pu.id
    ORDER BY
        CASE WHEN shipping_id = olit.shipping_id THEN 0 ELSE 1 END,
        id
) AS puo
```

### 発送先住所の結合

```sql
INNER JOIN idoz0804db.addresses AS a
    ON a.address_type    = 'OrderShipping'
   AND a.address_type_id = o.id
```

### ゲスト・退会ユーザーの除外

```sql
INNER JOIN idoz0804db.users AS u ON o.user_id = u.id
WHERE u.is_guest   = 0
  AND u.resignation = 0
```
