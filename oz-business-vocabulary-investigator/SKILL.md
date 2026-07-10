---
name: oz-business-vocabulary-investigator
description: OZ 系利用側プロジェクトから、OZ-DatabaseEntities の DbContext に現れない Enum、Dictionary、const、画面表示名、文字列変換、業務判定ロジックを調査し、DBごとの business vocabulary reference 草案を作成するスキル。日本語依頼語を DB・テーブル・カラム・値・SQL条件へマッピングしたい時、SQL生成用の業務語辞書を各対象プロジェクトから同一フォーマットで作りたい時に使う。
---

# OZ Business Vocabulary Investigator

この skill は読み取り専用の調査 skill であり、コード変更や repo 変更は行わない。
目的は、利用側プロジェクトに散らばる業務語、表示名、値変換、定数を調査し、SQL 生成で使える DB 別 business vocabulary 草案へ整理すること。

## 入力として受け取る情報

- 利用側プロジェクトのパス
- 対象機能、画面、チケット文面、または日本語依頼語
- 対象DB候補が分かる場合は DB 名
- `OZ-DatabaseEntities` のパス。指定がない場合は現在のワークスペース、または近い親子ディレクトリから探す
- `sql_generator_skill_path`: `oz-sql-generator-routed` の skill root パス。ファイル保存時に指定がある場合は最優先する

`sql_generator_skill_path` が未指定の場合は、この skill の親ディレクトリ配下にある兄弟フォルダ `oz-sql-generator-routed` を探す。
見つからない場合はファイルを作成せず、調査結果を提示して保存先確認に切り替える。

## 対象DB

- `idoz0804db`
- `irxoz0804db`
- `igeoz0805db`
- `ibtoz0804db`
- `masonpearson2`

DB ごとに値やカラムが違うものは共通化しない。

## 調査ワークフロー

1. 利用側プロジェクトで DB 名、namespace、DbContext 名、project 名、Service 名、Controller 名、画面名から対象 DB 候補を出す。
2. `enum`、`Dictionary`、`const`、`static readonly`、`switch`、`case`、表示属性、画面表示名、変換メソッドを検索する。
3. 注文ステータス、会員区分、商品区分、配送、発送、支払、サプライヤー、除外条件に関係する値を優先して抽出する。
4. 抽出した値を `OZ-DatabaseEntities` の Model / DbContext / Enum / Migration と照合し、DB・テーブル・カラム・値・SQL条件に分解する。
5. コード根拠が弱いものは `推測` または `要確認` に分ける。
6. 過去 SQL が見つかった場合は全文を主情報にせず、再利用できる業務ルールだけ抽出する。
7. 出力は必ず `references/output-template.md` の章立てと列順に合わせる。

## 優先検索パターン

詳細な検索語は `references/search-patterns.md` を読む。

特に次を優先する。

- 値定義: `enum`, `Dictionary`, `const`, `static readonly`
- 変換処理: `switch`, `case`, `ToString`, `GetDisplayName`, `DisplayAttribute`, `DescriptionAttribute`
- 表示・選択肢: `SelectList`, `ViewBag`, `ViewData`, HTML select, radio, checkbox
- 業務語: `status`, `order_status`, `cancel`, `payment`, `shipping`, `delivery`, `user_type`, `doctor_type`, `product_type`, `supplier`
- 日本語: `キャンセル`, `有効`, `売上対象`, `未入金`, `発送済み`, `退会`, `テスト`, `医師`, `OTC`, `定期購入`

## 判定ルール

- `OZ-DatabaseEntities` の DbContext / Model / Enum / Migration と照合できた値を最も強い根拠にする。
- 利用側プロジェクトにしかない Dictionary や表示文字列は、根拠ファイルを必ず残す。
- 同じ業務語でも DB ごとに対象カラムや値が違う場合は `DB別差分` に分離する。
- 「有効注文」「売上対象」「抽出対象」は業務で意味が変わるため、固定できない場合は要確認にする。
- 主テーブル、JOIN、WHERE の根拠が弱い場合は SQL 条件を断定しない。
- 過去 SQL は補助根拠とし、古い仕様やチケット固有条件を一般ルールとして昇格しない。

## 出力ルール

- 出力は日本語で書く。
- `事実`, `推測`, `要確認` を混ぜない。
- 根拠ファイルは相対パスまたは絶対パスと行番号をできるだけ付ける。
- 表に入らない補足は短く `備考` に書く。
- 最終出力は、対象プロジェクト単位の調査結果として `references/output-template.md` の形式に揃える。
- ファイルとして保存する場合は、利用側プロジェクト配下ではなく、`sql_generator_skill_path\references\business-vocabulary-{db}.md` に集約する。
- `.workstate` は開発時の置き場所にすぎない。ポータビリティを優先し、保存先は SQL 生成スキルのフォルダを基準にする。

`sql_generator_skill_path` の決定順:

1. ユーザー入力で明示された `sql_generator_skill_path`
2. この skill の親ディレクトリにある `oz-sql-generator-routed`
3. 見つからない場合は保存せず、調査結果と必要な保存先を提示する
