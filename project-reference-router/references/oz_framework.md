# oz_framework — Copilot 共通コンテキスト

## Response Policy

すべてのコミュニケーションとドキュメントは、必ず**日本語**で記述・応答してください。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| プロジェクト名 | oz_framework（OZグループ共通ライブラリ） |
| ソリューション | `oz_framework.sln` |
| フレームワーク | .NET Framework 4.0（extensions / services / libs） |
| 用途 | 複数 EC サイト・管理画面から Visual Studio **プロジェクト参照**で利用される共通基盤 |
| リポジトリ | Azure DevOps `ozinter/oz_framework` |
| パス | `d:\git_003\oz_framework` |

> **重要**: oz_framework は単独では動作せず、各サイトソリューション（mason_pearson.sln 等）から**相対パスでプロジェクト参照**される。変更時は全参照先への影響を必ず考慮すること。

---

## 2. ソリューション構成（プロジェクト一覧）

```
oz_framework.sln
├── oz_framework.extensions    ← 拡張メソッド・ヘルパー群
├── oz_framework.services      ← 共通サービス（コントローラー基盤・DAL・決済・認証等）
├── oz_framework.libs          ← 共通ユーティリティライブラリ
│
├── oz_framework.unittest      ← テスト基盤ユーティリティ（.NET 3.5）
├── oz_frameworkUnitTest       ← 単体テスト（MSTest 1.3.2 / .NET 4.7.1）
├── oz_framework.services.test ← サービス層テスト（MSTest 2.2.10 / .NET 4.7.2）
├── OnePayTest                 ← OnePay決済APIテスト（Console / .NET 4.0）
└── RakutenPayAPItest          ← 楽天ペイAPIテスト（Console / .NET 4.6.1）
```

### 参照元サイト一覧

| サイト | リポジトリ | 説明 |
|--------|-----------|------|
| mason_pearson2015 | `mason_pearson2015` | メイソンピアソン EC・管理画面 |
| ibeauty_store2016 | `ibeauty_store2016` | iBeautyStore EC・管理画面 |
| idrug_store2015 | `idrug_store2015` | iDrugStore 管理画面 |
| igeneric_store2018 | `igeneric_store2018` | iGenericStore EC・管理画面 |
| irx_medicine | `irx_medicine` | iRx Medicine 管理画面 |
| ozinter2015 | `ozinter2015` | OZ企業サイト・管理画面 |
| call_center | `call_center` | 共通管理画面(shared)・定期実行 |
| accounting | `accounting` | 経理向け管理画面 |
| ozshopping | `ozshopping` | 管理画面ログイン・権限設定 |

---

## 3. アーキテクチャ

### 3.1 レイヤー構成

```
┌──────────────────────────────────────────────────────────┐
│  各サイトプロジェクト                                      │
│  (mason_pearson, ibeauty_store2016, idrug_store2015 等)   │
└────────────────┬─────────────────────────────────────────┘
                 │ プロジェクト参照（相対パス）
┌────────────────▼─────────────────────────────────────────┐
│  oz_framework                                            │
│                                                          │
│  ┌─────────────────┐  ┌──────────────────────────────┐   │
│  │ extensions       │  │ services                     │   │
│  │ 拡張メソッド      │  │ コントローラー基盤            │   │
│  │ ヘルパークラス    │  │ データアクセス層              │   │
│  │ LINQ拡張         │  │ 認証・認可フィルター          │   │
│  │ 日本語処理       │  │ 決済処理                     │   │
│  │ URL操作          │  │ メール送信                   │   │
│  │ JSON操作         │  │ セキュリティ                 │   │
│  │ HTML生成         │  │ ロギング                     │   │
│  └─────────────────┘  │ HTTP通信                     │   │
│                        │ 外部API連携                  │   │
│  ┌─────────────────┐  │ 配送・追跡                   │   │
│  │ libs             │  │ PCA会計連携                  │   │
│  │ 画像編集         │  │ キャッシュ管理               │   │
│  │ 日本語マッピング  │  │ バリデーション               │   │
│  │ ページネーション  │  └──────────────────────────────┘   │
│  │ 動的述語構築     │                                    │
│  │ 楽天/ポンパレAPI  │                                    │
│  └─────────────────┘                                     │
└──────────────────────────────────────────────────────────┘
```

### 3.2 プロジェクト間依存関係

```
oz_framework.extensions
  └── (依存なし、最下層)

oz_framework.libs
  └── oz_framework.extensions

oz_framework.services
  ├── oz_framework.extensions
  └── oz_framework.libs
```

### 3.3 コントローラー継承チェーン

```
System.Web.Mvc.Controller
  └── OzController                   (oz_framework.services/controller/)
        └── ApplicationController    (各サイトプロジェクトで定義)
              └── 各Controller       (各サイトの個別コントローラー)
```

---

## 4. oz_framework.extensions（拡張メソッド・ヘルパー）

### 4.1 プロジェクト基本情報

