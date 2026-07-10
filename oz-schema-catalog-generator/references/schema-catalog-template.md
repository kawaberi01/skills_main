# Schema Catalog Template

各 DB の generated schema catalog はこの章立てに合わせる。

```md
# Schema Catalog - {db}

Generated from:
- DbContext:
- Models:
- Enums:
- Migrations:

Last updated:
- {yyyy-MM-dd}

## Context

| Item | Value |
|---|---|
| DB |  |
| DbContext |  |
| ConnectionStringName |  |
| Project path |  |

## Tables

| Table | Schema | Entity | DbSet | Primary key | Notes |
|---|---|---|---|---|---|

## Columns

### {table}

| Column | Property | CLR type | DB type | Nullable | Key | Notes |
|---|---|---|---|---|---|---|

## Relationships

| From table | From column | To table | To column | Navigation | Constraint | Notes |
|---|---|---|---|---|---|---|

## Indexes

| Table | Columns | Name | Unique | Notes |
|---|---|---|---|---|

## Enum And Constants

| Name | Member | Value | Candidate table | Candidate column | Confidence | Source |
|---|---|---|---|---|---|---|

## Recent Migrations

| Migration | Change | Table | Column | Notes |
|---|---|---|---|---|

## SQL Generation Notes

| Topic | Fact |
|---|---|
```

## 記入ルール

- `Confidence` は `高` / `中` / `低` / `要確認` を使う。
- Entity と Table が 1 対 1 で確定できるものだけ `高` にする。
- Enum とカラムの紐付けが命名由来だけの場合は `中` 以下にする。
- 業務上の「有効」「売上対象」「除外」などは書かない。business vocabulary に分離する。

