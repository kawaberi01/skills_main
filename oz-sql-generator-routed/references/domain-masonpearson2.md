# ドメイン知識 — masonpearson2（Mason Pearson）

## スキーマ名

- テーブル参照時は `[masonpearson2].[mason].[テーブル名]` の形式を使う（スキーマ: `mason`）

## orders.status

sql_reference.md の #20168 より確認済みの値:

| 値 | 表示名 |
|----|--------|
| -10 | 予約(在庫切れ) |
| 1 | 入金未確認 |
| 2 | 入金済み |
| 3 | 保留 |
| 5 | 手続き済み |
| 10 | 発送完了 |
| 15 | 発送お知らせ済み |
| 20 | 配達完了 |
| 95 | キャンセル処理待ち |
| 99 | キャンセル |

## product_units.unit_type（ProductUnitType）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | Product | 商品 |
| 1 | NoveltyOneOrder | ノベルティ(1注文に1個) |
| 2 | NoveltyOneItem | ノベルティ(1アイテムに1個) |

## よく使う結合パターン

```sql
FROM [masonpearson2].[mason].[users]  AS u
INNER JOIN [masonpearson2].[mason].[orders] AS o ON u.[id] = o.[user_id]
```

## 年齢計算

```sql
DATEDIFF(YEAR, u.[birthday], GETDATE())
- CASE
    WHEN DATEADD(YEAR, DATEDIFF(YEAR, u.[birthday], GETDATE()), u.[birthday]) > GETDATE()
    THEN 1 ELSE 0
  END AS 年齢
```
