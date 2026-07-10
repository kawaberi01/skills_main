# ドメイン知識 — irxoz0804db（iRx 医師向け）

## orders.order_status_id（OrderStatusType）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | Estimating | 見積受付 |
| 1 | NotProcessed | 注文受付（未処理） |
| 15 | PaymentReceived | 入金済み |
| 25 | Processed | 入金お礼済み |
| 35 | Shipped | 発送済み |
| 40 | ShipmentNotified | 発送お知らせ済み |
| 45 | ShipmentCompleted | 配達完了 |
| 50 | Completed | すべて完了 |
| 99 | Cancel | キャンセル |

> キャンセル除外: `AND o.order_status_id <> 99`

## users.type_id（UserType）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | Doctor | お医者様 |
| 2 | Patient | 患者様 |

> 医師会員のみ: `AND u.type_id = 1`

## users.doctor_type（UserDoctorType）

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 0 | Usual | 医師 |
| 1 | Veterinarian | 獣医師 |
| 2 | Dentist | 歯科医師 |
| 3 | Researcher_Company | 法人（企業等） |
| 4 | Researcher_Laboratory | 研究機関・大学等 |

## suppliers（SupplierType）※ irxoz0804db.suppliers テーブルのID

| 値 | 識別子 | 表示名 |
|----|--------|--------|
| 1 | Farmamondo | FARMAMONDO |
| 2 | GlobalRx | GLOBALRX |
| 3 | GCP | GCP |
| 4 | V | SHARE |
| 5 | BK | BK |
| 6 | PandD | Kashiwanoha |
| 7 | Budget | CORENA |
| 8 | ALAN | ALAN |
| 9 | Cyno | CYNO |
| 10 | IPS | IPS |
| 11 | Alex | Alex |
| 12 | Ftl | FTL |
| 13 | Kokunai | Kokunai |
| 14 | Elixi | Elixi |
| 15 | Ilapo | Ilapo |
| 16 | Ekimae | Ekimae |

## 国内住所の絞り込み

```sql
AND a.country_id = 109   -- 日本
```

## テスト・社内ユーザーの除外（配信リスト作成時）

```sql
AND (a.hospital_name NOT LIKE '%テスト%' OR a.hospital_name IS NULL)
AND u.last_name  NOT LIKE '%テスト%'
AND u.first_name NOT LIKE '%テスト%'
AND u.email NOT LIKE '%@ozinter.jp'
AND u.email NOT LIKE '%@ozinter.co.jp'
```

## よく使う結合パターン

### 医師会員 + 請求先住所

```sql
FROM irxoz0804db.users AS u
INNER JOIN irxoz0804db.addresses AS a
    ON u.billing_address_id = a.id
WHERE u.type_id = 1   -- 医師会員のみ
```

### 注文集計

```sql
FROM irxoz0804db.orders AS o
INNER JOIN irxoz0804db.users AS u ON o.user_id = u.id
WHERE o.order_status_id <> 99   -- キャンセル除外
```

### セグメント判定（病院名・診療科から推定）

```sql
CASE
    WHEN a.hospital_name LIKE N'%小児%' OR a.hospital_name LIKE N'%こども%'
      OR ISNULL(a.hospital_department,'') LIKE N'%小児%'
    THEN N'小児科'
    WHEN a.hospital_name LIKE N'%眼科%'
      OR ISNULL(a.hospital_department,'') LIKE N'%眼科%'
    THEN N'眼科'
    WHEN u.doctor_type = 1 THEN N'動物病院'
    WHEN a.country_id = 109 AND u.doctor_type = 3 THEN N'製薬企業'
    WHEN a.country_id = 109 AND u.doctor_type = 4 THEN N'研究機関/大学'
    ELSE N'その他'
END AS segment
```
