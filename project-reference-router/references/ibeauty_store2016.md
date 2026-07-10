# iBeauty Store プロジェクト — Copilot 共通コンテキスト

## Response Policy

すべてのコミュニケーションとドキュメントは、必ず**日本語**で記述・応答してください。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | iBeauty Store（アイビューティーストアー）EC サイト・管理画面 |
| ソリューション | `ibeauty_store.sln` |
| フレームワーク | ASP.NET MVC 5 (.NET Framework 4.5.1/4.6.1) |
| ORM | LINQ to SQL（`System.Data.Linq`） |
| ビューエンジン | Razor（`.cshtml`） |
| データベース | SQL Server (`ibeautystore` / スキーマ `ibtoz0804db`) |
| セッション管理（EC）| Redis（Microsoft.Web.Redis.RedisSessionStateProvider） |
| セッション管理（管理画面）| SQL Server |
| キャッシュ | Redis（StackExchange.Redis） |
| 検索エンジン | Elasticsearch |
| 決済 | チョコム（クレジットカード/コンビニ）、NP後払い、代金引換、銀行振込 |
| CI/CD | Azure Pipelines |
| DBマイグレーション | 独自マイグレーションフレームワーク（`db_migrations`）※旧版リポジトリ側 |
| ロギング | NLog / ELMAH |
| 監視 | Application Insights |
| 業種特性 | **海外コスメEC**（多通貨・海外配送・会員ランク制度・レコメンドエンジン対応） |

---

## 2. ソリューション構成（プロジェクト一覧）

```
ibeauty_store.sln
├── ibeauty_store              ← EC サイト（Web）
├── ibeauty_store.callcenter   ← 管理画面（コールセンター）
├── ibeauty_store.data         ← データ層（モデル・DAL・ViewModel）
├── ibeauty_store.common       ← 共通設定・定数
├── ibeauty_store.helpers      ← ヘルパー関数群
├── ibeauty_store.jobs         ← バッチジョブ（Quartz.NET）
├── ibeauty_store.elasticsearch← Elasticsearch 統合
├── ibeauty_store.ml           ← 機械学習（不正検知）
├── ibeauty_store.sitemap      ← サイトマップ生成
├── ibeautystore.test          ← テスト
│
├── oz_framework.services      ← 共通サービス（別リポジトリ参照）
└── oz_framework.extensions    ← 共通拡張メソッド（別リポジトリ参照）
```

### リポジトリ構成

| リポジトリ | パス | 説明 |
|-----------|------|------|
| `ibeauty_store2016` | `d:\git_003\ibeauty_store2016` | EC サイト本体（2016年版・現行） |
| `ibeauty_store` | `d:\git_003\ibeauty_store` | 旧版（db_migrations、旧管理画面等） |
| `oz_framework` | `d:\git_003\oz_framework` | 複数サイト共通ライブラリ |

> `oz_framework` は Azure DevOps の別リポジトリ。ibeauty_store.sln からは相対パスで参照。
> `ibeauty_store`（旧版）の `ibeauty_store.callcenter` は旧管理画面として現在も利用中。`ibeauty_store`（旧版ECサイト）は利用していないため参照不要。
> `ibeauty_store`（旧版）にはDBマイグレーション（`db_migrations`）が格納されている。

---

## 3. アーキテクチャ

### 3.1 レイヤー構成

```
                ┌──────────────────────────────────────────────┐
Presentation    │  ibeauty_store (EC)                          │
                │  ibeauty_store.callcenter (管理画面)          │
                │  ibeauty_store.jobs (バッチ)                  │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Helpers/Common  │  ibeauty_store.helpers (ヘルパー)             │
                │  ibeauty_store.common (共通設定)              │
                │  ibeauty_store.elasticsearch (検索)           │
                │  ibeauty_store.ml (機械学習)                  │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Data Layer      │  ibeauty_store.data                          │
                │    Models/     ← LINQ to SQL エンティティ     │
                │    ViewModels/ ← メール用・注文用ViewModel    │
                │    Attributes/ ← バリデーション属性            │
                │    Functions/  ← ビジネスロジック              │
                │    Interfaces/ ← インターフェース              │
                └─────────────┬────────────────────────────────┘
                              │ 参照
                ┌─────────────▼────────────────────────────────┐
Framework       │  oz_framework.services (共通サービス)         │
(別リポジトリ)   │  oz_framework.extensions (拡張メソッド)       │
                └──────────────────────────────────────────────┘
```

### 3.2 コントローラー継承チェーン

**ECサイト（ibeauty_store）：**
```
System.Web.Mvc.Controller
  └── OzController                    (oz_framework.services)
        └── ApplicationController     (ibeauty_store.controllers)
              └── 各Controller        (HomeController, ProductController 等)
```

**管理画面（ibeauty_store.callcenter）：**
```
System.Web.Mvc.Controller
  └── OzController                                (oz_framework.services)
        └── ApplicationController [ValidateInput(false)] [ErrorHandler] [ActionExecuteLog]
              [RequiresNewAdminAuthentication(ConnectionStringName="callcenter_db", Site="IB2016")]
              └── 各Controller  (OrderTelController, ProductController 等)
```

**旧管理画面（ibeauty_store/ibeauty_store.callcenter）：**
```
System.Web.Mvc.Controller
  └── OzController
        └── BeautyBaseController
              └── ApplicationController
                    [RequiresNewAdminAuthentication(ConnectionStringName="callcenter_db", Site="IB")]
                    └── 各Controller
```

---

## 4. データアクセスパターン

### 4.1 LINQ to SQL（DataContext）

- **DataContext**: `BeautyStoreDb`（自動生成、`ibeauty_store_dal.cs`）
- **データベース名**: `ibeautystore`（スキーマ: `ibtoz0804db`）
- **接続文字列キー**: `ibeauty_store_db`
- **コンテキスト取得**: `DB.context`（HttpContext ごとにインスタンス管理）
- **CommandTimeout**: 600秒

```csharp
// DB.context は HttpContext.Items にキャッシュされる
public static BeautyStoreDb context
{
    get
    {
        if (HttpContext.Current.Items["ibeauty_store_db_context"].is_empty())
            HttpContext.Current.Items["ibeauty_store_db_context"] = new BeautyStoreDb();
        return (BeautyStoreDb)HttpContext.Current.Items["ibeauty_store_db_context"];
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
Orders.Get(order_id);           // Order を返す
Users.Get(user_id);             // User を返す
Carts.CreateNewCart(user_id);   // Cart を返す

// 単数形クラス = エンティティ（インスタンスメソッド）
product.Save(DB.context);
order.Update(DB.context);
```

### 4.3 共通接続文字列

| キー | 用途 |
|------|------|
| `ibeauty_store_db` | メインDB（ibeautystore） |
| `ibeauty_store_db_migration` | マイグレーション用（管理者権限） |
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

## 5. ECサイト（ibeauty_store）

### 5.1 コントローラー一覧

