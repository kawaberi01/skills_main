# Mason Pearson プロジェクト — Copilot 共通コンテキスト

## Response Policy

すべてのコミュニケーションとドキュメントは、必ず**日本語**で記述・応答してください。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | Mason Pearson EC サイト・管理画面 |
| ソリューション | `mason_pearson.sln` |
| フレームワーク | ASP.NET MVC 5 (.NET Framework 4.5.1) |
| ORM | LINQ to SQL（`System.Data.Linq`） |
| ビューエンジン | Razor（`.cshtml`） |
| データベース | SQL Server (`masonpearson2`) |
| キャッシュ | Redis（StackExchange.Redis） |
| 決済 | チョコム（クレジットカード/コンビニ） |
| CI/CD | Azure Pipelines（`azure-pipelines.yml`） |
| DBマイグレーション | 独自マイグレーションフレームワーク（`db_migrations`） |
| ロギング | NLog |

---

## 2. ソリューション構成（プロジェクト一覧）

```
mason_pearson.sln
├── mason_pearson              ← EC サイト（Web）
├── mason_pearson.callcenter   ← 管理画面（コールセンター）
├── mason_pearson.data         ← データ層（モデル・DAL・ViewModel）
├── mason_pearson.common       ← 共通設定・定数
├── mason_pearson.helpers      ← ヘルパー関数群
├── mason_pearson.job          ← バッチジョブ（WebJobs）
├── mason_pearson.ml           ← 機械学習（不正検知）
├── mason_pearson.sitemap      ← サイトマップ生成
├── db_migrations              ← DBマイグレーション
│
├── oz_framework.services      ← 共通サービス（別リポジトリ参照）
├── oz_framework.extensions    ← 共通拡張メソッド（別リポジトリ参照）
└── oz_framework.libs          ← 共通ライブラリ（別リポジトリ参照）
```

### リポジトリ構成

| リポジトリ | パス | 説明 |
|-----------|------|------|
| `mason_pearson2015` | `d:\git_003\mason_pearson2015` | EC サイト本体 |
| `oz_framework` | `d:\git_003\oz_framework` | 複数サイト共通ライブラリ |

> `oz_framework` は Azure DevOps の別リポジトリ。mason_pearson.sln からは相対パスで参照。

---

## 3. アーキテクチャ

### 3.1 レイヤー構成

```
                ┌──────────────────────────────────────────────┐
Presentation    │  mason_pearson (EC)                          │
                │  mason_pearson.callcenter (管理画面)          │
                │  mason_pearson.job (バッチ)                   │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Helpers/Common  │  mason_pearson.helpers (ヘルパー)             │
                │  mason_pearson.common (共通設定)              │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Data Layer      │  mason_pearson.data                          │
                │    models/     ← LINQ to SQL エンティティ     │
                │    view_models/← メール用・注文用ViewModel    │
                │    attribute/  ← バリデーション属性            │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Framework       │  oz_framework.services (共通サービス)         │
(別リポジトリ)   │  oz_framework.extensions (拡張メソッド)       │
                │  oz_framework.libs (ユーティリティ)            │
                └──────────────────────────────────────────────┘
```

### 3.2 コントローラー継承チェーン

**ECサイト（mason_pearson）：**
```
System.Web.Mvc.Controller
  └── OzController                    (oz_framework.services)
        └── ApplicationController     (mason_pearson.controllers)
              └── 各Controller        (HomeController, ProductController 等)
```

**管理画面（mason_pearson.callcenter）：**
```
System.Web.Mvc.Controller
  └── OzController                    (oz_framework.services)
        └── ApplicationBaseController (mason_pearson.callcenter.controllers)
              └── ApplicationController [ErrorHandler] [RequiresNewAdminAuthentication]
                    └── 各Controller  (OrderController, ProductController 等)
```

---

## 4. データアクセスパターン

### 4.1 LINQ to SQL（DataContext）

- **DataContext**: `MasonPearsonDb`（自動生成、`mason_pearson_dal.cs`）
- **データベース名**: `masonpearson2`
- **接続文字列キー**: `mason_pearson_db`
- **コンテキスト取得**: `DB.context`（HttpContext ごとにインスタンス管理）