| 項目 | 内容 |
|------|------|
| ターゲット | .NET Framework 4.0 |
| 名前空間 | `oz_framework.extensions` |
| 主要依存 | System.Web.Mvc 3.0, NMeCab 0.0.6.4, Microsoft.Office.Interop.Excel |

### 4.2 ファイル・クラス一覧

| ファイル | クラス | 対象型 | 主要メソッド | 用途 |
|---------|--------|--------|-------------|------|
| `string.cs` | StringExtension | `string` | `format()`, `is_numeric()`, `to_url()`, `left()`, `leftB()`, `lenB()`, `truncate()`, `safe_parse_xxx()`, `no_tag()`, `to_date()`, `to_masked_email()`, `to_zenkaku_hankaku()`, `to_hankaku_zenkaku()` | 文字列操作・日本語変換 |
| `object.cs` | ObjectExtension | `object` | `is_empty()`, `not_empty()`, `to_s()`, `to_i()`, `to_json()`, `get_property()`, `set_property()`, `call()`, `property_exists()` | 汎用オブジェクト操作 |
| `numeric.cs` | NumericExtension | `int` | `mod()`, `RoundOff()`, `null_if_0()`, `between()`, `to_enum<T>()`, `not_in()` | 数値ユーティリティ |
| `collection.cs` | CollectionExtension | `Dictionary`, `List` | `get_value_or_default()`, `add_range()`, `to_list_table()`, `to_group()`, `to_dropdown()` | コレクション操作 |
| `controller.cs` | ControllerExtension | — | *(空クラス — 将来予約)* | — |
| `form_collection.cs` | FormCollectionExtension | `FormCollection` | `bind_to()`, `get_model_list_in_form()` | フォームバインディング |
| `json.cs` | JsonHelper | *(static)* | `Parse()`, `Serialize()` | 低レベルJSON処理 |
| `humanize.cs` | HumanizeExtension | `string`, `int`, `float`, `double` | `titleize()`, `down_case()`, `monetize()`, `monetize_simple()`, `numerize()` | 表示フォーマット |
| `linq.cs` | LinqExtension | `IQueryable`, `IEnumerable`, `Expression` | `from_cache_or_db()`, `split_to_chunk()`, `BuildOrExpression()`, `BuildWhereExpression()` | LINQ拡張・キャッシュ |
| `html_helper.cs` | HtmlHelperExtension | `HtmlHelper` | `Clear()`, `DivSeparator()`, `Graphics()`, `SubmitImage()`, `BeginForm()`, `ExternalLink()` | HTML生成 |
| `array.cs` | ArrayExtension | `int[]`, `string[]` | `same_as()`, `to_integer_array()`, `to_integer_list()` | 配列操作 |
| `data_reader.cs` | DataReaderExtension | `IDataReader` | `to_data_table()` | DataReader変換 |
| `data_row.cs` | DataRowExtension | `DataRow` | `to_json_friendly()` | DataRow→辞書 |
| `data_table.cs` | DataTableExtension | `DataTable` | `to_json_friendly()` | DataTable→JSON用 |
| `dictionary.cs` | DictionaryExtension | `Dictionary` | `get_value_or_default()`, `add_range()` | 辞書操作 |
| `directory.cs` | DirectoryExtension | *(static)* | `create_folder()` | ディレクトリ再帰作成 |
| `Enum.cs` | EnumHelper | *(static)* | `GetSelectListItems()` | Enum→SelectList変換 |
| `form_helper.cs` | FormHelper | *(static)* | `is_checkbox_checked()` | チェックボックス判定 |
| `http_server_utility.cs` | HttpServerUtilityExtension | `HttpServerUtility` | `html_encode()` | 制限的HTMLエンコード |
| `io.cs` | IOExtension | `Stream` | `to_byte_array()` | Stream→バイト配列 |
| `jis_utility.cs` | JisUtilityExtension | `string`, `char` | `IsJISX0208()`, `ConvertToJISX0208()` | JIS文字フィルタ |
| `mail_message.cs` | MailMessageExtension | `MailMessage` | `save()` | eml保存 |
| `path.cs` | CommonPath | *(static)* | `ContentPath`, `ImagePath`, `StylesheetPath` 等 | パス定数 |
| `url.cs` | UrlExtension | `string` | `to_absolute_url()`, `to_ssl_url()`, `to_ssl_if_release()`, `to_http_url()`, `remove_xss()`, `append_query_strings()`, `break_query_string()` | URL操作・SSL制御 |
| `view_data_dictionary.cs` | ViewDataDictionaryExtension | `ViewDataDictionary` | `get_model_state_value()` | ModelState値復元 |

### 4.3 特に多用される拡張メソッド

> **各サイトの全コードで極めて頻繁に使用される。改修時は互換性に最大限注意。**

