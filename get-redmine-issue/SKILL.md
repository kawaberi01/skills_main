---
name: get-redmine-issue
description: Redmine（incidentプロジェクト）のチケットを検索・取得・更新するための手順書です。ユーザーが「チケット番号の詳細」「自分担当の未完了」「重要度/緊急度（カスタムフィールド）で絞り込み」「添付ファイルの取得」「ステータス更新」を求める場合に使用します。
---

# Redmine Issue Skill（incident）

このスキルは、Redmine の incident プロジェクトにおけるチケット（Issue）の取得・検索・更新を、MCPツール（`mcp_redmine_*`）を使って行うための運用手順です。

> 前提：実行環境で `mcp_redmine_redmine_request` などの Redmine MCP ツールが利用可能であること。

## 指示（Instructions）

- **一覧取得**は `/issues.json` を使う
- **詳細取得**は `/issues/{issue_id}.json` を使う
- **カスタムフィールドでの絞り込み**は `cf_<field_id>` 形式を使う（例：`cf_134: "今日中"`）
- **添付ダウンロード**は、詳細取得で `attachments` を含めて `attachment_id` を確認してから行う
- **更新**は `/issues/{issue_id}.json` に `PUT` で行い、`notes` で作業ログを残す

## 例（Examples / Quick start）

### 1) 自分担当の未完了チケット（open）を一覧で取得
```text
mcp_redmine_redmine_request(
  method: "GET",
  path: "/issues.json",
  params: {
    project_id: "incident",
    assigned_to_id: "me",
    status_id: "open",
    sort: "priority:desc,updated_on:desc",
    limit: 50
  }
)
```

### 2) チケットIDで詳細（添付・履歴含む）を取得
```text
mcp_redmine_redmine_request(
  method: "GET",
  path: "/issues/123.json",
  params: {
    include: "children,attachments,relations,journals,watchers"
  }
)
```

### 3) 緊急度「今日中」のチケットを検索（カスタムフィールドで絞り込み）
```text
mcp_redmine_redmine_request(
  method: "GET",
  path: "/issues.json",
  params: {
    project_id: "incident",
    status_id: "open",
    cf_134: "今日中",
    sort: "updated_on:desc",
    limit: 50
  }
)
```

### 4) カスタムフィールド指定の基本形
```text
mcp_redmine_redmine_request(
  method: "GET",
  path: "/issues.json",
  params: {
    project_id: "incident",
    cf_34: "iBeauty",       # 部署/サイト
    cf_133: "A",            # 重要度
    cf_134: "今日中"         # 緊急度
  }
)
```

### 5) 添付ファイルの取得
```text
mcp_redmine_redmine_download(
  attachment_id: 42,
  save_path: "C:\downloads\redmine"
)
```

### 6) 更新（ステータス・進捗・コメント）
```text
mcp_redmine_redmine_request(
  method: "PUT",
  path: "/issues/123.json",
  body: {
    issue: {
      status_id: 3,
      done_ratio: 100,
      notes: "対応完了しました。動作確認済みです。"
    }
  }
)
```

## トラブルシューティング（Troubleshooting）

| HTTP | 意味 | 対応 |
|---|---|---|
| 400 | 不正なリクエスト | パラメータ名・型・値を確認 |
| 401 | 認証エラー | APIキー/トークン、接続先設定を確認 |
| 403 | 権限不足 | プロジェクト権限、API権限を確認 |
| 404 | 不在 | issue_id / project_id / path を確認 |
| 422 | バリデーション | 必須フィールド、値の形式を確認 |

## 参照（References）
- トラッカー一覧と選び方：`references/trackers.md`
- カスタムフィールド定義：`references/custom-fields.md`
- チケットカテゴリ一覧：`references/categories.md`

## プロジェクト情報
- **プロジェクト名**: 商用サイト開発・デザイン相談  
- **プロジェクトID**: incident  
- **Redmine URL**: https://ozinter.cloud.redmine.jp/projects/incident
