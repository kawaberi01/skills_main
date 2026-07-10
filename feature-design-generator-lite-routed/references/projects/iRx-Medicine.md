# GitHub Copilot Instructions — iRx-Medicine

## プロジェクト概要

このワークスペースは **iRx-Medicine**（アイアールエックスメディシン）の EC サイトおよび管理画面を中心としたマルチプロジェクト構成です。
ASP.NET Core MVC (.NET 6) で構築された医薬品系 EC サイトと、Blazor を組み込んだコールセンター管理画面で構成されます。

- ターゲット フレームワーク: `net6.0`
- Web フレームワーク: ASP.NET Core MVC + Blazor Server（管理画面）
- ORM: Entity Framework Core 6
- DB: SQL Server (Azure SQL / ローカル SQL Server)
- Nullable: `disable`（全プロジェクト共通）
- ログ: NLog + Elmah
- セッション: Redis
- 認証: Cookie 認証
- 多言語: ja / en / zh（デフォルト: 日本語）

---

## ワークスペース構成

```
iRx-Medicine/                         ← メインソリューション
├── iRx-Medicine/                     # EC サイト（顧客向け Web アプリ）
├── iRx-Medicine.Callcenter/          # コールセンター管理画面（MVC + Blazor）
├── iRx-Medicine.Models/              # ビジネスロジック・サービス共通ライブラリ
├── iRxMedicine.NetCore.Models/       # アドレス処理等の補助モデルライブラリ
├── iRx-MedicineTests/                # EC サイトのユニットテスト
├── iRx-Medicine.CallcenterTest/      # 管理画面のユニットテスト
├── iRx-Medicine.ModelsTests/         # Models プロジェクトのユニットテスト
└── iRx-MedicineDocs/                 # ドキュメント
```

### 外部 NuGet パッケージ（同一ワークスペース内のライブラリ群）

以下のプロジェクトは **直接プロジェクト参照せず NuGet パッケージとして参照** しています。
ソースコードはワークスペースに含まれますが、ビルド依存はパッケージ経由です。

| パッケージ名 | ソース プロジェクト | 役割 |
|---|---|---|
| `irxoz0804db` | OZ-DatabaseEntities/irxoz0804db | メイン DB エンティティ＆サービス |
| `calloz0805db` | OZ-DatabaseEntities/calloz0805db | 管理画面権限 DB エンティティ |
| `shared.oz` | OZ-DatabaseEntities/shared | 共通 DB エンティティ |
| `OzLibrary` | OZ-Framework/OzLibrary | 共通ユーティリティ（HTTP, Azure, Cache, メール等） |
| `OzDotNetCoreLibrary` | OZ-Framework/OzDotNetCoreLibrary | ASP.NET Core ヘルパー（タグヘルパー, フィルター等） |
| `OzPaymentLibrary` | OzPaymentLibrary/ | 決済基盤ライブラリ |
| `OzPaymentLibrary.ChocomCredit` | OzPaymentLibrary/ChocomCredit | ちょコムクレジット決済 |
| `OzPcaLibrary` | OzPcaLibrary/ | PCA 販売管理システム連携 |

> **注意**: これらのパッケージのソースを変更しても、iRx-Medicine のビルドには反映されません。
> パッケージ側でバージョンアップ＆公開後、iRx-Medicine 側の NuGet 参照を更新する必要があります。

---

## プロジェクト別 詳細

### iRx-Medicine（EC サイト）

顧客向け Web アプリケーション。商品閲覧、カート、注文、マイページ、問い合わせ等。

