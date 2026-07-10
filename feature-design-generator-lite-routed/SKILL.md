---
name: feature-design-generator-lite-routed
description: "要件文とワークスペースの低コストな手掛かりから対象プロジェクトを絞り込み、該当する project reference と必要な shared reference だけを段階的に読み込んで、設計概要を生成する軽量版スキル。コード変更は行わず、読み取り専用で調査する。"
---

# 機能追加 設計概要ジェネレーター（ルーティング強化版）

## 目的
要件文から対象ドメインを特定し、既存コードベースの実装パターンに合わせた設計概要を、**低コストかつ誤判定を抑えて** 段階的に生成する。

- 初回は対象プロジェクトの推定と入口調査に限定する
- project reference は候補に絞って読む
- shared reference は必要条件に一致した場合のみ読む
- 実装で確認できた事実と推測を分ける

## 重要ルール
- 基本は読み取り専用で実施する
- ユーザーが明示しない限りコード変更を行わない
- 生成物は日本語で記載する
- 初回は必ず Phase 1 のみ実施する
- 初回判定のためにワークスペース全体を深く走査しない
- 確信度が低いまま単一プロジェクト前提で断定しない
- 一度に大量ファイルを横断要約しない

## 参照ファイルの役割

### Project references
対象プロジェクトが特定または候補化できた時に読む。初回は **最大2件まで**。

- `references/projects/iDrugStore.md`
- `references/projects/iRx-Medicine.md`
- `references/projects/ibeauty_store.md`
- `references/projects/ibeauty_store2016.md`
- `references/projects/igeneric_store2018.md`
- `references/projects/mason.md`

### Project 判定キーワード表
初回判定では、以下の表を「候補化のための目安」として使う。単独キーワードだけで断定せず、`.sln`、`csproj`、ディレクトリ名、要件文の固有語と合わせて判断する。

| Project reference | 主なプロジェクト名 / solution 名 | 業務・画面キーワード例 | 補助キーワード / 入口候補 |
|---|---|---|---|
| `references/projects/iDrugStore.md` | `iDrugStore`, `iDrugStore.Callcenter`, `iDrugStore.Models` | `薬`, `医薬品`, `注文`, `カート`, `決済`, `配送`, `コールセンター` | `OrderController`, `CartController`, `HomeController`, `ServiceFactory`, `idoz0804db`, `calloz0805db` |
| `references/projects/iRx-Medicine.md` | `iRx-Medicine`, `iRx-Medicine.Models` | `処方`, `薬局`, `服薬`, `問診`, `予約`, `診療`, `管理画面` | `IRx`, `Medicine`, `Prescription`, `irxoz0804db`, `shared`, `calloz0805db` |
| `references/projects/ibeauty_store.md` | `ibeauty_store`, `mason_pearson.sln` 配下の iBeauty 構成 | `美容`, `サロン`, `施術`, `予約`, `店舗`, `商品管理` | `OzController`, `BaseModel`, `ibtoz0804db`, `oz_framework` |
| `references/projects/ibeauty_store2016.md` | `ibeauty_store2016` | `美容`, `サロン`, `旧管理画面`, `2016`, `予約`, `店舗` | `OzController`, `BaseModel`, `ibtoz0804db`, `oz_framework.services` |
| `references/projects/igeneric_store2018.md` | `igeneric_store2018`, `igeneric_store` | `ジェネリック`, `Generic`, `注文`, `商品`, `会員`, `管理画面` | `OzController`, `BaseModel`, `igeoz0805db`, `oz_framework.extensions` |
| `references/projects/mason.md` | `mason`, `mason_pearson`, `mason_pearson.sln` | `Mason Pearson`, `ヘアブラシ`, `ブランド`, `商品`, `管理画面`, `受注` | `OzController`, `BaseModel`, `masonpearson2`, `oz_framework.libs` |

補足:
- `ibeauty_store.md` と `mason.md` は solution 名や共通基盤が似る場合があるため、業務語と DB 名まで見て切り分ける
- `ibeauty_store2016.md` は旧構成の可能性があるため、`2016`、旧 framework、旧ディレクトリ名が見える場合に優先する
- `iDrugStore` と `iRx-Medicine` は DB エンティティを共有する箇所があるため、業務語だけでなく solution / project 名で裏取りする

### Shared references
複数プロジェクトから参照される共通資料。必要条件に一致した時だけ読む。

- `references/projects/DatabaseEntities.md`
  - 用途: DB エンティティ、DbContext、Migration、DB プロジェクト分離構造の把握
  - 読む条件: `DbContext`、`Entity`、テーブル追加、Migration、`OZ-DatabaseEntities`、DB 変更の話が出た場合
- `references/projects/oz_framework.md`
  - 用途: 共通ライブラリ、基底クラス、共通コントローラー、共通サービスの把握
  - 読む条件: `oz_framework` 名前空間、`OzController`、`BaseModel`、共通認証/拡張メソッド/サービスの利用が見えた場合

## 低コストなプロジェクト判定ルール

### 判定に使ってよい初期手掛かり
初回は以下の **安い情報だけ** を見る。

