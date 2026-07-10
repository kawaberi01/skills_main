# iGeneric Store プロジェクト — Copilot 共通コンテキスト

## Response Policy

すべてのコミュニケーションとドキュメントは、必ず**日本語**で記述・応答してください。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | iGeneric Store（アイジェネリックストアー）EC サイト・管理画面 |
| ソリューション | `igeneric_store.sln` |
| フレームワーク | ASP.NET MVC 5 (.NET Framework) |
| ORM | LINQ to SQL（`System.Data.Linq`） |
| ビューエンジン | Razor（`.cshtml`） |
| データベース | SQL Server (`igeoz0805db`) |
| セッション管理 | Redis（Microsoft.Web.Redis.RedisSessionStateProvider） |
| キャッシュ | Redis（StackExchange.Redis） |
| 決済 | チョコム（クレジットカード/コンビニ）、NP後払い、代金引換、銀行振込、郵便振替 |
| CI/CD | Azure Pipelines（`azure-pipelines-igeneric-ozshopping-jp.yml`） |
| DBマイグレーション | 独自マイグレーションフレームワーク（`db_migrations`）※igeneric_storeリポジトリ側 |
| ロギング | NLog / ELMAH |
| 監視 | Application Insights |
| 業種特性 | **医薬品EC**（OTC医薬品の薬剤師審査フローあり） |

---

## 2. ソリューション構成（プロジェクト一覧）

```
igeneric_store.sln
├── igeneric_store              ← EC サイト（Web）
├── igeneric_store.callcenter   ← 管理画面（コールセンター）
├── igeneric_store.data         ← データ層（モデル・DAL・ViewModel）
├── igeneric_store.common       ← 共通設定・定数
├── igeneric_store.helpers      ← ヘルパー関数群
├── igeneric_store.dataTests    ← データ層テスト
│
├── oz_framework.services       ← 共通サービス（別リポジトリ参照）
└── oz_framework.extensions     ← 共通拡張メソッド（別リポジトリ参照）
```

### リポジトリ構成

| リポジトリ | パス | 説明 |
|-----------|------|------|
| `igeneric_store2018` | `d:\git_003\igeneric_store2018` | EC サイト本体（2018年版） |
| `igeneric_store` | `d:\git_003\igeneric_store` | 旧版（db_migrations、バッチジョブ等） |
| `oz_framework` | `d:\git_003\oz_framework` | 複数サイト共通ライブラリ |

> `oz_framework` は Azure DevOps の別リポジトリ。igeneric_store.sln からは相対パスで参照。
> `igeneric_store`（旧版）にはバッチジョブ（`igeneric_store.job`）やDBマイグレーション（`db_migrations`）が格納されている。

---

## 3. アーキテクチャ

### 3.1 レイヤー構成

```
                ┌──────────────────────────────────────────────┐
Presentation    │  igeneric_store (EC)                         │
                │  igeneric_store.callcenter (管理画面)         │
                │  igeneric_store.job (バッチ) ※旧版リポジトリ  │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Helpers/Common  │  igeneric_store.helpers (ヘルパー)            │
                │  igeneric_store.common (共通設定)             │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Data Layer      │  igeneric_store.data                         │
                │    Models/     ← LINQ to SQL エンティティ     │
                │    ViewModels/ ← メール用・注文用ViewModel    │
                │    Attributes/ ← バリデーション属性            │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Framework       │  oz_framework.services (共通サービス)         │
(別リポジトリ)   │  oz_framework.extensions (拡張メソッド)       │
                └──────────────────────────────────────────────┘
```

### 3.2 コントローラー継承チェーン

**ECサイト（igeneric_store）：**
```
System.Web.Mvc.Controller
  └── OzController                    (oz_framework.services)
        └── ApplicationController     (igeneric_store.controllers)
              └── 各Controller        (HomeController, ProductController 等)
```

**管理画面（igeneric_store.callcenter）：**
```
System.Web.Mvc.Controller
  └── OzController                                (oz_framework.services)
        └── ApplicationController [ValidateInput(false)] [CompressFilter]
              [RequiresNewAdminAuthentication(ConnectionStringName="callcenter_db", Site="IG2018")]
              └── 各Controller  (OrderController, ProductController 等)
```

---

## 4. データアクセスパターン

### 4.1 LINQ to SQL（DataContext）

- **DataContext**: `iGenericStoreDb`（自動生成、`igeneric_store_dal.cs`）
- **データベース名**: `igeoz0805db`
- **接続文字列キー**: `igeneric_store_db`
- **コンテキスト取得**: `DB.context`（HttpContext ごとにインスタンス管理）