```
iRx-Medicine/
├── Controllers/          # MVC コントローラー（14個）
│   ├── BaseController.cs     # 全コントローラーの基底クラス
│   ├── HomeController.cs     # トップページ
│   ├── ProductsController.cs # 商品ページ
│   ├── CartsController.cs    # カート
│   ├── OrdersController.cs   # 注文
│   ├── MypageController.cs   # マイページ
│   ├── UsersController.cs    # ユーザー登録・ログイン
│   ├── InterviewController.cs # 問診
│   ├── InquiryController.cs  # お問い合わせ
│   ├── ContentsController.cs # CMS コンテンツ
│   ├── ApiController.cs      # API エンドポイント
│   ├── MailOrdersController.cs # 郵送注文
│   ├── DownloadController.cs # ダウンロード
│   ├── HelpController.cs     # ヘルプ
│   └── ErrorController.cs    # エラーページ
│
├── Views/                # Razor ビュー（コントローラーと対応）
├── ViewModels/           # ビューモデル
├── Models/               # ドメインモデル
├── Resources/            # 多言語リソース（.resx）
│   └── Views/, Models/, Controllers/, Shared/
│
├── StartUpConfigures/    # DI 登録・設定クラス群
│   └── ServiceConfigures/
│       ├── EntityServiceConfiguration.cs       # DbContext・ServiceFactory 登録
│       ├── AuthorizationConfiguration.cs       # 認証・DataProtection
│       ├── SessionStateConfiguration.cs        # Redis セッション
│       ├── AppSettingsServiceConfiguration.cs  # Redis・CloudFlare 設定
│       ├── LoggingServiceConfiguration.cs      # NLog・Elmah
│       ├── PaymentServiceConfiguration.cs      # 決済設定
│       ├── ValidationServiceConfiguration.cs   # カスタムバリデーション
│       ├── HttpClientConfiguration.cs          # HttpClient 登録
│       ├── LocalizationConfiguration.cs        # 多言語設定（ja/en/zh）
│       └── ViewUtilityConfiguration.cs         # HTML エンコード・パンくず
│
├── wwwroot/              # 静的ファイル（CSS, JS, 画像）
├── Program.cs            # エントリーポイント
├── Startup.cs            # ミドルウェア・DI 設定
├── Nlog.config           # NLog 設定
├── appsettings.json      # アプリケーション設定
├── web.config            # IIS 設定
└── doc/                  # ドキュメント
    ├── CLAUDE.md         # AI タスク実行の4段階フロー
    └── spec/             # 仕様書（requirements.md, design.md, tasks.md）
```

### iRx-Medicine.Callcenter（管理画面）

コールセンター向け管理ツール。MVC + Blazor Server のハイブリッド構成。

```
iRx-Medicine.Callcenter/
├── Controllers/          # MVC コントローラー（19個）
│   ├── BaseController.cs          # 管理画面用基底クラス
│   ├── HomeController.cs          # ダッシュボード
│   ├── OrderController.cs         # 注文管理
│   ├── ProductsController.cs      # 商品管理
│   ├── UsersController.cs         # ユーザー管理
│   ├── PaymentController.cs       # 入金管理
│   ├── CreditCardController.cs    # クレジットカード管理
│   ├── OnePayController.cs        # OnePay（Alipay/WeChat）管理
│   ├── ContentsController.cs      # コンテンツ管理
│   ├── MasterController.cs        # マスター管理
│   ├── ExportController.cs        # データエクスポート
│   ├── ExcelOrderListController.cs # Excel 注文リスト
│   ├── OrderToSupplierController.cs # 仕入先発注
│   ├── ShippingNotificationController.cs   # 出荷通知
│   ├── ShippingStatusCheckController.cs    # 配送状況確認
│   ├── RepoertController.cs       # レポート
│   ├── ToDoTaskManagerController.cs # ToDo タスク管理
│   ├── SystemController.cs        # システム管理
│   └── ApiController.cs           # API エンドポイント
│
├── Blazor/               # Blazor Server コンポーネント
│   ├── Pages/            # Blazor ページ
│   │   ├── Addresses/        # 住所管理
│   │   ├── Exports/          # エクスポート
│   │   ├── Orders/           # 注文管理
│   │   ├── Payments/         # 入金管理
│   │   ├── Products/         # 商品管理
│   │   ├── ShippingStatusCheck/ # 配送状況
│   │   └── Users/            # ユーザー管理
│   ├── Components/       # 共通 Blazor コンポーネント（16個）
│   │   ├── DateTimePicker.razor
│   │   ├── ProductSelector.razor
│   │   ├── UserSelector.razor
│   │   ├── MailEditor.razor
│   │   ├── MultiFileUploader.razor
│   │   └── ... 等
│   └── Shared/           # レイアウト（MainLayout.razor）
│
├── Views/                # Razor ビュー（MVC）
├── Models/               # ビューモデル
├── StartUpConfigures/    # 設定クラス
├── wwwroot/              # 静的ファイル
├── Program.cs            # エントリーポイント
├── Startup.cs            # ミドルウェア設定（Blazor Hub 含む）
├── NLog.config           # NLog 設定
├── appsettings.json      # 設定
└── Dockerfile            # Docker コンテナ化
```

### iRx-Medicine.Models（共通ビジネスロジック）

EC サイト・管理画面の両方から参照されるサービス・モデル層。