| コントローラー | 機能 | 認証 |
|---------------|------|------|
| `HomeController` | トップページ、最近の注文、メルマガ登録、サイトマップ | 不要 |
| `ProductController` | 商品検索・詳細・カテゴリ・ランキング・タイムセール・アウトレット | 不要 |
| `BrandController` | ブランド一覧・詳細・セール | 不要 |
| `CartController` | カート表示・商品追加・更新・削除・複数追加 | 不要 |
| `OrderController` | 注文フロー（配送先→支払確認→決済→完了・領収書・3Dセキュア） | **要認証**（一部除外） |
| `OrderGuestController` | ゲストユーザー登録 | **要認証** |
| `UserController` | ログイン・会員登録・パスワードリセット・2要素認証・Yahoo/LINE連携 | 一部要認証 |
| `MypageController` | マイページ（プロフィール・住所録・注文履歴・2FA管理・お気に入り・ポイント） | **要認証** |
| `FavoriteController` | お気に入り追加・削除 | **Cookie認証** |
| `WatchedProductController` | 閲覧履歴管理・比較機能 | 不要 |
| `ReviewController` | レビュー一覧・投稿・確認 | 一部要認証 |
| `CouponController` | クーポン登録・表示 | 一部要認証 |
| `FeaturedController` | 特集一覧・詳細 | 不要 |
| `EventController` | イベント（川柳）・キャンペーンLP | 不要 |
| `TrialController` | モニター商品・レポート・応募 | 不要 |
| `NewsController` | お知らせ一覧・詳細 | 不要 |
| `HelpController` | ヘルプ・FAQ・配送情報・レッスン | 不要 |
| `EnquiryController` | お問い合わせ | 不要 |
| `SurveyController` | アンケート | **要認証** |
| `RecommendController` | SilverEgg レコメンド取得・クリック | 不要 |
| `ThirdPartyController` | アフィリエイト連携（アクセストレード/デクワス等）・サジェスト・e振込 | 不要 |
| `ApiController` | 住所取得・サブカテゴリ取得・チョコム通知・GoogleMerchantCenter | 不要 |
| `RedirectController` | 旧URL互換リダイレクト（ASPレガシー・SP・ブランド等） | 不要 |
| `ErrorController` | エラーページ（400/403/404/500）・復旧ページ | 不要 |

### 5.2 ルーティング

`App_Start/RouteConfig.cs` で全ルートを明示的に定義（属性ルーティング不使用）。約771行。

```csharp
// 代表的なルート例
routes.MapRoute("index", "", new { controller = "Home", action = "Index" });
routes.MapRoute("product_detail", "products/{product_id}", new { controller = "Product", action = "Detail" });
routes.MapRoute("product_search", "search", new { controller = "Product", action = "Search" });
routes.MapRoute("product_by_category", "categories/{category_id}.{category_name}/{*sub_category_id}",
    new { controller = "Product", action = "ByCategory" });
routes.MapRoute("brand", "brands", new { controller = "Brand", action = "Index" });
routes.MapRoute("brand_detail", "brands/{brand_name}", new { controller = "Brand", action = "Detail" });
routes.MapRoute("cart", "cart", new { controller = "Cart", action = "Index" });
routes.MapRoute("cart_add", "cart/add", new { controller = "Cart", action = "Add" });
routes.MapRoute("login", "user/login", new { controller = "User", action = "Login" });
routes.MapRoute("user_register", "user/register", new { controller = "User", action = "Register" });
routes.MapRoute("mypage", "my-page", new { controller = "Mypage", action = "Index" });
routes.MapRoute("order_payment_confirm", "order/payment-confirm", new { controller = "Order", action = "PaymentConfirm" });
routes.MapRoute("order_thank_you", "order/thank-you", new { controller = "Order", action = "ThankYou" });
routes.MapRoute("review", "reviews", new { controller = "Review", action = "Index" });
routes.MapRoute("review_write", "reviews/write/{product_id}", new { controller = "Review", action = "Write" });
```

### 5.3 ビュー構成

```
Views/
├── Home/            ← トップページ
├── Product/         ← 商品検索・詳細
├── Brand/           ← ブランド
├── Cart/            ← カート
├── Order/           ← 注文フロー
├── OrderGuest/      ← ゲスト注文
├── User/            ← ログイン・会員登録
├── Mypage/          ← マイページ
├── Review/          ← レビュー・クチコミ
├── Coupon/          ← クーポン
├── Featured/        ← 特集ページ
├── Event/           ← イベント
├── Trial/           ← モニター
├── News/            ← お知らせ
├── Help/            ← ヘルプ・FAQ
├── Enquiry/         ← お問い合わせ
├── Survey/          ← アンケート
├── Recommend/       ← おすすめ商品
├── WatchedProduct/  ← 閲覧履歴
├── Banner/          ← バナー
├── Error/           ← エラー表示
└── Shared/          ← レイアウト・パーシャル
```

### 5.4 認証方式

**セッション ベース認証（メイン）:**
- セッションキー: `SESSION_NAME_CURRENT_USER_ID`
- 認証フィルター: `[RequiresAuthentication]`（oz_framework 提供）
- 2要素認証: TOTP 対応

**クッキー ベース認証（自動ログイン）:**
- キー1: `COOKIE_NAME_USER_AUTH_KEY1`（暗号化済み・10年有効）
- キー2: `COOKIE_NAME_USER_AUTH_KEY2`（暗号化済み・10年有効）
- カスタムフィルター: `[RequiresCookieAuthentication]`

**ゲストユーザー:**
- セッションキー: `SESSION_NAME_GUEST_USER_TOKEN`
- `OrderGuestController` でゲスト登録フローを提供

**ソーシャルログイン:**
- Yahoo! ID 連携: `yahoo_id_cooperation_application_id`
- LINE ログイン: `line_id_connect_channel_id`

### 5.5 セッションキー

| セッションキー | 用途 |
|--------------|------|
| `SESSION_NAME_CURRENT_USER_ID` | ログインユーザーID |
| `SESSION_NAME_CURRENT_CART` | カートViewModel |
| `SESSION_NAME_HEADER` (`"HEADER_INFO"`) | ヘッダー表示情報（カート数等） |
| `SESSION_NAME_YAHOO_AUTH` | Yahoo認証情報 |
| `SESSION_NAME_GUEST_USER_TOKEN` | ゲストユーザートークン |
| `SESSION_NAME_GA4_VIEW_MODEL` | GA4トラッキング |

### 5.6 クッキーキー

| クッキーキー | 有効期限 | 用途 |
|------------|--------|------|
| `COOKIE_NAME_USER_AUTH_KEY1` | 10年 | ユーザー認証キー1（自動ログイン） |
| `COOKIE_NAME_USER_AUTH_KEY2` | 10年 | ユーザー認証キー2（自動ログイン） |
| `COOKIE_NAME_CART_KEY1` | 1年 | カートキー1 |
| `COOKIE_NAME_CART_KEY2` | 1年 | カートキー2 |
| `COOKIE_NAME_WATCHED_PRODUCT_ID` | 1年 | 閲覧履歴商品ID |
| `COOKIE_NAME_LOGIN_EMAIL` | 1年 | ログインメールアドレス保存 |

### 5.7 セッション状態（Redis）

```xml
<sessionState mode="Custom" customProvider="MySessionStateStore" cookieSameSite="None">
  <providers>
    <add name="MySessionStateStore"
         type="Microsoft.Web.Redis.RedisSessionStateProvider"
         host="localhost" port="6379"
         ssl="false" />
  </providers>
</sessionState>
```
- Cookie設定: HttpOnly=true, RequireSSL=true

### 5.8 端末判定