```csharp
// DB.context は HttpContext.Items にキャッシュされる
public static iGenericStoreDb context
{
    get
    {
        if (HttpContext.Current.is_empty())
        {
            if (_db_context.is_empty())
                _db_context = new iGenericStoreDb();
            return _db_context;
        }
        if (HttpContext.Current.Items["igeneric_store_db_context"].is_empty())
            HttpContext.Current.Items["igeneric_store_db_context"] = new iGenericStoreDb();
        return (iGenericStoreDb)HttpContext.Current.Items["igeneric_store_db_context"];
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
Orders.GetOrder(order_id);      // Order を返す
Users.GetActive(user_id);       // User を返す
Carts.Create(user_id);          // Cart を返す
Carts.GetByKeys(key1, key2);    // Cart をキーで取得

// 単数形クラス = エンティティ（インスタンスメソッド）
product.Save(DB.context);
order.Update(DB.context);
```

### 4.3 共通接続文字列

| キー | 用途 |
|------|------|
| `igeneric_store_db` | メインDB（igeoz0805db） |
| `igeneric_store_db_migration` | マイグレーション用（管理者権限） |
| `shared_db` | 共有DB（他サイト共通） |
| `callcenter_db` | コールセンター認証用DB（calloz0805db） |

### 4.4 BaseModel（oz_framework）

`oz_framework.services.BaseModel` が全エンティティの基底クラス：
- `Save(DataContext)` — 新規登録（InsertOnSubmit + SubmitChanges）
- `Update(DataContext)` — 更新（SubmitChanges）
- `Delete(DataContext)` — 削除
- `CopyDataFrom(FormCollection)` — フォームからプロパティへバインド
- `IsValid(Controller)` — バリデーション実行

---

## 5. ECサイト（igeneric_store）

### 5.1 コントローラー一覧

| コントローラー | 機能 | 認証 |
|---------------|------|------|
| `HomeController` | トップページ、サイトマップ | 不要 |
| `ProductController` | 商品検索・詳細、カテゴリ、ランキング、新着 | 不要 |
| `CartController` | カート表示・商品追加・更新・削除 | 不要 |
| `OrderController` | 注文フロー（配送先→支払→確認→完了） | **要認証** |
| `PeriodicalOrderController` | 定期購入注文フロー | **要認証** |
| `UserController` | ログイン・会員登録・パスワードリセット・2要素認証 | 一部要認証 |
| `MypageController` | マイページ（住所・メール・パスワード変更・2FA管理） | **要認証** |
| `FavoriteController` | お気に入り追加・削除 | アクション単位（クッキー認証） |
| `WatchedProductController` | 閲覧履歴管理 | 不要 |
| `ContentsController` | 静的コンテンツ（FAQ・利用規約・プライバシー等） | 不要 |
| `EnquiryController` | お問い合わせ | 不要 |
| `ReviewController` | レビュー一覧 | 不要 |
| `CampaignController` | キャンペーン | 不要 |
| `SpecialController` | 特集ページ | 不要 |
| `RecommendController` | おすすめ商品 | 不要 |
| `ApiController` | API（チョコムトークン、CloudFlare等） | 不要 |
| `ErrorController` | エラーページ（404/500/メンテナンス） | 不要 |
| `TestController` | テスト用 | 不要 |

### 5.2 ルーティング

`App_Start/RouteConfig.cs` で全ルートを明示的に定義（属性ルーティング不使用）。

```csharp
// 代表的なルート例
routes.MapRoute("index", "", new { controller = "Home", action = "Index" });
routes.MapRoute("product_detail", "product/{product_id}", new { controller = "Product", action = "detail" });
routes.MapRoute("product_search", "search", new { controller = "Product", action = "Search" });
routes.MapRoute("product_big_category", "category/{big_category_id}", new { controller = "Product", action = "... " });
routes.MapRoute("product_ranking", "ranking", new { controller = "Product", action = "..." });
routes.MapRoute("cart", "cart", new { controller = "Cart", action = "Index" });
routes.MapRoute("cart_add", "cart/add", new { controller = "Cart", action = "Add" });
routes.MapRoute("login", "login/{redirect_to}", new { controller = "User", action = "Login" });
routes.MapRoute("user_register", "user/register", new { controller = "User", action = "Register" });
routes.MapRoute("mypage_index", "mypage", new { controller = "Mypage", action = "Index" });
routes.MapRoute("contents_faq", "faq", new { controller = "Contents", action = "Faq" });
routes.MapRoute("contents_terms", "terms", new { controller = "Contents", action = "Terms" });
routes.MapRoute("contents_privacy", "privacy", new { controller = "Contents", action = "Privacy" });
routes.MapRoute("enquiry", "enquiry", new { controller = "Enquiry", action = "Index" });
```

