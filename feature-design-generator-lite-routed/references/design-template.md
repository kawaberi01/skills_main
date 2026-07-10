# 設計概要テンプレート

★☆{機能名} 設計概要★☆

■ 対象プロジェクト
- プロジェクト: {プロジェクト名}
- パターン: {A (EF Core) / B (LINQ to SQL)}
- DB層: {対象DB層プロジェクト名}

■ 概要
{機能の目的と効果を1-2文で記載}

■ DB変更
(1) {既存テーブル} にカラム追加
- {column_name} ({type}, {nullability/default})
  {意味と用途}

(2) {新規テーブル} 作成
- {column_name} ({type})
- {column_name} ({type})
- FK: {fk_name}
- Index: {index_name}

■ エンティティ（{対象DB層プロジェクト}）
- 新規: {EntityName}
- 既存変更: {ParentEntity} にプロパティ/ナビゲーション追加
- コンテキスト変更:
  パターンA: DbContext に DbSet と OnModelCreating マッピング追加
  パターンB: DataContext にテーブルマッピング追加

■ ビジネスロジック
- 変更箇所: {file/path}
- 既存メソッド: {method}
- 新規分岐: {condition}
- 新規処理: {new_method}
  1. 対象抽出
  2. 数量/金額判定
  3. 割引適用

■ 管理画面
- ViewModel: {property additions}
- Controller GET: {load/serialize}
- Controller POST: {deserialize/replace within transaction}
- Validation: {new/skip conditions}
- View: {input table, add/remove row, checkbox}

■ マイグレーション
パターンA（EF Core）:
- マイグレーション名: {migration_name}
- コマンド: ./add {project_prefix} {migration_name}
- 対象 Context: {context_name}

パターンB（手動SQL）:
- ファイル: {file_name}.sql
- 方針: IF NOT EXISTS で冪等
  1. カラム追加
  2. テーブル作成
  3. 制約作成
  4. インデックス作成

※ 対象パターンのみ記載する。

■ 後方互換
- {new_flag=false で既存動作不変}

■ テスト観点
- {通常系}
- {境界値}
- {既存機能回帰}
```
