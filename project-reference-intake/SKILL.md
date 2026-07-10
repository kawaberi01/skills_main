---
name: project-reference-intake
description: project-reference-router が選んだ reference を読み、プロジェクト構成・既存流儀・注意点を仮説として整理するスキル。実コード未確認のため仕様確定はしない。
---

# Project Reference Intake

この skill は、選ばれた reference からプロジェクト理解の仮説を作るために使う。  
Reference は調査の地図であり、仕様判断の正本ではない。

## ゴール
- 読み込んだ reference と利用理由を記録する。
- フレームワーク、主要プロジェクト、データアクセス、画面/API/バッチ構成を仮説として整理する。
- 既存流儀、避けるべき過剰設計、注意点を抽出する。
- 実コードで必ず裏取りすべき項目を明確にする。

## 前提
- Reference は読み取り専用で扱う。
- Reference の内容を、実コード確認なしに仕様へ採用しない。
- Reference が古い可能性を常に考慮する。
- Reference と実コードが矛盾した場合は実コードを優先する。

## 読み取り手順
1. `project-reference-router` の出力を確認する。
2. `reference_status` が `found` または `multiple_candidates` の場合のみ、指定 reference を読む。
3. `not_found` または `unavailable` の場合は、この skill をスキップ可能とし、実コード調査へ進む。
4. Reference から、プロジェクト構成、主要入口、データアクセス、共通基盤、テスト方式、禁止すべき過剰設計を抜き出す。
5. すべて「reference 由来の仮説」として記録する。

## 出力テンプレート
```md
# Project Reference Intake Result

## 1. 読み込んだ reference
| パス | 種別 | 読んだ理由 |
| --- | --- | --- |
|  | project / shared |  |

## 2. Reference 由来の仮説
- フレームワーク:
- 主要プロジェクト:
- 入口パターン:
- データアクセス:
- 表示 / 応答:
- 共通基盤:
- テスト:

## 3. 既存流儀として尊重すべきこと
-

## 4. 過剰設計を避ける注意点
- 既存にない DTO / Repository / Service / DI 分離を標準前提にしない:
- 技術刷新や横断リファクタを混ぜない:
- その他:

## 5. 実コードで要確認の項目
-

## 6. Reference の信頼度 / 古さの懸念
- 信頼度:
- 懸念:

## 7. 次の skill への引き渡し
- project-code-grounding-analysis へ渡す仮説:
- 実コード確認で優先すべき入口:
```

## 実施ルール
- 「reference に書いてある」だけでは確定仕様にしない。
- 対象機能固有の処理内容は必ず実コードから確認する。
- Reference が示す構成と実コードが違う場合は、差分記録の対象として引き渡す。
