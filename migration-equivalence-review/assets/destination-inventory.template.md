# 移行先処理棚卸し

## 基本情報
- 対象: `{TARGET_NAME}`
- 移行先候補: `{DESTINATION_PATH}`

## Function 一覧
| No | Function / クラス | Trigger 種別 | Function 名 | Route / Schedule / Queue | HTTP Method | 根拠 |
|---:|---|---|---|---|---|---|
| 1 | {FUNCTION_CLASS} | {TRIGGER_TYPE} | {FUNCTION_NAME} | {ROUTE_OR_BINDING} | {HTTP_METHOD} | `{DEST_FILE}:{LINE}` |

## 入力モデル・バリデーション
| No | モデル | プロパティ | 型 | 必須 | バリデーション | 根拠 |
|---:|---|---|---|---|---|---|
| 1 | {MODEL} | {PROPERTY} | {TYPE} | {REQUIRED} | {VALIDATION} | `{DEST_FILE}:{LINE}` |

## 出力モデル
| No | モデル | プロパティ | 型 | 成功時 | 失敗時 | 根拠 |
|---:|---|---|---|---|---|---|
| 1 | {MODEL} | {PROPERTY} | {TYPE} | {SUCCESS_VALUE} | {FAILURE_VALUE} | `{DEST_FILE}:{LINE}` |

## 主要処理
| No | 処理 | 条件 / 順序 | 呼び出し先 | 副作用 | 根拠 |
|---:|---|---|---|---|---|
| 1 | {PROCESS} | {CONDITION_OR_ORDER} | {CALLEE} | {SIDE_EFFECT} | `{DEST_FILE}:{LINE}` |

## 外部通信・設定・定数
| No | 種別 | 名前 | 値 / キー | 用途 | 根拠 |
|---:|---|---|---|---|---|
| 1 | {KIND} | {NAME} | {VALUE} | {PURPOSE} | `{DEST_FILE}:{LINE}` |

## 例外処理・リトライ・ログ
| No | 対象処理 | 例外時挙動 | リトライ | ログ | 根拠 |
|---:|---|---|---|---|---|
| 1 | {PROCESS} | {ERROR_BEHAVIOR} | {RETRY} | {LOG} | `{DEST_FILE}:{LINE}` |

## 未確認事項
{UNCONFIRMED_ITEMS}