### 5.3 ビュー構成

```
Views/
├── Home/            ← トップページ
├── Product/         ← 商品検索・詳細
├── Cart/            ← カート
├── Order/           ← 注文フロー
├── PeriodicalOrder/ ← 定期購入
├── User/            ← ログイン・会員登録
├── Mypage/          ← マイページ
├── Contents/        ← 静的コンテンツ
├── Enquiry/         ← お問い合わせ
├── Review/          ← レビュー
├── Campaign/        ← キャンペーン
├── Special/         ← 特集ページ
├── WatchedProduct/  ← 閲覧履歴
├── Banner/          ← バナー
├── Error/           ← エラー表示
└── Shared/          ← レイアウト・パーシャル
```

### 5.4 認証方式

**セッション ベース認証（メイン）:**
- セッションキー: `session["user_id"]`
- 認証フィルター: `[RequiresAuthentication]`（oz_framework 提供）
- 2要素認証: TOTP（OtpSharp + Base32）

**クッキー ベース認証（自動ログイン）:**
- キー1: `igeneric_k1`（暗号化済み）
- キー2: `igeneric_k2`（暗号化済み）
- カスタムフィルター: `[RequiresCookieAuthentication]`

### 5.5 セッションキー

| セッションキー | 用途 |
|--------------|------|
| `"user_id"` | ログインユーザーID |
| `"cart_view_model"` | カート情報 |
| `"HEADER_INFO"` | ヘッダー表示情報（カート数等） |
| `"PERIODICAL_CART_ID"` | 定期購入カートID |
| `"OTC_REQUEST_CONFIRM"` | OTC商品認証完了フラグ |
| `"url_redirect"` | ログイン後のリダイレクト先 |
| `"SESSION_NEW_ORDER"` | 注文処理中データ |
| `"SESSION_NEW_ORDER_USER"` | 注文処理中ユーザー |
| `"TWO_FACTOR_LOGIN_ENTITY"` | 2要素認証セッション |
| `"FAVORITE_PRODUCT_UNIT_ID_SESSION_KEY"` | お気に入り商品セッション |
| `"SESSION_NAME_GA4_VIEW_MODEL"` | GA4トラッキング |

### 5.6 クッキーキー

| クッキーキー | 暗号化 | 用途 |
|------------|------|------|
| `"cz96a35Z"` | ✓ | カートキー1 |
| `"B3oQ5kla"` | ✓ | カートキー2 |
| `"igeneric_login"` | ✓ | ログイン状態フラグ |
| `"v8T4Qez"` | ✓ | ログインメールアドレス保存 |
| `"igeneric_index_approve"` | ✓ | トップページ規約確認フラグ |
| `"igeneric_k1"` | ✓ | ユーザー認証キー1（自動ログイン） |
| `"igeneric_k2"` | ✓ | ユーザー認証キー2（自動ログイン） |
| `"watched_product_id"` | — | 閲覧履歴商品ID（最大10個） |

### 5.7 セッション状態（Redis）

```xml
<sessionState mode="Custom" customProvider="MySessionStateStore" timeout="120" cookieSameSite="None">
  <providers>
    <add name="MySessionStateStore"
         type="Microsoft.Web.Redis.RedisSessionStateProvider"
         host="localhost" port="6379" databaseId="12"
         ssl="false" applicationName="igenericstore" />
  </providers>
</sessionState>
```

---

## 6. 管理画面（igeneric_store.callcenter）

### 6.1 コントローラー一覧

| コントローラー | 機能 |
|---------------|------|
| `OrderController` | 注文検索・詳細・ステータス更新 |
| `OrderArrangementController` | 注文一括お手配処理 |
| `OrderTelController` | 電話注文 |
| `ProductController` | 商品管理 |
| `UserController` | ユーザー管理 |
| `AddressController` | 住所管理 |
| `BannerController` | バナー管理 |
| `CampaignController` | キャンペーン管理 |
| `CategoryController` | カテゴリ管理 |
| `MailController` | メール送信 |
| `ReviewController` | レビュー管理 |
| `ReportController` | レポート・売上集計 |
| `ShipmentController` | 出荷依頼管理 |
| `TrackingController` | 配送追跡管理 |
| `HolidayController` | 休日管理 |
| `RedisCacheController` | キャッシュ管理 |
| `SystemController` | システム設定 |
| `InformationController` | お知らせ管理 |
| `FaqController` | FAQ管理 |
| `SpecialController` | 特集ページ管理 |
| `CuenoteController` | メールマガジン管理（Cuenote） |
| `ChocomLogController` | チョコムログ管理 |
| `ClickConversionController` | クリックコンバージョン管理 |
| `RateController` | レート管理 |
| `PeriodicalOrderController` | 定期購入管理 |
| `OtcOrderRequestController` | OTC注文リクエスト管理 |
| `FtlStockStatusUpdateController` | FTL在庫ステータス更新 |
| `TaskListController` | タスクリスト管理 |
| `ApiController` | API |

