# Copilot Instructions — iDrugStore ワークスペース

## Response Policy

すべてのコミュニケーションとドキュメントは、必ず**日本語**で記述・応答してください。

---

## 1. ワークスペース概要

本ワークスペースは、**iDrugStore**（EC サイト＋管理画面）を中心に、複数の NuGet パッケージ化されたライブラリ群で構成されています。

### プロジェクト構成図

```
┌──────────────────────────────────────────────────┐
│              iDrugStore (メインソリューション)         │
│  ┌──────────────┐  ┌────────────────────────┐    │
│  │ iDrugStore   │  │ iDrugStore.Callcenter  │    │
│  │ (EC サイト)   │  │ (管理画面)              │    │
│  └──────┬───────┘  └──────────┬─────────────┘    │
│         │                     │                   │
│         └──────┬──────────────┘                   │
│                │                                  │
│       ┌────────▼────────┐                         │
│       │ iDrugStore.Models│  ← 共有ビジネスロジック  │
│       └────────┬────────┘                         │
└────────────────┼──────────────────────────────────┘
                 │ NuGet 参照
     ┌───────────┼───────────────────────────┐
     │           │           │               │
┌────▼────┐ ┌───▼────┐ ┌───▼──────┐ ┌──────▼──────┐
│OZ-DB    │ │iDrug   │ │OZ-      │ │OzPayment   │
│Entities │ │Store   │ │Framework│ │Library     │
│(DB層)   │ │Vars    │ │(共通Util)│ │(決済)      │
└─────────┘ └────────┘ └─────────┘ └────────────┘
                 │           │
          ┌──────┴──┐  ┌────▼────┐
          │OzPca    │  │OzLogimec│
          │Library  │  │Library  │
          │(会計PCA) │  │(倉庫)   │
          └─────────┘  └─────────┘
```

### プロジェクト一覧

| プロジェクト | 種別 | 概要 |
|---|---|---|
| **iDrugStore** | ASP.NET Core 6.0 MVC | EC サイト本体（フロントエンド） |
| **iDrugStore.Callcenter** | ASP.NET Core 6.0 MVC | EC サイト管理画面（コールセンター向け） |
| **iDrugStore.Models** | .NET 6.0 クラスライブラリ | 両 Web プロジェクトから参照される共有モデル・サービス |
| **OZ-DatabaseEntities** | .NET 6.0 / NuGet パッケージ | EF Core エンティティ・DbContext（DB 別に分離） |
| **iDrugStoreVariables** | .NET Standard 2.1 / NuGet パッケージ | 共通定数・Enum・拡張メソッド |
| **OZ-Framework** | .NET Standard 2.1 & .NET Core 3.1 / NuGet パッケージ | 共通ユーティリティ（Azure, Redis, メール, Excel 等） |
| **OzPaymentLibrary** | .NET Standard 2.1 / NuGet パッケージ | 決済ゲートウェイ統合（ちょコム, NP, OnePay 等） |
| **OzPcaLibrary** | .NET Standard 2.1 / NuGet パッケージ | PCA 会計システム連携（部門コード, 適用コード等） |
| **OzLogimecLibrary** | .NET Standard 2.1 / NuGet パッケージ | ロジメック倉庫出荷 API 連携 |

> **重要**: ライブラリプロジェクトは直接プロジェクト参照ではなく、すべて **NuGet パッケージとして参照** されています。ライブラリのコード変更はパッケージのバージョンアップ + 参照側での更新が必要です。

---

## 2. 技術スタック

### フレームワーク & ランタイム

| 項目 | 値 |
|---|---|
| メインフレームワーク | ASP.NET Core 6.0 (MVC / Razor) |
| ライブラリ共通ターゲット | .NET Standard 2.1 |
| ORM | Entity Framework Core 6.0.21 |
| データベース | SQL Server (Azure SQL) |
| キャッシュ | StackExchange.Redis |
| オブジェクトマッピング | AutoMapper 12.0.0 |
| ロギング | ELMAH (ElmahCore.Sql) |
| PDF 生成 | FreeSpire.PDF |
| Excel 処理 | NPOI |
| バルク操作 | EFCore.BulkExtensions |
| CI/CD | Azure Pipelines (YAML) |
| クラウド | Azure (App Service, Blob Storage, App Configuration, Redis Cache) |

### 主要 NuGet パッケージ（内部）