- **CloudFlare `CF-Device-Type`** ヘッダーでDesktop/Mobile自動判定
- フォールバック: User-Agent正規表現判定
- `ChangeBrowser()` アクションでPC/SP手動切替可能

### 5.9 ECサイト インターフェース

| インターフェース | 用途 |
|---------------|------|
| `IDeletable` | 削除操作 |
| `IFilterable` | フィルター操作 |
| `IPagenatable` | ページネーション |
| `ISelectable` | 選択操作 |
| `ISortable` | ソート操作 |
| `ITopPageProductListDisplayable` | トップページ商品一覧表示 |

---

## 6. 管理画面（ibeauty_store.callcenter）

### 6.1 コントローラー一覧

| コントローラー | 機能 |
|---------------|------|
| `OrderTelController` | 電話注文 |
| `OrderRefundController` | 返金処理 |
| `OrderReshipmentController` | 再発送処理 |
| `OrderPcaCheckController` | PCAチェック |
| `NpOrderController` | NP注文管理 |
| `ProductController` | 商品管理 |
| `ProductCategoryController` | 商品カテゴリ管理 |
| `ProductUnitSubImageController` | 商品ユニット副画像管理 |
| `UserController` | ユーザー管理 |
| `UserRankController` | ユーザーランク管理 |
| `AddressController` | 住所管理 |
| `BrandController` | ブランド管理 |
| `BannerManagerController` | バナー管理 |
| `BannerTagManagerController` | バナータグ管理 |
| `TagManagerController` | タグ管理 |
| `KeywordController` | キーワード管理 |
| `ReviewController` | レビュー管理 |
| `ReportController` | レポート・売上集計 |
| `SalesController` | 売上管理 |
| `TrackingController` | 配送追跡管理 |
| `SuggestController` | サジェスト管理 |
| `SupplierController` | サプライヤー管理 |
| `TrialController` | モニター管理 |
| `SenryuController` | 川柳管理 |
| `SystemController` | システム設定・キャッシュ管理 |
| `RedisCacheController` | Redisキャッシュ管理 |
| `RedirectSettingController` | リダイレクト設定 |
| `ReminderMailSettingController` | リマインダーメール設定 |
| `PointUpController` | ポイント加算 |
| `BackOrderController` | バックオーダー取り込み |
| `CuenoteAddressController` | Cuenote連携 |
| `StrawberryController` | Strawberry（外部EC連携） |
| `StrawberryBillCheckController` | Strawberry請求チェック |
| `SubRakutenController` | 楽天サブ管理 |
| `YahooController` | Yahoo連携 |
| `OtherShopProductInfoController` | 他店舗商品情報 |
| `OverseasShippingMailImportController` | 海外配送メールインポート |
| `PcaSalesCheckController` | PCA売上チェック |
| `PeriodicallyExecutingBatchProcessingReportController` | バッチ処理レポート |
| `FtlOtherProductUnitNameManageController` | FTL他商品ユニット名管理 |
| `FtlProductUnitsChangeStockStatusController` | FTL在庫ステータス変更 |
| `WrongUserInfoManagerController` | ユーザー情報不備管理 |
| `CommonController` | 共通処理 |
| `ApiController` | API |

### 6.2 認証方式

- **管理者認証**: Cookie ベース（`RequiresNewAdminAuthentication`）
- 接続先DB: `callcenter_db`（calloz0805db）
- サイト識別子: `Site = "IB2016"`
- セッション管理: SQL Server（timeout = 120分）

```csharp
[RequiresNewAdminAuthenticationAttribute(ConnectionStringName = "callcenter_db", Site = "IB2016")]
[ActionExecuteLog]
[ValidateInput(false)]
[ErrorHandler]
public class ApplicationController : OzController
```

### 6.3 管理者情報取得

```csharp
logged_in_staff_id    // Request.Cookies["USER_ID"].to_i() から取得
logged_in_staff       // Request.Cookies["user_name"] から取得（URLデコード）
```

### 6.4 管理画面ユーティリティ

| ファイル | 用途 |
|---------|------|
| `ExcelController.cs` | Excel出力 |
| `WebRequestUtility.cs` | 外部HTTPリクエスト |
| `ZipUtility.cs` | ZIP圧縮 |

---

## 7. 旧管理画面（ibeauty_store/ibeauty_store.callcenter）

旧管理画面は現在も利用中。サイト識別子は `Site = "IB"`。

### 7.1 主要コントローラー（32個）

| コントローラー | 機能 |
|---------------|------|
| `amazon_controller` | Amazon連携 |
| `logistics_controller` | 物流管理 |
| `payment_controller` | 決済管理 |
| `place_order_controller` | 注文処理 |
| `product_unit_controller` | 商品ユニット管理 |
| `product_search_controller` | 商品検索 |
| `product_due_controller` | 商品入荷予定 |
| `general_price_controller` | 一括価格管理 |
| `stock_controller` | 在庫管理 |
| `shipping_controller` | 配送管理 |
| `bill_check_controller` | 請求チェック |
| `rakuten_controller_for_*` | 楽天連携（注文/商品/画像/参照） |
| `yahoo_controller` | Yahoo連携 |
| `ponpare_controller_for_*` | ポンパレ連携 |
| `elastic_search_controller` | Elasticsearch管理 |
| `maintenance_controller` | メンテナンス |
| `reviews_controller` | レビュー管理 |
| `other_shop_controller` | 他店舗管理 |

---

## 8. データ層（ibeauty_store.data）

### 8.1 主要モデル一覧

