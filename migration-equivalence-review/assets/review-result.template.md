# {TARGET_NAME} 移行同等性レビュー結果

## レビュー概要
- 対象: `{TARGET_NAME}`
- ブランチ: `{BRANCH_NAME}`
- 比較先: `main`
- merge-base: `{MERGE_BASE}`
- 変更ファイル数: `{CHANGED_FILE_COUNT}`
- コミット数: `{COMMIT_COUNT}`
- 最終判定: `{FINAL_DECISION}`

## 指示整合性チェック結果
{CONSISTENCY_CHECK_RESULT}

## 確認した範囲
{CHECKED_SCOPE}

## 参照した資料
{REFERENCES}

## main 差分の概要
{MAIN_DIFF_SUMMARY}

## 移行元処理の棚卸し
{SOURCE_INVENTORY_SUMMARY}

## 移行先処理の棚卸し
{DESTINATION_INVENTORY_SUMMARY}

## 移行元と移行先の処理対応表
{EQUIVALENCE_MATRIX_SUMMARY}

## 移行漏れ確認結果
{MISSING_MIGRATION_RESULT}

## 仕様差異確認結果
{SPEC_DIFF_RESULT}

## 副作用の確認結果
{SIDE_EFFECT_RESULT}

## 例外処理・リトライ・ログの同等性確認結果
{ERROR_RETRY_LOG_RESULT}

## 設計境界の確認結果
{BOUNDARY_RESULT}

## namespace の確認結果
{NAMESPACE_RESULT}

## NuGet / ProjectReference の確認結果
{NUGET_RESULT}

## DI 登録の確認結果
{DI_RESULT}

## 設定値・接続文字列名の確認結果
{SETTINGS_RESULT}

## CancelOrder 実装との整合性確認結果
{REFERENCE_IMPLEMENTATION_RESULT}

## テスト確認結果
{TEST_RESULT}

## 指摘一覧

### Critical
{CRITICAL_FINDINGS}

### Major
{MAJOR_FINDINGS}

### Minor
{MINOR_FINDINGS}

## 修正推奨内容
{RECOMMENDATIONS}

## 未確認事項
{UNCONFIRMED_ITEMS}
