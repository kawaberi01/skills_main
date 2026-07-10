# API Materials

断層競馬の参考欄では、ローカル API からだけ情報を取ること。

## 優先 API

### 1. 出馬表

`GET /nankan/meetings/{date}/{course}/races/{race_no}/card`

主に見る項目:

- `distance`
- `weather`
- `track_condition`
- `runners[].horse_weight`
- `runners[].horse_weight_diff`

### 2. オッズ

`GET /nankan/meetings/{date}/{course}/races/{race_no}/odds?bet_type=win`

主に見る項目:

- `entries[].combination`
- `entries[].odds`

### 3. 勝ちパターン分析

`GET /nankankeiba/pattern/meetings/{date}/{course}/races/{race_no}?meeting_no={meeting_no}&meeting_day={meeting_day}`

主に見る項目:

- `pattern_uma.track_condition_rates`
- `pattern_uma.rates.kawasaki`
- `pattern_uma.rates.short / medium / long`
- `pattern_kis_cho.rates.kawasaki`
- `pattern_cho.rates.kawasaki`

### 4. 当日傾向

`GET /nankan/meetings/{date}/{course}/trend`

主に見る項目:

- `race_count_completed`
- `summary.frame`
- `summary.running_style`
- `summary.jockey`
- `summary.trainer`

### 5. 補助 API

- `GET /nankan/meetings/{date}/{course}/races/{race_no}/best-time`
- `GET /nankan/meetings/{date}/{course}/races/{race_no}/closing-speed`
- `GET /nankan/meetings/{date}/{course}/races/{race_no}/style-profile`

主な用途:

- 時計の裏付け
- 終いの裏付け
- 脚質のざっくり接続

## このスキルでの使い方

### 調査

- card
- odds
- pattern

### 設計

- card
- odds
- pattern
- 必要なら trend

### 実装寄り

- card
- odds
- pattern
- trend
- 必要なら best-time / closing-speed / style-profile

## 注意

- API が欠けている場合は、無理に埋めず不足を明示する
- trend は当日途中の補正材料として使う。後追い検証では時点再現できないなら強く使わない
- このスキルは「参考欄」専用なので、予想本体の順位や買い目を再構成し直さない