| メソッド | 用法 | 説明 |
|---------|------|------|
| `not_empty()` | `obj.not_empty()` | null / 空文字 / 空コレクションでなければ true |
| `is_empty()` | `obj.is_empty()` | null / 空文字 / 空コレクションなら true |
| `to_s()` | `obj.to_s()` | 安全な文字列変換（null → ""） |
| `to_i()` | `obj.to_i()` | 安全なInt32変換（失敗 → 0） |
| `format()` | `"text {0}".format(value)` | `string.Format()` のラッパー |
| `to_json()` | `obj.to_json()` | JSONシリアライズ |
| `monetize()` | `price.monetize()` | 通貨表示（¥1,234） |

---

## 5. oz_framework.services（共通サービス）

### 5.1 プロジェクト基本情報

| 項目 | 内容 |
|------|------|
| ターゲット | .NET Framework 4.0 |
| 名前空間 | `oz_framework.services` |
| 主要依存 | System.Web.Mvc 3.0, NLog 1.0, Newtonsoft.Json 11.0, Ninject 1.5 |

### 5.2 ディレクトリ構成と機能一覧

#### コア機能

| ディレクトリ | 主要クラス | 機能 |
|-------------|-----------|------|
| `controller/` | `OzController` | 全コントローラーの抽象基底クラス |
| `data_access_layer/` | `BaseModel`, `DataAccessLayer`, `SqlTranHelper` | ORM基盤・SQL実行・トランザクション管理 |
| `action_filter/` | 認証/認可/セキュリティフィルター群 | ASP.NET MVCアクションフィルター |
| `security/` | `Security`, `Password`, `IpAddress`, `AccessCheck`, `CallCenter` | セキュリティ・認証 |
| `Common.cs` | `Common` | 共通定数・ユーティリティ・IP判定 |

#### インフラストラクチャ

| ディレクトリ | 主要クラス | 機能 |
|-------------|-----------|------|
| `logging/` | `NLogLogger` (ILogger), `Record`, `IISCustomErrorLogger`, `DbLogger` | NLogロギング・DB保存 |
| `caching/` | *(CacheManager — コメントアウト中)* | *(Memcached — 現在未使用)* |
| `http/` | `Http` | HTTP GET/POST/JSON/Delete 通信（TLS 1.2+） |
| `json/` | `JsonResponse`, `JsonSerializerAlternative` | JSON応答ヘルパー |
| `csv/` | `CsvCreator` | DataTable→CSV変換 |
| `date_time/` | `DateTimeExtension`, `JST` | 日付操作・和暦変換・JST取得 |
| `blob/` | `BlobFunctionsClient` | Azure Blob Storage操作（Azure Functions経由） |
| `cloud_flare/` | `CloudFlare` | CDNキャッシュ管理 |
| `common_db/` | `OzCallCenterDB`, `SharedDB` | 共通DB接続（callcenter_db, shared_db） |
| `serializer/` | `Serializer` | バイナリシリアライゼーション |
| `template/` | `Render` | テンプレートレンダリング |
| `file_uploader/` | `FileUploader` | ファイルアップロード管理 |
| `parallel_proc/` | `MutexHelper` | 排他制御（Mutex） |
| `shell/` | `Shell` | 外部プロセス実行 |
| `excel_reader/` | `ExcelReader` | Excel読み込み |
| `qrcode/` | `QRCode` | QRコード生成（GIF） |
| `pagination/` | `Pagination`, `MobilePagination` | ページネーションHTML生成 |

#### 決済

| ディレクトリ | 主要クラス | 機能 |
|-------------|-----------|------|
| `payment/` | `Payment`, `PaymentMethod`, `PaymentManage` | 決済ファサード・抽象基底・メンテナンス管理 |
| `payment/credit_card/` | `CreditCard` | クレジットカード決済 |
| `payment/chocom_credit_card/` | `ChocomCreditCard` | チョコムクレジット |
| `payment/chocom_convini/` | `ChocomConvini` | チョコムコンビニ |
| `payment/gmo_credit_card/` | `GmoCreditCard` | GMOクレジット |
| `payment/gmo_atobarai/` | `GmoAtobarai` | GMO後払い |
| `payment/cash_on_delivery/` | `CashOnDelivery` | 代金引換 |
| `payment/bank/` | `Bank` | 銀行振込 |
| `payment/convenience_store/` | `ConvenienceStore` | コンビニ決済基底 |
| `payment/invoice/` | `Invoice` | 請求書払い |
| `payment/alipay/`・`wechat_pay/` | `Alipay`, `WechatPay` | 中国系決済 |
| `payment/yahoo-paypay/` | `YahooPaypay` | PayPay |

#### メール

| ディレクトリ | 主要クラス | 機能 |
|-------------|-----------|------|
| `mailer/` | `Mailer`, `RakutenMailer`, `CueNote`, `Pop3` | メール送信・受信・マーケティング |

#### 外部API連携

