# 移行元・移行先 処理対応表

## 対応表

| No | 移行元処理 | 移行元根拠 | 移行先処理 | 移行先根拠 | 判定 | 差異種別 | 備考 |
|---:|---|---|---|---|---|---|---|
| 1 | {SOURCE_PROCESS} | `{SOURCE_FILE}:{LINE}` | {DEST_PROCESS} | `{DEST_FILE}:{LINE}` | 対応済み / 一部対応 / 未対応 / 対応不明 | 移行漏れ / 仕様差異 / 意図的変更か判断不能 / 設計上の改善だが挙動影響なし / 未確認 / 差異なし | {NOTE} |

## 差異分類サマリー

| 差異種別 | 件数 | 概要 |
|---|---:|---|
| 移行漏れ | {COUNT} | {SUMMARY} |
| 仕様差異 | {COUNT} | {SUMMARY} |
| 意図的変更か判断不能 | {COUNT} | {SUMMARY} |
| 設計上の改善だが挙動影響なし | {COUNT} | {SUMMARY} |
| 未確認 | {COUNT} | {SUMMARY} |
| 差異なし | {COUNT} | {SUMMARY} |

## 未確認事項
{UNCONFIRMED_ITEMS}
