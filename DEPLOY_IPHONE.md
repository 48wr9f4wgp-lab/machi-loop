# MACHI LOOP iPhone固定URLテスト運用

## 標準運用

MACHI LOOPの日常テストは、iPhoneのSafariからGitHub Pages版を1回だけホーム画面へ追加し、以後は同じアイコンを使う。

固定URL:
`https://48wr9f4wgp-lab.github.io/machi-loop/`

開発の流れ:

1. コード変更をbranch/PRで確認する。
2. `main`へmergeする。
3. `Build and deploy MACHI LOOP` が自動実行される。
4. Godot Web buildが成功すると、同じGitHub Pages URLへ上書きされる。
5. iPhoneではホーム画面の `MACHI LOOP` を終了して再度開き、更新版を確認する。

URLは更新ごとに変えない。ホーム画面への追加も原則1回だけ。

## 最初の1回だけ

1. Safariで固定URLを開く。
2. 共有ボタンを押す。
3. `ホーム画面に追加` を選ぶ。
4. 名前を `MACHI LOOP` にして追加する。

## 開発中のキャッシュ方針

開発中はGodotのPWA Service Workerを無効にする。
理由は、古いWeb buildがiPhone側へ残って「更新したのに変わらない」状態を避けるため。

通常はホーム画面アプリを完全終了して再起動すれば最新buildを取得する。
更新が見えない場合のみSafariで固定URLを再読み込みして確認する。

## CI確認

Actionsで以下がすべて成功してから実機確認へ進む。

- Prepare Godot export templates
- Validate Godot project
- Export Godot Web build
- Verify Web build
- Configure Pages
- Upload Pages artifact
- Deploy to GitHub Pages

`build.txt` に公開したcommit SHAを出力するため、公開版の取り違え確認にも使える。

## Release時

この固定URLは開発・実機確認用として運用する。
Store公開や本番配布へ進む際は、Release Candidateを別途作成してQA/Release Audit後に扱う。