### 6.2 認証方式

- **管理者認証**: Cookie ベース（`RequiresNewAdminAuthentication`）
- 接続先DB: `callcenter_db`（calloz0805db）
- サイト識別子: `Site = "IG2018"`

```csharp
[ValidateInput(false)]
[CompressFilter]
[RequiresNewAdminAuthenticationAttribute(ConnectionStringName = "callcenter_db", Site = "IG2018")]
public class ApplicationController : OzController
```

### 6.3 管理者情報取得

```csharp
logged_in_staff       // Cookie["user_name"] から取得
logged_in_staff_id    // Cookie["USER_ID"].to_i() から取得
LoggedInNaisen        // Cookie["naisen"] から取得（内線番号）
// 薬剤師判定: Cookie["PHARMACIST"] の有無（DEBUG時は常にTrue）
```

---

## 7. データ層（igeneric_store.data）

### 7.1 主要モデル一覧

| モデル | テーブル | 概要 |
|--------|---------|------|
| `Product` / `Products` | products | 商品マスタ |
| `ProductUnit` / `ProductUnits` | product_units | 商品バリエーション（色・サイズ・容量） |
| `ProductUnitStock` | product_unit_stocks | 在庫管理 |
| `ProductCategory` | product_categories | 商品カテゴリ紐付け |
| `ProductSubImage` | product_sub_images | 商品サブ画像 |
| `ProductIngredientReport` | product_ingredient_reports | 商品成分表 |
| `ProductSearchKeyword` | product_search_keywords | 検索キーワード |
| `ProductSearchGroup` | product_search_groups | 検索グループ |
| `Order` / `Orders` | orders | 注文 |
| `OrderLineItem` / `OrderLineItems` | order_line_items | 注文明細 |
| `OrderLineItemTracking` | order_line_item_trackings | 追跡番号 |
| `OrderMemo` | order_memos | 注文メモ |
| `OrderOtherCharge` | order_other_charges | 注文追加料金 |
| `OrderPca` | order_pcas | PCA連携 |
| `OrderCampaign` | order_campaigns | 注文キャンペーン |
| `User` / `Users` | users | ユーザー |
| `UserLoginHistory` | user_login_histories | ログイン履歴 |
| `UserNote` | user_notes | ユーザーメモ |
| `UserAuthKeys` | user_auth_keys | 自動ログインキー |
| `UserWatchedProduct` | user_watched_products | 閲覧履歴 |
| `Cart` / `Carts` | carts | カート |
| `CartItem` / `CartItems` | cart_items | カート内商品 |
| `Address` / `Addresses` | addresses | 住所 |
| `Campaign` / `Campaigns` | campaigns | キャンペーン |
| `CampaignProduct` | campaign_products | キャンペーン商品 |
| `Review` / `Reviews` | reviews | レビュー |
| `Banner` / `Banners` | banners | バナー |
| `BannerPosition` | banner_positions | バナー表示位置 |
| `BigCategory` / `MdlCategory` / `SmlCategory` | categories | カテゴリ（大・中・小） |
| `SpecialContent` | special_contents | 特集コンテンツ |
| `Information` | informations | お知らせ |
| `Faq` / `FaqCategory` | faqs, faq_categories | FAQ |
| `Favorite` | favorites | お気に入り |
| `Recommend` | recommends | おすすめ商品 |
| `Holiday` / `Holidays` | holidays | 休日マスタ |
| `MailTemplate` / `MailTemplates` | mail_templates | メールテンプレート |
| `Coupon` / `FirstTimeCoupon` | coupons, first_time_coupons | クーポン |
| `PointHistory` | point_histories | ポイント履歴 |
| `PeriodicalOrder` / `PeriodicalOrders` | periodical_orders | 定期購入 |
| `PeriodicalOrderLineItem` | periodical_order_line_items | 定期購入明細 |
| `PeriodicalOrderHistory` | periodical_order_histories | 定期購入履歴 |
| `ShipmentRequest` | shipment_requests | 出荷依頼 |
| `ShippingCompany` | shipping_companies | 配送会社 |
| `OtcOrderRequest` | otc_order_requests | OTC注文リクエスト |
| `OtcOrderRequestConfirmation` | otc_order_request_confirmations | OTC確認結果 |
| `ProductOtcQuestion` | product_otc_questions | OTC薬剤師質問 |
| `ProductOtcAnswer` | product_otc_answers | OTC回答記録 |
| `ProductOtcCaution` | product_otc_cautions | OTC注意事項 |
| `Pharmacist` | pharmacists | 薬剤師情報 |
| `PasswordReset` | password_resets | パスワードリセット |
| `TwoFactorAuth` | two_factor_auths | 2要素認証 |
| `SystemLog` | system_logs | システムログ |
| `ChocomLog` | chocom_logs | チョコム決済ログ |
| `ChocomConviniReceptionLog` | chocom_convini_reception_logs | コンビニ受付ログ |
| `ClickConversion` | click_conversions | クリックコンバージョン |
| `Country` | countries | 国マスタ |
| `Zip` | zips | 郵便番号マスタ |
| `Supplier` | suppliers | 仕入先 |
| `Survey` | surveys | アンケート |
| `CreditCardHistory` | credit_card_histories | クレジットカード履歴 |