| ディレクトリ | 主要クラス | 機能 | 利用状況 |
|-------------|-----------|------|---------|
| `amazon/` | `AmazonApiClient` | Amazon出品者API | 現在店舗なし |
| `yahoo/` | Yahoo OAuth2/OpenID | Yahoo!認証API | 利用中 |
| `rakuten-pay/` | `RakutenPayAPI` | 楽天ペイAPI | 未使用 |
| `LINE/` | `LinePayClient` | LINE Pay決済 | 未使用 |
| `one_pay/` | OnePay API | 給与天引き決済 | 利用中 |
| `OpenID/` | `LineLogin`, Yahoo認証 | OpenID Connect / OAuth2 | 利用中 |
| `google/` | `GoogleAnalytics` | Google Analytics | 利用中 |
| `pca/` | `Pca` | PCA会計ソフト連携 | 利用中 |

#### 配送・物流

| ディレクトリ | 主要クラス | 機能 |
|-------------|-----------|------|
| `shipment/` | `Logimecs` | ロジメック倉庫 配送連携 |
| `tracking/` | `Tracking` | 配送追跡（日本郵便/佐川/ヤマト/FedEx等） |
| `tracking_check/` | `TrackingCheckFunctionsClient` | Azure Functions経由 追跡確認 |

#### その他

| ディレクトリ | 主要クラス | 機能 | 利用状況 |
|-------------|-----------|------|---------|
| `validation/` | `Validate`, 各種条件クラス | フォームバリデーション | 利用中 |
| `smart_phone/` | `SmartPhone` | スマートフォンUA判定 | 利用中 |
| `mobile/` | `MobileAssister`, `Emoji` | フィーチャーフォン判定・絵文字 | レガシー |
| `search/` | `BeautyQuery`, `IndexBuilder` | Lucene.NET全文検索 | 未使用 |
| `black_list/` | `SharedBlackLists` | サイト横断ブラックリスト | 利用中 |
| `report/` | `Ltv` | LTV集計 | 利用中 |
| `rss/` | `Rss` | RSSフィード取得 | 利用中 |
| `zip/` | `Zip` | 郵便番号検索 | 未使用 |
| `gmarket/` | — | Gマーケット | 未使用 |
| `oz_call_center/` | — | コールセンター旧版 | 未使用 |

---

### 5.3 OzController（基底コントローラー）

```csharp
public abstract class OzController : Controller
```

**名前空間**: `oz_framework.services`

| メンバー | 説明 |
|---------|------|
| `set_doc_title(string)` | ページタイトル追加 |
| `keep_model_state()` | フォームバリデーション時のModelState保持 |
| `is_referer(string)` | リファラーURLチェック |
| `create_redirect_after_login(string)` | ログイン後リダイレクト先をセッションに保存 |
| `expires_page()` | ページキャッシュ無効化 |
| `add_cookie()` / `get_cookie()` / `delete_cookie()` | Cookie 操作 |
| `authenticate_cookie()` | HTTPS認証Cookie検証 |
| `trace_write(object)` | トレースログ出力 |
| `ReturnView()` | PC / スマートフォンビュー自動切替 |
| `IsSmartPhone()` / `IsShowSpView()` | 端末判定 |
| `GetAccessIpAddress()` | クライアントIP取得 |

**定数**:
- `AUTHENTICATE_COOKIE_NAME = "authentication_cookie"`
- `AUTHENTICATE_COOKIE_PASSWORD = "JFXmsdjOu3FjaBaB"`

---

### 5.4 BaseModel（データアクセス基盤）

```csharp
public partial class BaseModel
```

**名前空間**: `oz_framework.services`

#### インスタンスメソッド

| メソッド | 説明 |
|---------|------|
| `Save(DataContext)` | InsertOnSubmit + SubmitChanges（新規登録） |
| `Update(DataContext)` | SubmitChanges（更新） |
| `Delete(DataContext)` | DeleteOnSubmit + SubmitChanges（削除） |
| `CopyDataFrom(BaseModel)` | 別モデルからプロパティコピー |
| `CopyDataFrom(FormCollection)` | フォームデータからバインド |
| `Bind(NameValueCollection)` | フォーム値を自動バインド（チェックボックス対応） |
| `IsValid(Controller)` | バリデーション実行 |
| `GetColumns()` | `[Column]` 属性付きプロパティ一覧取得 |
| `RecordType` | Mode.New / Mode.Update を自動判定 |
| `UpdateTimestampIfExist()` | created_at / updated_at 自動更新 |

#### Staticメソッド（SQL直接実行）

| メソッド | 説明 |
|---------|------|
| `execute_non_query(string conn, string sql)` | UPDATE/DELETE/INSERT実行 |
| `execute_sp(string conn, string sp_name)` | ストアドプロシージャ実行 |
| `get_by_sql(string conn, string sql)` | SELECT → DataTable |
| `get_scalar_by_sql(string conn, string sql)` | SELECT スカラー値取得 |
| `get_list_by_sql<T>(string conn, string sql)` | SELECT → List<T>（リフレクション自動マッピング） |
| `get_length<TTable>(string property)` | NVarChar(n) のサイズ取得 |

#### Mode Enum

```csharp
public enum Mode { New, Update }
```

