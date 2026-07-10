---
name: oz-sql-generator-routed
description: "OZグループ向けSQL生成の routed 版スキル。複数プロジェクトの reference が混在する前提で、要件文・チケット文面・.sln・*.csproj・浅い階層名・generated schema catalog・business vocabulary・必要時のみログ中 namespace から低コストに対象DB/プロジェクトを候補化し、必要な資料だけ段階的に読んで T-SQL を生成する。対象DB: ibtoz0804db, idoz0804db, igeoz0805db, irxoz0804db, masonpearson2。"
---

# OZ SQL Generator Routed

この skill は SQL を生成するための読み取り専用 skill であり、コード変更や repo 変更は行わない。
目的は、この skill フォルダ配下の `references/` に混在する複数 project / shared / generated schema catalog / business vocabulary 資料を最初から全部読まず、誤判定を抑えながら必要な資料だけ読むこと。

この skill では、現在読み込んでいる `oz-sql-generator-routed/SKILL.md` と同じディレクトリを `sql_generator_skill_path` とみなす。
参照資料は常に `sql_generator_skill_path\references\` から読む。
`schema-catalog-*.md` と `business-vocabulary-*.md` は、`oz-schema-catalog-generator` または `oz-business-vocabulary-investigator` がこの `references` に保存する想定である。

## 2段階ワークフロー

### Phase 1: 軽量な絞り込み

初回は安い情報だけを見る。

- 要件文、チケット文面、補足メモの固有語
- ワークスペース直下または浅い階層で見つかる `.sln`
- 浅い階層で見つかる `*.csproj`
- 浅い階層のディレクトリ名
- この skill フォルダ配下の `references/` のファイル名
- この skill フォルダ配下の `references/schema-catalog-*.md` が存在するかどうか
- この skill フォルダ配下の `references/business-vocabulary-*.md` が存在するかどうか
- 必要時のみログや例外文面に出る namespace

初回判定でやらないこと:

- ワークスペース全体の深い走査
- 複数 project reference の本文をまとめて読む
- 画像だけで断定する

### Phase 2: 必要時のみ深掘り

Phase 1 で候補化した後、確信度に応じて必要な reference だけ読む。

- 候補 1 件ならその project reference だけ読む
- 候補が複数なら上位 2 件まで読む
- テーブル、カラム、PK、FK、Enum / const の確認が必要な場合は該当 DB の generated schema catalog を読む
- 日本語業務語、DB値、ステータス、区分、除外条件が SQL 条件に影響する場合は該当 DB の business vocabulary を読む
- shared reference は必要条件に一致した時だけ読む
- それでも曖昧なら深掘り前に短く確認する

一度に大量ファイルを横断要約しない。必要な資料を 1 件ずつ読み、都度候補を更新する。

## Project references

project reference は、対象 project / DB の業務ルール、値体系、JOIN の癖を確定するために読む。
初回に読む本文資料は最大 2 件まで。

| Project / DB | Reference | 用途 |
|---|---|---|
| `idoz0804db` | `references/domain-idoz0804db.md` | 会計期、注文状態、商品種別、サプライヤーなどの業務ルール |
| `idoz0804db` | `references/domain-idoz0804db-variables.md` | enum 値、状態値、配送時間帯、支払方法などの値確定 |
| `idoz0804db` | `references/linq-patterns-idoz0804db.md` | LINQ 実装由来の JOIN パターン確認 |
| `irxoz0804db` | `references/domain-irxoz0804db.md` | 医師向け会員、住所、注文状態、配信除外条件 |
| `igeoz0805db` | `references/domain-igeoz0805db.md` | 美容系 DB の注文状態と ID 系との差分 |
| `ibtoz0804db` | `references/domain-ibtoz0804db.md` | iBeauty Store の補足ルール |
| `masonpearson2` | `references/domain-masonpearson2.md` | Mason 用ステータス、JOIN、年齢計算 |

追加読込ルール:

- `idoz0804db` の値体系が必要な時だけ `domain-idoz0804db-variables.md` を読む
- `idoz0804db` で JOIN パターンに迷った時だけ `linq-patterns-idoz0804db.md` を読む
- それ以外の project では、まず各 `domain-*.md` を優先する

## Generated schema catalog references

generated schema catalog は、`OZ-DatabaseEntities` の DbContext / Model / Enum / Migration から作成された SQL 生成用の一次情報である。
`oz-schema-catalog-generator` で作成・更新される想定であり、テーブル、カラム、型、PK、FK、スキーマ名、Enum / const 値の確認では最優先する。

推奨配置:

`sql_generator_skill_path` は、この `SKILL.md` と同じディレクトリを指す。

| DB | Reference |
|---|---|
| `idoz0804db` | `references/schema-catalog-idoz0804db.md` |
| `irxoz0804db` | `references/schema-catalog-irxoz0804db.md` |
| `igeoz0805db` | `references/schema-catalog-igeoz0805db.md` |
| `ibtoz0804db` | `references/schema-catalog-ibtoz0804db.md` |
| `masonpearson2` | `references/schema-catalog-masonpearson2.md` |

読む条件:

- 候補 DB が 1 件または上位 2 件まで絞れている
- SQL の FROM / JOIN / SELECT / WHERE に使うテーブルやカラムを確認する
- PK / FK / navigation / constraint から JOIN 候補を確認する
- Enum / const 値と対象カラムの対応を確認する
- domain reference や business vocabulary の対象カラムが現行コードに存在するか確認する

扱い方:

- schema catalog は schema / table / column / relationship の一次情報とする
- 業務語の意味や「売上対象」「有効注文」などの解釈は business vocabulary / domain reference を使う
- schema catalog と他 reference が矛盾する場合は schema catalog を優先し、業務解釈だけ要確認にする
- schema catalog が存在しない、または古い可能性がある場合は `OZ-DatabaseEntities` の DbContext / Model / Enum / Migration を直接確認する

## Business vocabulary references

business vocabulary は、利用側プロジェクト由来の業務語、表示名、Enum 以外の Dictionary / const / 文字列変換、日本語依頼語を DB 値や SQL 条件へ対応付ける補助資料である。
`oz-business-vocabulary-investigator` で後から作成される想定であり、存在しない場合は無理に読む前提にしない。

推奨配置:

`sql_generator_skill_path` は、この `SKILL.md` と同じディレクトリを指す。

| DB | Reference |
|---|---|
| `idoz0804db` | `references/business-vocabulary-idoz0804db.md` |
| `irxoz0804db` | `references/business-vocabulary-irxoz0804db.md` |
| `igeoz0805db` | `references/business-vocabulary-igeoz0805db.md` |
| `ibtoz0804db` | `references/business-vocabulary-ibtoz0804db.md` |
| `masonpearson2` | `references/business-vocabulary-masonpearson2.md` |

読む条件:

- 入力に「キャンセル」「有効注文」「売上対象」「未入金除外」「発送済み」「退会ユーザー除外」「テストユーザー除外」などの日本語業務語がある
- SQL 条件に DB 値、ステータス、種別、支払方法、配送方法、サプライヤー区分を使う
- DbContext / domain reference だけでは、業務語から対象カラムと値を確定できない
- DB ごとに同じ業務語の値やカラムが違う可能性がある

読まない条件:

- テーブル・カラム存在確認だけで足りる
- 入力に明示的な DB 値やカラム名があり、業務語変換が不要
- 候補 DB が未確定で、複数 DB の vocabulary を広く読む必要がある

扱い方:

- business vocabulary は SQL 条件の補助根拠とする
- schema / table / column の存在確認は DbContext 由来資料や `db-schemas.md` を優先する
- domain reference と business vocabulary が矛盾する場合は、根拠ファイルを並べて要確認にする
- 過去 SQL より business vocabulary を優先する。ただし vocabulary の根拠が推測の場合は断定しない

## Shared references

shared reference は project 共通の補助資料であり、存在するだけでは読まない。
必要条件に一致した時だけ読む。

| Reference | 何のための資料か | 読む条件 |
|---|---|---|
| `references/db-schemas.md` | 3 部構成のテーブル参照、リンクサーバー名、スキーマ名の確定 | FROM/JOIN を組み立てる時、またはスキーマ名に揺れがある時 |
| `references/sql-format-rules.md` | SQL 出力フォーマット、コメント、DECLARE、クエリ区切りの規約 | SQL を実際に生成する直前 |
| `references/sql_reference.md` | 過去チケット実績、類似クエリ、JOIN の裏取り | 主テーブルや JOIN パターンの裏取りが必要な時 |

## Project 判定キーワード表

単独キーワードだけで断定しない。主なプロジェクト名 / solution 名、業務語、補助キーワードを組み合わせて候補化する。

| Project reference | 主なプロジェクト名 / solution 名 | 業務・画面キーワード | 補助キーワード / 入口候補 |
|---|---|---|---|
| `idoz0804db` | `idoz0804db`, `iDrug`, `ID` | 定期購入, OTC, キャンペーン, アフィリエイト, 発送方法, サプライヤー, 商品発送 | `iDrugStore`, `OrderBilling`, `OrderShipping`, `periodical_order_line_items`, `affiliate_orders` |
| `irxoz0804db` | `irxoz0804db`, `iRx` | 医師, 病院, 請求先住所, 配信リスト, Cuenote, LTV | `doctor`, `hospital`, `order_status_id`, `type_id`, `UserDoctorType` |
| `igeoz0805db` | `igeoz0805db`, `iGe`, `IG` | 美容, 分析, RFM, キャンペーン分析 | `point_histories`, `OrderStatus`, `iGeneric` |
| `ibtoz0804db` | `ibtoz0804db`, `iBeauty`, `IB` | HK, リフィル, サプライヤー, 美容EC | `ibeautystore`, `ConsentDocumentType`, `product_units` |
| `masonpearson2` | `masonpearson2`, `Mason Pearson`, `MP` | 顧客情報抽出, 年齢, ブランドEC | `mason`, `product_units.unit_type`, `orders.status` |

## 低コストなプロジェクト判定ルール

1. 明示 project 名、DB 名、solution 名が依頼文にある場合は最優先する。
2. 依頼文に明示名がない場合は、業務語と補助キーワードを組み合わせて候補化する。
3. 必要なら浅い階層の `.sln`、`*.csproj`、ディレクトリ名を確認し、solution 名や project 名の一致を見る。
4. さらに必要なら、ログや例外文面に現れた namespace や DB 名を補助証拠として使う。
5. 単独キーワードだけでは断定しない。例えば「注文」「顧客」だけでは確定しない。

namespace を使う時の例:

- `iDrugStore` 系 namespace は `idoz0804db` の強い補助証拠
- `iRx`、`Doctor`、`Hospital` 系 namespace は `irxoz0804db` の補助証拠
- `mason` は `masonpearson2` の補助証拠

## 候補化ルール

- 明示プロジェクト名があれば最優先
- 一致 1 件ならその reference だけ読む
- 複数候補なら上位 2 件まで読む
- 上位 2 件を読んでも曖昧なら、深掘り前に短く確認する
- shared reference は候補確定後、必要条件に一致した時だけ読む

上位順位の付け方:

1. 明示 DB 名 / project 名
2. solution 名 / csproj 名 / ディレクトリ名
3. 業務語と補助キーワードの複数一致
4. ログ中 namespace やテーブル名の一致

## 確信度ルール

- 高: 明示 DB 名がある、または複数の強いシグナルが一致しており競合がない
- 中: 業務語と補助キーワードは一致するが、近い project が残る
- 低: 単発キーワードしかない、または複数 project が同程度に競合する

低確信のまま project reference の深掘りを広げない。確認を優先する。

## SQL 生成時の読込順

1. Phase 1 で候補化する
2. 候補 DB の generated schema catalog を読み、テーブル、カラム、PK、FK、Enum / const 値を確認する
3. 確信度が高い候補の project reference を読み、業務ルールや JOIN の癖を確認する
4. 日本語業務語や DB 値の解釈が必要なら、該当 DB の business vocabulary を読む
5. 必要なら同 project の追加 reference を読む
6. 3 部構成やリンクサーバー名に揺れがある時だけ `references/db-schemas.md` を読む
7. SQL 出力直前に `references/sql-format-rules.md` を読む
8. JOIN や実績の裏取りが必要な時だけ `references/sql_reference.md` を読む

generated schema catalog が存在しない、または古い可能性がある場合は、`OZ-DatabaseEntities` の DbContext / Model / Enum / Migration を直接確認する。
DB スナップショットは、project 候補がほぼ固まり、コード由来 catalog だけではテーブルやカラムの確定が不足する時だけ読む。

## 事実 / 推測 / 要確認 の分離ルール

- 事実: 入力文、チケット文面、ログ、reference に直接書かれている内容
- 推測: 類似チケット、業務語、既存 JOIN パターンからの補完
- 要確認: project 候補が競合する点、主テーブル、出力列、期間、除外条件で不確定な点

回答では、必要に応じてこの 3 つを分けて示す。

## SQL 生成ルール

- 生成する SQL は T-SQL とする
- フォーマットは `references/sql-format-rules.md` に従う
- FROM / JOIN / SELECT / WHERE に使うテーブルとカラムは、generated schema catalog または DbContext / Model で存在確認する
- 主テーブルが確定しない場合は、推測候補を 1 つに絞り切らず短く確認する
- 「過去 N 年」などの相対指定は、対象 project の reference に会計期ルールがある場合のみそれに従う
- project ごとの差分を ID 系の既存慣習で埋めず、当該 project reference の事実を優先する
- 日本語業務語を SQL 条件へ変換する時は、該当 DB の business vocabulary を優先し、見つからない場合は domain reference / DbContext / 過去 SQL の順で根拠を確認する

## この routed 版で明示すること

- 初回候補化に使う安い情報:
  - 要件文 / チケット文面の固有語
  - `.sln`
  - `*.csproj`
  - 浅い階層のディレクトリ名
  - `references/` のファイル名
  - 必要時のみログ中 namespace
- shared reference を読む条件:
  - `db-schemas.md`: 3 部構成やスキーマ確認が必要
  - `sql-format-rules.md`: SQL 出力直前
  - `sql_reference.md`: 類似クエリや JOIN 実績の裏取りが必要
- generated schema catalog を読む条件:
  - テーブル、カラム、型、PK、FK、JOIN 候補、Enum / const 値を確認する
  - domain reference や business vocabulary の対象カラムが現行コードに存在するか確認する
  - SQL に使う識別子を DbContext / Model 由来の事実で固定する
- business vocabulary を読む条件:
  - 日本語業務語を DB 値へ変換する必要がある
  - ステータス、区分、支払、配送、除外条件が SQL の WHERE に影響する
  - DbContext に現れない利用側プロジェクト由来の値変換が必要
- ユーザー確認に切り替える条件:
  - 候補が 2 件まで絞っても競合する
  - 単独キーワードしかなく確信度が低い
  - 主テーブル、期間、出力列の曖昧さが project 判定や SQL 構造に影響する
  - generated schema catalog と DbContext / Model の現物が矛盾する、または catalog が古い疑いがある
  - business vocabulary と domain reference / DbContext 由来情報が矛盾する
