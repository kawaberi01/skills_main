# GitHub Copilot Instructions — OZ-DatabaseEntities

## プロジェクト概要

このソリューションは **Entity Framework Core 6** を使用した **SQL Server** 向け DB エンティティ＆サービス クラス群です。
各 .NET 6 プロジェクトがデータベース単位に分かれており、マイグレーションの実行もこのソリューション内で行います。

- ターゲット フレームワーク: `net6.0`
- ORM: Entity Framework Core 6
- DB: SQL Server (Azure SQL / ローカル SQL Server)
- Nullable: `disable`（全プロジェクト共通）

---

## ソリューション構成

```
OZ-DatabaseEntities.sln
├── bdash/                          # Bdash (メール配信・BI) DB エンティティ
├── calloz0805db/                   # 管理画面権限 DB エンティティ
├── ibtoz0804db/                    # アイビューティーストアー DB エンティティ
├── idoz0804db/                     # アイドラッグストアー DB エンティティ
├── igeoz0805db/                    # アイジェネリックストアー DB エンティティ
├── irxoz0804db/                    # アイアールエックスメディシン DB エンティティ
├── masonpearson2/                  # メイソンピアソン DB エンティティ
├── ozter0805db/                    # コーポレートサイト DB エンティティ
├── shared/                         # 共通管理画面 DB エンティティ
├── MigrationSettingConsoleApplication/  # マイグレーション実行用スタートアッププロジェクト
├── OzDatabaseLibrary/              # 共通ライブラリ（DbContextService 基底クラス等）
└── OzDatabaseSharedModels/         # 共通モデル・定数
```

### テスト プロジェクト（AI の作業対象外）

```
calloz0805dbTest/
idoz0804dbTest/
igeoz0805dbTests/
masonpearson2Test/
```

---

## DB コンテキスト一覧

| Context クラス名 | プロジェクト | 接続先 DB | ConnectionString キー |
|---|---|---|---|
| `sharedContext` | `shared` | shared | `shared` |
| `irxoz0804dbContext` | `irxoz0804db` | irxoz0804db | `irxoz0804db` |
| `idoz0804dbContext` | `idoz0804db` | idoz0804db | `idoz0804db` |
| `igeoz0805dbContext` | `igeoz0805db` | igeoz0805db | `igeoz0805db` |
| `calloz0805dbContext` | `calloz0805db` | calloz0805db | `calloz0805db` |
| `masonpearson2Context` | `masonpearson2` | masonpearson2 | `masonpearson2` |
| `ibeautystoreContext` | `ibtoz0804db` | ibeautystore | `ibtoz0804db` |
| `ozter0805dbContext` | `ozter0805db` | ozter0805db | `ozter0805db` |
| `BdashContext` | `bdash` | (Bdash) | `bdash` |
| `DwhContext` | (DWH 系) | — | — |

> **注意**: `ibtoz0804db` プロジェクトの Context クラス名は `ibeautystoreContext`、ConnectionString キーは `ibtoz0804db` です。  
> プロジェクト名と DB 名・Context 名が一致しない唯一のケースです。

---

## マイグレーション手順

### スタートアップ プロジェクト

パッケージ マネージャー コンソールのスタートアップ プロジェクトは必ず  
**`MigrationSettingConsoleApplication`** を指定してください。

### マイグレーション追加（Add-Migration）

PowerShell スクリプト `add.ps1` を使用します。

```powershell
# 書式: ./add <プロジェクト略称> <マイグレーション名>
./add id AddNewTable          # idoz0804db
./add ib AddNewColumn         # ibtoz0804db (ibeautystore)
./add ig AddNewTable          # igeoz0805db
./add irx AddNewTable         # irxoz0804db
./add mason AddNewTable       # masonpearson2
./add shared AddNewTable      # shared
./add ozinter AddNewTable     # ozter0805db
```

プロジェクト略称と Context の対応：