```
iRx-Medicine.Models/
├── Services/             # サービスクラス（45個以上）
│   ├── UserService.cs
│   ├── OrderService.cs
│   ├── ProductService.cs
│   ├── CartService.cs / CartItemService.cs
│   ├── AddressService.cs
│   ├── MailTemplateService.cs
│   ├── TwoFactorAuthService.cs
│   ├── ChocomLogService.cs / ChocomConvenienceService.cs
│   ├── OnePayService.cs
│   ├── OrderPcaService.cs
│   ├── BlockedIpAddressesService.cs
│   └── ... 等
│
├── Models/               # ドメインモデル
│   ├── Address/          # 住所検証・解析
│   ├── Orders/           # 注文関連
│   ├── UserData/         # ユーザーデータ（IUserData インターフェース）
│   ├── Mails/            # メールテンプレート（JP/EN/CN）
│   ├── OnePay/           # OnePay 決済モデル
│   ├── ChocomCredit/     # ちょコム決済モデル（3Dセキュア含む）
│   ├── PCA/              # PCA 会計連携
│   ├── Configs/          # 設定モデル
│   ├── Filters/          # フィルタークラス
│   ├── Trackings/        # トラッキング
│   ├── TodoCreaters/     # ToDo 自動生成
│   └── Utils/            # ユーティリティ
│
├── Configs/              # 設定クラス
├── Extensions/           # 拡張メソッド
├── Factories/            # Factory パターン
├── BackgroundTasks/      # バックグラウンドタスク
├── Pdfs/                 # PDF 生成ロジック
├── PersistKeysStore/     # DataProtection キーストア
└── Resources/            # 多言語リソース
```

### iRxMedicine.NetCore.Models（補助モデル）

アドレス処理やインポート確認等の補助的なモデルを格納するラッパープロジェクト。
`iRx-Medicine.Models` をプロジェクト参照しています。

```
iRxMedicine.NetCore.Models/
├── Addresses/            # 住所関連モデル
└── ImportComfirmation/   # インポート確認モデル
```

---

## DB コンテキスト

iRx-Medicine が使用する DB コンテキスト:

| Context クラス名 | NuGet パッケージ | 接続先 DB | 用途 |
|---|---|---|---|
| `irxoz0804dbContext` | `irxoz0804db` | irxoz0804db | メイン DB（注文・商品・ユーザー等） |
| `sharedContext` | `shared.oz` | shared | 共通 DB |
| `calloz0805dbContext` | `calloz0805db` | calloz0805db | 管理画面権限 DB |
| `PersistKeysStoreDBContext` | — | — | DataProtection キー永続化 |

> DB エンティティ・サービスの定義は `OZ-DatabaseEntities` ソリューション側にあります。
> iRx-Medicine.Models のサービスは OZ-DatabaseEntities のサービスを**継承・拡張**しています。

---

## アーキテクチャ・設計パターン

### ServiceFactory パターン

サービスの取得に `IServiceFactory<irxoz0804dbContext>` / `ServiceFactory` パターンを使用します。

```csharp
// インターフェース（OZ-DatabaseEntities で定義）
public interface IServiceFactory<DbContextType> where DbContextType : DbContext
{
    public ServiceType GetService<ServiceType>() where ServiceType : DbContextService<DbContextType>;
}
```

**EC サイト側**: DI で `IServiceFactory<irxoz0804dbContext>` を注入

```csharp
public abstract class BaseController : Controller
{
    protected IServiceFactory<irxoz0804dbContext> serviceFactory;

    protected BaseController(IServiceFactory<irxoz0804dbContext> serviceFactory, ...) { ... }
}
```

**管理画面側**: コンストラクタで直接生成

```csharp
public abstract class BaseController : Controller
{
    protected ServiceFactory serviceFactory;

    protected BaseController(irxoz0804dbContext dbContext, ILoggerFactory loggerFactory)
    {
        serviceFactory = new ServiceFactory(dbContext, loggerFactory);
    }
}
```

### サービスクラス階層

iRx-Medicine.Models のサービスは OZ-DatabaseEntities のサービスを継承・拡張します。

```
DbContextService<TDbContext>             ← OzDatabaseLibrary（最基底）
  └─ IRxoz0804DbContextService           ← irxoz0804db プロジェクト固有の基底
       └─ irxoz0804db.Services.UserService  ← DB エンティティのサービス
            └─ iRx_Medicine.Models.Services.UserService  ← ビジネスロジック拡張
```