| モデル | テーブル | 概要 |
|--------|---------|------|
| `Product` / `Products` | products | 商品マスタ |
| `ProductUnit` / `ProductUnits` | product_units | 商品バリエーション |
| `ProductCategory` / `ProductCategories` | product_categories | 商品カテゴリ |
| `ProductsSubCategory` | products_sub_categories | 商品サブカテゴリ |
| `ProductCategoryBanner` | product_category_banners | カテゴリバナー |
| `ProductUnitSubImage` | product_unit_sub_images | 商品ユニット副画像 |
| `ProductUnitOriginalJan` | product_unit_original_jans | 商品JANコード |
| `ProductRanking` | product_rankings | 商品ランキング |
| `ProductsAccessLog` | products_access_logs | 商品アクセスログ |
| `ProductInfoAliasForOtherShop` | — | 他店舗商品情報エイリアス |
| `Order` / `Orders` | orders | 注文 |
| `LineItem` / `LineItems` | line_items | 注文明細 |
| `OrderMemo` | order_memos | 注文メモ |
| `OrderCampaign` | order_campaigns | 注文キャンペーン |
| `OrderCashOnDelivery` | order_cash_on_deliveries | 代引き注文 |
| `OrderPcas` | order_pcas | PCA連携 |
| `OtherCharge` / `OtherCharges` | other_charges | 追加料金 |
| `AdditionalCharges` | additional_charges | 追加料金（別系統） |
| `TrackingNumber` | tracking_numbers | 追跡番号 |
| `User` / `Users` | users | ユーザー |
| `UserLoginHistory` | user_login_histories | ログイン履歴 |
| `UserMemo` | user_memos | ユーザーメモ |
| `UserAuthKey` | user_auth_keys | 自動ログインキー |
| `UserWatchedProduct` | user_watched_products | 閲覧履歴 |
| `UserAccessInfo` | user_access_infos | アクセス情報 |
| `UserPointHistory` | user_point_histories | ポイント履歴 |
| `UserPointRateUpPeriod` | user_point_rate_up_periods | ポイント倍率アップ期間 |
| `UserPurchaseRankForNextMonths` | — | 翌月ランク予測 |
| `UserRankChangeHistory` | — | ランク変更履歴 |
| `Cart` / `Carts` | carts | カート |
| `CartItem` / `CartItems` | cart_items | カート内商品 |
| `Address` / `Addresses` | addresses | 住所 |
| `Campaign` / `Campaigns` | campaigns | キャンペーン |
| `CampaignBrand` | campaign_brands | キャンペーンブランド |
| `CampaignPoint` | campaign_points | キャンペーンポイント |
| `Review` / `Reviews` | reviews | レビュー |
| `ReviewFilterKeyword` | review_filter_keywords | レビューフィルターキーワード |
| `ReviewReputationKeyword` | review_reputation_keywords | レビュー評判キーワード |
| `Banner` / `Banners` | banners | バナー |
| `Brand` / `Brands` | brands | ブランド |
| `BrandLine` | brand_lines | ブランドライン |
| `BrandAlertMail` | brand_alert_mails | ブランドアラートメール |
| `Membership` / `Memberships` | memberships | 会員ランク |
| `Coupon` / `Coupons` | coupons | クーポン |
| `PointHistory` | point_histories | ポイント履歴 |
| `PointReward` | point_rewards | ポイント報酬 |
| `Point` | points | ポイント |
| `PeriodicalOrder` / `PeriodicalOrders` | periodical_orders | 定期購入 |
| `Favorite` / `Favorites` | favorites | お気に入り |
| `FeaturedGroup` | featured_groups | 特集グループ |
| `SpecialContents` | special_contents | 特集コンテンツ |
| `Trial` / `Trials` | trials | モニター |
| `TrialApplicant` | trial_applicants | モニター応募者 |
| `TrialReport` | trial_reports | モニターレポート |
| `TesterReport` | tester_reports | テスターレポート |
| `News` / `NewsCategory` | news, news_categories | お知らせ |
| `Survey` | surveys | アンケート |
| `Faq` / `FaqCategory` / `FaqContent` | — | FAQ |
| `Keyword` | keywords | 検索キーワード |
| `MailTemplate` / `MailTemplates` | mail_templates | メールテンプレート |
| `MailMagazine` | mail_magazines | メルマガ |
| `Holiday` / `Holidays` | holidays | 休日マスタ |
| `ShippingCompany` | shipping_companies | 配送会社 |
| `ShippingTime` | shipping_times | 配送時間 |
| `Country` | countries | 国マスタ（`JAPAN = 109`） |
| `Currency` | currencies | 通貨 |
| `Zip` | zips | 郵便番号 |
| `Supplier` / `Suppliers` | suppliers | 仕入先 |
| `SupplierSurchage` | supplier_surcharges | 仕入先追加料金 |
| `BackOrder` | back_orders | バックオーダー |
| `BlackList` | black_lists | ブラックリスト |
| `Claim` | claims | クレーム |
| `ChocomRequest` | chocom_requests | チョコム決済リクエスト |
| `ClickConversion` / `ClickConversionType` | — | クリックコンバージョン |
| `CompanyInfo` | company_infos | 企業情報 |
| `GlobalVariable` | global_variables | グローバル変数 |
| `PasswordReset` | password_resets | パスワードリセット |
| `TwoFactorAuth` | two_factor_auths | 2要素認証 |
| `PaymentToken` | payment_tokens | 決済トークン |
| `PaymentInfo` | payment_infos | 決済情報 |
| `OAuthLine` | oauth_lines | LINE認証 |
| `YahooAuth` | — | Yahoo認証 |
| `FriendInvite` | friend_invites | お友達紹介 |
| `Senryu` | senryus | 川柳 |
| `RoulettePlay` | roulette_plays | ルーレット |
| `Skin` | skins | 肌タイプ |
| `BeautyConcern` | beauty_concerns | 美容のお悩み |
| `BlogTitle` / `BlogItem` | — | ブログ |
| `ScheduledJob` / `ScheduledJobLog` | — | スケジュール済みジョブ |
| `RedisCacheSystem` / `RedisCacheSystems` | — | Redisキャッシュ管理 |
| `DailyWork` | daily_works | 日次業務 |
| `ReminderMailSetting` | reminder_mail_settings | リマインダーメール設定 |
| `AutoOrderLog` | — | 自動発注ログ |
| `PdfReceiptMaker` | — | PDF領収書生成 |

### 8.2 注文ステータス

```csharp
Orders.Status {
    NotProcessed = 1,        // 未処理
    PaymentRequested = 5,    // 入金お願い済み
    UrgePayment = 10,        // 入金催促中
    Reservation = 13,        // 予約
    PaymentReceived = 15,    // 入金済み
    Suspended = 20,          // 保留
    Processed = 25,          // 手続済
    PartlyShipped = 30,      // 一部発送済み
    Shipped = 35,            // 発送済み
    ShipmentNotified = 40,   // 発送お知らせ済み
    Completed = 45,          // 完了
    Cancel = 99,             // キャンセル
}
```

### 8.3 明細ステータス

```csharp
LineItems.Status {
    NotProcessed = 1,        // 未処理
    OutOfStock = 5,          // 在庫切れ
    Accepted = 10,           // 受付済み
    Processed = 15,          // お手続き済み
    Shipped = 20,            // 発送済み
    ShipmentNotified = 25,   // 発送お知らせ済み
    ReviewRequested = 35,    // 口コミ依頼済み
    Cancel = 99,             // キャンセル
}
```

### 8.4 注文元サイト

```csharp
EnteredFrom.Site {
    Web = 0,                 // ウェブ（本店）
    iBeautyStaff = 1,        // スタッフ
    Yahoo = 2,               // ヤフー
    OtherDepartment = 3,     // 他部署
    Mobile = 4,              // 携帯
    Amazon = 5,              // アマゾン
    Gmarket = 6,             // Gmarket
    SmartPhoneWeb = 7,       // スマホ
    AmazonFba = 8,           // フルフィルメント by Amazon
    Rakuten = 9,             // 楽天
    PeriodicalOrder = 10,    // 定期購入
    Reservation = 12,        // 予約
    SubRakuten = 15,         // ベア楽天
    Ponpare = 16,            // ポンパレ
    Syahan = 17,             // 社販
    RakutenPay = 18,         // 楽天ペイ
    All = 999,               // 全体
}
```

**サイトディビジョン:**
- `HeadOffice` → 本店（Web, Mobile, SmartPhoneWeb, iBeautyStaff, PeriodicalOrder, Reservation）
- `Yahoo` → ヤフー
- `Amazon` → アマゾン
- `Rakuten` → 楽天
- `OtherDepartment` → 他部署
- `Syahan` → 社販

### 8.5 支払方法