| パッケージ名 | 提供元プロジェクト | 用途 |
|---|---|---|
| `idoz0804db` | OZ-DatabaseEntities | メイン DB エンティティ |
| `calloz0805db` | OZ-DatabaseEntities | 管理画面 DB エンティティ |
| `igeoz0805db` | OZ-DatabaseEntities | iGeneric DB エンティティ |
| `iDrugStoreVariables` | iDrugStoreVariables | 共通定数・Enum |
| `OzDotNetCoreLibrary` | OZ-Framework | ASP.NET Core ユーティリティ |
| `OzLibrary` | OZ-Framework | 汎用ユーティリティ |
| `OzDatabaseLibrary` | OZ-DatabaseEntities | DbContext 抽象化基盤 |
| `OzPaymentLibrary.*` | OzPaymentLibrary | 各決済プロバイダー |
| `OzPcaLibrary` | OzPcaLibrary | PCA 会計連携 |
| `OzLogimecLibrary` | OzLogimecLibrary | 倉庫出荷連携 |

---

## 3. アーキテクチャ & 設計パターン

### 3.1 レイヤー構造

```
[Controller] → [ViewModel] → [Service / Factory] → [DbContextService] → [DbContext / SQL Server]
```

- **Controller**: ドメイン別に分割（`HomeController`, `OrderController`, `CartController` 等）
- **BaseController**: 共通フィールド（`ServiceFactory`, `RedisManager`, `SessionManager`, `CookieManager`）を保持する抽象基底クラス
- **ViewModel**: `ViewModels/` に各コントローラー対応のサブフォルダで管理
- **ServiceFactory**: DI コンテナから各種サービスを動的に取得するファクトリ
- **DbContextService<TDbContext>**: 汎用 CRUD 操作の抽象基底クラス（`IContextService<TEntity>` 実装）

### 3.2 依存注入 (DI)

- コンストラクタインジェクションを使用
- サービス登録は `StartUpConfigures/ServiceConfigures/` 内の静的クラスに分離
  - 例: `EntityServiceConfiguration.ConfigureServices(services, configuration)`
- 各構成クラスが責務ごとにサービスを登録（10〜13 個の構成クラス）

### 3.3 Entity Framework Core 設定

```
- DbContext スコープ: ServiceLifetime.Transient
- クエリ分割: QuerySplittingBehavior.SplitQuery
- 追跡なし: QueryTrackingBehavior.NoTracking（読取最適化）
- リトライ: EnableRetryOnFailure()
- タイムアウト: 600 秒
```

**主要 DbContext**:
- `idoz0804dbContext` — メイン EC サイト DB（250+ エンティティ）
- `calloz0805dbContext` — 管理画面権限 DB
- `igeoz0805dbContext` — iGeneric DB
- `sharedContext` — 共有管理 DB
- `PersistKeysStoreDBContext` — DataProtection キー格納

### 3.4 認証・認可

- Cookie ベース認証 (`CookieAuthenticationDefaults`)
- EntityFrameworkCore DataProtection キー格納
- 2 要素認証: OTP (`OtpSharp.Core`)

### 3.5 ミドルウェアパイプライン（iDrugStore）

```
DeveloperExceptionPage (DEV)
→ ExceptionHandler / StatusCodePages
→ HSTS
→ StaticFiles
→ HttpsRedirection
→ RedirectMiddleware (カスタム)
→ Routing
→ Authentication & Authorization
→ Session
→ ELMAH
→ Endpoints (MVC)
```

### 3.6 DB エンティティのパッケージ化

OZ-DatabaseEntities では各 DB ごとにプロジェクトを分離し、独立した NuGet パッケージとして管理:
- スキャフォルディングで DbContext + エンティティモデルを自動生成
- `Services/` フォルダにドメイン別の操作サービス（`OrderService`, `UserService` 等）
- `ServiceFactory` でサービスを統合的にアクセス
- ビルド構成に `CreateDatabase` を持ち、マイグレーション専用のビルドが可能

---

## 4. ソリューション内プロジェクト構造

### iDrugStore（EC サイト）

```
iDrugStore/
├── Program.cs                      ← Minimal Hosting Model
├── appsettings.json
├── Controllers/                    ← ドメイン別コントローラー (23+)
├── Views/                          ← Razor ビュー
├── ViewModels/                     ← ドメイン別ビューモデル (20+)
├── Models/                         ← ローカルモデル
├── Components/                     ← Razor コンポーネント
├── Resources/                      ← ローカライズリソース (.resx)
├── StartUpConfigures/
│   ├── ServiceConfigures/          ← DI 登録クラス (10+)
│   ├── ActionFilters/              ← アクションフィルター
│   └── Middleware/                  ← カスタムミドルウェア
└── wwwroot/                        ← 静的ファイル
```

### iDrugStore.Callcenter（管理画面）

