# MACHI LOOP — ART BIBLE v1.0

Status: LOCKED — title-local Canonical / Visual North Star
Date: 2026-09-17 JST
Scope: Vertical Slice v2 onward
Authority: Title-local Art Bible / Visual Canonical for MACHI LOOP.
Scope: title-local
Version: 1.0
Locked by user: 2026-09-17 JST

---

## 0. Canonical metadata

- title: MACHI LOOP
- scope: title-local
- authority: LOCKED Art Bible / Visual Canonical
- version: v1.0
- date: 2026-09-17 JST
- supersedes: dashboard-first visual direction and any conflicting legacy visual assumptions

### Visual Canonical asset

- asset name: `MACHI_LOOP_Visual_North_Star_v1_MASTER.png`
- role: overall visual north star / art direction / city-growth progression reference
- status: TARGET
- priority: P0
- source_type: DRIVE
- source_locator: `https://drive.google.com/file/d/1phOiKAR0ZwwvRjnAWfc-K89ymvGlIerg/view`
- source_file_id: `1phOiKAR0ZwwvRjnAWfc-K89ymvGlIerg`
- attachment_required: NO
- verified_access: YES in the locking chat on 2026-09-17; must be re-verified after chat handoff before visual judgments
- derived preview: `MACHI_LOOP_Visual_North_Star_v1.jpg` / Drive file id `1BXDJzaV9ICRx9KCTw7wVaZ0gvpseU1TU`
- repo preview: `docs/visual/MACHI_LOOP_Visual_North_Star_v1.jpg`

### Interpretation rule

The TARGET image is a **quality and art-direction target**, not a promise that every compositional detail, promotional frame, or phone mockup must be reproduced literally in gameplay. The gameplay implementation must preserve the locked visual qualities: city-dominant framing, dense but readable urban growth, warm natural light, legible roads/traffic, rich vegetation, strong transformation from empty land to city, and restrained HUD.

The image and this Art Bible are used together. Text alone must not substitute for viewing the TARGET asset when making Art/UI/layout decisions.

---

## 1. Visual thesis

**一本の道から、街が生まれる。**

MACHI LOOPのビジュアルは、
- 「街が勝手に育つ驚き」
- 「道路一本で街の未来が変わる納得感」
- 「iPhoneの小さい画面でも街の構造が読める明瞭さ」

を同時に成立させる。

このゲームの見た目は飾りではない。**街の成長そのものが報酬**であり、ビジュアルはゲームメカニクスの一部とみなす。

---

## 2. North Star

目標とする見た目は、以下の3要素の中間点。

1. **3D miniature city**
   - 俯瞰で街全体を把握できる
   - ミニチュア感があり、成長の差分が読みやすい

2. **stylized realism**
   - 完全な低ポリ玩具ではなく、現実の都市らしい説得力を持つ
   - ただし細部は簡略化し、スマホ視認性を優先

3. **cinematic readability**
   - 光、影、植生、水辺、交通の流れで「見ていて気持ちいい」を作る
   - しかし暗すぎ・細かすぎ・情報過多にはしない

**一言でいうと：**
「リアル寄りの美しいミニチュア都市を、スマホで読みやすくしたルック」

---

## 3. Visual pillars

### 3.1 City is the hero
- 常に都市が画面の主役。
- HUDは補助。
- プレイヤーが最初に目に入れるべきものは、数値ではなく街。

### 3.2 Empty-to-dense transformation
- 更地から都市へ変わる差分が大きいこと。
- 一本目の道路の価値が、建物、道路、車、緑、密度で明確に返ること。

### 3.3 Readable urban structure
- 幹線道路、生活道路、交差点、中心地、住宅地、商業地、交通集中が見た瞬間に分かること。
- 診断パネルなしでも「どこが伸びているか」「どこが詰まっているか」が見えること。

### 3.4 Warm aspirational beauty
- “デバッグ画面”ではなく“商品として欲しい都市景観”。
- 暖かい自然光、豊かな緑、気持ちいい密度感。