```csharp
PaymentType.Type {
    BankTransfer = 1,        // 銀行振込
    Postal = 2,              // ぱるる送金
    CreditCard = 3,          // クレジットカード
    Daibiki = 4,             // 代金引換
    SevenEleven = 7,         // セブンイレブン
    Lawson = 8,              // ローソン・ミニストップ
    FamilyMart = 9,          // ファミリーマート
    CirclekAndOthers = 10,   // デイリー・サークルK等
    LawsonOrSeicormart = 12, // セイコーマート
    CircleK = 13,            // サークルKサンクス
    DailyYamazaki = 14,      // デイリーヤマザキ
    NetProtections = 21,     // NP後払い
    OzPayment = 22,          // 給与天引
    SoftbankYmobile = 23,    // ソフトバンク・Y!モバイル
    YahooPoint = 24,         // Yahoo!ポイント
    YahooMoney = 25,         // Yahoo!マネー
    YahooPaypay = 26,        // Yahoo!PayPay
    NetProtectionsSpot = 28, // NP後払い（Spot）
    YahooPaypayAtobarai = 29,// PayPay 後払い
}
```

> **無効化された支払方法**: `_ConviniSeven = 5`, `E_payment = 6`, `OldMinistop = 11`, `_PayPal = 20`

### 8.6 割引種別

```csharp
DiscountType.Name {
    GeneralDiscount = 3,           // 割引適用
    MinimumPurchase = 4,           // 最低購入額割引
    NewProduct = 5,                // 新着特価
    BulkBuy = 7,                   // まとめ買い割引
    PremiumMembership = 8,         // プレミアムクラブ会員割引
    SteppedDiscount = 12,          // 段階割
    Coupon = 13,                   // クーポン（金額引き）
    Brand = 14,                    // ブランドセール
    AllProductUnit = 15,           // 全商品セール
    BrandPercent = 16,             // ブランド％セール
    AllProductUnitPercent = 17,    // 全商品％セール
    BulkBuyAll = 18,               // 全商品まとめ買い割引
    SpecialPoint = 20,             // 注文金額から％ポイント
    Yoridori = 21,                 // 選り取りセール
    PeriodicalOrder = 22,          // 定期購入
    CouponPercent = 24,            // クーポン（％引き）
    FreeShipping = 25,             // 送料無料
}
```

### 8.7 カートアイテム種別

```csharp
CartItems.Type {
    Usual,           // 通常購入
    SpecialOffer,    // 特別購入
    Reservation,     // 予約
    PeriodicalOrder, // 定期購入
}
```

### 8.8 追加料金種別

```csharp
OtherCharges.Type {
    CashOnDelivery = 1,   // 代引き手数料
    Shipping = 2,         // 送料
    DistributionFee = 3,  // 流通手数料
    GiftWrap = 4,         // プレゼント包装費
    NpFee = 5,            // NP手数料
    GiftWrapAll = 6,      // おまとめ包装費
}
```

### 8.9 会員ランク

```csharp
Membership.Rank {
    Regular = 1,       // 通常会員
    Silver = 2,        // シルバー
    Gold = 3,          // ゴールド
    Platinum = 4,      // プラチナ
    PlatinumPlus = 5,  // プラチナプラス
}
```

- ランク判定期間: 過去6ヶ月（`PAST_ORDER_MONTH = 6`）
- Redisキャッシュ: `Membership` キーで全ランク情報をキャッシュ

### 8.10 ユーザーステータス

```csharp
Users.ActiveStatus {
    Normal,       // 通常
    NoDaibiki,    // 代引き不可
    NoAtobarai,   // 後払い不可
    NoDaiAto,     // 代引き・後払い不可
    NotActive,    // 非アクティブ
}

Users.GuestFlag {
    Member = 0,        // 会員
    Guest = 1,         // ゲスト
    DeleteGuest = 2,   // 削除済みゲスト
}

Users.Gender {
    F,  // 女性
    M,  // 男性
    O,  // その他
}
```

### 8.11 定期購入

```csharp
PeriodicalOrders.RunType {
    Processing,  // 処理中
    Skip,        // スキップ
    Stop,        // 停止
    Activate,    // アクティブ
}
```

### 8.12 配送会社

```csharp
ShippingCompanies.Name {
    JapanPost = 1,           // 国際書留（香港）
    SagawaGlobal = 2,        // 佐川グローバル
    Usps = 3,                // USPS
    Sagawa = 4,              // 佐川急便
    Yamato = 5,              // ヤマト運輸
    Lci = 6,                 // LCI
    Dhl = 7,                 // DHL
    Nittsu = 8,              // Mプラス
    StandardInternational = 9, // 国際普通郵便
    Rgt = 10,                // RGT
    EPelican = 11,           // eペリ
    Fedex = 12,              // Fedex
    EMS = 13,                // EMS
    YuPack = 16,             // ゆうパック
    YuanTong = 17,           // Yuan Tong
    SfexPress = 18,          // sfexpress
    InternationalEPacketLight = 19, // 国際eパケットライト
    SwissPost = 20,          // スイスポスト
}
```

### 8.13 配送期間

```csharp
ProductUnits.DeliveryPeriod {
    FourDays = 4,     // 2～4日
    OneWeek = 7,      // 2～7日
    EightDays = 8,    // 3～7日
    TenDays = 10,     // 7～10日
    TwoWeeks = 14,    // 10～14日
    ThreeWeeks = 21,  // 7～20日
    OneMonth = 28,    // 10～28日
    Unknown = 90,     // メーカー予約（入荷次第発送）
    Delay = 200,      // およそ3～5週間
}
```

### 8.14 特集グループ種別

```csharp
FeaturedGroups.Type {
    General = 1,   // 一般
    Seasonal = 2,  // シーズナル
    Genre = 3,     // ジャンル
}
```

### 8.15 モニター（Trial）ステータス

```csharp
Trials.Status {
    Hide,              // 非表示
    ApplicantsWanted,  // モニター募集中
    Show,              // 応募終了・表示
}
```

### 8.16 バナー配置位置

```csharp
Banners.PositionType {
    TOP_中下_スマホ中 = 0,
    PC_スマホトップ = 1,
    PCヘッダーセール会場_マイページトップ = 2,
    特集バナー = 3,
    イベント特集一覧 = 4,
    カテゴリーページ = 5,
    ブランドページ = 6,
    商品ページ = 7,
    メディア掲載 = 8,
    PC左部 = 9,
    全品セールページ = 10,
    特集ページ_アイテムまとめ = 11,
    特集ページ_オリジナル企画 = 12,
    特集ページ_テーマ別読み物 = 13,
}
```

### 8.17 ポイント報酬種別

```csharp
PointRewards.Type {
    Purchase,                 // ポイント使用
    Review,                   // 口コミ
    FriendInviteRegister,     // お友達紹介（登録）
    FriendInvitePurchase,     // お友達紹介（お友達購入）
    Registration,             // 新規登録
    Manual,                   // 管理者変更
    OrderCancel,              // 注文キャンセル
    Campaign,                 // キャンペーン
    SugorokuGame,             // すごろくゲーム
    PointCancel,              // ポイント取り消し
    Transition,               // 繰り越し残高
    Expiration,               // 期限切れ
    Roulette,                 // ルーレット
    ReservedPoint,            // お買い物付与
    RefundByPoint,            // ポイント返金
}
```

### 8.18 キャッシュシステム（Redis）

`RedisCacheSystems` クラスが Redis キャッシュを管理:

