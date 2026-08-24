# MACHI LOOP — GDD v0.1

## One-line pitch
幹線道路だけを描くと生活道路と街が自律的に育ち、プレイヤーは渋滞・成長・都市問題を大きな意思決定で整えるスマホ都市シミュレーター。

## Context Lock
- Platform: iOS / Android primary, PC later candidate
- Orientation: landscape
- Input: touch first; mouse compatible
- Genre: casual city simulation / light management
- Session: 3–10 min casual, 20+ min sandbox
- Mode: offline single-player first
- Visual target: readable stylized 2.5D/isometric target; v0.1 uses abstract grid
- Monetization hypothesis: no forced ads; premium unlock / cosmetic-supporter pack to validate later
- Save: local versioned save, cloud later
- Backend: none for first public test

## Success Definition
- Repeat: 幹線を決める → 街が自動成長 → 問題を読む → 改善する → 新地区を開く。
- Delight: 道路を一本通しただけで生活道路・建物・人口が連鎖的に立ち上がる瞬間。
- Progress: 人口、都市Lv、新地区、交通設備、政策、景観が増える。
- Return: 次の地区解放、混雑解決、都市の変化を見たくなる。
- Revenue: プレイを邪魔しない買い切り/拡張/外観系を優先検証。
- Convention: 都市需要、交通、税収、サービス、成長を分かりやすく可視化。
- Differentiation: 細街路を手作業で引かず、都市の“意図”だけ決める。

## Core Loop
1. プレイヤーが幹線道路を引く。
2. シミュレーションが生活道路を自動生成する。
3. 道路沿いに住宅・商業・工業が自動成長する。
4. 人口・雇用・税収が増える。
5. 渋滞や需給アンバランスが発生する。
6. プレイヤーが拡幅・新幹線・交通政策で改善する。
7. 人口閾値で新地区が解放される。
8. さらに大きい都市問題へ進む。

## Vertical Slice 0.1 Acceptance Criteria
- Touch dragで幹線道路を配置できる。
- 幹線から生活道路が自動発生する。
- 道路沿いに3用途の建物が自動発生する。
- 人口、雇用、税収、幸福度、渋滞が変動する。
- 渋滞が道路上の色/エフェクトで認識できる。
- 幹線道路を拡幅して容量を改善できる。
- 人口で新地区が解放される。
- 5分以内に「街が勝手に育つ気持ちよさ」と「詰まりを直す判断」を両方体験できる。

## Benchmark roles
- Cities: Skylines: 都市システム同士の因果・問題解決の深さ（コピー対象ではない）
- TheoTown: モバイルでの都市シム密度・長期性
- Pocket City 2: モバイル向け分かりやすさ・成長演出
- Mini Motorways: 交通問題の即読性・簡潔な操作

## Not in v0.1
- 住民一人ずつのエージェントAI
- 個別車両の本格経路探索
- 鉄道/バス/地下鉄
- 電気/水道/ゴミ/消防/警察
- 災害
- 課金
- オンライン
- 3Dアセット量産