### 7.2 注文ステータス

```csharp
Orders.StatusType {
    PaymentNotConfirmed = 1,   // 注文完了（未入金）
    PaymentConfirmed = 2,      // 入金済み
    Arranged = 3,              // お手配済み
    PartShipped = 4,           // 一部発送完了
    Shipped = 5,               // 発送完了
    Cancel = 9,                // キャンセル
}
```

### 7.3 注文種別

```csharp
Orders.OrderType {
    Web = 1,                   // WEB注文
    Tel = 2,                   // 電話注文
    Periodical = 3,            // 定期購入
    EmsShipping = 4,           // EMS送料
    Mobile = 5,                // 携帯サイト注文
    SmartPhone = 7,            // スマートフォン注文
    SaveSubscriptionOnly = 102 // クレジットカードキー保存のみ
}
```

### 7.4 支払方法

| 支払方法 | 説明 |
|---------|------|
| CreditCard | クレジットカード（チョコム） |
| ChocomConvini | コンビニ決済（チョコム） |
| CashOnDelivery | 代金引換 |
| PelicanCashOnDelivery | ペリカン代金引換 |
| Postal | 郵便振替 |
| Bank | 銀行振込 |
| SevenEleven | セブン-イレブン |
| LawsonOrSeicoMart | ローソン・セイコーマート |
| FamilyMart | ファミリーマート |
| CircleKAndOthers | サークルK・その他 |
| Lawson | ローソン |
| NetProtectionsSpot | 後払い.com（NP決済） |

### 7.5 商品種別

```csharp
Products.ProductType {
    MedicalSupplies = 0,     // 海外医薬品
    NotMedicalSupplies = 1,  // 一般商品
    ContactLenses = 2,       // コンタクトレンズ
    Otc = 3,                 // 国内医薬品（OTC）
}
```

### 7.6 カートアイテム種別

```csharp
CartItems.Type {
    Usual,           // 通常購入
    SpecialOffer,    // 特別購入
    PeriodicalOrder, // 定期購入
}
```

### 7.7 追加料金種別

```csharp
OtherCharges.Type {
    Point,              // ポイント利用（割引）
    CollectFee,         // 代金引換手数料
    AddShipping,        // 追加送料
    EmsShipping,        // EMS（国際速配）送料
    NewProductDiscount, // 新着商品割引
    NpFee,              // NP決済手数料
}
```

### 7.8 出荷依頼ステータス

```csharp
ShipmentRequests.Status {
    Requested,  // 出荷依頼済
    Shipped,    // 出荷済
    Canceled,   // キャンセル済
}
```

### 7.9 サイト種別

```csharp
Common.SiteType {
    Web = 1,           // PCサイト
    Mobile = 5,        // モバイルサイト
    SmartPhone = 7,    // スマートフォンサイト
    Callcenter = 99,   // 電話注文
}
```

### 7.10 キャッシュシステム（Redis）

`RedisCacheSystems` クラスが Redis キャッシュを管理:

