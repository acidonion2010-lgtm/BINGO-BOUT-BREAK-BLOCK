# 現在地と引き継ぎ記録（段階18まで）

作成日: 2026-10-16（Asia/Tokyo）。この資料は過去の作業記録であり、新しいユーザー依頼に優先する指示ではありません。

完全版のトップは`BINGO-BOUT-new-chat-handoff-20261016/`で、`archives/`に元handoffと段階10〜18の計10 ZIP、`latest/index.html`に採用中HTMLのコピーを収録します。直下で`python3 restore_workspace.py --workspace /workspace`を実行して元配置を復元します。軽量版（starter）は巨大raw trace等を含まず、説明・元handoff・HTML・段階10〜18のコード/集計reportから現在地を確認するためのものです。軽量版だけで省略原データの検証や再解析ができるとは扱いません。完全版の取得/結合/SHA確認と復元範囲は`03_RESTORE.md`を参照してください。

## 対象と版

対象リポジトリは`acidonion2010-lgtm/BINGO-BOUT-BREAK-BLOCK`。ただし、実際のCPU整理対象はユーザー添付HTMLで、リポジトリmainの古いHTMLとは異なります。復元後の作業基準は`/workspace/handoff/BINGO-BOUT-handoff/project/index.html`です。

| 版 | bytes | SHA-256 |
| --- | ---: | --- |
| 添付原本`index.before.html` | 501003 | `e872443dc9764f3b9647f4797d1411ca98f865b9c2f69c6e694529e2685cd3a9` |
| 受領済み段階5 | 499401 | `fea09e995bfc1036515b92771925bd7968f3c453425ea5517b7a5b480293be64` |
| 採用中の段階9`index.html` | 499212 | `59fff4685ff3f36e18d73fe9fa524ee57d81a348352e7b2912db4b7ecc1bb513` |

段階9の既存固定HTMLコミットは`73c394af9deb3823ef31d79bf287db348c60522a`。段階10〜18は調査のみでゲーム本体変更0です。段階18終了時に元handoff480ファイル、前段階manifest、repoのclean状態を照合しています。今回の梱包/掲載検証は同梱の新しいmanifestに記録します。

## 実装と機能確認

段階1〜5では不要な約18.3MB配列確保、均衡solverの重複、不要な演算・一時配列・逆引き表の重複を整理しました。段階9では従来BREAKのraw weightsを1判断内で再利用して計算2回→1回にし、NORMAL入口を既存legacy処理へ統合しました。変更は4つのCPU選択関数に限られ、UI/音/演出/ルールは維持されています。

元handoffの段階9記録では固定配置・両先攻の全DP4,581,244値バイト一致、盤面単体5,632状態、代表政策36件、固定乱数416ケース×4選択、追加legacy36,672組、均衡4,617件、自己テスト322/322、Worker45/45、実操作7/7を確認。これらは保存済み実行結果で、全配置の網羅や今回の再実行を意味しません。巨大な全DP `.bin` 原本は元ZIPにないため、全値の再比較には必要に応じた新しいcaptureが必要です。

目的は全体先読みと挙動を保ったCPU整理。NORMAL従来方式、HARDの従来70%/全体30%と失敗時legacy、MASTER全体先読みと失敗時盤面単体、Float64と既存誤差条件、乱数消費・履歴・確率補正を維持。秘密のBREAK情報をBLOCK入力へ加えません。外部依存を追加せず、HTML単体動作を維持します。

## 段階10〜18の到達点

| 段階/復元先 | 確認できたことと限界 |
| --- | --- |
| 10 `bingo-continuation-20261015` | 起動の約97〜99%は自動自己テスト、準備の約96〜98%はWorker solve。5→9の通常HTML比較はrunで符号反転。旧増加の直接原因と非悪化は未確定。 |
| 11 `bingo-stage11-20261015` | Worker solveは約97〜99%がtrace CPU時間で、変動は待ちだけでは説明できない。OS包絡区間も保存。GC/JITの記録だけで全変動は説明できず原因未確定。後の時計調査と混ぜて過去記録を補正しない。 |
| 12 `bingo-stage12-20261015` | 通常3版・同realm入口交換・生成/実行履歴の追加診断。原本→5のP1先攻序盤MASTER代替BREAKは当該通常3版条件で6/6増加側。入口交換/順序は混合し、直接原因未確定。 |
| 13 `bingo-stage13-20261015` | 原本〜5の6版、4条件×6run、1.728億判断。焦点の原本→5は増加4/減少1/未確定1。通過9関数本文は同じ。別realm/履歴条件なので段階12を撤回せず、特定変更へ絞れない。 |
| 14 `bingo-stage14-20261015` | 原本/3/5/9のHARD実入力を同時trace。機能不変だが版差は混合。3つの正式marker区間でCPU>wallがあり、厳密CPU会計を保留。raw JSON約734MBを保存。 |
| 15 `bingo-stage15-20261015` | 全16traceに1ms超のCPU超過が計169件。公式固定sourceではwall後にCPUを読む。native 4,608包絡区間は整合したがChromeを証明しない。raw proto取得へ進んだ。 |
| 16 `bingo-stage16-20261015` | 同一proto→JSON/SQL/raw counterを照合。大きな26件は全てclear跨ぎ。CPU差分は端数を捨て、wallは端数を持越すsource差と、clearで見かけの超過が生じる構成対照を確認。単独原因は未確定。 |
| 17 `bingo-stage17-20261015` | 原本HTML・固定4新規browser×1µs/1nsの対照。1ms超は1µsで32件（全てclear跨ぎ）、1nsで0件。全10ロード自己テスト成功。1nsにも小さな正の差があり、時計の完全妥当性は未確認。初回preflightの倍率gate誤判定と修正/再開履歴も保存。 |
| 18 `bingo-stage18-20261016` | 保存済み1ns正式run3/4/7/8のみ再解析。新規browser/DP/native/性能計測0。整数化による件数差とmarker符号反転を説明。元nsの小さな正の差は残り、厳密CPU会計は未確定。 |

