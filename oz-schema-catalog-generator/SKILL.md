---
name: oz-schema-catalog-generator
description: OZ-DatabaseEntities の DbContext、Model、Enum、Migration を読み取り、SQL生成用の generated schema catalog をDBごとに作成・更新するスキル。テーブル、カラム、型、PK、FK、スキーマ名、Enum/const値、Migration由来の追加変更を SQL 生成スキルが参照できる形式に揃えたい時に使う。
---

# OZ Schema Catalog Generator

この skill は `OZ-DatabaseEntities` を開いた状態で、SQL 生成用の generated schema catalog を作成・更新するための読み取り中心 skill である。
出力ファイルを作成・更新する時は、ユーザーから明示的に依頼された場合だけ行う。

## 入力

実行時に以下を受け取る。

- `oz_database_entities_path`: `OZ-DatabaseEntities` のパス
- `sql_generator_skill_path`: `oz-sql-generator-routed` の skill root パス。指定がある場合は最優先する

`sql_generator_skill_path` が未指定の場合は、この skill の親ディレクトリ配下にある兄弟フォルダ `oz-sql-generator-routed` を探す。
見つからない場合はファイルを作成せず、生成内容を提示して保存先確認に切り替える。

## 目的

- DbContext / Model / Enum / Migration を正本として、DBごとのスキーマ索引を作る
- SQL生成時に、毎回 DbContext 全体を深く読まなくてもテーブル・カラム・JOIN候補を確認できるようにする
- 手書き reference ではなく、コード由来の generated catalog として更新漏れを発見しやすくする

## 対象DB

- `idoz0804db`
- `irxoz0804db`
- `igeoz0805db`
- `ibtoz0804db`
- `masonpearson2`

## 推奨出力先

`oz-sql-generator-routed` から読めるよう、`sql_generator_skill_path` で指定された skill root の直下にある `references/` に配置する。
この skill が `.workstate` 配下にある場合でも、`.workstate` は開発時の置き場所にすぎない。ポータビリティを優先し、project 固定パスではなく、SQL 生成スキルのフォルダを基準にする。

```text
{sql_generator_skill_path}/references/schema-catalog-idoz0804db.md
{sql_generator_skill_path}/references/schema-catalog-irxoz0804db.md
{sql_generator_skill_path}/references/schema-catalog-igeoz0805db.md
{sql_generator_skill_path}/references/schema-catalog-ibtoz0804db.md
{sql_generator_skill_path}/references/schema-catalog-masonpearson2.md
```

`sql_generator_skill_path` の決定順:

1. ユーザー入力で明示された `sql_generator_skill_path`
2. この skill の親ディレクトリにある `oz-sql-generator-routed`
3. 見つからない場合は保存せず、生成結果と必要な保存先を提示する

## 調査対象

- `Models/*Context.cs`
- `Models/*.cs`
- `Enums/*.cs`
- `Migrations/*.cs`
- 必要に応じて `Services/*.cs` の Include / Join / OrderBy パターン

## 生成内容

各 DB の catalog は `references/schema-catalog-template.md` の章立てに合わせる。

必ず含める情報:

- DbContext クラス名
- 接続名または DB 名
- DbSet 名と Entity 名
- SQL テーブル名とスキーマ名
- カラム名、プロパティ名、型
- PK
- FK / navigation / constraint 名
- Index
- Enum / const / static readonly の値
- Migration で近年追加・変更されたテーブルやカラム

## 更新ルール

- DbContext / Model / Enum / Migration が変わったら catalog を再生成する。
- catalog とコードが矛盾した場合は、コードを正とする。
- 手で業務ルールを追記しない。業務語や日本語表現は business vocabulary に書く。
- catalog に推測を書かない。対応カラムが不明な Enum は `未対応 / 要確認` として分ける。

## 検索手順

1. `references/search-patterns.md` のコマンドで対象 DB の Context / Model / Enum / Migration を洗い出す。
2. `ToTable(...)`、`HasColumnName(...)`、`HasKey(...)`、`HasForeignKey(...)`、`HasConstraintName(...)` を抽出する。
3. Entity クラスのプロパティと DbContext のマッピングを照合する。
4. Enum / const を DB 値候補として抽出し、対応する Model プロパティが明確な場合だけ紐付ける。
5. Migration の新しい順に、追加・変更テーブル/カラムを catalog の `Recent migrations` に要約する。
6. 出力前に、DBごとの catalog が同一フォーマットになっているか確認する。
7. ファイル保存を行う場合は、`sql_generator_skill_path\references` が存在することを確認し、なければ作成する。

## 出力時の注意

- SQL生成スキルが読むため、文章より表を優先する。
- カラム表は長くなりすぎる場合、主要テーブルを先に置き、その他はテーブル単位で折りたたみや検索しやすい見出しに分ける。
- `orders`、`users`、`addresses`、`line_items`、`order_line_items`、`products`、`product_units` など SQL 生成で頻出するテーブルは省略しない。
- 実DBへ接続しない。実DB由来の値確認が必要なものは `要確認` とする。