```csharp
RedisCacheSystems.CacheName {
    IndexViewModel,                 // トップページ
    SearchByNewProducts,            // 新着商品検索
    SearchByCategory,               // カテゴリ検索
    SearchByNewReviews,             // 新着レビュー
    BigCategories,                  // 大カテゴリ
    MdlCategories,                  // 中カテゴリ
    SmlCategories,                  // 小カテゴリ
    Reviews,                        // レビュー
    Recommends,                     // おすすめ商品
    Recommend,                      // おすすめ商品（単数）
    HtmlPcIndexRecommend,           // PCトップおすすめHTML
    PurchasedSameTimeProducts,      // 同時購入商品
    ProductIngredientReports,       // 商品成分表
    SimilarCategories,              // 類似カテゴリ
    SimilarProducts,                // 類似商品
    HtmlPcLeftBigCategory,          // 左カラム大カテゴリHTML
    Banner,                         // バナー
    BannerPosition,                 // バナー表示位置
    MailTemplate,                   // メールテンプレート
    ProductSubImage,                // 商品サブ画像
    FaqIndexResult,                 // FAQページデータ
    ReviewsTemp,                    // レビュー一時
    SpecialContentPreview,          // 特集ページプレビュー
    SearchReasonViewModel,          // お薬通販ページデータ
}
```

```csharp
// キャッシュ操作パターン
var data = RedisCacheSystems.Get<T>(RedisCacheSystems.CacheName.XXX);
RedisCacheSystems.Add(RedisCacheSystems.CacheName.XXX, data, 3600);
RedisCacheSystems.Remove(RedisCacheSystems.CacheName.XXX);
```

### 7.11 ViewModel の配置

| 場所 | 用途 |
|------|------|
| `igeneric_store.data/ViewModels/Cart/` | カート画面用 |
| `igeneric_store.data/ViewModels/Order/` | 注文フロー・決済画面用 |
| `igeneric_store.data/ViewModels/Mails/` | メール送信用（40+件） |
| `igeneric_store.data/ViewModels/Pca/` | PCA連携用 |
| `igeneric_store.data/ViewModels/Special/` | 特集ページ用 |
| `igeneric_store/ViewModels/` | ECサイト画面固有 |
| `igeneric_store.callcenter/ViewModels/` | 管理画面固有 |

### 7.12 バリデーション

`igeneric_store.data/Attributes/` にカスタムバリデーション属性:

| 属性 | 用途 |
|------|------|
| `InputRequired` | 必須入力（「{0}を入力してください」） |
| `SelectRequired` | 選択必須（「{0}を選択してください」） |
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
        [InputRequired] public string name;
    }
}
```

---

## 8. ヘルパー層（igeneric_store.helpers）

### 8.1 Functions

| ファイル | 概要 |
|---------|------|
| `OrderHelper.cs` | 支払方法名称取得、SelectListItem 生成 |
| `ProductHelper.cs` | 商品関連ヘルパー |
| `CategoryHelper.cs` | カテゴリ関連ヘルパー |
| `CreditPaymentHelper.cs` | クレジット決済関連 |
| `HtmlHelper.cs` | HTML ヘルパー |
| `JavaScriptHelper.cs` | JavaScript ヘルパー |
| `CallcenterHelper.cs` | 管理画面共通ヘルパー |
| `PagingHelper.cs` | ページネーション |

### 8.2 Extensions

| ファイル | 概要 |
|---------|------|
| `IQueryableExtensions.cs` | LINQ クエリ拡張 |

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
| `payment/` | 決済（チョコムクレジット/コンビニ、NP後払い等） |
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

### 9.3 認証フィルター

| フィルター | 用途 |
|-----------|------|
| `RequiresAuthentication` | ECサイトユーザー認証 |
| `RequiresCookieAuthentication` | ECサイトクッキー認証（igeneric_store 拡張） |
| `RequiresNewAdminAuthentication` | 管理者認証（新） |
| `ValidateReCaptcha` / `ValidateReCaptchaV3` | reCAPTCHA検証 |
| `CompressFilter` | GZIP圧縮 |
| `RequiresSSL` | SSL強制 |
| `ErrorHandler` | エラーハンドリング |
| `BeforeFilter` | アクション前処理（初期化等） |

---

## 10. 業種固有：OTC医薬品フロー

本プロジェクトは**医薬品ECサイト**であり、OTC（国内医薬品）の購入には薬剤師審査が必要です。

### 10.1 OTC購入フロー

```
ユーザーがOTC商品をカートに追加
    ↓
OtcOrderRequest 生成（承認待ち状態）
    ↓
薬剤師が管理画面で質問事項を確認（ProductOtcQuestion / ProductOtcAnswer）
    ↓
確認結果を記録（OtcOrderRequestConfirmation: OK / Caution）
    ↓
薬剤師承認 → 承認メール送信（有効期限14日）
    ↓