```
iDrugStore.Callcenter/
├── Program.cs + Startup.cs         ← 従来型 Host.CreateHostBuilder パターン
├── appsettings.json
├── Controllers/                    ← 管理コントローラー
├── Views/                          ← 管理画面 Razor ビュー
├── Models/                         ← ドメイン別モデル (30+)
├── Services/                       ← ProductBulkUpdateService 等
├── Helper/                         ← ヘルパークラス
├── ModelBinders/                   ← カスタムモデルバインダー
└── StartUpConfigures/
    └── ServiceConfigures/          ← DI 登録クラス (13+)
```

> **注意**: iDrugStore は Minimal Hosting、Callcenter は従来の `Startup.cs` パターンと、ホスティングモデルが異なります。

### iDrugStore.Models（共有モデル・ロジック）

```
iDrugStore.Models/
├── Models/                         ← ドメイン別モデル (40+サブフォルダ)
│   ├── Cart/, Order/, Product/, User/, Payment/, Mail/ ...
├── Extensions/                     ← 拡張メソッド
├── Services/                       ← ビジネスロジック
├── Factories/                      ← ファクトリパターン
├── Migrations/                     ← EF Core マイグレーション
├── BackgroundTasks/                ← バックグラウンドジョブ
├── Mails/                          ← メール処理
├── Caches/                         ← キャッシング戦略
├── Configs/                        ← 設定クラス
└── Resources/                      ← ローカライズリソース
```

---

## 5. コーディング規約

### 5.1 コードスタイル（.editorconfig 準拠）

| 項目 | ルール |
|---|---|
| インデント | **2 スペース** |
| 改行コード | **CRLF** |
| 文字セット | **UTF-8 BOM** |
| 最終改行 | なし |
| `var` 使用 | 型が明確な場合は `var` を優先 |
| アクセス修飾子 | 常に明示的に記述 |
| 中括弧 `{}` | 常に必須（省略不可） |
| NULL チェック | `is null` / `is not null` パターンを推奨 |
| 式メンバー | プロパティ・アクセッサ・ラムダは可、メソッドは不可 |
| パターンマッチング | 推奨 |

### 5.2 命名規則

| 対象 | 規則 | 例 |
|---|---|---|
| クラス / 構造体 | PascalCase | `OrderService` |
| インターフェース | `I` + PascalCase | `IContextService` |
| メソッド | PascalCase | `GetOrderAsync()` |
| パブリックプロパティ | PascalCase | `OrderId` |
| プライベートフィールド | `_` + camelCase | `_redisManager` |
| ローカル変数 | camelCase | `orderTotal` |
| 定数 | PascalCase | `MaxRetryCount` |
| Enum メンバー | PascalCase + `[Display]` 属性 | `CreditCard` |

### 5.3 コーディングパターン

#### コントローラー

```csharp
// BaseController を継承し、共通フィールドを利用
public class OrderController : BaseController
{
    public OrderController(
        ServiceFactory serviceFactory,
        IHttpContextAccessor httpContextAccessor,
        RedisManager redisManager,
        SessionManager sessionManager,
        IMapper mapper) : base(...)
    {
    }
}
```

#### サービス登録

```csharp
// StartUpConfigures/ServiceConfigures/ 内に責務別の静的クラスを作成
public class EntityServiceConfiguration
{
    public static void ConfigureServices(
        IServiceCollection services,
        IConfiguration configuration)
    {
        // DbContext・サービスの登録
    }
}
```

#### AutoMapper

```csharp
// Profile クラスで Entity ↔ ViewModel のマッピング定義
public class AutoMapperProfileConfiguration : Profile
{
    public AutoMapperProfileConfiguration()
    {
        CreateMap<Address, AddressViewModel>()
            .ForMember(dest => dest.AddressId, opt => opt.MapFrom(src => src.Id));
    }
}
```

#### DB 操作

```csharp
// DbContextService<T> の汎用 CRUD を利用
// 結果は SaveChangesResult で構造化
var result = await service.AddAsync(entity);
if (!result.IsSucceeded)
{
    // result.Status, result.Exception でエラーハンドリング
}
```

---

## 6. テスト

### テストフレームワーク

| テストプロジェクト | フレームワーク | 特徴 |
|---|---|---|
| **iDrugStoreTest** | xUnit 2.5.1 | `Xunit.DependencyInjection` でコンストラクタ DI テスト |
| **iDrugStore.CallcenterTest** | MSTest 2.1.0 | 管理画面テスト |
| **iDrugStore.ModelsTest** | MSTest 2.1.0 | モデル・ビジネスロジックテスト |

### テスト共通

- **モック**: Moq 4.16.1
- **インメモリ DB**: EF Core InMemory 6.0.21
- **カバレッジ**: coverlet.collector
- **テストデータ**: JSON ファイル形式

