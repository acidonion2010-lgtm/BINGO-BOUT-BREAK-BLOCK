# BINGO BOUT 新しいチャットへの引き継ぎ（2026-10-16 JST）

段階18までの資料・未確定項目・最新HTML・再開用プロンプト・保存済み原データの一式です。

- [まず読む](00_START_HERE.md)
- [新しいチャットへ送るプロンプト](01_NEW_CHAT_PROMPT.txt)
- [到達点と残件](02_HANDOFF.md)
- [受取・復元手順](03_RESTORE.md)
- [添付用starter ZIP（約16.4MB）](BINGO-BOUT-new-chat-starter-20261016.zip)
- [PowerShell受取スクリプト](receive-handoff.ps1)
- [サイズ・SHA-256 manifest](manifest.json)
- [受取・復元の検証記録](VERIFICATION.json)

完全版は195,467,349 bytesです。GitHubの単一ファイル上限のため3分割で保存し、受取スクリプトで1本のZIPへ結合・検証します。starterには巨大なraw trace等が含まれないため、全件再解析には完全版が必要です。

ユーザーに案内した固定コミットを`-Revision`へ指定し、`receive-handoff.ps1 -Revision <40桁commit> -Destination <受取フォルダー>`を実行します。完全版・starter・`PUBLICATION.json`を取得します。`-Starter`を追加すると軽量版だけ取得します。

新チャットにはstarterとPUBLICATION.jsonを添付し、01_NEW_CHAT_PROMPT.txtの本文を送ってください。

ゲームの最新採用版は段階9（SHA-256 `59fff4685ff3f36e18d73fe9fa524ee57d81a348352e7b2912db4b7ecc1bb513`）です。接続repoのmainは古い版です。この掲載は引き継ぎ専用ブランチへの資料追加です。