```csharp
RedisCacheSystems.CacheName {
    Keyword,                          // キーワード
    Brand,                            // ブランド
    BrandDetail,                      // ブランド詳細
    BrandTop20Ranking,                // ブランドTOP20ランキング
    BrandLine,                        // ブランドライン
    GlobalVariable,                   // グローバル変数
    News,                             // お知らせ
    NewsCategory,                     // お知らせカテゴリ
    Banner,                           // バナー
    ProductSearch,                    // 商品検索
    Faq,                              // FAQ
    FaqCategory,                      // FAQカテゴリ
    FaqContent,                       // FAQコンテンツ
    ProductUnitCount,                 // 商品ユニット数
    ReviewCount,                      // レビュー数
    ProductCategory,                  // 商品カテゴリ
    ActiveProductsSubCategory,        // アクティブ商品サブカテゴリ
    TimeSale,                         // タイムセール
    Outlet,                           // アウトレット
    AllItemSale,                      // 全品セール
    Holiday,                          // 休日
    MailTemplate,                     // メールテンプレート
    NegativeProductCategory,          // 除外商品カテゴリ
    IndexViewModel,                   // トップページ
    NewestOrderViewModel,             // 最近の注文
    ActiveAndFutureCampaign,          // アクティブ・今後のキャンペーン
    Currency,                         // 通貨
    SupplierSurcharge,                // 仕入先追加料金
    Membership,                       // 会員ランク
    ProductCategoryViewModel,         // 商品カテゴリVM
    ProductReviewViewModel,           // 商品レビューVM
    TopSeller,                        // トップセラー
    ActiveProductBrand,               // アクティブ商品ブランド
    Restocked,                        // 再入荷
    ThisWeekPriceDown,                // 今週値下げ
    NewProductUnitIDs,                // 新着商品ユニットID
    NewDiscountProductUnitIDs,        // 新着割引商品ユニットID
    BlogTitle,                        // ブログタイトル
    BlogItem,                         // ブログ記事
    SearchByKeyword,                  // キーワード検索
    SearchByCategory,                 // カテゴリ検索
    SearchBaseAllProducts,            // 検索ベース全商品
    SearchBaseProductSalePrices,      // 検索ベース商品セール価格
    ReviewResult,                     // レビュー結果
    ReservableProductUnitIDs,         // 予約可能商品ユニットID
    BrandSale,                        // ブランドセール
    ReservableBrandProductIDs,        // 予約可能ブランド商品ID
    ReservableSupplierIDs,            // 予約可能サプライヤーID
    CategoryMenu,                     // カテゴリメニュー
    AppSmartNews,                     // SmartNewsフィード
    ElasticSearchUpadateCount,        // Elasticsearch更新カウント
    BlandInitial,                     // ブランド頭文字
    BrandRanking_TopPage,             // トップページブランドランキング
    ProductDetailViewModel,           // 商品詳細VM
    ElasticSearchCloudUpadateCount,   // Elasticsearchクラウド更新カウント
    ElasticSearchCloudReviewUpadateCount, // Elasticsearchクラウドレビュー更新
    ReviewFilterKeyword,              // レビューフィルターキーワード
}
```

```csharp
// キャッシュ操作パターン
var data = RedisCacheSystems.Get<T>(RedisCacheSystems.CacheName.XXX);
RedisCacheSystems.Add(RedisCacheSystems.CacheName.XXX, data, 1800); // デフォルト30分
RedisCacheSystems.Remove(RedisCacheSystems.CacheName.XXX);
RedisCacheSystems.GetMultiple<T>(keys); // Redis MGET

// Redis接続失敗時は HttpContext.Cache（ローカル）にフォールバック
```

### 8.19 グローバル変数キー（GlobalVariable）

| キー | 用途 |
|------|------|
| `MaxOrderNo` / `MaxCustomerId` / `MaxPcaUserCode` | 最大値管理 |
| `ImportOrderExclusiveControl` | 注文インポート排他制御 |
| `ExclusiveControlTimeout` | 排他制御タイムアウト |
| `RakutenDataProcess` / `SubRakutenDataProcess` | 楽天注文インポート状態 |
| `PonpareDataProcess` | ポンパレ注文処理状態 |
| `YahooAccessToken` / `YahooRefreshToken` | Yahoo API連携トークン |
| `ElasticSearchDataUpdateProcess` | Elasticsearch更新ジョブ |
| `ElasticSearchCloudDataUpdateProcess` | Elasticsearchクラウド更新 |
| `ElasticSearchCloudReviewUpdateProcess` | Elasticsearchレビュー更新 |
| `RefundCheck` / `PeriodicalOrderCheck` | 定常業務実行フラグ |
| `KandaObtainCheck` / `OzShipmentCheck` | 定常業務（カンダ/オズ） |
| `NoveltyDistributionCount` / `NoveltyDistributionMaxCount` | ノベルティ配布数管理 |
| `A8_DomesticRate` / `A8_OverseasRate` | アフィリエイト手数料率 |

### 8.20 データ層ビジネスロジック（Functions）

| ディレクトリ | 用途 |
|-------------|------|
| `AutoOrder/` | 自動発注ロジック |
| `Credit/` | クレジットカード処理 |
| `Cuenote/` | Cuenoteメルマガ連携 |
| `UserIntegrations/` | ユーザー統合処理 |
| `UserRank/` | ユーザーランク計算 |

### 8.21 ViewModel の配置

| 場所 | 用途 |
|------|------|
| `ibeauty_store.data/ViewModels/Cart/` | カート画面用 |
| `ibeauty_store.data/ViewModels/Order/` | 注文フロー・決済画面用 |
| `ibeauty_store.data/ViewModels/Mails/` | メール送信用（27件） |
| `ibeauty_store.data/ViewModels/Shared/` | 共有ViewModel |
| `ibeauty_store.data/ViewModels/Shipping/` | 配送用 |
| `ibeauty_store.data/ViewModels/Coupon/` | クーポン用 |
| `ibeauty_store.data/ViewModels/ElasticSearch/` | Elasticsearch用 |
| `ibeauty_store.data/ViewModels/Strawberry/` | Strawberry EC連携用 |
| `ibeauty_store/ViewModels/` | ECサイト画面固有（25カテゴリ） |
| `ibeauty_store.callcenter/ViewModels/` | 管理画面固有（44カテゴリ） |

### 8.22 バリデーション

`ibeauty_store.data/Attributes/` にカスタムバリデーション属性:

| 属性 | 用途 |
|------|------|
| `Required` | 必須入力 |
| `StringLength` | 文字列長 |
| `StringByteLength` | バイト長 |
| `StringByteLengthRange` | バイト長範囲 |
| `Range` | 範囲 |
| `RegularExpression` | 正規表現 |

MetadataType パターンで LINQ to SQL エンティティにバリデーションを追加。

### 8.23 レポートモデル

| ファイル | 用途 |
|---------|------|
| `OrderQuantitiesReport.cs` | 注文数量レポート |
| `StockReport.cs` | 在庫レポート |
| `StockTransitionReport.cs` | 在庫推移レポート |

---

## 9. ヘルパー層（ibeauty_store.helpers）

### 9.1 Functions