### 3.5 Performance-aware illusion
- 実機性能の都合で見た目を捨てない。
- LOD、簡略影、インスタンシング、遠景簡略化で“密度が高く見える”錯覚を使う。

---

## 4. Camera / composition lock

### 4.1 Camera angle
- 基本は**高めのアイソメ寄り俯瞰**。
- 角度目安：地面に対して **40〜55度**。
- 真上すぎず、横すぎず。建物の高さと道路の流れを両立。

### 4.2 Rotation philosophy
- 標準構図を1つ強く持つ。
- 初期Vertical Sliceでは自由回転を前提にしすぎない。
- まずは「一番美しく読める角度」を正として詰める。

### 4.3 Framing
- iPhone縦画面で、**都市が有効表示領域の70%以上**を占有することを目標。
- 無意味な余白を作らない。
- 旧版のような「小さな菱形の街が中央に浮く構図」は禁止。

### 4.4 Motion
- 道路敷設・成長時に軽いカメラ補助は可。
- ただし操作不能になる長い演出は不可。
- “気持ちいいがテンポを殺さない”こと。

---

## 5. Lighting / atmosphere

### 5.1 Lighting target
- ベースは**明るい昼の自然光**。
- やや暖色寄り。
- コントラストはあるが潰しすぎない。

### 5.2 Shadow target
- 建物・樹木・高架要素の影で立体感を出す。
- ただしスマホ性能の都合上、影を落とす対象は選別する。
- 遠景の影精度より、近景の読みやすさ優先。

### 5.3 Atmosphere
- 空気感は軽く爽やか。
- 汚れ、曇天、灰色の重さより、“育てたくなる街”の魅力を優先。

---

## 6. Color script

### 6.1 Global palette
- 地面：明るいベージュ〜黄緑寄り
- 植生：自然な緑、彩度は中程度
- 道路：ダークグレー〜チャコール
- 建物：白・クリーム・ベージュ・淡いグレーを基調に、一部アクセント色
- 水辺：明るめの青〜青緑

### 6.2 Contrast logic
- 幹線道路は明確に目立たせる。
- 生活道路は一段控えめ。
- 建物は地区差より“都市構造の読みやすさ”優先。

### 6.3 Prohibited color directions
- 全体が暗すぎる
- 彩度が強すぎておもちゃっぽくなる
- UIと都市の色が競合する
- 灰色一色で無機質すぎる

---

## 7. Environment art

### 7.1 Terrain
- 何もない土地でも退屈に見えない最小限の起伏・質感を持たせる。
- ただし地形がうるさすぎて道路可読性を壊さない。

### 7.2 Vegetation
- 木はシルエット差を持たせる。
- 単木、低木、クラスターを使い分ける。
- 等間隔のコピペ感は避ける。

### 7.3 Water / coast / river
- 実装時はマップごとの差別化の強い武器。
- Vertical Sliceの平地でも将来拡張しやすい材質設計にする。

---

## 8. Roads and traffic

### 8.1 Arterial roads
- プレイヤーの主役操作対象。
- 最も読みやすく、最も美しく見せる。
- 幅、色、交差点、交通量で“都市の骨格”として認識できること。

### 8.2 Local roads
- 自律生成される従属要素。
- 幹線の邪魔をせず、街の成長結果として見えること。
- 主張しすぎない。

### 8.3 Traffic
- 車は都市に生命を与える重要要素。
- 多すぎてノイズにならず、少なすぎて寂しくもない密度を狙う。
- 渋滞時は“止まって見える/詰まって見える”ことが重要。

### 8.4 Congestion readability
- 数字より先に、見た目で「あ、混んでる」と分かること。
- 幹線に車が列をなす、交差点が詰まる、流れが滞るなどの視覚言語を使う。

---

## 9. Architecture

### 9.1 Building philosophy
- 実在都市風の説得力を持つ、簡略化された中密度〜高密度建築。
- 細部を描き込みすぎない。スマホで読めるシルエットが最優先。

### 9.2 Growth stages
- 更地
- 小住宅・低層建築
- 小さな店舗・街区形成
- 中層集合住宅・商業拡大
- 高層化・中心地形成