ユーザーが承認期限内に注文完了
```

### 10.2 関連モデル

| モデル | 用途 |
|--------|------|
| `OtcOrderRequest` | OTC注文リクエスト（承認管理） |
| `OtcOrderRequestConfirmation` | 確認結果（OK / Caution） |
| `ProductOtcQuestion` | 薬剤師質問項目 |
| `ProductOtcAnswer` | 回答記録 |
| `ProductOtcCaution` | 注意事項 |
| `Pharmacist` | 薬剤師情報 |

---

## 11. 定期購入

### 11.1 概要

- 月単位の注文サイクル（`interval_month`）
- 指定日配送（`delivery_day`）
- 次回注文日の自動計算（`next_order_at`）
- クレジットカード情報は `periodical_subscription_id` で管理

### 11.2 ステータス

```csharp
PeriodicalOrders.Status {
    Invalidity = 0,    // 無効
    Effectively = 1,   // 有効
}
```

---

## 12. バッチジョブ（igeneric_store.job）※旧版リポジトリ

| ジョブファイル | 用途 |
|--------------|------|
| `scheduler.cs` | ジョブスケジューラー（Quartz） |
| `generic_job.cs` | ジョブ基底クラス |
| `cancel_orders.cs` | 60日以上未入金注文の自動キャンセル |
| `tracking_check.cs` | 配送追跡確認 |
| `point_erase.cs` | ポイント失効処理 |
| `data_maintenance.cs` | データメンテナンス |
| `recount_category_product_count.cs` | カテゴリ別商品数再集計 |
| `recount_category_ranking.cs` | カテゴリ売上ランキング再計算 |
| `recount_purchased_same_time_product.cs` | 同時購入商品再集計 |
| `np_rest_shipments.cs` | NP決済コマンド処理 |
| `retargeting_mail.cs` | リターゲティングメール送信 |
| `review_mail.cs` | レビュー投稿促進メール |
| `review_display_check.cs` | レビュー表示資格チェック |
| `send_follow_up_mail.cs` | フォローアップメール |
| `user_survey.cs` | ユーザーアンケート |
| `product_image_resize.cs` | 商品画像リサイズ |
| `added_second_point.cs` | 追加ポイント付与 |
| `pinger.cs` | ヘルスチェック |

---

## 13. 決済システム

### 13.1 対応決済方法

| 決済方法 | 実装場所 |
|---------|---------|
| クレジットカード（VISA/Master/JCB/AMEX/Diners） | チョコム（`chocom_credit_card.cs`） |
| コンビニ決済 | チョコム（`chocom_convini.cs`） |
| 代金引換 | `cash_on_delivery.cs` |
| ペリカン代金引換 | — |
| 銀行振込 | 三菱UFJ銀行麹町中央支店（普通口座 1414707） |
| 郵便振替 | ぱるる（10150-60694251） |
| 後払い（NP） | NP後払い.com（REST API） |

### 13.2 3Dセキュア

チョコム経由の3Dセキュア認証に対応（`chocom_3D_secure_url`）。

### 13.3 注文関連定数

```csharp
Orders.USE_POINT_BORDER = 3000;              // ポイント利用最低注文金額
Orders.CASH_ON_DELIVERY_CHARGE_BORDER = 3000; // 代引き手数料閾値
Orders.NP_UPPER_LIMIT = 55000;               // NP後払い上限金額
```

---

## 14. 外部連携

| サービス | 用途 |
|---------|------|
| Redis | セッション管理（DB 12）・キャッシュ（DB 2） |
| CloudFlare | CDN・キャッシュ管理 |
| Cuenote | メールマガジン配信（Azure Functions 連携） |
| Google reCAPTCHA v2 | ボット対策 |
| Cloudflare Turnstile | ボット対策 |
| Application Insights | 監視・テレメトリ |
| ELMAH | エラーログ・通知 |
| NLog | ロギング |
| PCA | 会計ソフト連携 |
| Logimecs | 出荷管理システム連携（部門コード: 115） |
| NP後払い.com | 後払い決済（REST API） |
| Google Analytics 4 | アクセス解析 |

---

## 15. 改修時の注意事項

### 15.1 コーディング規約

- **命名規則**: スネークケース（`snake_case`）。クラス名のみパスカルケース
- **ファイル名**: パスカルケース（`ProductController.cs`）
- **名前空間**: `igeneric_store.controllers`, `igeneric_store.data.models`
- **null チェック**: `obj.not_empty()` / `obj.is_empty()` を使用（`!= null` は使わない）
- **文字列フォーマット**: `"text {0}".format(value)` を使用（`$""` interpolation は使わない）
- **型変換**: `obj.to_i()`, `obj.to_s()` を使用

### 15.2 DB 操作パターン

```csharp
// 取得
var order = Orders.GetOrder(order_id);

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