---

### 5.5 SqlTranHelper（トランザクション管理）

```csharp
public class SqlTranHelper : IDisposable
```

| メソッド | 説明 |
|---------|------|
| `execute_non_query(string sql)` | トランザクション内SQL実行 |
| `execute_non_query(string sql, Predicate<int>)` | 影響行数チェック付き実行（条件不一致でROLLBACK） |
| `commit()` | COMMIT & Close |
| `roll_back()` | ROLLBACK & Close |
| `Dispose()` | 自動COMMIT |

---

### 5.6 認証・認可フィルター

| フィルター | 用途 | 主要プロパティ |
|-----------|------|--------------|
| `RequiresAuthentication` | ECサイトユーザー認証 | `https`, `except[]`, `redirect_to_route` |
| `RequiresAdminAuthentication` | 管理者認証（旧） | `ConnectionStringName` |
| `RequiresNewAdminAuthentication` | 管理者認証（新・CallCenter） | `ConnectionStringName`, `Site` |
| `RequiresSharedAuthentication` | 共有機能アクセス認証 | `ConnectionStringName` |
| `RequiresSystemAdminAuthentication` | システム管理者認証 | `ConnectionStringName` |
| `InternalIpsOnly` | 内部IP制限（OZサーバーのみ） | — |
| `ValidateReCaptcha` | Google reCAPTCHA v2 検証 | — |
| `ValidateReCaptchaV3` | Google reCAPTCHA v3 検証（スコアベース） | — |
| `CompressFilter` | GZIP/DEFLATE レスポンス圧縮 | — |
| `DealWithError` (= ErrorHandler) | エラーハンドリング + NLog出力 | — |
| `RequiresSSL` / `ToHttp` | HTTPS強制 / HTTP強制 | — |
| `RedirectIfMaintenance` | メンテナンスモード時リダイレクト | — |
| `SaveRequestLog` | HTTPリクエストログDB保存 | — |
| `SetDocTitle` | ドキュメントタイトル自動設定 | — |
| `BeforeFilter` | リフレクションによる前処理メソッド実行 | — |

---

### 5.7 セキュリティ

#### Security クラス（static）

| メソッド | 説明 |
|---------|------|
| `md5_hash(string)` | MD5ハッシュ |
| `sha_hash(string)` | SHA512ハッシュ |
| `EncryptString(string, string key)` | DES暗号化 |
| `DecryptString(string, string key)` | DES復号化 |

#### Password クラス（static）

| メソッド | 説明 |
|---------|------|
| `salt(int)` | ランダムソルト生成 |
| `unique_salt(int, ...)` | DBでユニークなソルト生成 |
| `random_password` | 8文字ランダムパスワード |
| `hash(string, string salt)` | パスワード + ソルトを SHA512 ハッシュ |

#### IpAddress クラス（static）

| 定数 | 説明 |
|------|------|
| `Oz[]` | OZサーバーIPアドレス群 |
| `ChocomConvenience[]` | ちょコムコンビニIP |
| `Efuri[]` | 電算システムIP |
| `Onepay[]` | OnePayサーバーIP |
| `SCT[]` | セキュリティチェックIP |

#### AccessCheck クラス（static）

ブルートフォース攻撃対策。テーブル: `login_failed`, `blocked_ip_address`

| メソッド | 説明 |
|---------|------|
| `LoginFailedAdd(string ip)` | 失敗ログイン記録（30分内20回でIPブロック） |
| `IsBlockedIpAddress(string ip)` | IPブロック判定 |
| `ReleaseBlockedIpAddress(int id)` | ブロック解除 |
| `NeedSendAlertEmail(string ip)` | アラートメール送信判定 |

#### CallCenter クラス（static）

コールセンター認証・管理。

**定数**:
- `SYSTEM_REQUEST_PASSWORD = "zW2yIEjo"`
- `COOKIE_NAME_USER_ID = "USER_ID"`
- `COOKIE_NAME_SESSION_ID = "OZ_SESSION_ID"`
- `SESSION_NAME_CALLCENTER_USER = "CALLCENTER_USER"`

**内部クラス**:
- `User` — id, name, real_name, email, session_id, naisen, user_roles
- `Role` — site, controller, action
- `AccessLogResponse` — Success, Deny, RedirectToLogin, AdminSuccess

---

### 5.8 決済システム

#### 決済フロー

```
Payment (ファサード / Ninject DI)
  ↓ get_payment(payment_method)
PaymentMethod (抽象基底)
  ↓ pay(NameValueCollection, Payment.Data)
    1. extract_payment_data()
    2. pay_up()       ← 外部API通信
    3. construct_payment_result()
    4. log_transaction()
  ↓
Result { is_success, receipt_no, message, ... }
```

#### 対応決済方法