| ファイル | 概要 |
|---------|------|
| `AjaxPagingHelper.cs` | AJAXページネーション |
| `BannerHelper.cs` | バナーヘルパー |
| `BrandHelper.cs` | ブランドヘルパー |
| `CurrencyHelper.cs` | 通貨フォーマット |
| `HtmlHelper.cs` | HTMLヘルパー |
| `JavaScriptHelper.cs` | JavaScriptヘルパー |
| `MyPageHelper.cs` | マイページヘルパー |
| `PagingHelper.cs` | ページネーション |
| `ProductCategoryHelper.cs` | 商品カテゴリヘルパー |
| `ProductHelper.cs` | 商品ヘルパー |
| `ProductUnitHelper.cs` | 商品ユニットヘルパー |
| `ReviewHelper.cs` | レビューヘルパー |
| `ShippingCompanyHelper.cs` | 配送業者ヘルパー |
| `SpecialContentsHelper.cs` | 特集コンテンツヘルパー |
| `StrawberrySaleHelper.cs` | Strawberry EC連携ヘルパー |
| `SupplierHelper.cs` | サプライヤーヘルパー |
| `SurveyHelper.cs` | アンケートヘルパー |
| `UserHelper.cs` | ユーザーヘルパー |
| `AutoOrder/` | 自動発注ヘルパー群 |

### 9.2 Extensions

| ファイル | 概要 |
|---------|------|
| `IQueryableExtensions.cs` | LINQ クエリ拡張 |

---

## 10. oz_framework（共通ライブラリ）

### 10.1 oz_framework.extensions

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

### 10.2 oz_framework.services

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
| `LINE/` | LINE 連携 |
| `amazon/` | Amazon 連携 |
| `yahoo/` | Yahoo! 連携 |
| `rakuten-pay/` | 楽天ペイ |

### 10.3 認証フィルター

| フィルター | 用途 |
|-----------|------|
| `RequiresAuthentication` | ECサイトユーザー認証 |
| `RequiresCookieAuthentication` | ECサイトクッキー認証 |
| `RequiresNewAdminAuthentication` | 管理者認証（新） |
| `ValidateReCaptcha` / `ValidateReCaptchaV3` | reCAPTCHA検証 |
| `CompressFilter` | GZIP圧縮 |
| `RequiresSSL` | SSL強制 |
| `ErrorHandler` | エラーハンドリング |
| `BeforeFilter` | アクション前処理 |
| `ActionExecuteLog` | アクション実行ログ |

---

## 11. バッチジョブ（ibeauty_store.jobs）— Quartz.NET

### 11.1 ジョブ一覧（43個）

| ジョブファイル | 用途 |
|--------------|------|
| `Scheduler.cs` | ジョブスケジューラー |
| `BeautyJob.cs` | ジョブ基底クラス |
| `BeautyNotifyShippingJob.cs` | 発送通知ジョブ基底 |
| `BeautyOrderImportJob.cs` | 注文インポートジョブ基底 |
| `AutoCancelLongTermNonPaymentOrder.cs` | 長期未入金注文の自動キャンセル |
| `AutomaticLogisticNotification.cs` | お手続きメール自動送信 |
| `ApplyReservedUserPoint.cs` | 付与予定ポイント適用 |
| `ValidateReservedUserPoint.cs` | ポイント検証 |
| `CalcurateUserRanks.cs` | ユーザーランク集計 |
| `CalcurateUserRanksForNextMonth.cs` | 翌月ユーザーランク計算 |
| `CalcurateReviewScore.cs` | レビュースコア計算 |
| `DataMaintenance.cs` | データメンテナンス |
| `ImportAmazonOrderReport.cs` | Amazon注文レポートインポート |
| `ImportRakutenOrders.cs` | 楽天注文インポート |
| `ImportStrawberryTracking.cs` | Strawberry荷物番号インポート |
| `CheckPublishedProductsAsin.cs` | Amazon出品商品ASINチェック |
| `UpdateShippingNotification.cs` | Amazon出荷通知更新 |
| `UpdateAmazonProduct.cs` | Amazon商品更新 |
| `updateAmazonStockQuantity.cs` | Amazon在庫更新 |
| `UpdateAmazonStockQuantityBase.cs` | Amazon在庫更新基底 |
| `UpdateAmazonStockQuantityFull.cs` | Amazon在庫フル更新 |
| `UpdateRautenPayShippingNotification.cs` | 楽天ペイ発送通知 |
| `UpdateElasticSearchProductAlternative.cs` | Elasticsearch商品データ更新 |
| `UpdateElasticSearchCloudProduct.cs` | Elasticsearchクラウド商品更新 |
| `UpdateElasticSearchCloudReview.cs` | Elasticsearchクラウドレビュー更新 |
| `UpdateProductSearchAlternative.cs` | SQL商品検索セール価格設定 |
| `UpdateProductUnitWeeklySoldCount.cs` | 週間売上数計算 |
| `UpdateWeeklySoldCountAlternative.cs` | 週間売上数代替更新 |
| `UpdateCardLastNo.cs` | クレジットカード下4桁更新 |
| `NpRestShipments.cs` | NP決済出荷API |
| `NpRestTransaction.cs` | NP決済取引API |
| `NpOldOrderCheck.cs` | NP古い注文チェック |
| `SendCouponReminderMail.cs` | クーポンリマインダーメール送信 |
| `SendPeriodicalOrderExpiredCreditCardMail.cs` | 定期購入クレカ期限切れ通知 |
| `ChangeStaffStatus.cs` | スタッフステータス変更 |
| `OpenStaffStatus.cs` | スタッフステータスOpen |
| `CloseStaffStatus.cs` | スタッフステータスClose |
| `ResetDailyWorksStatus.cs` | 日次業務ステータスリセット |
| `CheckHKCashOnDelivery.cs` | 香港代引きチェック |
| `CleanupElasticSearchKeywordIndices.cs` | Elasticsearchキーワードインデックスクリーンアップ |
| `ElmahLogChecker.cs` | Elmahエラーログチェック |
| `AlternativePinger.cs` | ヘルスチェック（ping） |

### 11.2 スケジュール済みジョブ管理

```csharp
ScheduledJobs.BelongedSystem {
    OLD = 0,      // 旧版
    RENEWAL = 1,  // 新版（2016）
}
```

---

## 12. Elasticsearch 統合

`ibeauty_store.elasticsearch` プロジェクトで Elasticsearch を統合:

| パス | 用途 |
|------|------|
| `elasticsearch.cs` | コア実装 |
| `models/` | Elasticsearch モデル |
| `query/` | クエリビルダー |
| `schema/` | インデックスマッピング |

商品検索（`ProductController.Search`）でElasticsearchを使用。

---

## 13. 機械学習（ibeauty_store.ml）

| パス | 用途 |
|------|------|
| `fraud-detection/` | 不正注文検知 |
| `ibeauty_store.data/ML/FraudOrderDetection/` | 不正注文検知データモデル |

---

## 14. 決済システム

### 14.1 対応決済方法

| 決済方法 | 実装場所 |
|---------|---------|
| クレジットカード（VISA/Master/JCB/AMEX/Diners） | チョコム（`chocom_credit_card.cs`） |
| コンビニ決済（セブン/ローソン/ファミマ/サークルK等） | チョコム（`chocom_convini.cs`） |
| 代金引換 | `cash_on_delivery.cs` |
| 銀行振込 | — |
| ぱるる送金 | — |
| 後払い（NP） | NP後払い（REST API） |
| 給与天引（OzPayment） | 社内決済 |
| Yahoo!ポイント/マネー/PayPay | Yahoo連携 |
| ソフトバンク・Y!モバイル | — |
| PayPay後払い | — |