```csharp
// DB.context は HttpContext.Items にキャッシュされる
public static MasonPearsonDb context
{
    get
    {
        if (HttpContext.Current.Items["mason_pearson_db_context"].is_empty())
            HttpContext.Current.Items["mason_pearson_db_context"] = new MasonPearsonDb();
        return (MasonPearsonDb)HttpContext.Current.Items["mason_pearson_db_context"];
    }
}
```

### 4.2 モデルの命名規則（重要）

| 種別 | クラス名 | 役割 | 例 |
|------|---------|------|-----|
| エンティティ | **単数形** | LINQ to SQL テーブルマッピング | `Product`, `Order`, `User` |
| 操作クラス | **複数形** | static メソッド集約（CRUD・検索） | `Products`, `Orders`, `Users` |

```csharp
// 複数形クラス = static メソッド群（リポジトリ相当）
Products.GetActive();           // List<Product> を返す
Products.GetByUrl("brush-name"); // Product を返す
Users.Get(user_id);             // User を返す
Carts.CreateNewCart(user_id);   // Cart を返す

// 単数形クラス = エンティティ（インスタンスメソッド）
product.Save(DB.context);
order.Update(DB.context);
cart.Login(user_id);
```

### 4.3 共通接続文字列

| キー | 用途 |
|------|------|
| `mason_pearson_db` | メインDB（masonpearson2） |
| `shared_db` | 共有DB（他サイト共通） |
| `callcenter_db` | コールセンター認証用DB |

### 4.4 BaseModel（oz_framework）

`oz_framework.services.BaseModel` が全エンティティの基底クラス：
- `Save(DataContext)` — 新規登録（InsertOnSubmit + SubmitChanges）
- `Update(DataContext)` — 更新（SubmitChanges）
- `Delete(DataContext)` — 削除
- `CopyDataFrom(FormCollection)` — フォームからプロパティへバインド
- `IsValid(Controller)` — バリデーション実行

---

## 5. ECサイト（mason_pearson）

### 5.1 コントローラー一覧

| コントローラー | 機能 | 認証 |
|---------------|------|------|
| `HomeController` | トップ、会社案内、FAQ、店舗、ランキング等 | 不要 |
| `ProductController` | 商品一覧・詳細、レビュー | 不要 |
| `CartController` | カート表示・商品追加・削除 | 不要 |
| `OrderController` | 注文フロー（配送先→オプション→支払→確認→完了） | **要認証** |
| `UserController` | ログイン・会員登録・マイページ・2段階認証 | 一部要認証 |
| `AddressController` | 住所管理 | 要認証 |
| `ReviewController` | レビュー一覧 | 不要 |
| `EnquiryController` | お問い合わせ | 不要 |
| `MediaController` | メディア・雑誌掲載 | 不要 |
| `SpecialController` | 特集ページ | 不要 |
| `ApiController` | API（チョコムトークン、CloudFlare等） | 不要 |
| `EfuriController` | e振込（コンビニ決済通知受信） | 不要 |
| `ErrorController` | エラーページ | 不要 |
| `MypageController` | マイページ | 要認証 |

### 5.2 ルーティング

`App_Start/RouteConfig.cs` で全ルートを明示的に定義（属性ルーティング不使用）。

```csharp
// 代表的なルート例
routes.MapRoute("product", "products", new { controller = "product", action = "index" });
routes.MapRoute("product_detail", "products/{product_name}", new { controller = "product", action = "detail" });
routes.MapRoute("cart", "cart", new { controller = "cart", action = "index" });
routes.MapRoute("order_shipping_address", "order/shipping-address", new { controller = "order", action = "shipping_address" });
```

### 5.3 ビュー構成

```
views/
├── home/        ← トップ・会社案内・FAQ・店舗等
├── product/     ← 商品一覧・詳細
├── cart/        ← カート
├── order/       ← 注文フロー
├── user/        ← ログイン・会員登録
├── address/     ← 住所管理
├── review/      ← レビュー
├── enquiry/     ← お問い合わせ
├── media/       ← メディア掲載
├── special/     ← 特集ページ
├── mypage/      ← マイページ
├── error/       ← エラー表示
├── banner/      ← バナー
└── shared/      ← レイアウト・パーシャル
```

### 5.4 認証方式

- **ECサイトユーザー認証**: セッションベース（`Session["USER_ID"]`）
- 認証フィルター: `[RequiresAuthentication]`（oz_framework 提供）
- 2要素認証: `TwoFactorAuth` テーブルで管理

