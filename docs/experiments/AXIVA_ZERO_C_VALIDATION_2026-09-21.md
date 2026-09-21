# AXIVA ZERO C — 実装・検証記録

日付: 2026-09-21 / scope: AXIVA title-local / 非Canonicalの実験記録

## 結果

ZERO Cを実装し、ローカルの自動試験167項目とWebエクスポートが成功。
実機の面白さ・操作感・画面・性能は未検証。Core Funは引き続きPARTIAL。

- 対象: iPhone / iOS、縦画面、タッチ操作
- ACTIVE_PHASE: VERTICAL_SLICE
- PRODUCTION_DECISION: UNDECIDED
- RELEASE_APPROVAL: NOT_REQUESTED
- GitHubへの送信・PR作成・Pages更新: 未実施

## 実装内容

1. 住宅地・駅・物流拠点を、実際につながった幹線網で評価。
2. 拠点間の移動を経路へ割り当て、同じ道への集中と迂回による分散を計算。
3. 孤立した道や無関係な小ループではメトロポリスへ進めない。
4. 地区の用途に合う実在建物を成長条件とし、大都市からの突破を構造で制限。
5. 最初から良い道路網を作っても突破可能。故意の失敗は不要。
6. 車の動き・車列・短い状況説明・実在街区の高密度化で結果を伝える。
7. ZERO Cは通常の都市・バックアップ・チュートリアル保存から隔離。

起動方法: Webの `?zero=c`、ローカルGodotの `-- --zero-c`。
通常モード、ZERO A、ZERO Bは維持。Cはページ再読込で新規試行となる。

## 検証済みの実装状態

- Repository: `48wr9f4wgp-lab/machi-loop`
- Branch: `experiment/zero-c-metropolis`
- 実装・試験commit: `f8253e0f582bfbf80ae5abca81e450d95330b66e`
- Engine: `4.7.1.stable.official.a13da4feb`
- Renderer: `gl_compatibility`
- 入力基準サイズ: 430×932
- 既存配布baseline: `main@bf28bdb5dea8e593af81e8ec603d3b7f377bcd2b`
- この記録とDEV_STATUSの追記は実装commit後の文書変更。

| 試験 | 結果 |
|---|---|
| ZERO C 道路グラフ | 16項目 PASS |
| ZERO C 現行mainの操作・成長・修復・保存隔離 | 23項目 PASS |
| 通常版の入力→渋滞→回復 | 82項目 PASS |
| ZERO A 回帰 | 25項目 PASS |
| ZERO B 回帰 | 21項目 PASS |
| Godot import / parse | PASS、script errorなし |
| 日本語文字セット・生成フォント | 177文字の実フォント収録を確認 |
| Web release export | PASS、HTML/PCK/WASM生成 |
| Release readiness静的検査 | PASS（公開承認を意味しない） |

実行コマンド:

```sh
bash tools/run_zero_c_core_fun.sh
bash tools/run_zero_core_fun.sh
bash tools/run_zero_b_core_fun.sh
bash tools/run_playable_loop.sh
python tools/check_playable_text.py --font generated/MachiLoopJP.otf
godot --headless --path . --export-release Web build/web/index.html
```

## 観測した結果

- 木の枝状の道路網: 接続済み建物40棟、大都市で停滞。中心地3。
- 同じ条件で20tick放置: 棟数増加なし。
- 実際の道路建設処理で迂回路追加: 成長が再開し72棟、メトロポリスへ。
- 有効な2系統の修復網: 最大交通負荷比が1.29から0.97 / 0.65へ低下。
- 最初から構造を整えた街: 失敗履歴なしでも安定期間後に突破。
- 一時停止・道路ドラッグ中: 安定期間を加算しない。
- 駅への接続を撤去: 到達条件を無効化。修復後に再到達可能。
- 通常保存のsentinel: 起動・操作・保存呼出・reset削除hook・終了で保持。

## 修正した検証上の問題

最初の最短経路を固定して別経路を探すと、環状道路の中を横切る経路を
最初に選んだ場合、有効な迂回路を誤って棄却していた。
最初の経路を組み替えられる2単位の残余フローへ変更し、異なる2形状で確認。

## 未確認・限界

- 5〜8分のiPhone実機通し試験、面白さ、停滞原因の読み取り、達成感。
- Cの実画面・タッチの使い心地。ブラウザはローカルURLに
  `ERR_BLOCKED_BY_CLIENT` で接続できず、画面合格とはしていない。
- iOSネイティブbuild、cold launch、割込・復帰、熱・電池・実機FPS。
- 交通は試作用の集約モデル。大規模都市の交通精度・性能は未検証。
- 全マップを道路で埋める等の敵対的な配置に対する長時間試験は未実施。
- ZERO Aの既存fixture終了時にObjectDB 2 instancesの警告。Cの試験では
  同警告なし。引き継ぎの既知事項として保持し、Device Validation前に確認。
- CIは新branchを未送信のため未実行。ここでのPASSはローカル証拠。

## RECOVERY_STATE / 次工程

実装と検証をローカルcommitへ保存。未送信の作業を破棄・resetしない。
自動承認審査がGitHub pushを拒否した。理由は、実装指示のみでは外部GitHubへ
リポジトリ内容を送信する明示承認が足りないと判定されたこと。

次はこのbranchの送信・PR作成について明示承認を得る。
Pages更新まで承認された場合は、PRの検証を確認した後、その承認範囲で更新し、
実機試験へ進む。App Store公開はこの工程に含まれない。

実機試験で見る点:
1. 目的地を結ぶと、次も道を引きたくなるか。
2. 大都市で止まった理由を、車列や街から読み取れるか。
3. 別経路を作った後の変化が都市計画として納得できるか。
4. メトロポリスへの変化が、苦労に見合う報酬に感じるか。

自動試験が通っただけでVertical Slice/Device Validation/Greenlightを合格にしない。