| 決済方法 | クラス | ディレクトリ |
|---------|--------|------------|
| クレジットカード（VISA/Master/JCB/AMEX/Diners/42種） | `CreditCard` | `payment/credit_card/` |
| チョコムクレジット | `ChocomCreditCard` | `payment/chocom_credit_card/` |
| チョコムコンビニ | `ChocomConvini` | `payment/chocom_convini/` |
| GMOクレジット | `GmoCreditCard` | `payment/gmo_credit_card/` |
| GMO後払い | `GmoAtobarai` | `payment/gmo_atobarai/` |
| 代金引換 | `CashOnDelivery` | `payment/cash_on_delivery/` |
| 銀行振込（三菱UFJ） | `Bank` | `payment/bank/` |
| コンビニ決済 | `ConvenienceStore`（抽象） | `payment/convenience_store/` |
| 請求書払い | `Invoice` | `payment/invoice/` |
| PayPay | `YahooPaypay` | `payment/yahoo-paypay/` |
| Alipay | `Alipay` | `payment/alipay/` |
| WeChat Pay | `WechatPay` | `payment/wechat_pay/` |
| LINE Pay | `LinePayClient` | `LINE/LINE_Pay/` |
| OnePay | OnePay API | `one_pay/` |

#### PaymentManage（決済メンテナンス管理）

**SiteType Enum**:
```
All, iBeautyStore, iDrugStore, iRxmedicine, iGenericStore, Masonpearson
```

**PaymentType Enum**:
```
credit_card, cash_on_delivery, pelican_cash_on_delivery,
postal, bank, ufg_e_payment, seven_eleven, lawson, family_mart,
circle_k_and_others, LawsonOrSeicoMart, Convini_All
```

---

### 5.9 メール送信

#### Mailer クラス（static）

| メソッド | 説明 |
|---------|------|
| `send(from, to, subject, body)` | メール直接送信 |
| `load_email_file(file)` | ascxテンプレートロード |
| `send_alert_to_it(subject, body)` | IT管理者へアラートメール |
| `bulk_send(List<BulkMailData>)` | 一括送信 |

**SmtpHost Enum**: Default (Cuenote), Cuenote, OneOffice

#### CueNote クラス（static）

| メソッド | 説明 |
|---------|------|
| `get_block_count_all()` | 送信失敗メール一覧 |
| `get_block_count(email)` | 特定メール失敗カウント |
| `reset_block_count(email)` | 失敗カウント初期化 |

---

### 5.10 ロギング

| クラス | 説明 |
|--------|------|
| `NLogLogger` (ILogger) | NLogベースのロガー（Info/Warn/Debug/Error/Fatal） |
| `Record` | NLoggerシングルトンアクセス（`Record.Log`） |
| `IISCustomErrorLogger` | IISカスタムエラーのDB記録（`log.iis_custom_errors`） |
| `DbLogger` (IRequestLogger) | HTTPリクエストログのDB保存 |

**ログフォーマット**: `[{DateTime} {method_name} {caller_method}] {message}`

**DbLogger SchemaType（DB名）**:
- iDrugStore → `idoz0804db`
- iBeautyStore → `ibtoz0804db`
- iRxMedicine → `irxoz0804db`
- iGenericStore → `igeoz0805db`

---

### 5.11 バリデーション

```csharp
Validate validate = new Validate(Request);
validate.add("field_name", new PresenceOf().message("必須です"));
validate.add("email", new FormatOf().with(@"^[\w\.\-]+@[\w\-]+\.[\w\.]+$").message("形式が正しくありません"));
bool is_valid = validate.is_correct();
```

| 条件クラス | 説明 |
|-----------|------|
| `PresenceOf` | 必須入力 |
| `FormatOf` | 正規表現マッチ（`with(pattern)`） |
| `NumericalityOf` | 数値（最小/最大/範囲） |
| `IntegerOf` | 整数 |
| `DigitOf` | 数字 |
| `SelectionOf` | リスト選択 |
| `UniquenessOf` | ユニーク性 |
| `ImageValidator` | 画像検証 |

---

### 5.12 日付操作

| メソッド / クラス | 説明 |
|-----------------|------|
| `JST.now` | 日本標準時の現在時刻 |
| `JST.epoch_seconds` | UNIXタイムスタンプ |
| `to_japanese_format()` | 「2024年1月1日」形式 |
| `to_japanese_wareki_date()` | 和暦変換（令和対応） |
| `date_with_day()` | 「2024年1月1日(月)」形式 |
| `in_words()` | 「昨日」「今週」等のテキスト |
| `between(from, to)` | 期間内判定 |
| `first_of_month()` / `end_of_month()` | 月初/月末 |

---

### 5.13 HTTP通信

```csharp
var http = new Http();
http.header = new WebHeaderCollection();
http.encoding = Encoding.UTF8;
// TLS 1.2+ 必須

string result = http.Post(url, data);
string result = http.PostJson(url, json_data);
string result = http.Get(url);
```

---

### 5.14 JSON応答ヘルパー

```csharp
// コントローラーでのJSON応答
return JsonResponse.Success(new { html = "...", count = 10 });
return JsonResponse.NotSuccess(new { message = "エラー" });
```