### 5.5 セッション管理

| セッションキー | 用途 |
|--------------|------|
| `CART_ID` | カートID |
| `USER_ID` | ログインユーザーID |
| `KEEP_PC` | PC版表示強制 |
| `fbp` / `fbc` | Facebook ピクセル用 |
| `novelty` | ノベルティ追加用 |

---

## 6. 管理画面（mason_pearson.callcenter）

### 6.1 コントローラー一覧

| コントローラー | 機能 |
|---------------|------|
| `OrderController` | 注文検索・詳細・配送情報更新・メモ管理 |
| `ProductController` | 商品管理（Web掲載/卸向け） |
| `UserController` | ユーザー管理 |
| `BannerController` | バナー管理 |
| `CampaignController` | キャンペーン管理 |
| `ContentController` | コンテンツ管理 |
| `MailController` | メール送信 |
| `ReviewController` | レビュー管理 |
| `ReportController` | レポート・売上集計 |
| `CreditController` | クレジットカード処理 |
| `HolidayController` | 休日管理 |
| `CacheController` | キャッシュ管理 |
| `SystemSettingController` | システム設定 |
| `AffiliateController` | アフィリエイト管理 |
| `PcaProductController` | PCA商品管理 |
| `ApiController` | API |

### 6.2 認証方式

- **管理者認証**: Cookie ベース（`RequiresNewAdminAuthentication`）
- 接続先DB: `callcenter_db`
- RELEASE ビルド時のみ認証強制

### 6.3 管理者情報取得

```csharp
LoggedInUserName  // Cookie["user_name"] から取得
LoggedInNaisen    // Cookie["naisen"] から取得（内線番号）
```

---

## 7. データ層（mason_pearson.data）

### 7.1 主要モデル一覧

| モデル | テーブル | 概要 |
|--------|---------|------|
| `Product` / `Products` | products | 商品マスタ |
| `ProductUnit` / `ProductUnits` | product_units | 商品バリエーション（色・サイズ） |
| `Order` / `Orders` | orders | 注文 |
| `LineItem` / `LineItems` | line_items | 注文明細 |
| `User` / `Users` | users | ユーザー |
| `Cart` / `Carts` | carts | カート |
| `CartItem` / `CartItems` | cart_items | カート内商品 |
| `Address` / `Addresses` | addresses | 住所 |
| `Campaign` / `Campaigns` | campaigns | キャンペーン |
| `Review` / `Reviews` | reviews | レビュー |
| `Banner` / `Banners` | banners | バナー |
| `Wrapping` / `Wrappings` | wrappings | ラッピング |
| `OptionItem` / `OptionItems` | option_items | オプション商品 |
| `Color` / `Colors` | colors | カラーマスタ |
| `Shipping` | — | 配送（ヘルパー的） |
| `SystemSetting` / `SystemSettings` | system_settings | システム設定 |
| `MailTemplate` / `MailTemplates` | mail_templates | メールテンプレート |
| `Holiday` / `Holidays` | holidays | 休日マスタ |
| `Coupon` / `Coupons` | coupons | クーポン |
| `PointHistory` | point_histories | ポイント履歴 |

### 7.2 注文ステータス

```csharp
Orders.StatusType {
    OutOfStock,              // 在庫切れ
    PaymentNotConfirmed,     // 入金未確認
    PaymentConfirmed,        // 入金確認済
    Shipped,                 // 出荷済
    Cancelled,               // キャンセル
    // ... その他
}
```

### 7.3 キャッシュシステム（Redis）

`RedisCacheSystems` クラスが Redis キャッシュを管理:

```csharp
// キャッシュ名は CacheName enum で管理
RedisCacheSystems.CacheName.ActiveProduct
RedisCacheSystems.CacheName.SystemSetting

// 取得
RedisCacheSystems.Get<T>(CacheName);

// 追加
RedisCacheSystems.Add(CacheName, data);
```

- 接続設定: `cache_host`, `cache_port`, `cache_password`, `cache_number`（Web.config）
- フェイルオーバー: Redis 接続エラー時は1分間キャッシュスキップ

### 7.4 ViewModel の配置

