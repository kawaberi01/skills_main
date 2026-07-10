# SQLリファレンス — カテゴリ「（4）集計・分析の相談」

> **対象プロジェクト**: 商用サイト開発・デザイン相談 (`incident`)  
> **対象カテゴリ**: `（4）集計・分析の相談`（category_id: **3**）  
> **対象件数**: tracker 136 / category 3 全35チケット（うち SQL を記録したチケット: **21件**）  
> **DB 種別**:
> - `idoz0804db` — iDrug Store  
> - `irxoz0804db` — iRx (医師向け)  
> - `igeoz0805db` — iGeneric Store  
> - `ibtoz0804db` — iBeauty Store  
> - `masonpearson2` / `mason` スキーマ — Mason Pearson  

---

## 早見表

| # | チケット | 件名 | DB | 主テーブル | 担当 |
|---|---------|------|-----|-----------|------|
| 1 | [#21583](#1-チケット-21583--定期購入利用者数調査) | 定期購入利用者数調査 | idoz0804db | periodical_order_line_items | 山本 瑞樹 |
| 2 | [#21518](#2-チケット-21518--商品発送用注文抽出) | 商品発送用注文抽出 | idoz0804db | orders / addresses | 石川 勝 |
| 3 | [#20337](#3-チケット-20337--irx-ltv分析) | 【iRx】LTV分析（最終版） | irxoz0804db | orders / users | 山本 瑞樹 |
| 4 | [#18913](#4-チケット-18913--アフィリエイト注文調査詳細版) | アフィリエイト注文調査（詳細版） | idoz0804db | orders / affiliate_orders | 山本 瑞樹 |
| 5 | [#22618](#5-チケット-22618--月次発送方法別集計) | 月次発送方法別集計 | idoz0804db | order_line_item_trackings | 山本 瑞樹 |
| 6 | [#18283](#6-チケット-18283--otc医薬品商品リスト抽出) | OTC医薬品商品リスト抽出 | idoz0804db | products / product_categories | 石川 勝 |
| 7 | [#18289/#20264/#20891/#17557/#16140/#15876](#7-チケット-18289--20264--20891--17557--16140--15876--キャンペーン利用者の発送用情報抽出テンプレート) | キャンペーン利用者 発送情報抽出 (テンプレート) | idoz0804db | order_campaigns / addresses | 山本 瑞樹 |
| 8 | [#20168](#8-チケット-20168--mason-pearson-顧客情報抽出) | Mason Pearson 顧客情報抽出 | masonpearson2 | users / orders | 石川 勝 |
| 9 | [#18883/#16734/#15353](#9-チケット-18883--16734--15353--irx-cuenote-配信リスト作成) | iRx Cuenote 配信リスト作成 | irxoz0804db | users / addresses | 石川 勝 |
| 10 | [#18251](#10-チケット-18251--ftlサプライヤー商品抽出) | FTL サプライヤー商品抽出 | idoz0804db | product_unit_orders / products | 山本 瑞樹 |
| 11 | [#22610](#11-チケット-22610--ibサプライヤーhkリフィルアイテム抽出) | 【IB】サプライヤーHKリフィルアイテム抽出 | ibtoz0804db | product_units | 荒井 克之進 |
| 12 | [#23369](#12-チケット-23369--ig分析用データの抽出依頼) | 【IG】分析用データの抽出依頼（RFM + キャンペーン分析） | igeoz0805db | orders | 西澤 文弥 |
| ref | [#17729](#参考-チケット-17729--アフィリエイト注文調査基本版--17729-の前バージョン) | アフィリエイト注文調査（基本版・#18913の前版） | idoz0804db | orders / affiliate_orders | 山本 瑞樹 |
| ref | [#20001](#参考-チケット-20001--irx-ltv分析前バージョン) | iRx LTV分析（前バージョン・#20337の前版） | irxoz0804db | orders / users | 山本 瑞樹 |

---

## 1. チケット #21583 — 定期購入利用者数調査

**件名**: 【ID】一部商品の定期購入利用者数の調査依頼  
**ジャーナル**: #39988（山本 瑞樹、private_notes: true）  
**用途**: 指定した商品 ID に対して定期購入申込中（契約中/停止中）のユーザーを一覧化する  
**DB**: `idoz0804db`  
**テーブル**: `periodical_order_line_items`, `users`, `product_units`, `products`

```sql
SELECT DISTINCT
    p.id  AS '商品ID',
    p.name AS '商品名',
    u.email AS 'メールアドレス',
    u.id  AS '顧客ID',
    CASE WHEN poli.status = 1 THEN '契約中' ELSE '停止中' END AS 'ステータス'
FROM idoz0804db.idoz0804db.periodical_order_line_items poli
INNER JOIN idoz0804db.idoz0804db.users u         ON poli.user_id = u.id
INNER JOIN idoz0804db.idoz0804db.product_units pu ON poli.product_unit_id = pu.id
INNER JOIN idoz0804db.idoz0804db.products p       ON pu.product_id = p.id
WHERE p.id IN (47858, 55658, 317715)   -- ★ 対象商品 ID を指定
  AND poli.status IN (0, 1)            -- 0: 停止中, 1: 契約中
ORDER BY p.id, u.email;
```

---

## 2. チケット #21518 — 商品発送用注文抽出

**件名**: 商品発送用：対象注文抽出依頼  
**ジャーナル**: #39954（初版）/ #39995（ゲスト除外改訂版）（石川 勝、private_notes: true）  
**用途**: 指定した商品 ID を含む注文の発送先・顧客情報を一覧化する  
**DB**: `idoz0804db`  
**テーブル**: `orders`, `order_line_items`, `product_units`, `products`, `addresses`, `users`（改訂版のみ）

### 初版（全顧客対象）

```sql
SELECT
    o.no                            AS '注文番号',
    o.created_at                    AS '注文日時',
    MIN(p.id)                       AS '該当商品の最小ID',
    o.user_id                       AS 'ユーザーID',
    (a.last_name + N' ' + a.first_name)  AS '氏名',
    a.postcode                      AS '郵便番号',
    (a.prefecture + a.city + a.address_1
     + ISNULL(a.address_2, '') + ISNULL(a.address_3, '')) AS '住所',
    o.id                            AS '注文ID',
    COUNT(p.id)                     AS '注文内の該当商品数',
    MIN(p.name)                     AS '商品名',
    a.telephone                     AS '電話番号',
    CASE WHEN COUNT(*) OVER (PARTITION BY o.user_id) > 1
         THEN '★重複あり' ELSE '' END AS '重複フラグ'
FROM idoz0804db.orders AS o
INNER JOIN idoz0804db.order_line_items AS ol ON o.id = ol.order_id
INNER JOIN idoz0804db.product_units    AS pu ON ol.product_unit_id = pu.id
INNER JOIN idoz0804db.products         AS p  ON pu.product_id = p.id
INNER JOIN idoz0804db.addresses        AS a
       ON a.address_type = 'OrderShipping' AND a.address_type_id = o.id
WHERE p.id IN (330158, 317384, /* ★ 対象商品 ID を列挙 */)
  AND o.status IN (3, 4)                -- 入金確認済 / 発送済
  AND o.created_at >= '2026-01-01'
  AND o.created_at <  '2026-02-01'      -- ★ 集計期間
GROUP BY o.id, o.no, o.created_at, o.user_id,
         a.last_name, a.first_name, a.postcode,
         a.prefecture, a.city, a.address_1, a.address_2, a.address_3,
         a.telephone
ORDER BY o.created_at;
```

### 改訂版（ゲスト・退会ユーザー除外）

初版に以下を追加：

```sql
-- テーブル追加
INNER JOIN idoz0804db.users AS u ON o.user_id = u.id

-- WHERE 条件追加
  AND u.is_guest = 0
  AND u.resignation = 0
```

---

## 3. チケット #20337 — iRx LTV分析

**件名**: 【iRx】LTV分析に用いる売上データの抽出依頼  
**ジャーナル**: #39133（山本 瑞樹、private_notes: true）  
**前バージョンチケット**: [#20001](#参考-チケット-20001--irx-ltv分析前バージョン)  
**用途**: iRx 医師会員のセグメント（小児科/眼科/動物病院/製薬企業/その他）別・期間別 LTV 集計  
**DB**: `irxoz0804db`  
**テーブル**: `users`, `addresses`, `orders`

```sql
WITH SegmentedUsers AS (
    SELECT
        u.[id]  AS user_id,
        COALESCE(a.[hospital_name], N'（施設名なし）') AS hospital_name,
        a.[hospital_department],
        a.[country_id],
        u.[doctor_type],
        u.[billing_address_id],
        CASE
            WHEN a.[hospital_name]       LIKE N'%小児%'
              OR a.[hospital_name]       LIKE N'%こども%'
              OR a.[hospital_name]       LIKE N'%新生児%'
              OR ISNULL(a.[hospital_department],'') LIKE N'%小児%'
              OR ISNULL(a.[hospital_department],'') LIKE N'%こども%'
              OR ISNULL(a.[hospital_department],'') LIKE N'%新生児%'
            THEN N'小児科'
            WHEN a.[hospital_name]       LIKE N'%眼科%'
              OR a.[hospital_name]       LIKE N'%アイクリニック%'
              OR ISNULL(a.[hospital_department],'') LIKE N'%眼科%'
              OR ISNULL(a.[hospital_department],'') LIKE N'%アイクリニック%'
            THEN N'眼科'
            WHEN u.[doctor_type] = 1 THEN N'動物病院'
            WHEN a.[country_id] = 109 AND u.[doctor_type] = 3 THEN N'製薬企業'
            WHEN a.[country_id] = 109 AND u.[doctor_type] = 4 THEN N'研究機関/大学'
            ELSE N'その他'
        END AS segment
    FROM irxoz0804db.[users] u
    LEFT JOIN irxoz0804db.[addresses] a
           ON u.[billing_address_id] = a.[id]
    WHERE u.[type_id] = 1   -- 医師会員のみ
)
SELECT
    N'(2024/12～2025/11)' AS 期間,
    su.segment            AS セグメント,
    COUNT(DISTINCT su.user_id)  AS ユーザー数,
    COUNT(DISTINCT o.[id])      AS 購買回数,
    SUM(o.[grand_total])        AS 受注金額
FROM irxoz0804db.[orders] o
INNER JOIN SegmentedUsers su ON o.[user_id] = su.user_id
WHERE o.[created_at] >= '2024-12-01'
  AND o.[created_at] <  '2025-12-01'
  AND o.[order_status_id] != 99   -- キャンセル除外
GROUP BY su.segment
-- ★ 以下 UNION ALL で各期間分を続ける（同パターンで最大5期間）
UNION ALL
-- (2023/12～2024/11), (2022/12～2023/11), ... を同様に追加
ORDER BY 期間, セグメント, 受注金額 DESC;
```

---

## 4. チケット #18913 — アフィリエイト注文調査（詳細版）

**件名**: アフィリエイト注文調査  
**ジャーナル**: #37714（山本 瑞樹、private_notes: true）  
**前バージョンチケット**: [#17729](#参考-チケット-17729--アフィリエイト注文調査基本版--17729-の前バージョン)  
**用途**: カンマ区切りの注文番号リストから顧客属性・購買情報・アフィリエイト情報を抽出する  
**DB**: `idoz0804db`  
**テーブル**: `orders`, `order_line_items`, `product_units`, `products`, `users`, `affiliate_orders`, `mail_magazine_address`

```sql
-- ★ 注文番号をカンマ区切りで入力
DECLARE @order_nos NVARCHAR(MAX) = 'ID-251109-192445, ID-251108-123456';

-- XML 分割で一時テーブルに投入
IF OBJECT_ID('tempdb..#target_orders') IS NOT NULL DROP TABLE #target_orders;
CREATE TABLE #target_orders (order_no NVARCHAR(50));
DECLARE @xml XML;
SET @xml = N'<root><item>' + REPLACE(@order_nos, ',', '</item><item>') + '</item></root>';
INSERT INTO #target_orders (order_no)
SELECT LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)')))
FROM @xml.nodes('/root/item') T(c)
WHERE LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) <> '';

;WITH user_order_counts AS (
    SELECT o.user_id, COUNT(*) AS total_orders
    FROM [idoz0804db].[orders] o
    GROUP BY o.user_id
)
SELECT
    'JANET'         AS ASP,
    o.no            AS 注文番号,
    CASE WHEN u.is_guest = 1 THEN N'ゲスト' ELSE N'会員' END AS ゲスト購入か否か,
    pu.product_id   AS 購入商品ID,
    pu.id           AS サイズID,
    p.name          AS 購入商品名称,
    oli.total       AS 購入金額,
    u.id            AS UID,
    u.created_at    AS 登録日,
    COALESCE(cnt.total_orders, 0) AS 累計購入回数,
    CASE WHEN EXISTS (
        SELECT 1 FROM [idoz0804db].[mail_magazine_address] mma
        WHERE mma.email = u.email
    ) THEN 1 ELSE 0 END AS メルマガ許可フラグ,
    CASE WHEN u.information_mail = 1 THEN 1 ELSE 0 END AS おしらせ許可フラグ
FROM #target_orders tgt
JOIN [idoz0804db].[orders]           o   ON o.no = tgt.order_no
LEFT JOIN [idoz0804db].[affiliate_orders] ao ON ao.order_id = o.id
JOIN [idoz0804db].[order_line_items] oli ON oli.order_id = o.id
JOIN [idoz0804db].[product_units]    pu  ON pu.id = oli.product_unit_id
JOIN [idoz0804db].[products]         p   ON p.id = pu.product_id
JOIN [idoz0804db].[users]            u   ON u.id = o.user_id
LEFT JOIN user_order_counts          cnt ON cnt.user_id = u.id
ORDER BY o.no, oli.id;

DROP TABLE #target_orders;
```

---

## 5. チケット #22618 — 月次発送方法別集計

**件名**: 【ID】商品の発送方法を計測してほしい  
**添付ファイル**: `22618_発送方法_monthly_report.sql`（attachment ID: 20793、9,922 bytes）  
**作成日**: 2026-02-26  
**用途**: 会計期・月別・発送方法別・サプライヤー別に出荷実績を集計する（月次レポート）  
**DB**: `idoz0804db`  
**テーブル**: `orders`, `order_line_items`, `order_line_item_trackings`, `product_units`, `products`, `product_categories`, `big_categories`, `product_unit_orders`, `shippings`

```sql
USE idoz0804db;
GO

-- ★ サプライヤー(BigCategory)フィルタ設定
-- NULL = 全カテゴリ対象。特定カテゴリに絞る場合は数値をセット。
DECLARE @big_category_id INT = NULL;

-- ★ 期間設定（44期〜46期 = 2023-03-01〜2026-02-28）
DECLARE @date_from DATE = '2023-03-01';
DECLARE @date_to   DATE = '2026-02-28';

SELECT
    -- 会計期（3月始まり / 期 = 開始年 - 1979）
    CASE
        WHEN MONTH(o.created_at) >= 3 THEN YEAR(o.created_at) - 1979
        ELSE YEAR(o.created_at) - 1 - 1979
    END AS 会計期,
    YEAR(o.created_at)  AS 注文年,
    MONTH(o.created_at) AS 注文月,
    COALESCE(s.display_name, olit.shipping_way, N'（配送会社不明）') AS 発送方法,
    bc.name             AS 上部カテゴリ,
    puo.supplier_id     AS サプライヤーID,
    CASE puo.supplier_id
        WHEN  0 THEN N'【国内】倉庫'      WHEN  1 THEN N'【国内】オズ'
        WHEN  2 THEN N'【海外】BK'        WHEN  3 THEN N'【海外】WW'
        WHEN  4 THEN N'【海外】ISA'       WHEN  5 THEN N'【海外】エンドア'
        WHEN  9 THEN N'【国内】UPJ'       WHEN 26 THEN N'【国内】メリーサイト(SHO-BI)'
        WHEN 27 THEN N'【国内】アイセイ'  WHEN 30 THEN N'【国内】NLS'
        -- (他のサプライヤーは本番 SQL 参照)
        ELSE N'（不明）'
    END AS サプライヤー名,
    COUNT(DISTINCT o.id)    AS 注文件数,
    COUNT(DISTINCT olit.id) AS 出荷件数,
    SUM(olit.quantity)      AS 出荷点数
FROM idoz0804db.orders AS o
INNER JOIN idoz0804db.order_line_items         AS oli  ON o.id  = oli.order_id
INNER JOIN idoz0804db.order_line_item_trackings AS olit ON oli.id = olit.order_line_item_id
INNER JOIN idoz0804db.product_units            AS pu   ON oli.product_unit_id = pu.id
INNER JOIN idoz0804db.products                 AS p    ON pu.product_id = p.id
LEFT  JOIN idoz0804db.product_categories       AS pc   ON p.id = pc.product_id AND pc.main_category = 1
LEFT  JOIN idoz0804db.big_categories           AS bc   ON pc.big_category_id = bc.id
OUTER APPLY (
    SELECT TOP 1 supplier_id
    FROM idoz0804db.product_unit_orders
    WHERE product_unit_id = pu.id
    ORDER BY CASE WHEN shipping_id = olit.shipping_id THEN 0 ELSE 1 END, id
) AS puo
LEFT  JOIN idoz0804db.shippings                AS s    ON olit.shipping_id = s.id
WHERE o.created_at >= @date_from
  AND o.created_at <  DATEADD(DAY, 1, @date_to)
  AND p.shipment <> 0   -- 国内発送商品を除外
  AND (olit.shipping_id IS NOT NULL
       OR (olit.shipping_way IS NOT NULL AND olit.shipping_way <> ''))
  AND (@big_category_id IS NULL OR bc.id = @big_category_id)
GROUP BY
    CASE WHEN MONTH(o.created_at) >= 3 THEN YEAR(o.created_at) - 1979
         ELSE YEAR(o.created_at) - 1 - 1979 END,
    YEAR(o.created_at), MONTH(o.created_at),
    COALESCE(s.display_name, olit.shipping_way, N'（配送会社不明）'),
    bc.name, puo.supplier_id,
    CASE puo.supplier_id WHEN 0 THEN N'【国内】倉庫' /* ... */ ELSE N'（不明）' END
ORDER BY 会計期, 注文年, 注文月, 発送方法;
GO

-- 補足: shipping_id が NULL のレコード件数確認
SELECT
    YEAR(olit.created_at) AS 年, MONTH(olit.created_at) AS 月,
    COUNT(*) AS 配送会社未設定件数,
    COUNT(CASE WHEN olit.shipping_way IS NOT NULL AND olit.shipping_way <> ''
               THEN 1 END) AS 配送方法テキストあり件数
FROM idoz0804db.order_line_item_trackings AS olit
WHERE olit.shipping_id IS NULL
  AND olit.created_at >= '2023-03-01'
  AND olit.created_at <  '2026-03-01'
GROUP BY YEAR(olit.created_at), MONTH(olit.created_at)
ORDER BY 年, 月;
GO

-- 参考: shippings マスタ確認
SELECT id, name, display_name, delivery_day FROM idoz0804db.shippings ORDER BY id;
GO
```

---

## 6. チケット #18283 — OTC医薬品商品リスト抽出

**件名**: 【ID】OTC医薬品の商品リストが欲しい  
**ジャーナル**: #36949（石川 勝、private_notes: true）  
**添付ファイル（別途）**: `update_products.sql`（attachment ID: 18943、38,041 bytes）— 商品名一括 UPDATE 用  
**用途**: `product_type = 3`（OTC医薬品）の商品に紐づく全カテゴリ情報をピボットして出力する  
**DB**: `idoz0804db`  
**テーブル**: `products`, `product_categories`, `big_categories`, `mdl_categories`, `sml_categories`

```sql
WITH pc AS (
    SELECT
        a.product_id,
        a.main_category,
        CONCAT(
            a.main_category, ' [',
            CAST(a.big_category_id AS varchar(5)), ':', b.name, ' > ',
            CAST(a.mdl_category_id AS varchar(5)), ':', c.name, ' > ',
            CAST(a.sml_category_id AS varchar(5)), ':', d.name, ']'
        ) AS cat_text,
        ROW_NUMBER() OVER (
            PARTITION BY a.product_id
            ORDER BY CASE WHEN a.main_category = 1 THEN 0 ELSE 1 END, a.id
        ) AS rn
    FROM [idoz0804db].[idoz0804db].[product_categories] a
    INNER JOIN [idoz0804db].[idoz0804db].[big_categories] b ON a.big_category_id = b.id
    INNER JOIN [idoz0804db].[idoz0804db].[mdl_categories] c ON a.mdl_category_id = c.id
    INNER JOIN [idoz0804db].[idoz0804db].[sml_categories] d ON a.sml_category_id = d.id
),
pc8 AS (
    SELECT product_id, rn, cat_text
    FROM pc
    WHERE rn <= 8
)
SELECT
    aa.id,
    aa.name,
    aa.product_type,
    CASE aa.status
        WHEN 1 THEN N'欠品'           WHEN 2 THEN N'新商品非表示'
        WHEN 4 THEN N'廃番'           WHEN 5 THEN N'英語商品'
        WHEN 6 THEN N'サンプル商品'   WHEN 7 THEN N'その他商品(Web非表示で購入可能)'
        WHEN 8 THEN N'発売前'         WHEN 9 THEN N'販売終了'
        ELSE N'不明'
    END AS status_name,
    aa.short_pop,
    MAX(CASE WHEN p.rn = 1 THEN p.cat_text END) AS cat1,
    MAX(CASE WHEN p.rn = 2 THEN p.cat_text END) AS cat2,
    MAX(CASE WHEN p.rn = 3 THEN p.cat_text END) AS cat3,
    MAX(CASE WHEN p.rn = 4 THEN p.cat_text END) AS cat4,
    MAX(CASE WHEN p.rn = 5 THEN p.cat_text END) AS cat5,
    MAX(CASE WHEN p.rn = 6 THEN p.cat_text END) AS cat6,
    MAX(CASE WHEN p.rn = 7 THEN p.cat_text END) AS cat7,
    MAX(CASE WHEN p.rn = 8 THEN p.cat_text END) AS cat8
FROM [idoz0804db].[idoz0804db].[products] aa
LEFT JOIN pc8 p ON p.product_id = aa.id
WHERE aa.product_type = 3   -- OTC医薬品のみ
GROUP BY aa.id, aa.name, aa.product_type, aa.status, aa.short_pop
ORDER BY aa.id;
```

---

## 7. チケット #18289 / #20264 / #20891 / #17557 / #16140 / #15876 — キャンペーン利用者の発送用情報抽出（テンプレート）

**件名**（各チケット）:
- #15876: 【ID】キャンペーンID：9199 利用者の抽出依頼（初回）
- #16140: 【ID】キャンペーンID：9199 利用者の抽出依頼（追加分）/ 9199,9202,9205,9212,9213,9214 の複合版も含む
- #18289: 【ID】キャンペーンID：9290 利用者の抽出依頼
- #20264: 【ID】キャンペーンID：9383 利用者の抽出依頼
- #17557: 【ID】キャンペーンID：9274 利用者の抽出依頼
- #20891: 【ID】キャンペーンID：9422 利用者の抽出依頼

> **注意**: #16141（9202等複数ID）はファイルサーバーへの配置のみでジャーナルへの SQL 記録なし

**担当**: 山本 瑞樹  
**用途**: お米プレゼントなど特定キャンペーン利用者の配送先情報を抽出して倉庫（JPL）へ連携する  
**DB**: `idoz0804db`  
**テーブル**: `orders`, `order_campaigns`, `addresses`

> 💡 `@campaign_id` と `@date_from` / `@date_to` を変更するだけで再利用できるテンプレート

```sql
-- ★ パラメータ（依頼ごとに変更）
-- campaign_id: 9290（#18289）/ 9383（#20264）/ 9422（#20891）
-- 期間フィルタ: #20891 のみ追加（他は不要）

SELECT
    o.id                                                 AS order_id,
    o.user_id                                            AS customer_id,
    (a.last_name + N' ' + a.first_name)                 AS name,
    a.postcode                                           AS zipcode,
    (a.prefecture + a.city + a.address_1
     + ISNULL(a.address_2,'') + ISNULL(a.address_3,'')) AS address,
    a.telephone                                          AS phone,
    oc.campaign_id                                       AS campaign_id
    -- #20891 のみ追加:
    -- ,o.created_at AS created_at
FROM idoz0804db.orders AS o
INNER JOIN idoz0804db.order_campaigns AS oc
       ON oc.order_id = o.id
INNER JOIN idoz0804db.addresses AS a
       ON a.address_type     = 'OrderShipping'
      AND a.address_type_id  = o.id
WHERE oc.campaign_id = 9383   -- ★ キャンペーン ID を変更
  AND o.status IN (2, 3, 4)   -- 入金済+保留+発送済（入金待ち・キャンセル除外）
  -- ★ 期間指定が必要な場合（#20891）:
  -- AND o.created_at > '2026-01-09 00:00:00.000'
  -- AND o.created_at < '2026-01-15 23:59:59.999'
ORDER BY o.updated_at DESC;
```

---

## 8. チケット #20168 — Mason Pearson 顧客情報抽出

**件名**: 【MP】顧客情報抽出依頼  
**ジャーナル**: #39061（石川 勝、private_notes: true）  
**用途**: ホリデーシーズン（11〜12月）の3ヵ年比較のために購入顧客の性別・年齢・注文状況を抽出する  
**DB**: `masonpearson2`（`mason` スキーマ）  
**テーブル**: `users`, `orders`

```sql
SELECT
    u.[id]       AS [顧客ID],
    u.[gender]   AS [性別],
    u.[birthday] AS [誕生日],
    -- 年齢計算
    DATEDIFF(YEAR, u.[birthday], GETDATE())
    - CASE
        WHEN DATEADD(YEAR, DATEDIFF(YEAR, u.[birthday], GETDATE()), u.[birthday]) > GETDATE()
        THEN 1 ELSE 0
      END AS [年齢],
    CASE o.[status]
        WHEN -10 THEN '予約(在庫切れ)' WHEN 1  THEN '入金未確認'
        WHEN 2   THEN '入金済み'        WHEN 3  THEN '保留'
        WHEN 5   THEN '手続き済み'      WHEN 10 THEN '発送完了'
        WHEN 15  THEN '発送お知らせ済み' WHEN 20 THEN '配達完了'
        WHEN 95  THEN 'キャンセル処理待ち' WHEN 99 THEN 'キャンセル'
        ELSE CAST(o.[status] AS VARCHAR)
    END AS [ステータス名],
    o.[created_at] AS [注文作成日]
FROM [masonpearson2].[mason].[users]  AS u
INNER JOIN [masonpearson2].[mason].[orders] AS o ON u.[id] = o.[user_id]
WHERE
    -- ★ 対象期間（3ヵ年のホリデーシーズン）
    (o.[created_at] >= '2023-11-01' AND o.[created_at] < '2024-01-01')
    OR
    (o.[created_at] >= '2024-11-01' AND o.[created_at] < '2025-01-01')
    OR
    (o.[created_at] >= '2025-11-01' AND o.[created_at] < '2026-01-01')
ORDER BY o.[created_at];
```

---

## 9. チケット #18883 / #16734 / #15353 — iRx Cuenote 配信リスト作成

**件名**（各チケット）:
- #15353: 【iRx】Cuenote配信リストの作成依頼（お盆前発注促進 / ジャーナル #33354）
- #16734: 【iRx】Cuenote配信リストの作成依頼（厚生局指導・申請方法変更案内 / ジャーナル #35380）
- #18883: 【iRx】Cuenote配信リストの作成依頼（一般案内 / ジャーナル #37715）

**担当**: 石川 勝（private_notes: true 全件）  
**用途**: iRx 医師会員への一斉メール配信のための Cuenote アドレス帳用 CSV データを生成する  
**DB**: `irxoz0804db`  
**テーブル**: `users`, `addresses`, `user_additional_mail_addresses`

> 出力形式: `email, hospital_name, user_name` のヘッダー行 + データ行（CSV 用 UNION ALL 構造）

```sql
-- ヘッダー行
SELECT 'email' AS email, 'hospital' AS hospital_name, 'name' AS user_name
UNION ALL
-- 追加メールアドレス登録済み会員
SELECT
    '"' + u.email            + '"',
    '"' + b.hospital_name    + '"',
    '"' + b.user_name        + N'様"'
FROM irxoz0804db.irxoz0804db.users u
INNER JOIN irxoz0804db.irxoz0804db.addresses a
       ON u.billing_address_id = a.id
LEFT  JOIN irxoz0804db.irxoz0804db.user_additional_mail_addresses b
       ON u.id = b.user_id
WHERE u.type_id = 1                                   -- 医師会員のみ
  AND a.country_id = 109                              -- 国内住所
  AND u.information_mail = 1                          -- メール許可
  AND (a.hospital_name NOT LIKE '%テスト%' OR a.hospital_name IS NULL)
  AND u.last_name  NOT LIKE '%テスト%'
  AND u.first_name NOT LIKE '%テスト%'
  AND a.last_name  NOT LIKE '%テスト%'
  AND a.first_name NOT LIKE '%テスト%'
  AND u.email NOT LIKE '%@ozinter.jp'
  AND u.email NOT LIKE '%@ozinter.co.jp'
  AND b.address_type = 3                             -- Cuenote 用アドレス区分
UNION ALL
-- 追加メールアドレス未登録会員（請求先住所の姓名を使用）
SELECT DISTINCT
    '"' + u.email                           + '"',
    '"' + a.hospital_name                   + '"',
    '"' + (a.last_name + a.first_name) + N'様"'
FROM irxoz0804db.irxoz0804db.users u
INNER JOIN irxoz0804db.irxoz0804db.addresses a
       ON u.billing_address_id = a.id
LEFT  JOIN irxoz0804db.irxoz0804db.user_additional_mail_addresses b
       ON u.id = b.user_id
WHERE u.type_id = 1
  AND a.country_id = 109
  AND u.information_mail = 1
  AND (a.hospital_name NOT LIKE '%テスト%' OR a.hospital_name IS NULL)
  AND u.last_name  NOT LIKE '%テスト%'
  AND u.first_name NOT LIKE '%テスト%'
  AND a.last_name  NOT LIKE '%テスト%'
  AND a.first_name NOT LIKE '%テスト%'
  AND u.email NOT LIKE '%@ozinter.jp'
  AND u.email NOT LIKE '%@ozinter.co.jp'
  AND b.id IS NULL;                                  -- 追加アドレス未登録
```

---

## 12. チケット #23369 — 【IG】分析用データの抽出依頼（RFM分析 + キャンペーン分析）

**件名**: 【IG】分析用データの抽出依頼  
**チケットID**: #23369  
**申請者**: 西澤 文弥  
**カテゴリ**: （4）集計・分析の相談  
**重要度**: Ｓ（絶対にやる）  
**緊急度**: 1週間以内  
**作成日**: 2026-03-13  
**用途**: 顧客分析目的のためのRFMデータ抽出・セールキャンペーン売上分析  
**DB**: `igeoz0805db`（iGeneric Store）  
**テーブル**: `orders`, `addresses`  
**SQL ファイル**: [doc/spec/rfm_campaign_analysis.sql](../../doc/spec/rfm_campaign_analysis.sql)

### 概要

**⑴ RFM分析に使用** — 3つの期間パターン

各期間で以下を抽出：
- 顧客ID
- 注文番号
- 注文日時
- 合計金額

対象期間：
1. **2025年1月1日～2025年12月31日**（通年1年）
2. **2025年3月1日～2025年8月31日**（上期6ヵ月）
3. **2025年9月1日～2026年2月28日**（下期6ヵ月）

**⑵ セールキャンペーン見直しに使用** — 7つの期間パターン

各期間で以下を抽出：
- 顧客ID
- 注文番号
- 注文日時
- 合計金額
- **支払い方法**

対象期間：
1. 2025年4月11日～4月21日
2. 2025年5月9日～5月19日
3. 2025年6月13日～6月23日
4. 2025年8月8日～8月18日
5. 2025年9月12日～9月22日
6. 2025年10月10日～10月20日
7. 2026年1月16日～1月22日

### ステータスフィルタ

| 値 | ステータス | 含める |
|----|----------|--------|
| 1 | PaymentNotConfirmed（未入金） | ✗ |
| 2 | PaymentConfirmed（入金済み） | ✓ |
| 3 | Arranged（お手配済み） | ✓ |
| 4 | PartShipped（一部発送完了） | ✓ |
| 5 | Shipped（発送完了） | ✓ |
| 9 | Cancel（キャンセル） | ✗ |

**フィルタ条件**: `o.status IN (2, 3, 4, 5)`

### SQL パターン（テンプレート）

```sql
-- ★ 期間パラメータ（依頼ごとに変更）
DECLARE @date_from DATE = '2025-01-01';
DECLARE @date_to   DATE = '2025-12-31';

-- ★ RFM分析用（支払い方法なし）
SELECT
    o.user_id        AS '顧客ID',
    o.no             AS '注文番号',
    o.created_at     AS '注文日時',
    o.total          AS '合計金額'
FROM [igeoz0805db].[igeoz0805db].orders AS o
WHERE
    o.created_at >= @date_from
    AND o.created_at < DATEADD(DAY, 1, @date_to)
    AND o.status IN (2, 3, 4, 5)  -- 入金済み以降
ORDER BY o.user_id, o.created_at;

-- ★ キャンペーン分析用（支払い方法を含む）
SELECT
    o.user_id              AS '顧客ID',
    o.no                   AS '注文番号',
    o.created_at           AS '注文日時',
    o.total                AS '合計金額',
    o.payment_method       AS '支払い方法'
FROM [igeoz0805db].[igeoz0805db].orders AS o
WHERE
    o.created_at >= @date_from
    AND o.created_at < DATEADD(DAY, 1, @date_to)
    AND o.status IN (2, 3, 4, 5)  -- 入金済み以降
ORDER BY o.user_id, o.created_at;
```

### 出力形式

- **形式**: Excel（各期間パターン / クエリごと）
- **文字コード**: UTF-8
- **列名**: 日本語（1行目ヘッダー）

---

> **最新版は [チケット #18913](#4-チケット-18913--アフィリエイト注文調査詳細版) を参照。**  
> 本バージョンは注文番号変数入力と XML 分割処理が基本形。#18913 では ASP 名 'JANET' の出力列や `information_mail` フラグが追加された。

**ジャーナル**: 山本 瑞樹（private_notes: true）

```sql
DECLARE @order_nos NVARCHAR(MAX) = 'ID-250807-687934';

IF OBJECT_ID('tempdb..#target_orders') IS NOT NULL DROP TABLE #target_orders;
CREATE TABLE #target_orders (order_no NVARCHAR(50) NOT NULL);
DECLARE @xml XML;
SET @xml = N'<root><item>' + REPLACE(@order_nos, ',', '</item><item>') + '</item></root>';
INSERT INTO #target_orders (order_no)
SELECT LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)')))
FROM @xml.nodes('/root/item') T(c)
WHERE LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) <> '';

;WITH user_order_counts AS (
    SELECT o.user_id, COUNT(*) AS total_orders
    FROM [idoz0804db].[orders] o GROUP BY o.user_id
)
SELECT
    o.no           AS 注文番号,
    CASE WHEN u.is_guest = 1 THEN N'ゲスト' ELSE N'会員' END AS ゲスト購入か否か,
    pu.product_id  AS 購入商品ID,
    pu.id          AS サイズID,
    p.name         AS 購入商品名称,
    oli.total      AS 購入金額,
    u.id           AS UID,
    u.created_at   AS 登録日,
    COALESCE(cnt.total_orders, 0) AS 累計購入回数,
    CASE WHEN EXISTS (SELECT 1 FROM [idoz0804db].[mail_magazine_address] mma
                      WHERE mma.email = u.email)
         THEN 1 ELSE 0 END AS メルマガ許可フラグ
FROM #target_orders tgt
JOIN [idoz0804db].[orders]           o   ON o.no = tgt.order_no
LEFT JOIN [idoz0804db].[affiliate_orders] ao ON ao.order_id = o.id
JOIN [idoz0804db].[order_line_items] oli ON oli.order_id = o.id
JOIN [idoz0804db].[product_units]    pu  ON pu.id = oli.product_unit_id
JOIN [idoz0804db].[products]         p   ON p.id = pu.product_id
JOIN [idoz0804db].[users]            u   ON u.id = o.user_id
LEFT JOIN user_order_counts          cnt ON cnt.user_id = u.id
ORDER BY o.no, oli.id;

DROP TABLE #target_orders;
```

---

## 参考: チケット #20001 — iRx LTV分析（前バージョン）

> **最新版は [チケット #20337](#3-チケット-20337--irx-ltv分析) を参照。**  
> 本バージョンは「施設名がマスク化されているため小児科・眼科セグメント判定不可」という制約を注記した修正版。  
> SQL の構造は #20337 と同一（CTE `SegmentedUsers` + UNION ALL 集計）。

---

## 10. チケット #18251 — FTLサプライヤー商品抽出

**件名**: 【ID】登録商品の抽出依頼  
**ジャーナル**: #36882（山本 瑞樹、private_notes: true）  
**用途**: サプライヤーID=20（FTL）の商品ユニットを一覧化する（商品ステータス・サイズ情報・発送方法を含む）  
**DB**: `idoz0804db`  
**テーブル**: `product_unit_orders`, `product_units`, `products`, `product_unit_groups`

```sql
SELECT
    p.[id]   AS 商品ID,
    p.[name] AS 商品名,
    CASE p.[status]
        WHEN 0 THEN '通常表示'       WHEN 1 THEN '欠品'
        WHEN 2 THEN '新商品非表示'   WHEN 4 THEN '廃番'
        WHEN 5 THEN '英語商品'       WHEN 6 THEN 'サンプル商品'
        WHEN 7 THEN 'その他商品(Web非表示で購入可能)'
        WHEN 8 THEN '発売前'         WHEN 9 THEN '販売終了'
    END AS 商品ステータス,
    pu.[name]  AS サイズ名,
    CASE pu.[status]
        WHEN 0 THEN '取扱中止'       WHEN 1 THEN '取扱中'
        WHEN 2 THEN '在庫整理'
    END AS サイズステータス,
    COALESCE(pug.[name], '-')              AS サイズグループ,
    COALESCE(pu.[group_unit_name], '-')    AS サイズグループ内表示名,
    puo.[shipping]                         AS 発送方法
FROM [idoz0804db].[product_unit_orders] puo
INNER JOIN [idoz0804db].[product_units]  pu  ON puo.[product_unit_id]       = pu.[id]
INNER JOIN [idoz0804db].[products]       p   ON pu.[product_id]             = p.[id]
LEFT  JOIN [idoz0804db].[product_unit_groups] pug ON pu.[product_unit_group_id] = pug.[id]
WHERE puo.[supplier_id] = 20   -- FTL
  AND puo.[output] = 1
GROUP BY
    p.[id], p.[name], p.[status],
    pu.[id], pu.[name], pu.[status],
    pu.[product_unit_group_id], pug.[name], pu.[group_unit_name],
    puo.[shipping]
ORDER BY p.[id], pu.[id];
```

---

## 11. チケット #22610 — 【IB】サプライヤーHKリフィルアイテム抽出

**件名**: 【IB】サプライヤーHK商品のリフィルアイテムの抽出について  
**添付ファイル**: `260225_HK_英語名（発注用）に「Refill」を含まないユニット一覧.sql`（attachment ID: 20799、2,344 bytes）  
**作成日**: 2026-02-26（荒井 克之進）  
**用途**: HK から提供されたサプライヤー商品IDリストのうち、英語名（発注用）に「Refill」を含まないユニットを抽出する（後からリフィルに変更された商品を特定するため）  
**DB**: `ibtoz0804db`（`ibeautystore` スキーマ）  
**テーブル**: `product_units`

```sql
-- ============================================================
-- チケット #22610 【IB】サプライヤーHK商品のリフィルアイテムの抽出
-- IB管理画面ユニット情報の英語名（発注用）に「Refill」を含まないユニット一覧
-- 対象期間: 44期〜46期 (2023-03-01 〜 2026-02-28)
-- 除外: name_en に「Refill」を含むもの
-- フィルタ: チケット添付の「260225_HKリフィル商品一覧.xlsx」に含まれる supplier_product_id
-- 作成日: 2026-02-26
-- ============================================================

SELECT
    supplier_product_id AS サプライヤー商品ID,
    id                  AS ユニットID,
    name_en             AS '英語名（発注用）'
FROM [ibeautystore].[ibtoz0804db].[product_units]
WHERE name_en NOT LIKE '%Refill%'
  AND supplier_product_id IN
(
    '165134', '169569', '190774', '194439', '212198', '212200',
    '225572', '227563', '227572', '236026', '236776', '246957',
    '247157', '250726', '253008', '260005', '264894', '267326',
    -- ★ 全リストはチケット添付の Excel を参照（約130件）
    '136820', '50869', '274964', '269290', '234382', '264730', '264731'
)
ORDER BY supplier_product_id;
```

---

## テーブル一覧（登場実績）

| テーブル名 | DB | 説明 |
|------------|-----|------|
| `orders` | idoz0804db / irxoz0804db / masonpearson2 | 注文マスタ |
| `order_line_items` | idoz0804db | 注文明細 |
| `order_line_item_trackings` | idoz0804db | 出荷トラッキング |
| `order_campaigns` | idoz0804db | 注文に紐づくキャンペーン |
| `affiliate_orders` | idoz0804db | アフィリエイト注文情報 |
| `periodical_order_line_items` | idoz0804db | 定期購入明細 |
| `addresses` | idoz0804db / irxoz0804db | 住所（請求先/配送先共通） |
| `users` | idoz0804db / irxoz0804db / masonpearson2 | 会員 |
| `products` | idoz0804db | 商品マスタ |
| `product_units` | idoz0804db | 商品ユニット（サイズ） |
| `product_categories` | idoz0804db | 商品カテゴリ紐付け |
| `product_unit_orders` | idoz0804db | 商品ユニット発注（サプライヤー情報） |
| `big_categories` | idoz0804db | 大カテゴリマスタ |
| `mdl_categories` | idoz0804db | 中カテゴリマスタ |
| `sml_categories` | idoz0804db | 小カテゴリマスタ |
| `shippings` | idoz0804db | 配送会社マスタ |
| `product_unit_groups` | idoz0804db | 商品ユニットグループ |
| `mail_magazine_address` | idoz0804db | メルマガ登録アドレス |
| `user_additional_mail_addresses` | irxoz0804db | ユーザー追加メールアドレス |

---

## 擅当者別 SQL 傾向

| 擅当者 | 主な担当 | 特徴 |
|--------|---------|------|
| **山本 瑞樹** | iDrug 分析・アフィリエイト調査・キャンペーン | CTE/UNION ALL、複数期間集計、XML 文字列分割 |
| **石川 勝** | iDrug 抽出・Mason・iRx Cuenote | ROW_NUMBER ピボット、OUTER APPLY、年齢計算 |
| **荒井 克之進** | iBeauty データ抽出 | SQL ファイル添付形式 (`.sql`)、supplier_product_id IN リスト |

---

## 全チケット確認結果（tracker 136 / category 3 / 全35件）

| チケット# | 件名（抜粋） | SQL有無 | 備考 |
|-----------|------------|---------|------|
| #22618 | 月次発送方法別集計 | ✅ | SQL添付ファイル |
| #22610 | IB HKリフィルアイテム抽出 | ✅ | SQL添付ファイル（荒井） |
| #21583 | 定期購入利用者数調査 | ✅ | journal #39988（山本） |
| #21518 | 商品発送用注文抽出 | ✅ | journal #39954/#39995（石川） |
| #21979 | MP購入者データ抽出 | ❌ | ファイルサーバー置き |
| #20891 | キャンペーンID:9422 利用者抽出 | ✅ | journal（山本） |
| #20337 | iRx LTV分析（最終版） | ✅ | journal #39133（山本） |
| #20330 | IG 定期購入取扱有無 | ❌ | Excelファイル添付のみ |
| #20264 | キャンペーンID:9383 利用者抽出 | ✅ | journal（山本） |
| #20168 | Mason Pearson顧客情報抽出 | ✅ | journal #39061（石川） |
| #20001 | iRx LTV分析（前版） | ✅ | ref:同パターン |
| #19803 | ID商品レビュー抽出 | ❌ | ファイルサーバー置き |
| #19537 | IB自動メールタイトル確認 | ❌ | Excelファイル添付のみ |
| #19044 | ポイント調査 | ❌ | Excelファイル添付のみ |
| #18913 | アフィリエイト注文調査（詳細版） | ✅ | journal #37714（山本） |
| #18883 | iRx Cuenote配信リスト | ✅ | journal #37715（石川） |
| #18289 | キャンペーンID:9290 利用者抽出 | ✅ | journal（山本） |
| #18283 | OTC医薬品商品リスト抽出 | ✅ | journal #36949（石川） |
| #18251 | FTLサプライヤー商品抽出 | ✅ | journal #36882（山本） |
| #17922 | 販促強化女性購入商品データ | ❌ | Excelファイル添付のみ |
| #17829 | 会員ランク・購入金額等の分布 | ❌ | CSVファイル添付のみ |
| #17729 | アフィリエイト注文調査（基本版） | ✅ | ref:同パターン |
| #17557 | キャンペーンID:9274 利用者抽出 | ✅ | journal #36002（山本） |
| #16734 | iRx Cuenote配信リスト | ✅ | journal #35380（石川） |
| #16581 | IBボットアクセス分析 | ❌ | SQLなし（アクセスログ調査） |
| #16141 | キャンペーンID:9202等 利用者抽出 | ❌ | ファイルサーバー置き（journal SQL記録なし） |
| #16140 | キャンペーンID:9199 利用者抽出（追加） | ✅ | journal #34281（山本） |
| #15876 | キャンペーンID:9199 利用者抽出 | ✅ | journal #33860（山本） |
| #15776 | コーポレートサイトニュース抽出 | ❌ | CSVファイル添付のみ |
| #15754 | IBノベルティ対象者bdash | ❌ | CSVファイル添付のみ |
| #15353 | iRx Cuenote配信リスト | ✅ | journal #33354（石川） |
| #14922 | MP顧客データ抽出 | ❌ | Excelファイル添付のみ |
| #14694 | Cuenoteアドレス帳更新（初回購入者） | ❌ | ペンディング（機能改修依頼） |
| #14491 | JPLサンプルデータ | ❌ | テキストファイル配置（SQL記録なし） |
| #14469 | IB再入荷登録商品データ抽出 | ❌ | Excelファイル添付のみ |

**集計**: SQL確認 **20件** / SQLなし **15件** （全35件）
