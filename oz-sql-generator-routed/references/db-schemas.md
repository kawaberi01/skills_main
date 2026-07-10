# DBスキーマ一覧 — OZグループ

SQLを生成する際のテーブル参照は `[サーバー名].[スキーマ名].[テーブル名]` の3部構成で記述する。

## スキーマ対応表

| サーバー名（リンクサーバー） | スキーマ名 | サービス |
|---|---|---|
| `[accounting]` | `[acc1206db]` | 会計DB |
| `[bdash]` | `[bdash]` | Bdash（メール配信・BI） |
| `[calloz0805db]` | `[calloz0805db]` | 管理画面権限DB |
| `[ibeautystore]` | `[ibtoz0804db]` | iBeauty Store（IB） |
| `[idoz0804db]` | `[idoz0804db]` | iDrug Store（ID） |
| `[igeoz0805db]` | `[igeoz0805db]` | iGeneric Store（IG） |
| `[irxoz0804db]` | `[irxoz0804db]` | iRx-Medicine（iRx） |
| `[masonpearson2]` | `[mason]` | Mason Pearson（MP） |
| `[ozter0805db]` | `[ozter0805db]` | コーポレートサイト |
| `[shared]` | `[publicdata]` | 共通管理画面DB |

## 使用例

```sql
-- iBeauty Store（IB）のポイント履歴
FROM [ibeautystore].[ibtoz0804db].user_point_history

-- iDrug Store（ID）の注文
FROM [idoz0804db].[idoz0804db].orders

-- iGeneric Store（IG）のポイント履歴
FROM [igeoz0805db].[igeoz0805db].point_histories

-- Mason Pearson（MP）のユーザー
FROM [masonpearson2].[mason].users

-- iRx-Medicine（iRx）の注文
FROM [irxoz0804db].[irxoz0804db].orders
```

## 注意事項

- `[ibeautystore]` はリンクサーバー名、スキーマは `[ibtoz0804db]`（プロジェクト名と異なる点に注意）
- `[masonpearson2]` はリンクサーバー名、スキーマは `[mason]`（プロジェクト名と異なる点に注意）
- `dbo` スキーマは使用しない。必ず上記スキーマ対応表に従うこと