### 14.2 3Dセキュア

チョコム経由の3Dセキュア認証に対応（`chocom_3D_secure_url`）。

---

## 15. 外部連携

| サービス | 用途 |
|---------|------|
| Redis | セッション管理（EC）・キャッシュ（DB #1） |
| Elasticsearch | 商品全文検索 |
| CloudFlare | CDN・端末判定（CF-Device-Type） |
| Cuenote | メールマガジン配信 |
| SilverEgg | レコメンドエンジン |
| Google reCAPTCHA v3 | ボット対策 |
| Cloudflare Turnstile | ボット対策 |
| Application Insights | 監視・テレメトリ |
| ELMAH | エラーログ・通知 |
| NLog | ロギング |
| PCA | 会計ソフト連携 |
| Amazon MWS | Amazon出品・在庫・注文連携 |
| 楽天 / 楽天ペイ | 楽天出品・注文連携 |
| Yahoo! ショッピング | Yahoo出品・注文連携 |
| Strawberry | 外部EC連携（仕入・配送） |
| LINE Login | LINEソーシャルログイン |
| Yahoo! ID連携 | Yahoo!ソーシャルログイン |
| アクセストレード | アフィリエイト |
| A8.net | アフィリエイト |
| SmartNews | ニュースフィード |
| Google Merchant Center | 商品フィード |
| Google Analytics 4 | アクセス解析 |

---

## 16. 改修時の注意事項

### 16.1 コーディング規約

- **命名規則**: スネークケース（`snake_case`）。クラス名のみパスカルケース
- **ファイル名**: パスカルケース（`ProductController.cs`）
- **名前空間**: `ibeauty_store.controllers`, `ibeauty_store.data.models`
- **null チェック**: `obj.not_empty()` / `obj.is_empty()` を使用（`!= null` は使わない）
- **文字列フォーマット**: `"text {0}".format(value)` を使用（`$""` interpolation は使わない）
- **型変換**: `obj.to_i()`, `obj.to_s()` を使用

### 16.2 DB 操作パターン

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

### 16.3 ビュー表示パターン

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

### 16.4 キャッシュ操作パターン

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

### 16.5 アクションフィルター

```csharp
// エラーハンドリング
[ErrorHandler]

// 初期化フィルター（全アクション前に指定メソッド実行）
[BeforeFilter(Order = 2, methods = new string[] { "cart_check" },
    except = new string[] { "ThankYou", ... })]

// ユーザー認証（ECサイト）
[RequiresAuthentication(Order = 1, except = new string[] { "ThankYou", "Print", "CardAuth" })]

// クッキー認証（ECサイト・アクション単位）
[RequiresCookieAuthentication]

// 管理者認証（管理画面）
[RequiresNewAdminAuthenticationAttribute(ConnectionStringName = "callcenter_db", Site = "IB2016")]

// アクション実行ログ
[ActionExecuteLog]

// reCAPTCHA（フォーム送信時）
[ValidateReCaptcha]
```

### 16.6 PC / スマートフォン切替

- CloudFlare `CF-Device-Type` ヘッダーで自動判定
- `OzController` の `ReturnView()` メソッドが端末判定を行い、自動的に PC / SP ビューを切り替え
- `IsSmartPhone()` / `IsShowSpView()` で明示的な判定も可能
- `HomeController.ChangeBrowser()` でPC/SP手動切替

---

## 17. ビルド構成

| 構成 | 用途 | 備考 |
|------|------|------|
| `Debug` | ローカル開発 | キャッシュ使用あり（`use_cache_system = true`） |
| `Release` | 本番 | アクセスログ送信・エラーハンドラ有効 |
| `Staging` | ステージング | |
| `Test` / `Testing` | テスト | |

### Web.config 変換

- `Web.Debug.config` — ローカル設定
- `Web.Release.config` — 本番設定（Azure SQL接続文字列・APIキー切替）

---

## 18. DBマイグレーション（旧版リポジトリ）

`db_migrations/migrations/` に日付プレフィックスのマイグレーションファイル:

```
YYYYMMDDHHMMSS_migration_name.cs
```

- 最古のマイグレーション: `2009/` フォルダ内（2009年）
- 最新マイグレーション: `20210910081042_insert_first_record_to_consent_documents.cs`
- 300件以上のマイグレーションファイル
- 独自マイグレーションフレームワーク（EF Migrations ではない）

---

## 19. ファイル配置リファレンス

### ibeauty_store2016（現行）

| パス | 内容 |
|------|------|
| `ibeauty_store/Controllers/` | EC サイトコントローラー |
| `ibeauty_store/Views/` | EC サイトビュー |
| `ibeauty_store/ViewModels/` | EC サイト固有ViewModel（25カテゴリ） |
| `ibeauty_store/App_Start/` | ルーティング・フィルター・バンドル設定 |
| `ibeauty_store/ActionFilters/` | EC サイト固有フィルター |
| `ibeauty_store/Interface/` | EC サイト固有インターフェース |
| `ibeauty_store/OAuth/` | LINE ログイン実装 |
| `ibeauty_store/Content/` | CSS・画像 |
| `ibeauty_store/Script/` | JavaScript |
| `ibeauty_store.callcenter/Controllers/` | 管理画面コントローラー |
| `ibeauty_store.callcenter/Views/` | 管理画面ビュー |
| `ibeauty_store.callcenter/ViewModels/` | 管理画面固有ViewModel（44カテゴリ） |
| `ibeauty_store.callcenter/Utils/` | 管理画面ユーティリティ |
| `ibeauty_store.data/Models/` | LINQ to SQL エンティティ・操作クラス |
| `ibeauty_store.data/Models/Reports/` | レポートモデル |
| `ibeauty_store.data/ViewModels/` | 共有ViewModel（注文・メール・カート等） |
| `ibeauty_store.data/Attributes/` | カスタムバリデーション属性 |
| `ibeauty_store.data/Functions/` | ビジネスロジック |
| `ibeauty_store.data/Interfaces/` | データ層インターフェース |
| `ibeauty_store.data/ML/` | 機械学習データモデル |
| `ibeauty_store.common/BeautyCommon.cs` | 共通定数・設定 |
| `ibeauty_store.helpers/Functions/` | ヘルパー関数 |
| `ibeauty_store.helpers/Extensions/` | LINQ拡張 |
| `ibeauty_store.helpers/ActionFilters/` | ヘルパー側フィルター |
| `ibeauty_store.jobs/Jobs/` | バッチジョブ |
| `ibeauty_store.elasticsearch/` | Elasticsearch統合 |
| `ibeauty_store.ml/` | 機械学習（不正検知） |

### ibeauty_store（旧版リポジトリ）

| パス | 内容 |
|------|------|
| `ibeauty_store.callcenter/controllers/` | 旧管理画面コントローラー（32個） |
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
| `services/common_db/` | 共有DB操作 |
| `services/shipment/` | 配送関連 |
| `services/tracking/` | 追跡番号関連 |
| `services/blob/` | Azure Blob Storage |
| `services/csv/` | CSV出力 |
| `services/google/` | Google API連携 |
| `services/LINE/` | LINE連携 |
| `services/amazon/` | Amazon連携 |
| `services/yahoo/` | Yahoo!連携 |
| `services/rakuten-pay/` | 楽天ペイ |
| `libs/` | 画像編集、ページネーション等 |
