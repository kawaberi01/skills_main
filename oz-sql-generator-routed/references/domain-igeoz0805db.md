# ドメイン知識 — igeoz0805db（iGe 美容系）

## orders.status（OrderStatus）

| 値 | 識別子 | 意味 |
|----|--------|------|
| 1 | PaymentNotConfirmed | 注文完了（未入金） |
| 2 | PaymentConfirmed | 入金済み |
| 3 | Arranged | お手配済み |
| 4 | PartShipped | 一部発送完了 |
| 5 | Shipped | 発送完了 |
| 9 | Cancel | キャンセル |

> 入金済み以降を対象とする場合: `AND o.status IN (2, 3, 4, 5)`  
> キャンセル除外: `AND o.status <> 9`

## 備考

- igeoz0805db は iDrug Store（idoz0804db）と類似した構造を持つが、OrderStatus の値体系が異なる（idoz0804dbは4=発送済み、igeoz0805dbは5=発送完了）
- Enums は AddressType・ConsentDocumentType・OrderStatus のみ定義済み
- sqlスキーマ確認時はスナップショット（igeoz0805dbContextModelSnapshot.cs）を参照すること