- ユーザー要件文の固有語
- ルート直下または浅い階層の `.sln`、`*.csproj`、主要ディレクトリ名
- `references/projects/` 配下のファイル名
- 入口候補に直結する限定的な検索結果

### 初回判定でやらないこと
- Controller / Service / Entity をワークスペース全体で広く検索する
- 複数プロジェクトの本文資料をまとめて読む
- 1件に決め切るためだけに深い再帰探索を行う

### 候補化ルール
1. ユーザー要件に明示プロジェクト名があれば最優先する
2. 明示名がない場合は `.sln`、`csproj`、ディレクトリ名、要件中キーワードで照合する
3. 一致が1件なら、その project reference だけを読む
4. 一致が複数なら、上位2件までの project reference を読む
5. それでも曖昧なら、深掘り前に短く確認する

### 確信度ルール
- 高: プロジェクト名や solution 名が一致し、要件語も矛盾しない
- 中: 2候補に絞れるが、業務語や構成が重なる
- 低: 複数候補が残り、単一前提で進めると誤判定リスクが高い

## 実行ワークフロー

## Phase 1: 入口調査・全体マップ作成（軽量）

### Step 0: プロジェクト推定と最小コンテキスト読み込み
1. ワークスペースから `.sln`、主要プロジェクト名、ディレクトリ名を確認する
2. 要件文から対象ドメイン候補と業務キーワードを抽出する
3. 候補になった project reference を最大2件まで読む
4. DB 層や共通ライブラリが関係しそうな場合のみ shared reference を追加で読む
5. この時点では深いコード探索に入らない

出力:
- 対象候補プロジェクト
- 確信度
- 読み込んだ reference 名
- 要確認事項（必要時のみ）

### Step 1: 要件構造化
要件文から以下を抽出する。

- 対象ドメイン候補
- 変更種類（新規 / 拡張 / 修正）
- 対象画面 / API / バッチ候補
- 受け入れ条件
- 制約事項

出力:
- 要件解釈（短い箇条書き）
- 要確認事項（最大3件まで）

### Step 2: 入口ファイルの特定
以下の順で、**入口候補だけ** を探す。

優先順:
1. Controller / API Endpoint
2. Razor Page / View / ViewModel
3. Batch / Background Task
4. Service の公開メソッド
5. 既存の関連テスト

探索対象は **最大5ファイル程度** に抑えること。
関係が薄いファイルは深追いしない。

### Step 3: 処理の流れの概要整理
Step 2 で見つけた入口ファイルを中心に、以下だけを整理する。

- 入口
- 主処理の呼び出し先
- DB または外部依存の有無
- 戻り値 / 画面反映 / 更新の方向

詳細実装や全分岐の洗い出しはまだ行わない。

出力:
- 処理概要（5〜10行程度）
- 次に深掘りすべきファイル（最大3件）
- 深掘り優先順位

### Phase 1 の出力フォーマット
1. 対象プロジェクト候補
2. 確信度と判定根拠
3. 要件解釈
4. 読み込んだ reference
5. 関連ファイル候補
6. 処理概要
7. 次に深掘りすべきファイル
8. 要確認事項

---

## Phase 2: 詳細設計生成（必要時のみ）

この Phase は以下のどちらかの場合のみ実施する。
- ユーザーが「続けて詳細化して」と指示した場合
- Phase 1 の結果から対象範囲が十分に絞れている場合

### Step 4: エンティティ / DB 層調査
対象機能に必要な範囲でのみ調査する。

確認項目:
- 関連テーブル
- 関連エンティティ
- Enum
- 既存フラグ / ステータス
- マッピング規約
- 既存 migration / DDL パターン

DB 変更が絡む場合のみ `DatabaseEntities.md` を参照し、必要なら対象 DB プロジェクトまで絞る。

### Step 5: ビジネスロジック層調査
対象の入口から呼ばれる範囲に限定して調査する。

確認項目:
- 主要公開メソッド
- 分岐条件
- 拡張ポイント
- 既存の後方互換条件
- エラー処理
- トランザクション / 外部連携の有無

### Step 6: UI / API 層調査
必要な範囲でのみ調査する。

確認項目:
- GET / POST / API Action
- ViewModel / DTO
- 入力項目
- バリデーション
- エラーメッセージ
- 画面反映 / レスポンス形式

共通基盤が絡む場合のみ `oz_framework.md` を参照する。

### Step 7: 設計概要生成
以下を具体化する。
- DB変更
- Entity変更
- Logic変更
- UI / API変更
- 後方互換条件
- テスト観点
- 移行方針

テンプレートが必要な場合は `references/design-template.md` を使う。

### Step 8: 整合性チェック
以下を確認する。
- 既存呼び出し元への影響
- 新規条件が無効時に従来動作を維持できるか
- NULL / DEFAULT / FK / バリデーションの妥当性
- テスト追加ポイント

## 設計原則
- 後方互換を最優先にする
- 既存命名規則・既存パターンを優先する
- 不明点は断定せず `要確認` と記載する
- 実装で確認できた事実と推測を必ず分ける
- 共通ライブラリ変更時は参照先全体への影響を意識する
