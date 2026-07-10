---
name: project-reference-router
description: 現在のワークスペース、要件文、solution/project 名から、読むべき project reference と shared reference を選ぶ薄いルーティング専用スキル。reference がない場合は停止せず、実コード調査へのフォールバックを返す。
---

# Project Reference Router

この skill は、仕様策定の最初に使う。  
役割は **読むべき reference を選ぶだけ** であり、設計判断や仕様化は行わない。

## ゴール
- 対象プロジェクト候補を軽量に判定する。
- 読むべき project reference を最大 2 件まで選ぶ。
- 条件に一致する場合のみ shared reference を選ぶ。
- reference が存在しない場合も作業を止めず、実コード調査へのフォールバックを返す。

## Reference root
既定の reference root は、この skill に同梱された以下のディレクトリとする。

```text
/home/masaruishikawa/.agents/skills/project-reference-router/references/
```

このディレクトリ配下の `*.md` だけを読み取り専用の参考資料として扱う。ユーザーが別の reference root を明示した場合のみ、その指定を優先してよい。

## 判定に使う初期手掛かり
- ユーザー要件文のプロジェクト名、画面名、業務語。
- 現在のワークスペース名。
- ルート直下または浅い階層の `.sln`、`*.csproj`、主要ディレクトリ名。
- `git status --short`、必要に応じた `git diff --name-only`。
- 入口候補に直結する限定的な検索結果。

## 初回判定でやらないこと
- ワークスペース全体を深く再帰探索しない。
- 複数 reference をまとめて大量に読まない。
- 確信度が低いまま単一プロジェクト前提で断定しない。
- 設計方針や実装配置を決めない。

## Shared reference 読み込み条件
- 共通基盤 reference: 認証基盤、共通 Controller、共通モデル基底、共通拡張メソッド、共通サービスが関係する場合のみ候補に入れる。現行同梱 reference では `oz_framework.md` が該当する。
- DB / Entity reference: DB 変更、Migration、Entity、DbContext、外部 DB エンティティ、SQL スキーマ変更が関係する場合のみ候補に入れる。現行同梱 reference では `DatabaseEntities.md` が該当する。

## Reference status
- `found`: 対象 project reference が 1 件に絞れた。
- `multiple_candidates`: 候補が複数残る。最大 2 件まで読む候補を返す。
- `not_found`: 対象 project reference が見つからない。
- `unavailable`: reference root が存在しない、または読めない。

`not_found` または `unavailable` でも失敗扱いにしない。実コードの浅い構成調査へ進む。

## 出力テンプレート
```md
# Project Reference Routing Result

## 1. Reference status
- status:
- reason:

## 2. 対象プロジェクト候補
| 候補 | 確信度 | 根拠 | 注意点 |
| --- | --- | --- | --- |
|  |  |  |  |

## 3. 読む reference
| 種別 | パス | 理由 |
| --- | --- | --- |
| project / shared |  |  |

## 4. 読まない reference
| パス | 理由 |
| --- | --- |
|  |  |

## 5. フォールバック方針
- reference がある場合:
- reference がない場合:
- 複数候補が残る場合:

## 6. 次の skill への引き渡し
- project-reference-intake に渡す reference:
- project-code-grounding-analysis に渡す初期仮説:
```

## 実施ルール
- Reference は任意入力であり、存在しなくても仕様策定を止めない。
- Reference 選定結果は仮説であり、実コード確認なしに仕様判断へ使わない。
- 判断根拠には、可能な範囲で `.sln`、`csproj`、ディレクトリ名、要件語を明記する。