| 場所 | 用途 |
|------|------|
| `mason_pearson.data/view_models/cart/` | カート画面用 |
| `mason_pearson.data/view_models/order/` | 注文フロー・決済画面用 |
| `mason_pearson.data/view_models/mail/` | メール送信用 |
| `mason_pearson/view_models/` | ECサイト画面固有 |
| `mason_pearson.callcenter/view_models/` | 管理画面固有 |

### 7.5 バリデーション

`mason_pearson.data/attribute/` にカスタムバリデーション属性:

| 属性 | 用途 |
|------|------|
| `InputRequired` | 必須入力 |
| `InputStringLength` | 文字列長 |
| `InputStringByteLength` | バイト長 |
| `InputRange` | 範囲 |
| `InputRegularExpression` | 正規表現 |

MetadataType パターンで LINQ to SQL エンティティにバリデーションを追加:
```csharp
[MetadataTypeAttribute(typeof(Product.Metadata))]
public partial class Product
{
    internal class Metadata
    {
        [InputRequired] public string name_ja;
    }
}
```

---

## 8. ヘルパー層（mason_pearson.helpers）

| ファイル | 概要 |
|---------|------|
| `order_helper.cs` | 支払方法名称取得、SelectListItem 生成 |
| `product_helper.cs` | 商品関連ヘルパー |
| `user_helper.cs` | ユーザー関連ヘルパー |
| `mail_helper.cs` | メールテンプレートSelectListItem 生成 |
| `campaign_helper.cs` | キャンペーン関連 |
| `content_helper.cs` | コンテンツ関連 |
| `credit_card_helper.cs` | クレジットカード関連 |
| `credit_payment_helper.cs` | クレジット決済関連 |
| `html_helper.cs` | HTML ヘルパー |
| `java_script_helper.cs` | JavaScript ヘルパー |
| `review_helper.cs` | レビュー関連 |
| `route_helper.cs` | ルーティング関連 |

---

## 9. oz_framework（共通ライブラリ）

### 9.1 oz_framework.extensions

C# の標準型に対する拡張メソッド群（**全プロジェクトで多用**）:

| ファイル | 対象型 | 主要メソッド |
|---------|-------|-------------|
| `string.cs` | `string` | `not_empty()`, `is_empty()`, `to_i()`, `to_s()`, `format()`, `to_ssl_url()` |
| `object.cs` | `object` | `not_empty()`, `is_empty()`, `to_s()`, `to_i()`, `set_property()`, `get_property()` |
| `numeric.cs` | `int` 等 | `to_s()`, `to_i()` |
| `collection.cs` | `IEnumerable` | `join()` |
| `controller.cs` | `Controller` | `ReturnView()`, `IsSmartPhone()`, `IsShowSpView()`, `GetAccessIpAddress()` |
| `form_collection.cs` | `FormCollection` | フォームデータ操作 |
| `json.cs` | 各型 | `to_json()` |
| `humanize.cs` | — | 日本語フォーマット |
| `linq.cs` | LINQ | 追加LINQ操作 |
| `html_helper.cs` | `HtmlHelper` | HTML生成ヘルパー |

> **重要**: `not_empty()`, `is_empty()`, `to_i()`, `to_s()`, `format()` はコード全体で極めて頻繁に使用される。null チェックの代わりに `not_empty()` / `is_empty()` を使用するのがプロジェクトの慣例。

### 9.2 oz_framework.services

| ディレクトリ | 概要 |
|-------------|------|
| `controller/` | `OzController` — 全コントローラーの基底クラス |
| `data_access_layer/` | `BaseModel`, `DataAccessLayer` — ORM基盤 |
| `payment/` | 決済（チョコムクレジット/コンビニ、GMO、PayPay、LinePay等） |
| `security/` | セキュリティ（ハッシュ、暗号化、IP制限、アクセスチェック） |
| `action_filter/` | 認証・認可・SSL・圧縮・reCAPTCHA 等のフィルター |
| `caching/` | キャッシュマネージャー |
| `mailer/` | メール送信（SMTP、Cuenote） |
| `logging/` | ロギング（NLog、DB保存） |
| `search/` | 全文検索（Lucene.Net） |
| `common_db/` | 共有DB操作 |
| `shipment/` | 配送関連 |
| `tracking/` | 追跡番号関連 |
| `blob/` | Azure Blob Storage |
| `csv/` | CSV 出力 |
| `google/` | Google API 連携 |
| `LINE/` | LINE 連携 |
| `amazon/` | Amazon 連携 |
| `yahoo/` | Yahoo! 連携 |
| `rakuten-pay/` | 楽天ペイ |