---

## 6. oz_framework.libs（共通ライブラリ）

### 6.1 プロジェクト基本情報

| 項目 | 内容 |
|------|------|
| ターゲット | .NET Framework 4.0 |
| 名前空間 | `oz_framework.libs` |

### 6.2 モジュール一覧

| ディレクトリ | クラス | 機能 | 利用状況 |
|-------------|--------|------|---------|
| `image_editor/` | `ImageEditor` | 画像リサイズ・圧縮（resize, save_to_jpeg） | 利用中 |
| `japanese/` | `Japanese` | 半角⇔全角、ひらがな⇔カタカナの辞書マッピング変換 | 利用中 |
| `pagination/` | `PagingInfo` | ページネーションUI生成（ITEMS_PER_PAGE=50） | 利用中 |
| `predicate_builder/` | `PredicateBuilder` | LINQ動的述語構築（True/False/Or/And） | 利用中 |
| `ponpare/` | `PonpareApi` | ポンパレモールAPI（在庫/注文/決済） | レガシー |
| `rakuten/` | `RakutenApi` | 楽天市場API（在庫/注文/RCCS） | レガシー |

---

## 7. テストプロジェクト

| プロジェクト | FW | テストFW | テスト対象 |
|-------------|-----|---------|-----------|
| `oz_frameworkUnitTest` | .NET 4.7.1 | MSTest 1.3.2 | extensions（文字列変換）、LINE Pay、logging |
| `oz_framework.services.test` | .NET 4.7.2 | MSTest 2.2.10 | BaseModel（DB操作 — shared_db） |
| `oz_framework.unittest` | .NET 3.5 | *(ユーティリティ)* | テスト基盤（Fixture, TemplateMachine, JsonHelper） |
| `OnePayTest` | .NET 4.0 | *(Console実行)* | OnePay API（34テストクラス） |
| `RakutenPayAPItest` | .NET 4.6.1 | *(Console実行)* | 楽天ペイAPI |

---

## 8. 設定キー一覧（web.config）

oz_framework が参照する `appSettings` および接続文字列キー。

### 接続文字列

| キー | 用途 |
|------|------|
| `shared_db` | 共有DB |
| `callcenter_db` | コールセンター認証DB |
| *(各サイト固有)* | 各サイトメインDB |

### appSettings

| キー | 用途 |
|------|------|
| `perform_logging` | ロギング有効/無効 |
| `log_directory` | ログファイル出力先 |
| `application_name` | アプリケーション名（ログファイル名に使用） |
| `google_recaptcha_secret_key` | reCAPTCHA シークレットキー |
| `cloud_flare_zone_id` | CloudFlare ゾーンID |
| `cloud_flare_api_key` | CloudFlare APIキー |
| `cloud_flare_email` | CloudFlare メールアドレス |
| `cache_host` / `cache_port` / `cache_password` / `cache_number` | Redis接続 |
| `oz_ip_1` ～ `oz_ip_6` | OZサーバーIP（動的定義） |

---

## 9. 改修時の注意事項

### 9.1 影響範囲の確認

> **oz_framework のすべての変更は、参照元の全サイト（8+プロジェクト）に波及する。**

改修前チェックリスト:
1. **既存メソッドのシグネチャ変更** → 全参照先でコンパイルエラーとなる。オーバーロード追加を推奨
2. **拡張メソッドの挙動変更** → `is_empty()`, `not_empty()`, `to_i()`, `to_s()` は全サイトで多用。互換性必須
3. **BaseModel の変更** → 全サイトのエンティティモデルに影響
4. **OzController の変更** → 全サイトのコントローラー基底に影響
5. **認証フィルターの変更** → 全サイトのアクセス制御に影響

### 9.2 コーディング規約

| 規約 | 例 |
|------|-----|
| 命名規則 | スネークケース（`snake_case`） — クラス名のみパスカルケース |
| ファイル名 | スネークケース（`base_model.cs`, `oz_controller.cs`） |
| null チェック | `obj.not_empty()` / `obj.is_empty()` を使用（`!= null` は使わない） |
| 文字列フォーマット | `"text {0}".format(value)` を使用（`$""` 補間は使わない） |
| 型変換 | `obj.to_i()`, `obj.to_s()` を使用 |
| JSON応答 | `JsonResponse.Success()` / `JsonResponse.NotSuccess()` |
| ログ出力 | `Record.Log.Info()`, `Record.Log.Error()` |

### 9.3 ブランチ運用

> 各参照プロジェクトが必要な際に更新を行いPushする運用。  
> 各プロジェクトで変更を行った場合は、他者が変更を加えている可能性がある為、必ず最新をFetchすること。

### 9.4 ビルド構成

| 構成 | 用途 | プリプロセッサ |
|------|------|-------------|
| Debug | ローカル開発 | `DEBUG` |
| Release | 本番 | `RELEASE` |
| Testing | テスト | `TESTING` |