### 15.3 ビュー表示パターン

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

### 15.4 キャッシュ操作パターン

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

### 15.5 アクションフィルター

```csharp
// エラーハンドリング（Release ビルド時のみ）
#if !DEBUG
[ErrorHandler]
#endif

// 初期化フィルター（全アクション前に initialize() 実行）
[BeforeFilter(Order = 1, methods = new string[] { "initialize" })]

// ユーザー認証（ECサイト）
[RequiresAuthentication(Order = 1, https = true)]

// クッキー認証（ECサイト・アクション単位）
[RequiresCookieAuthentication]

// 管理者認証（管理画面）
[RequiresNewAdminAuthenticationAttribute(ConnectionStringName = "callcenter_db", Site = "IG2018")]

// reCAPTCHA（フォーム送信時）
[ValidateReCaptcha]
```

### 15.6 PC / スマートフォン切替

`OzController` の `ReturnView()` メソッドが端末判定を行い、自動的に PC / SP ビューを切り替える。
`IsSmartPhone()` / `IsShowSpView()` で明示的な判定も可能。

### 15.7 OTC医薬品に関する注意

- OTC商品の注文には薬剤師の承認が必要
- 承認は14日間有効
- 未成年・年齢制限チェックが注文・カートで実施される
- 管理画面に `OtcOrderRequestController` で承認管理機能あり

---

## 16. ビルド構成

| 構成 | 用途 | 備考 |
|------|------|------|
| `Debug` | ローカル開発 | `#if !DEBUG` でエラーハンドラ除外 |
| `Release` | 本番 | 認証有効化・ELMAHアクセス制限 |
| `Staging` | ステージング | |
| `Test` / `Testing` | テスト | |

### Web.config 変換

- `Web.Debug.config` — ローカル設定
- `Web.Release.config` — 本番設定（接続文字列・APIキー切替）

---

## 17. DBマイグレーション（旧版リポジトリ）

`db_migrations/migrations/` に日付プレフィックスのマイグレーションファイル:

```
YYYYMMDDHHMMSS_migration_name.cs
```

- 最新マイグレーション: `20210531023230_add_scheduled_jobs_data_cancel_orders.cs`
- 独自マイグレーションフレームワーク（EF Migrations ではない）

---

## 18. ファイル配置リファレンス

### igeneric_store2018

| パス | 内容 |
|------|------|
| `igeneric_store/Controllers/` | EC サイトコントローラー |
| `igeneric_store/Views/` | EC サイトビュー |
| `igeneric_store/ViewModels/` | EC サイト固有ViewModel |
| `igeneric_store/App_Start/` | ルーティング・フィルター・バンドル設定 |
| `igeneric_store/ActionFilters/` | EC サイト固有フィルター |
| `igeneric_store/Content/` | CSS・画像 |
| `igeneric_store/Script/` | JavaScript |
| `igeneric_store.callcenter/Controllers/` | 管理画面コントローラー |
| `igeneric_store.callcenter/Views/` | 管理画面ビュー |
| `igeneric_store.callcenter/ViewModels/` | 管理画面固有ViewModel |
| `igeneric_store.data/Models/` | LINQ to SQL エンティティ・操作クラス |
| `igeneric_store.data/ViewModels/` | 共有ViewModel（注文・メール・カート） |
| `igeneric_store.data/Attributes/` | カスタムバリデーション属性 |
| `igeneric_store.common/GenericCommon.cs` | 共通定数・設定 |
| `igeneric_store.helpers/Functions/` | ヘルパー関数 |
| `igeneric_store.helpers/Extensions/` | LINQ拡張 |
| `igeneric_store.helpers/ActionFilters/` | ヘルパー側フィルター |

### igeneric_store（旧版リポジトリ）

| パス | 内容 |
|------|------|
| `igeneric_store.job/jobs/` | バッチジョブ |
| `db_migrations/migrations/` | DBマイグレーション |

### oz_framework

| パス | 内容 |
|------|------|
| `extensions/` | 拡張メソッド（string, object, controller 等） |
| `services/controller/` | `OzController` 基底クラス |
| `services/data_access_layer/` | `BaseModel`, `DataAccessLayer` |
| `services/payment/` | 決済（チョコム、NP後払い等） |
| `services/security/` | セキュリティ（ハッシュ、暗号化、IP制限） |
| `services/action_filter/` | 認証・認可フィルター |
| `services/caching/` | キャッシュマネージャー |
| `services/mailer/` | メール送信 |
| `services/logging/` | ロギング |
| `services/search/` | Lucene全文検索 |
| `libs/` | 画像編集、ページネーション等 |
