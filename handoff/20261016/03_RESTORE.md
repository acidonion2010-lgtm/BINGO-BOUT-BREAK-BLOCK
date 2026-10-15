# 受取・復元・再開

Windowsでは案内したPowerShellコードを実行してください。完全版ZIP、添付用starter ZIP、`PUBLICATION.json`を同じ受取フォルダーへ保存します。各分割ファイルと結合後の完全版、starterのSHA-256を検証します。ZIP内のファイルを受け取るだけで、ゲームの検証プログラムは実行しません。

## 新しいチャットに渡すもの

`BINGO-BOUT-new-chat-starter-20261016.zip`と、同じ受取フォルダーの`PUBLICATION.json`を添付し、展開した`01_NEW_CHAT_PROMPT.txt`の本文を送ってください。starterは32MiB未満で、最新の引き継ぎ資料・プロンプト・HTML・元stage0〜9のZIP・段階10〜18の軽量なコード/集計資料を含みます。完全版は約196MBなので、添付容量を超える環境ではGitHubから取得します。

starterの`summaries/`は参照用の抜粋です。大きなtrace・ledgerなどを省略しており、これだけで段階10〜18の全件照合や再解析を実行できません。省略したファイルは`STARTER_CONTENTS.json`に列挙しています。

## クラウド側で完全版を取得

starterを展開したディレクトリーで次を実行します。`PUBLICATION.json`のパスは実際の添付ダウンロード先に合わせます。Python 3.11以上、外部パッケージ不要です。

```bash
python3 fetch_full_handoff.py --publication /workspace/PUBLICATION.json --destination /workspace/bingo-handoff-download
python3 -m zipfile -e /workspace/bingo-handoff-download/BINGO-BOUT-new-chat-handoff-20261016.zip /workspace/bingo-handoff-full
cd /workspace/bingo-handoff-full/BINGO-BOUT-new-chat-handoff-20261016
python3 restore_workspace.py --workspace /workspace
```

`PUBLICATION.json`にはGitHubの固定コミットとmanifestのSHA-256があります。ダウンローダーは固定コミットから取得し、manifest・各分割ファイル・結合ZIPを照合します。受取コードの自己検証用SHAはユーザーに案内したPowerShellコードに含めています。

## 完全版から復元される配置

| 保存ZIP | 復元先（`--workspace /workspace`時） |
|---|---|
| 元20261015 handoff | `/workspace/handoff/BINGO-BOUT-handoff` |
| stage10 | `/workspace/bingo-continuation-20261015` |
| stage11〜17 | `/workspace/bingo-stage11-20261015`〜`/workspace/bingo-stage17-20261015` |
| stage18 | `/workspace/bingo-stage18-20261016` |

元ZIP10個を`archives/`にそのまま保存しています。`ARCHIVES.json`が外側ZIPのSHA・サイズ・対応先を記録します。復元スクリプトは全ZIPのサイズとSHAを先に確認し、内部manifestの網羅性を確認したうえで、各ファイルを一時ファイルへ展開・SHA照合してから新規配置します。同じ内容の既存ファイルは照合して再利用し、異なる内容の既存ファイルは上書きせず停止します。途中で失敗した場合も、既に正常配置したファイルは残ります。POSIX環境ではZIP内の通常の権限を復元し、既存同一ファイルには不足する実行ビットだけを追加します。添付コードや歴史的プロンプトは実行しません。

確認だけ行う場合:

```bash
python3 restore_workspace.py --workspace /workspace --verify-only
```

starterだけで元stage0〜9を先に復元する場合は`--original-only`を付けます。後で完全版から通常復元すると、同一ファイルを再利用してstage10〜18を追加します。

```bash
python3 restore_workspace.py --workspace /workspace --original-only
```

完全展開の原データは合計約3.8GBです。元資料に記録された巨大DPバイナリーなど、元からZIPに含まれていなかったファイルは本一式にもありません。再解析の実行環境（ブラウザー、trace_processor等）は別途コードとREPRODUCE.mdを確認して準備します。今回は受取と復元の確認であり、新しいブラウザー/DP/性能測定の実施結果ではありません。

現行HTMLは`latest/index.html`にもコピーしました。復元先の`project/index.html`と同じ499,212 bytes、SHA-256 `59fff4685ff3f36e18d73fe9fa524ee57d81a348352e7b2912db4b7ecc1bb513`です。GitHub mainの古いHTMLを最新として使わないでください。
