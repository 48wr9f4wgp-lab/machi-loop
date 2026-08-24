# iPhoneだけで公開する手順

## 最初の1回だけ

1. GitHubで新規Repositoryを作る。
2. 名前は `machi-loop`。
3. `Public` を選ぶ。
4. `Add a README file` をONにして作成する。
5. ChatGPTへ「machi-loop作った」と送る。

その後はChatGPT側から接続済みGitHubへゲームファイルを投入できる。

## Pages設定

ファイル投入後にGitHubで以下だけ行う。

1. `machi-loop` → `Settings`
2. `Pages`
3. `Build and deployment`
4. `Source` を `GitHub Actions` にする
5. `Actions` タブで `Build and deploy MACHI LOOP` が緑色になることを確認
6. Pagesに表示されたURLをSafariで開く

以後、mainへ更新が入るたびにWeb版が自動更新される。