```csharp
// iRx-Medicine.Models/Services/UserService.cs
namespace iRx_Medicine.Models.Services
{
    public class UserService : irxoz0804db.Services.UserService
    {
        public UserService(irxoz0804dbContext dbContext, ILogger logger) : base(dbContext, logger) { }

        // ビジネスロジック固有メソッド
        public async Task<bool> IsExistAsync(int userId) { ... }
        public async Task<bool> IsUniqueEmailAddressAsync(string email) { ... }
    }
}
```

### コントローラー基底クラス

#### EC サイト BaseController
- `[TypeFilter(typeof(DefaultLanguageSettingActionFilter))]` で多言語フィルター適用
- 依存注入: `IServiceFactory<irxoz0804dbContext>`, `IHttpContextAccessor`, `ICompositeViewEngine`
- 主要メソッド: `SignInUserAsync()`, `GetUserId()`, `GetUserAsync()`, `AddItemToCartAsync()`, `GetCurrentCulture()`
- GA4（Google Analytics 4）連携

#### 管理画面 BaseController
- 依存注入: `irxoz0804dbContext`, `ILoggerFactory`
- `ServiceFactory` を直接生成
- 主要メソッド: `GetName()`, `SignInTestUserAsync()`, `SignInUserAsync()`

### DI 登録パターン（StartUpConfigures）

`Startup.cs` で設定クラスの拡張メソッドをチェーンして登録します:

```csharp
services
    .ConfigureEntityServices(Configuration)        // DbContext・ServiceFactory
    .ConfigureAppSettingsService(Configuration)     // Redis・CloudFlare 設定
    .ConfigureLoggingServices(Configuration)        // NLog・Elmah
    .ConfigureAuthorizationServices()               // Cookie 認証
    .ConfigureLocalizationServices()                // 多言語（ja/en/zh）
    .ConfigureViewUtilityServices(assembly)          // HTML エンコード・パンくず
    .ConfigureHttpClientServices(Configuration)     // HttpClient
    .ConfigurePaymentServices(Configuration)        // 決済サービス
    .ConfigureSessionStateServices(Configuration);  // Redis セッション
```

### 認証・セッション設定

| 項目 | EC サイト | 管理画面 |
|---|---|---|
| Cookie 名 | `iRx-Medicine` | 管理画面用 Cookie |
| ログイン パス | `/login` | トークンベース認証 |
| セッション Cookie | `.iRxWorks.Session` | `.iRxWorks.Session` |
| セッション タイムアウト | 20 分 | 20 分 |
| セッション ストア | Redis | Redis |
| SameSite | None | None |
| SecurePolicy | Always (HTTPS) | Always (HTTPS) |

---

## 決済プロバイダー

| プロバイダー | NuGet パッケージ | 主な機能 |
|---|---|---|
| ちょコムクレジット | `OzPaymentLibrary.ChocomCredit` | クレジットカード決済（3Dセキュア対応、トークン決済） |
| ちょコムコンビニ | `OzPaymentLibrary` | コンビニ決済 |
| 電算コンビニ | `OzPaymentLibrary` | コンビニ決済（電算系） |
| OnePay | `OzPaymentLibrary` | Alipay / WeChat Pay |
| NP 後払い | `OzPaymentLibrary` | 後払い決済（NetProtections） |

---

## 依存関係

```
iRx-Medicine（EC サイト）
├── iRx-Medicine.Models            ← プロジェクト参照
│   ├── irxoz0804db                ← NuGet（メイン DB エンティティ）
│   ├── calloz0805db               ← NuGet（管理画面権限 DB）
│   ├── shared.oz                  ← NuGet（共通 DB）
│   ├── OzLibrary                  ← NuGet（共通ユーティリティ）
│   ├── OzPaymentLibrary           ← NuGet（決済基盤）
│   └── OzPaymentLibrary.ChocomCredit ← NuGet（ちょコム決済）
│
├── iRxMedicine.NetCore.Models     ← プロジェクト参照
│   └── iRx-Medicine.Models        ← プロジェクト参照
│
└── OzDotNetCoreLibrary            ← NuGet（ASP.NET Core ヘルパー）

iRx-Medicine.Callcenter（管理画面）
├── iRx-Medicine.Models            ← プロジェクト参照
├── iRxMedicine.NetCore.Models     ← プロジェクト参照
├── OzBlazorLibrary                ← NuGet（Blazor コンポーネント）
├── Radzen.Blazor                  ← NuGet（Blazor UI ライブラリ）
└── jsreport.AspNetCore            ← NuGet（レポート生成）
```

---

## 主要 NuGet パッケージ一覧