### 9.3 認証フィルター

| フィルター | 用途 |
|-----------|------|
| `RequiresAuthentication` | ECサイトユーザー認証 |
| `RequiresAdminAuthentication` | 管理者認証（旧） |
| `RequiresNewAdminAuthentication` | 管理者認証（新） |
| `RequiresSharedAuthentication` | 共有認証 |
| `RequiresSystemAdminAuthentication` | システム管理者認証 |
| `InternalIpsOnly` | 内部IP制限 |
| `ValidateReCaptcha` / `ValidateReCaptchaV3` | reCAPTCHA検証 |
| `CompressFilter` | GZIP圧縮 |
| `RequiresSSL` | SSL強制 |
| `ErrorHandler` | エラーハンドリング |

---

## 10. バッチジョブ（mason_pearson.job）

| ジョブファイル | 用途 |
|--------------|------|
| `scheduler.cs` | ジョブスケジューラー |
| `mason_job.cs` | メインジョブ |
| `tracking_auto_import.cs` | 追跡番号自動取り込み |
| `tracking_check_mail.cs` | 追跡確認メール送信 |
| `point_erase.cs` | ポイント失効処理 |
| `user_survey_mail.cs` | アンケートメール送信 |
| `data_maintenance.cs` | データメンテナンス |
| `recount_monthly_sold_count.cs` | 月間販売数再集計 |
| `price_change.cs` | 価格変更 |
| `update_credit_card_info.cs` | クレジットカード情報更新 |
| `pinger.cs` | ヘルスチェック |

---

## 11. 決済システム

### 11.1 対応決済方法

| 決済方法 | 実装場所 |
|---------|---------|
| クレジットカード（VISA/Master/JCB/AMEX/Diners） | チョコム（`chocom_credit_card.cs`） |
| コンビニ決済 | チョコム（`chocom_convini.cs`） |
| 代金引換 | `cash_on_delivery.cs` |
| 銀行振込 | `bank.cs` |
| 後払い（GMO） | `gmo_atobarai.cs` |

### 11.2 3Dセキュア

チョコム経由の3Dセキュア認証に対応（`chocom_3D_secure_url`）。

---

## 12. 外部連携

| サービス | 用途 |
|---------|------|
| Redis | キャッシュ |
| CloudFlare | CDN・キャッシュ管理 |
| Cuenote | メールマガジン配信 |
| Google reCAPTCHA / Turnstile | ボット対策 |
| Google Analytics 4 | アクセス解析 |
| PCA | 会計ソフト連携 |
| A8.net | アフィリエイト |
| Facebook Pixel | 広告計測 |

---

## 13. 改修時の注意事項

### 13.1 コーディング規約

- **命名規則**: スネークケース（`snake_case`）。クラス名のみパスカルケース
- **ファイル名**: スネークケース（`product_controller.cs`）
- **名前空間**: `mason_pearson.controllers`, `mason_pearson.data.models`
- **null チェック**: `obj.not_empty()` / `obj.is_empty()` を使用（`!= null` は使わない）
- **文字列フォーマット**: `"text {0}".format(value)` を使用（`$""` interpolation は使わない）
- **型変換**: `obj.to_i()`, `obj.to_s()` を使用

### 13.2 DB 操作パターン

```csharp
// 取得
var order = Orders.Get(order_id);

// 新規作成
var entity = new Entity();
entity.property = value;
entity.Save(DB.context);

// 更新
entity.property = new_value;
entity.Update(DB.context);
// または
DB.context.SubmitChanges();

// 削除
entity.Delete(DB.context);
```

### 13.3 ビュー表示パターン

```csharp
// 通常のビュー返却（PC / SP 自動切替）
return ReturnView(viewModel);

// Ajax リクエスト時のパーシャルビュー
if (Request.IsAjaxRequest())
    return PartialView("_partial_name", viewModel);

// リダイレクト（ルート名指定）
return RedirectToRoute("route_name");

// JSON レスポンス（管理画面）
return JsonResponse.Success(new { html = "..." });
return JsonResponse.NotSuccess(new { message = "エラー" });
```