### テスト作成ガイドライン

- 新規テストは既存のテストフレームワーク（xUnit or MSTest）に合わせること
- iDrugStoreTest は xUnit + DI、それ以外は MSTest
- EF Core のテストには `InMemory` プロバイダーを使用
- モックは Moq を使用し、インターフェース経由で依存を注入

---

## 7. ビルド & デプロイ

### ビルド構成

| 構成名 | 用途 |
|---|---|
| `Debug` | ローカル開発 |
| `Release` | 本番ビルド |
| `Testing` | テスト実行用カスタム構成 |
| `CreateDatabase` | EF Core マイグレーション実行用 |

### Azure Pipelines

- `azure-pipelines.yml` — 本番デプロイ
- `azure-pipelines-staging-iDrugStore.yml` — ステージング
- `azure-pipelines-develop-test-iDrugStore.yml` — 開発テスト (EC サイト)
- `azure-pipelines-develop-test-iDrugStore.Callcenter.yml` — 開発テスト (管理画面)

### Azure 環境

| サービス | 用途 |
|---|---|
| App Service | Web アプリホスティング（本番・ステージング・開発） |
| Azure SQL Database | データベース（複数インスタンス） |
| Azure App Configuration | アプリ設定の一元管理 |
| Azure Blob Storage | 画像・アセット保存 |
| Azure Cache for Redis | セッション・分散キャッシュ |

---

## 8. DB 接続 & データソース

### 接続文字列キー

| キー | 対象 DB | 用途 |
|---|---|---|
| `idoz0804db` | メイン DB | EC サイトのコアデータ |
| `calloz0805db` | 管理画面 DB | コールセンター権限・管理 |
| `igeoz0805db` | iGeneric DB | 汎用ストアデータ |
| `shared` | 共有 DB | サイト横断管理データ |
| `PersistKeysStoreDB` | DataProtection | 暗号化キー保存 |

---

## 9. 決済連携

OzPaymentLibrary で以下の決済プロバイダーを統合:

| パッケージ | 決済方式 |
|---|---|
| `OzPaymentLibrary.ChocomCredit` | ちょコムクレジットカード決済 |
| `OzPaymentLibrary.ChocomConvenience` | ちょコムコンビニ決済 |
| `OzPaymentLibrary.DensanConvenience` | デンサンコンビニ決済 |
| `OzPaymentLibrary.NetProtectionsSpot` | NP 後払い（Net Protections） |
| `OzPaymentLibrary.OnePay` | OnePay 決済 |

---

## 10. 外部システム連携

| システム | ライブラリ | 用途 |
|---|---|---|
| **PCA（会計）** | `OzPcaLibrary` | 部門コード・適用コード・商品マスターの管理 |
| **ロジメック（倉庫）** | `OzLogimecLibrary` | Azure Functions API 経由の出荷依頼・出荷結果照会 |
| **Redis** | `StackExchange.Redis` | セッション管理・分散キャッシュ |
| **Cuenote（メール）** | 内部実装 | メール配信 |
| **ELMAH** | `ElmahCore.Sql` | エラーロギング |

---

## 11. コード変更時の注意事項

### ライブラリ変更時

1. ライブラリプロジェクトのコードを変更
2. `.csproj` のバージョン番号をインクリメント
3. NuGet パッケージをビルド・公開
4. 参照元プロジェクト（iDrugStore 等）の NuGet 参照を更新

### iDrugStore 内の変更時

- **新しいサービス追加**: 対応する `ServiceConfigures/` クラスに DI 登録を追加
- **新しいコントローラー**: `BaseController` を継承
- **新しいエンティティ**: OZ-DatabaseEntities 側で追加 → NuGet パッケージ更新
- **新しい定数・Enum**: iDrugStoreVariables に追加 → NuGet パッケージ更新

### Nullable 参照型

- iDrugStore / iDrugStore.Callcenter / iDrugStore.Models: `<Nullable>enable</Nullable>`
- OZ-DatabaseEntities の各 DB プロジェクト: `<Nullable>disable</Nullable>`
- ライブラリ各種: プロジェクトにより異なる

---

## 12. よくある開発タスク

### DB エンティティの追加・変更

```
OZ-DatabaseEntities → 対象DBプロジェクトでスキャフォルド → NuGetバージョンアップ → iDrugStoreで参照更新
```

### 新しい決済方式の追加

```
OzPaymentLibrary → 新プロジェクト追加 → .NET Standard 2.1 → NuGetパッケージ化 → iDrugStore.Modelsで参照追加
```

### 共通定数の追加

```
iDrugStoreVariables → Enums/ or Models/ にクラス追加 → [Display]属性付与 → NuGetバージョンアップ
```