### iRx-Medicine（EC サイト）

| パッケージ | バージョン | 用途 |
|---|---|---|
| `Azure.Identity` | 1.12.0 | Azure 認証 |
| `Microsoft.Extensions.Caching.StackExchangeRedis` | 5.0.1 | Redis キャッシュ |
| `Microsoft.Extensions.Caching.SqlServer` | 5.0.0 | SQL キャッシュ |
| `Microsoft.Extensions.Localization` | 3.1.7 | 多言語対応 |
| `Microsoft.Azure.AppConfiguration.AspNetCore` | 3.0.2 | Azure App Configuration |
| `OzDotNetCoreLibrary` | 1.1.2 | ASP.NET Core ヘルパー |
| `OtpSharp.Core` | 1.0.0 | OTP / 2FA |
| `QRCoder` | 1.3.9 | QR コード生成 |
| `Schema.NET` | 12.0.0 | JSON-LD 構造化データ |
| `SmartBreadcrumbs` | 3.5.1 | パンくずナビ |
| `IPAddressRange` | 6.0.0 | IP アドレス範囲チェック |
| `NLog.Extensions.AzureBlobStorage` | 3.0.0 | Azure Blob ログ |

### iRx-Medicine.Models

| パッケージ | バージョン | 用途 |
|---|---|---|
| `irxoz0804db` | 1.1.60 | メイン DB エンティティ |
| `calloz0805db` | 1.1.5 | 管理画面権限 DB |
| `shared.oz` | 1.1.13 | 共通 DB |
| `OzLibrary` | 1.1.57 | 共通ユーティリティ |
| `OzPaymentLibrary` | 1.0.7 | 決済基盤 |
| `OzPaymentLibrary.ChocomCredit` | 1.0.18 | ちょコム決済 |
| `FreeSpire.PDF` | 8.6.0 | PDF 生成 |
| `WanaKanaSharp` | 1.0.0 | ひらがな/カタカナ変換 |

---

## コーディング規約

### コントローラー（Controllers/）

- `BaseController` を継承する
- EC サイト: `[TypeFilter(typeof(DefaultLanguageSettingActionFilter))]` が基底で適用済み
- 内部メソッドには `[Route("ignore")]` を付与して外部公開しない
- ビュー返却は `return View(viewModel)` パターン

```csharp
namespace iRxMedicine.Controllers
{
    public class ProductsController : BaseController
    {
        public ProductsController(
            IServiceFactory<irxoz0804dbContext> serviceFactory,
            IHttpContextAccessor httpContextAccessor,
            ICompositeViewEngine engine)
            : base(serviceFactory, httpContextAccessor, engine) { }

        public async Task<IActionResult> Index() { ... }
    }
}
```

### サービスクラス（iRx-Medicine.Models/Services/）

- OZ-DatabaseEntities のサービスを継承するか、`IRxoz0804DbContextService` を継承
- コンストラクタは `(irxoz0804dbContext dbContext, ILogger logger)` パターン
- `GetAll()` メソッドでは `includeRelations` フラグで関連エンティティの Include を制御

```csharp
namespace iRx_Medicine.Models.Services
{
    public class OrderService : IRxoz0804DbContextService
    {
        public OrderService(irxoz0804dbContext dbContext, ILogger<OrderService> logger)
            : base(dbContext, logger) { }

        public IQueryable<Order> GetAll(bool includeRelations = false, bool asNoTracking = false)
        {
            var query = dbContext.Orders.AsQueryable();
            if (includeRelations)
            {
                query = query
                    .Include(o => o.User)
                    .Include(o => o.LineItems)
                    .Include(o => o.OrderStatus);
            }
            return asNoTracking ? query.AsNoTracking() : query;
        }
    }
}
```

### ビューモデル（ViewModels/）

- ビュー専用のモデルクラス。コントローラーから View に渡すデータを構造化
- 命名規則: `<Action名>ViewModel.cs`

### Blazor コンポーネント（Callcenter 専用）

- `Blazor/Pages/` にページコンポーネント、`Blazor/Components/` に共通コンポーネント
- `Radzen.Blazor` を UI ライブラリとして使用
- `MainLayout.razor` でレイアウト定義

### 多言語対応

- リソースファイル（.resx）を `Resources/` 配下に配置
- サポート言語: `ja`（日本語）, `en`（英語）, `zh`（中国語）
- デフォルト: 日本語
- `RequestCultureProviders`: QueryString と Cookie のみ

---

## 環境・インフラ

### Azure サービス

