---
name: review-pr
description: 'Azure DevOpsのプルリクエスト（PR）に対して日本語で厳格なコードレビューを実施するスキル。PRブランチがチェックアウト済みの状態で使用する。使用タイミング: (1) PRのコードレビューを依頼された時、(2)「PR番号XXXをレビューして」と言われた時、(3) Azure DevOpsのプルリクエストの品質チェックが必要な時。Azure DevOps MCP、Redmine MCP、Serena MCP、Microsoft Docs MCPサーバーと連携して動作する。コード変更は一切行わず、読み取り専用レビューのみ実施する。'
---

# Azure DevOps プルリクエスト コードレビュー

**重要**: コード/リポジトリの変更は一切行わない。レビューのみ実施する。

## 前提条件
- PRのブランチがチェックアウト済みであること
- Azure DevOps MCPサーバーが設定済み
- Redmine MCPサーバーが設定済み（任意：PR説明にRedmine URLがある場合）

## レビューワークフロー

### Step 1: PR情報の特定
1. 現在のプロジェクトを確認
2. [references/projects.md](references/projects.md) からプロジェクト名→**リポジトリID**を特定
3. PR番号が不明な場合はユーザーに確認
4. MCPサーバーでPR詳細を取得（**リポジトリID**を使用、プロジェクトIDではない）
5. PR説明に Redmine URL（`https://ozinter.cloud.redmine.jp/issues/XXXX`）があれば、Redmine MCPでissue内容も確認

### Step 2: ブランチ分岐点からの差分取得
**⚠️** ベースブランチ差分ではなく、**分岐点からの差分**を確認する。

```bash
# ベースブランチを確認
git branch -r | grep -E "(origin/master|origin/main)"

# 分岐点のコミットIDを取得
git merge-base HEAD origin/master  # または origin/main

# 変更ファイル一覧
git diff <分岐点コミットID>..HEAD --name-status

# 特定ファイルの差分
git diff <分岐点コミットID>..HEAD -- <ファイルパス>
```

### Step 3: コードレビュー実施
[references/checklist.md](references/checklist.md) のチェック項目に沿ってレビュー：
- **A. アーキテクチャ・設計** - SOLID原則、責任分離
- **B. コード品質** - 命名規則（C#/.NET）、可読性、重複
- **C. 機能性・ロジック** - 要件充足、エッジケース、エラーハンドリング
- **D. パフォーマンス** - N+1問題、メモリリーク、非同期処理
- **E. セキュリティ** - SQLi、XSS、認証/認可、機密情報
- **F. テスト** - カバレッジ、網羅性
- **G. 既存コードとの整合性** - 既存パターン準拠、互換性

### Step 4: レビュー結果出力
[references/checklist.md](references/checklist.md) の出力フォーマットに従い結果をまとめる。

最終判定: ✅承認 / ❌要修正 / ⚠️条件付き承認

## 注意事項
- **厳格性**: 高品質なコードレビューを目的とする
- **読み取り専用**: コードの変更や修正提案の実装は行わない
- **網羅性**: すべての変更ファイルを詳細に確認する
- **客観性**: 確立されたベストプラクティスに基づいて評価する
- **建設的**: 問題を指摘するだけでなく、改善の具体的な提案も含める
- **⚠️ ID使用**: MCPサーバー使用時は必ずリポジトリIDを使用する