| 略称 | Context | プロジェクト |
|---|---|---|
| `id` | `idoz0804dbContext` | `idoz0804db` |
| `ib` | `ibeautystoreContext` | `ibtoz0804db` |
| `ig` | `igeoz0805dbContext` | `igeoz0805db` |
| `irx` | `irxoz0804dbContext` | `irxoz0804db` |
| `mason` | `masonpearson2Context` | `masonpearson2` |
| `shared` | `sharedContext` | `shared` |
| `ozinter` | `ozter0805dbContext` | `ozter0805db` |

### データベース更新（Update-Database）

PowerShell スクリプト `update.ps1` またはパッケージ マネージャー コンソールで直接実行します。

```powershell
# PowerShell スクリプト使用
./update id             # 未適用の全マイグレーションを適用
./update ib BdashOptOut # 指定マイグレーションまで適用/ロールバック
```

パッケージ マネージャー コンソールから直接実行する場合：

```
Update-Database -Context sharedContext
Update-Database -Context irxoz0804dbContext
Update-Database -Context idoz0804dbContext
Update-Database -Context igeoz0805dbContext
Update-Database -Context calloz0805dbContext
Update-Database -Context masonpearson2Context
Update-Database -Context ibeautystoreContext
Update-Database -Context BdashContext
```

> `MigrationSettingConsoleApplication/appsettings.json` の `ConnectionStrings` セクションに  
> 接続先 DB の接続文字列が定義されています。ローカル開発環境では `localhost,11444` が使われます。

---

## プロジェクト別 フォルダ構成

### 標準構成（idoz0804db, igeoz0805db 等）

```
<project>/
├── Models/          # エンティティクラス + DbContextクラス
├── Services/        # 各エンティティに対応するサービスクラス
├── Enums/           # 列挙型
├── Migrations/      # EF Core マイグレーションファイル（自動生成）
└── <project>.csproj
```

### 拡張構成（idoz0804db）

```
idoz0804db/
├── Configs/         # 設定クラス
├── Enums/
├── Filters/         # フィルタークラス
├── Interfaces/      # インターフェース
├── Migrations/
├── Models/
├── Services/
├── StoredProcedures/
└── Validations/     # バリデーションクラス
```

### 拡張構成（irxoz0804db）

```
irxoz0804db/
├── DataProviders/
├── EntitySetters/
├── Enums/
├── Extensions/
├── Interfaces/
├── ManualMigrations/ # 手動マイグレーション
├── Migrations/
├── Models/
├── Resources/        # .resx リソースファイル
└── Services/
```

---

## コーディング規約

### エンティティクラス（Models/）

- `partial class` で定義し、DbContext クラスと同一ファイルではなく個別ファイルに格納
- プロパティは `public` で、EF Core のマッピング規約に従う
- `Nullable` は無効 (`disable`) のため、参照型に `?` は原則不要

```csharp
namespace idoz0804db.Models
{
  public partial class Order
  {
    public int Id { get; set; }
    public string OrderNo { get; set; }
    // ...
  }
}
```

### DbContext クラス（Models/<ProjectName>Context.cs）

- `ConnectionStringName` 定数を定義して接続文字列キーを一元管理
- `DbSet<TEntity>` は複数形プロパティ名で定義

```csharp
public partial class idoz0804dbContext : DbContext
{
  public const string ConnectionStringName = "idoz0804db";
  // ...
  public virtual DbSet<Order> Orders { get; set; }
}
```

### サービスクラス（Services/）

各エンティティに対応するサービスクラスは以下の基底クラスを継承します。

**idoz0804db の例：**

```
DbContextService<TDbContext>         ← OzDatabaseLibrary（最基底）
  └─ Idoz0804DbContextService        ← プロジェクト固有の基底（Context なし）
       └─ Idoz0804DbContextService<TEntity>  ← エンティティ操作の基底
            └─ OrderService          ← 個別サービスクラス
```

基本パターン：