プリプロセッサ指令の使用箇所:
- `#if DEBUG || TESTING` — SSL強制をスキップ（url.cs 等）
- `#if RELEASE` — ログファイル名の動的設定、認証強制

### 9.5 外部ライブラリ（dependencies/）

NuGet パッケージではなく、`dependencies/` ディレクトリに配置されたDLLを直接参照する方式。

**extensions/dependencies/**:
- `asp.net.mvc/` — System.Web.Mvc 3.0
- `nmecab/` — NMeCab 0.0.6.4（日本語形態素解析）

**services/dependencies/**:
- 各種外部DLL（NLog, Newtonsoft.Json, Ninject 等）

### 9.6 DB操作パターン

```csharp
// LINQ to SQL（DataContext経由）
var entity = new Entity();
entity.property = value;
entity.Save(DB.context);            // INSERT
entity.Update(DB.context);          // UPDATE
entity.Delete(DB.context);          // DELETE

// SQL直接実行（BaseModel static）
var dt = BaseModel.get_by_sql("shared_db", "SELECT * FROM table WHERE id = 1");
BaseModel.execute_non_query("shared_db", "UPDATE table SET col = 'val' WHERE id = 1");
var list = BaseModel.get_list_by_sql<MyClass>("shared_db", "SELECT * FROM table");

// トランザクション
using (var tran = new SqlTranHelper("connection_string_name"))
{
    tran.execute_non_query("INSERT INTO ...");
    tran.execute_non_query("UPDATE ...", count => count == 1);
    tran.commit();
}
```

### 9.7 ビュー表示パターン

```csharp
// PC / SP 自動切替
return ReturnView(viewModel);

// JSON応答（管理画面AJAX）
return JsonResponse.Success(new { html = "...", count = 10 });
return JsonResponse.NotSuccess(new { message = "エラー" });
```

### 9.8 認証フィルター使用パターン

```csharp
// ECサイトユーザー認証
[RequiresAuthentication(Order = 1, https = true)]

// 管理者認証（RELEASE時のみ）
#if RELEASE
[RequiresNewAdminAuthentication(ConnectionStringName = "callcenter_db", Site = "MP")]
#endif

// reCAPTCHA検証
[ValidateReCaptcha]
[ValidateReCaptchaV3]

// 内部IP制限
[InternalIpsOnly]

// エラーハンドリング
[ErrorHandler]
```

---

## 10. ファイル配置リファレンス

| パス | 内容 |
|------|------|
| `extensions/string.cs` | string 拡張メソッド（format, is_numeric, 日本語変換等） |
| `extensions/object.cs` | object 拡張メソッド（is_empty, not_empty, to_s, to_i等） |
| `extensions/numeric.cs` | int 拡張メソッド（mod, between, to_enum等） |
| `extensions/collection.cs` | Dictionary/List 拡張 |
| `extensions/linq.cs` | IQueryable/IEnumerable 拡張（キャッシュ付きクエリ, Expression構築） |
| `extensions/html_helper.cs` | HtmlHelper 拡張（HTML要素生成） |
| `extensions/humanize.cs` | 表示フォーマット（通貨, 数値） |
| `extensions/url.cs` | URL操作・SSL制御 |
| `extensions/json.cs` | JSONパーサー |
| `extensions/jis_utility.cs` | JIS文字判定 |
| `services/Common.cs` | 共通定数・ユーティリティ |
| `services/controller/oz_controller.cs` | 基底コントローラー |
| `services/data_access_layer/base_model.cs` | データアクセス基盤 |
| `services/data_access_layer/data_access_layer.cs` | SQL直接実行層 |
| `services/data_access_layer/sql_tran_helper.cs` | トランザクション管理 |
| `services/action_filter/` | 認証・認可・セキュリティフィルター |
| `services/security/` | ハッシュ・暗号化・IP制限・アクセスチェック |
| `services/payment/` | 決済処理（チョコム/GMO/PayPay/Alipay等） |
| `services/mailer/` | メール送信（Cuenote/SMTP） |
| `services/logging/` | NLogロギング・DB保存 |
| `services/http/http.cs` | HTTP通信（TLS 1.2+） |
| `services/json/json_response.cs` | JSON応答ヘルパー |
| `services/date_time/` | 日付操作・和暦・JST |
| `services/blob/` | Azure Blob Storage |
| `services/cloud_flare/` | CDNキャッシュ管理 |
| `services/common_db/` | 共通DB接続 |
| `services/validation/` | フォームバリデーション |
| `services/shipment/` | ロジメック配送 |
| `services/tracking/` | 配送追跡 |
| `services/pca/` | PCA会計連携 |
| `services/OpenID/` | OpenID Connect / OAuth2 |
| `libs/image_editor/` | 画像リサイズ・圧縮 |
| `libs/japanese/` | 半角⇔全角、ひらがな⇔カタカナ辞書 |
| `libs/pagination/` | ページネーションUI |
| `libs/predicate_builder/` | LINQ動的述語構築 |