この差分が明確であること。

### 9.3 Density hierarchy
- 住宅地は低層〜中層
- 商業中心は中層〜高層
- 中心地・結節点は最も密度が高い
- 道路設計の違いが密度の違いとして返ること

### 9.4 Landmark philosophy
- ランドマークは乱雑な装飾ではなく、都市の重心・完成感を強化する目的で使う。
- Vertical Sliceでは必須ではないが、将来的に中心性を可視化する武器。

---

## 10. Growth presentation

### 10.1 First-road sequence
最重要演出。

プレイヤーが最初の道を引くと、短時間で以下が起きること。
- 車/到来シグナル
- 最初の住宅
- 住宅増加
- 生活道路分岐
- 小商業反応
- “街が生まれた”と感じる構図変化

### 10.2 Animation philosophy
- 成長は静的にポップするだけでは弱い。
- 建設の兆し → 建物出現 → 連鎖という“段階”を感じさせる。

### 10.3 Recovery presentation
- バイパスや拡幅後、交通が分散し、別の場所が伸び始める。
- 「道一本で街の流れが変わった」と分かること。

---

## 11. UI / HUD doctrine

### 11.1 Rule
**City first, UI second.**

### 11.2 Persistent HUD
常時表示は最小限。
- 都市名/都市段階
- 人口 or 最小限の成長指標
- 資金 or 制約指標
- 現在の主要アクション
- 重要アラートの要約

### 11.3 Contextual UI
以下は必要時のみ。
- 詳細交通情報
- 財政内訳
- 需要詳細
- 地区方針
- 政策詳細
- Settings

### 11.4 Forbidden HUD direction
以下の同時常設は禁止。
- 需要カード
- 交通カード
- 政策カード
- 財政赤字カード
- 目標大型パネル
- SFX/HAPTICトグル常駐

### 11.5 Bottom tool philosophy
- 道路系アクションを主役にする。
- ボタンは少数、明瞭、大きめ。
- 巨大すぎて都市を圧迫しない。

---

## 12. Performance strategy

### 12.1 Non-negotiable
“見た目が良いこと”は必須。ただし実機で動くことも必須。

### 12.2 Use illusions
- instancing
- LOD
- far simplified meshes
- selective shadow casting
- traffic density approximation
- staged growth FX reuse
- shared material systems

### 12.3 Optimization rule
品質を下げる前に、
「どうすれば高品質に“見える”か」を先に考える。

---

## 13. Vertical Slice v2 visual target
Vertical Sliceで最低限成立すべき体験:

1. empty land
2. first road
3. city born
4. visible autonomous growth
5. structural congestion
6. intervention
7. visible recovery/reconfiguration

この一連の流れを、**見た目だけでかなり理解できる**状態を目指す。

---

## 14. Reference quality bar
本作の目標は、
- App Store上でスクリーンショットを見た瞬間に弱く見えないこと
- 「システム説明画面」ではなく「この街を育ててみたい」と思わせること
- 単体の都市景観として魅力があること

---

## 15. Absolute no-go
- debug/simulator/dashboard感の強い画面
- 余白だらけで街が小さい構図
- 道路と建物の階層が読めない絵
- UIカードが街より目立つ画面
- 低品質なコピー感の強い樹木・建物の反復
- “後で綺麗にする前提”で仮画面を長期間放置すること

---

## 16. Production implication
このArt Bibleは「最後の装飾ガイド」ではない。
**Core Experienceそのものを規定する仕様**として扱う。

実装判断ルール:
- 街の主役感を強めるなら採用候補
- 成長の差分を明瞭にするなら採用候補
- 道路による因果が読みやすくなるなら採用候補
- UIを増やすだけなら原則Reject

---

## 17. Immediate next steps
1. このArt Bibleをtitle-local canonical候補として採用判断。
2. Core Experience Rebuild（PR #53以降）を、このBibleとの差分を潰す方向へ修正。
3. まずはVertical Slice v2の1画面を実機で“商品レベルに近い”ところまで詰める。
4. その後、建物セット、道路、植生、ライティング、成長演出を段階的に固定。