```csharp
namespace idoz0804db.Services
{
  public class OrderService : Idoz0804DbContextService<Order>
  {
    public OrderService(idoz0804dbContext dbContext, ILogger<OrderService> logger)
      : base(dbContext, logger) { }

    // 個別のメソッドを追加
    public async Task<Order> GetByIdAsync(int id)
    {
      return await dbContext.Orders.Where(o => o.Id == id).SingleOrDefaultAsync();
    }
  }
}
```

### OzDatabaseLibrary の提供するもの

| クラス/インターフェース | 役割 |
|---|---|
| `DbContextService<TDbContext>` | サービス基底。`SaveChangesAsync()` を提供 |
| `IContextService<TEntity>` | `GetAll()`, `AddAsync()`, `UpdateAsync()`, `DeleteAsync()` 等の共通インターフェース |
| `SaveChangesResult` | DB 更新結果クラス（StatusCode, 影響行数, 例外情報） |

`SaveChangesResult.StatusCode` の値：

- `Succeeded` — 正常完了
- `DbUpdateConcurrencyException` — 同時更新例外
- `DbUpdateException` — DB 更新失敗
- `Exception` — その他例外

---

## 依存関係

各 DB プロジェクトは `OzDatabaseLibrary` に依存します。

```
MigrationSettingConsoleApplication
├── bdash
├── calloz0805db
├── ibtoz0804db
├── idoz0804db　　　　　├── OzDatabaseLibrary
├── igeoz0805db　　　　　│     └── (EFCore 6, EFCore.BulkExtensions 等)
├── irxoz0804db
├── masonpearson2　　　　└── OzDatabaseSharedModels
├── ozter0805db               └── (Newtonsoft.Json, MailKit, NVelocity)
└── shared
```

---

## AI へのガイドライン

### マイグレーション追加・変更時の注意

1. **エンティティクラスを変更した後**、`Migrations/` フォルダのファイルを手動で編集しない
2. `Add-Migration` は `add.ps1` または `Add-Migration <Name> -Context <Context> -Project <Project>` で実行
3. `MigrationSettingConsoleApplication` がスタートアップ プロジェクトであることを確認
4. `Migrations/` ディレクトリは自動生成のため編集不要（`ManualMigrations/` は除く）

### サービスクラス追加時の注意

1. ファイル名は `<EntityName>Service.cs` の形式（例: `OrderService.cs`）
2. 各プロジェクト固有の基底サービスクラスを継承する（`OzDatabaseLibrary` の `DbContextService<T>` を直接継承しない）
3. `GetAll()` は基底で実装済み。プロパティ名の複数形が `DbSetName` として使われる

### テスト プロジェクトは対象外

`calloz0805dbTest/`, `idoz0804dbTest/`, `igeoz0805dbTests/`, `masonpearson2Test/` は  
本指示の対象外です。テスト関連のコード変更は各テスト プロジェクトを参照してください。

### 新規テーブル追加の標準フロー

1. `Models/<EntityName>.cs` — エンティティクラスを作成
2. `Models/<ProjectName>Context.cs` — `DbSet<TEntity>` プロパティを追加
3. `Models/<ProjectName>Context.cs` の `OnModelCreating()` — 必要に応じてマッピング設定を追加
4. `Services/<EntityName>Service.cs` — サービスクラスを作成
5. `add.ps1` でマイグレーションを追加
6. `update.ps1` でデータベースに適用

---

## doc/ フォルダ

| ファイル | 内容 |
|---|---|
| `doc/CLAUDE.md` | AI タスク実行の4段階フロー（要件定義→設計→タスク化→実行） |
| `doc/Database-Design-and-EntityFramework.md` | DB 設計・EF Core の設計指針 |
| `doc/ai-sql-generation-guide.md` | AI による SQL 生成ガイド |
| `doc/sql_reference.md` | SQL リファレンス集 |
| `doc/spec/` | タスクごとの仕様書（requirements.md, design.md, tasks.md） |

> 複雑なタスクを実施する前に `doc/CLAUDE.md` の4段階フローを確認してください。