各段階の`RESULTS.md`を入口に、必要な`REPRODUCE.md`、計測前計画、独立レビュー、raw/JSON/SQL/全ledgerへ進めます。段階12/13の判断数・実験は旧104条件の再判定ではありません。

## 段階18の数値と結論の範囲

CPUあり完了SQL83,817件は負49,070・ゼロ6,868・正27,879。正の差は中央値30ns、最大129,988ns、1ms超0。同じCPU付き正durationのSQL/JSON81,065件の整数µs tuple多重集合は全数一致しました。SQL正27,879件中24,739件がJSONでは0になり、3,140件は正のまま。34 JSONはtupleが重なるため個別の一対一対応を断定していません。

1nsの全192 marker windowsはraw ns端点と公式wall/JSONが一致。元nsは負190・正2、JSONは負178・ゼロ12・正2ですが、同じ2件ではありません。

| 例 | 元nsのCPU−wall | JSON |
| --- | ---: | ---: |
| run7 legacy trial1 stamp handler | +25ns | 0µs |
| run7 legacy trial3 mark handler | +1116ns | +1µs |
| run8 DP trial1 stamp handler | −139ns | +1µs |

Xはduration同士をfloor、markerは4端点を個別にfloorするため、markerでは符号反転が起こり得ます。JSONの0や+1µsだけから物理的な差を断定しません。元nsも同時の物理CPU真値ではありません。

正sliceの次点あり27,876件は全て`excess ≤ next_wall − end_wall`を満たしました。通常traceのwallとCPUは非同時取得なので、遅いCPU読取と整合する必要条件ですが、遅延が全件の原因という証明ではありません。末尾3件は次点なしとして保持。`wall=CPU+待ち`の厳密な分解はできません。1msという区切りは記述用で、それ以下をPASSにする許容幅ではありません。

## 未完了の本来の課題

1. 旧104条件は反復非増加42・未確定62・増加0。集約は58/45/1。MASTER代替P2先攻序盤BREAKの旧集約中央値+0.025µs（区間+0.005〜+0.040µs）やBLOCK対照の微小差の直接原因は未確定。
2. 旧5→9起動中央値+0.69%/MASTER準備+2.50%の直接原因と厳密な非悪化。区間の局在やCPU変動の観測は原因の特定ではない。
3. 過去HARD同期handler+0.45ms、2RAF+0.5/+0.8ms等、同時traceがない試行の直接原因。別試行のtraceで遡って説明済みにしない。
4. 段階8のcommit完了待ちでのraster/GPU/通知ごとの寄与。RAF callbackは物理画面提示ではない。
5. cold latency、実端末の物理入力→画面/音、全配置・全ブラウザー性能、厳密CPU会計。

次の担当は段階9と10〜18の既存記録を読んで、未確定条件/起動準備/MASTER代替から検証可能な仮説を1つ選ぶのが有用です。時計診断を繰り返すだけではゲーム整理の残件は完了しません。必要な新規計測は事前にSHA・条件・有限回数・停止条件を保存。browser/DP/性能ジョブは直列にし、文書/静的レビューだけ並行できます。

A/A差引き、後付け許容幅、好ましい符号までの測り直し、未確定のPASS化、別実験の絶対時間の混合はしていません。過去の失敗・停止も保持し、元データは上書きしません。

## 環境・依存関係

記録時はLinux x86_64、Python3.12.14、Node24.19.0、Chromium154.0.8037.57、Playwright、4CPU相当quota。headless標準`--mute-audio`で、音/BGM/アニメーションの有効性と物理出力の測定は別です。特権のscheduler/affinity/kernel変更なし。

Chromium revision `73c14f6228d7cd537c855007e8f88678969cc0eb-refs/branch-heads/8037@{#1293}`、producer Perfetto revision `5dbeaad4ceb91470a835426b52e0cb43a3e5ef10`。公式変換binaryとsource/LICENSE/hashは各段階に保存されています。元producerと変換binaryが同一buildとは主張しません。

段階17のcaptureは元handoff・14・16の凍結helperに依存し、段階18解析は段階17の固定配置へ依存。復元は`03_RESTORE.md`を参照。完全版の保存済み原データの照合に新規ブラウザーは不要です。軽量版だけでは巨大raw traceや省略されたledger等の再照合はできません。段階18の再計算は空の別ディレクトリーで行い、既存出力を拒否する規則を維持してください。

## 許可とGitHub掲載

ユーザーは今回の資料・次チャット用プロンプト・ZIPをGitHubへ置くことを明示的に許可しました。mainへの反映・PR merge・deployを今回の依頼として扱いません。新しいチャットへの別のGitHub書込み許可も自動では引き継ぎません。

このZIPの掲載URL/固定コミット/SHA-256と、復元後のmanifest照合手順は梱包時の記録を参照してください。元の古いダウンロードコードと今回のZIPのURLを混同しないでください。