| サービス | 用途 |
|---|---|
| Azure App Configuration | アプリケーション設定（Release/Testing 環境） |
| Azure Key Vault | シークレット管理 |
| Azure Blob Storage | ログ保存・ファイルストレージ |
| Azure SQL Database | データベース |
| Azure Redis Cache | セッション管理・キャッシュ |
| ManagedIdentityCredential | Azure 認証 |

### ビルド構成

| 構成 | 用途 |
|---|---|
| `Debug` | 開発環境（テストユーザー認証有効、Razor ランタイムコンパイル有効） |
| `Release` | 本番環境（Azure App Config 接続、Azure Key Vault 使用） |
| `Testing` | テスト環境（Azure App Config 接続） |
| `CreateDatabase` | DB 初期作成用 |

### CI/CD パイプライン

| ファイル | 対象 |
|---|---|
| `azure-pipelines-irxmedicine-jp.yml` | EC サイト本番デプロイ |
| `azure-pipelines-develop-test-irxmedicine-jp.yml` | EC サイトテストデプロイ |
| `azure-pipelines-callcenter-irx.yml` | 管理画面本番デプロイ |
| `azure-pipelines-develop-test-callcenter-irx.yml` | 管理画面テストデプロイ |

---

## doc/ フォルダ

| ファイル | 内容 |
|---|---|
| `doc/CLAUDE.md` | AI タスク実行の4段階フロー（要件定義→設計→タスク化→実行） |
| `doc/spec/requirements.md` | 要件定義書 |
| `doc/spec/design.md` | 設計書 |
| `doc/spec/tasks.md` | タスクリスト |

> 複雑なタスクを実施する前に `doc/CLAUDE.md` の4段階フローを確認してください。

---

## AI へのガイドライン

### 全般

1. iRx-Medicine がメインプロジェクト。OZ-DatabaseEntities 等は NuGet パッケージ経由の参照であり、直接変更しても iRx-Medicine のビルドには反映されない
2. `Nullable` は `disable`。参照型に `?` は原則不要
3. 名前空間は各プロジェクトの `RootNamespace` に従う（`iRxMedicine`, `iRx_Medicine.Models`, `iRx_Medicine.Callcenter`）

### コントローラー追加時の注意

1. EC サイト: `BaseController` を継承し、`IServiceFactory<irxoz0804dbContext>`, `IHttpContextAccessor`, `ICompositeViewEngine` をコンストラクタで受け取る
2. 管理画面: `BaseController` を継承し、`irxoz0804dbContext`, `ILoggerFactory` をコンストラクタで受け取る
3. 対応する Views フォルダにビューを作成
4. 管理画面はルートを `Startup.cs` の `MapControllerRoute` に定義すること

### サービスクラス追加時の注意

1. `iRx-Medicine.Models/Services/` に配置
2. OZ-DatabaseEntities のサービスを継承するか、`IRxoz0804DbContextService` を継承
3. OZ-DatabaseEntities のサービスを直接使わず、iRx-Medicine.Models 側で拡張してから使用するのが基本パターン

### Blazor コンポーネント追加時の注意（管理画面）

1. ページは `Blazor/Pages/<機能名>/` に配置
2. 共通コンポーネントは `Blazor/Components/` に配置
3. `Radzen.Blazor` コンポーネントの利用を優先

### テスト プロジェクト

| テスト プロジェクト | テスト対象 |
|---|---|
| `iRx-MedicineTests/` | EC サイト |
| `iRx-Medicine.CallcenterTest/` | 管理画面 |
| `iRx-Medicine.ModelsTests/` | Models ライブラリ |

テストフレームワーク: xUnit

### 外部ライブラリ（ワークスペース内）の変更

以下のプロジェクトはソースがワークスペースに含まれますが、NuGet パッケージ経由で参照されています。
iRx-Medicine と一緒にビルドされないため、変更時は各ソリューションで個別にビルド・パッケージ公開が必要です。

| ソリューション | 主なプロジェクト | 役割 |
|---|---|---|
| OZ-DatabaseEntities | irxoz0804db, shared, calloz0805db | DB エンティティ＆サービス |
| OZ-Framework | OzLibrary, OzDotNetCoreLibrary, OzBlazorLibrary | 共通ユーティリティ |
| OzPaymentLibrary | ChocomCredit, ChocomConvenience, DensanConvenience, OnePay, NetProtectionsSpot | 決済ライブラリ |
| OzPcaLibrary | OzPcaLibrary | PCA 販売管理連携 |