### 13.4 キャッシュ操作パターン

```csharp
// キャッシュ取得
var data = RedisCacheSystems.Get<T>(RedisCacheSystems.CacheName.XXX);

// キャッシュミス時
if (data == null)
{
    data = // DB から取得
    RedisCacheSystems.Add(RedisCacheSystems.CacheName.XXX, data);
}

// キャッシュ破棄（データ更新後）
RedisCacheSystems.Remove(RedisCacheSystems.CacheName.XXX);
```

### 13.5 アクションフィルター

```csharp
// エラーハンドリング（全コントローラーに付与）
[ErrorHandler]

// ユーザー認証（ECサイト）
[RequiresAuthentication(Order = 1, https = true)]

// 管理者認証（管理画面、RELEASE時のみ）
#if RELEASE
[RequiresNewAdminAuthentication(ConnectionStringName = "callcenter_db", Site = "MP")]
#endif

// reCAPTCHA（フォーム送信時）
[ValidateReCaptcha]
```

### 13.6 PC / スマートフォン切替

`OzController` の `ReturnView()` メソッドが端末判定を行い、自動的に PC / SP ビューを切り替える。
`IsSmartPhone()` / `IsShowSpView()` で明示的な判定も可能。

---

## 14. ビルド構成

| 構成 | 用途 | 備考 |
|------|------|------|
| `Debug` | ローカル開発 | `configuration = "debug"` |
| `Release` | 本番 | `#if RELEASE` で認証有効化 |
| `Staging` | ステージング | |
| `Test` / `Testing` | テスト | |

### Web.config 変換

- `Web.Debug.config` — ローカル設定
- `Web.Release.config` — 本番設定（接続文字列・APIキー切替）

---

## 15. DBマイグレーション

`db_migrations/migrations/` に日付プレフィックスのマイグレーションファイル:

```
YYYYMMDDHHMMSS_migration_name.cs
```

- 最初のマイグレーション: `20090319125625_initial_schema.cs`（2009年3月）
- 独自マイグレーションフレームワーク（EF Migrations ではない）

---

## 16. ファイル配置リファレンス

### mason_pearson2015

| パス | 内容 |
|------|------|
| `mason_pearson/controllers/` | EC サイトコントローラー |
| `mason_pearson/views/` | EC サイトビュー |
| `mason_pearson/view_models/` | EC サイト固有ViewModel |
| `mason_pearson/App_Start/` | ルーティング・フィルター・バンドル設定 |
| `mason_pearson/action_filter/` | EC サイト固有フィルター |
| `mason_pearson/content/` | CSS・画像 |
| `mason_pearson/scripts/` | JavaScript |
| `mason_pearson.callcenter/controllers/` | 管理画面コントローラー |
| `mason_pearson.callcenter/views/` | 管理画面ビュー |
| `mason_pearson.callcenter/view_models/` | 管理画面固有ViewModel |
| `mason_pearson.data/models/` | LINQ to SQL エンティティ・操作クラス |
| `mason_pearson.data/view_models/` | 共有ViewModel（注文・メール・カート） |
| `mason_pearson.data/attribute/` | カスタムバリデーション属性 |
| `mason_pearson.common/mason_common.cs` | 共通定数・設定 |
| `mason_pearson.helpers/function/` | ヘルパー関数 |
| `mason_pearson.helpers/extensions/` | LINQ拡張 |
| `mason_pearson.job/jobs/` | バッチジョブ |
| `db_migrations/migrations/` | DBマイグレーション |

### oz_framework

| パス | 内容 |
|------|------|
| `extensions/` | 拡張メソッド（string, object, controller 等） |
| `services/controller/` | `OzController` 基底クラス |
| `services/data_access_layer/` | `BaseModel`, `DataAccessLayer` |
| `services/payment/` | 決済（チョコム、GMO、PayPay等） |
| `services/security/` | セキュリティ（ハッシュ、暗号化、IP制限） |
| `services/action_filter/` | 認証・認可フィルター |
| `services/caching/` | キャッシュマネージャー |
| `services/mailer/` | メール送信 |
| `services/logging/` | ロギング |
| `services/search/` | Lucene全文検索 |
| `libs/` | 画像編集、ページネーション等 |