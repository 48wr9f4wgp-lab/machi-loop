# MACHI LOOP — Privacy Policy Draft v1

Status: **PRE-RC DRAFT — NOT READY TO PUBLISH AS-IS**
Purpose: reduce final legal/product assembly work; final text must match the actual released binary, providers, data destinations, and contact/URL information.

## Draft Japanese structure

### プライバシーポリシー

MACHI LOOP（以下「本アプリ」）は、ゲームの提供に必要な情報を最小限に扱うことを基本方針とします。

### 1. ゲームデータ

本アプリは、都市の進行状況、設定、セーブデータ等を端末内に保存します。

現行のv1.0設計では、ゲームを遊ぶためのアカウント登録は必要ありません。

端末内のゲームデータは、アプリの削除、ブラウザ/OSのストレージ削除、または本アプリが最終的に提供するデータリセット機能等により削除される場合があります。

### 2. 分析情報 — FINAL BUILDで選択

#### Variant A — 外部Analyticsを有効にしない場合
本アプリは、外部の利用状況分析サービスへゲームプレイデータを送信しません。

#### Variant B — 承認済みAnalyticsを有効にする場合
本アプリは、品質改善、チュートリアルやゲーム進行の改善、不具合傾向の把握のため、個人を直接特定しない範囲の利用情報を分析サービスへ送信する場合があります。

送信対象候補は、アプリのバージョン、プラットフォーム、ゲーム進行段階、操作イベント、保存/復旧結果、性能情報を粗い区分にしたデータ等です。

本アプリのゲーム分析用途では、氏名、メールアドレス、住所、正確な位置情報、自由入力テキスト、パスワード、秘密鍵、セーブデータ全文を送信しません。

**公開前にここへ実際のProvider名、Provider privacy policy URL、送信先/目的、必要な識別子の扱いを記載すること。**

### 3. クラッシュ・エラー情報 — FINAL BUILDで選択

クラッシュ/エラー報告機能を有効にする場合、不具合調査に必要な範囲で、アプリのバージョン、プラットフォーム、エラー分類、直前の限定された操作履歴等を送信する場合があります。

**公開前に実際に有効なProvider、収集項目、送信先を確定すること。**

### 4. 広告・トラッキング

v1.0のProduct Lockでは強制広告・広告依存の収益モデルを採用しない方針です。

**この段落は最終バイナリ/SDKを確認し、広告SDKや広告識別子の利用が本当に無い場合のみ次の確定文へ変更すること：**

`本アプリは広告SDKを使用せず、広告目的のトラッキングを行いません。`

### 5. 位置情報・連絡先等

ゲーム本体のv1.0機能では、正確な位置情報、連絡先、写真、マイク、カメラの利用を必要としません。

最終Android Manifest / iOS Entitlementsを監査し、この記載と実際の権限が一致することを確認します。

### 6. 第三者サービス

**FINAL BUILDのSDK inventoryから自動ではなく手動確定すること。**

候補例：
- GameAnalytics — 採用された場合のみ記載
- crash provider — 採用された場合のみ記載

使用していないサービスを記載しないこと。

### 7. データの保持

端末内セーブはユーザーがアプリ/ストレージを保持する間、ゲーム再開のため保存されます。

外部Analytics/Crashデータの保持期間は、最終採用Providerの設定と目的に基づき公開前に確定します。

### 8. 子ども・年齢

本アプリの最終年齢区分および対象者は、App Store / Google Playの最新年齢評価と最終コンテンツを基に公開前に確定します。

子ども向けアプリとして意図的に提供する判断を行う場合は、別途プライバシー/広告/同意要件を再監査します。

### 9. 本ポリシーの変更

ゲーム機能、利用する外部サービス、法令・Store要件等の変更に応じて、本ポリシーを更新する場合があります。

### 10. お問い合わせ

`[PUBLIC_CONTACT_METHOD_TO_BE_SET_BEFORE_RELEASE]`

### 11. 制定・改定日

`[RELEASE_DATE_TO_BE_SET]`

## Release conversion checklist

This file is not publishable until all brackets/conditional variants are resolved.

- [ ] Final analytics provider known or confirmed none.
- [ ] Final crash provider known or confirmed none.
- [ ] Final SDK inventory audited.
- [ ] Final Android permissions inspected.
- [ ] Final iOS capabilities/entitlements inspected.
- [ ] Actual network destinations inspected.
- [ ] Provider names/privacy URLs inserted where applicable.
- [ ] Retention/deletion statements match actual provider settings.
- [ ] Public contact method inserted.
- [ ] Effective date inserted.
- [ ] Hosted privacy-policy URL exists.
- [ ] Apple App Privacy answers match this policy and actual binary.
- [ ] Google Play Data safety answers match this policy and actual binary.
