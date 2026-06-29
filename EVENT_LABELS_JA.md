# CSQJek — Japanese Event Label Catalog (東京 / Tokyo)

**Purpose.** The Tokyo demo environment is operated by the Japanese team, so the events
in their Contentsquare / Heap dashboard should read in 日本語. This file is the **single
authoritative mapping** from each event's stable English key (as fired in the app code)
to its Japanese **display label**.

**How to use it.** These are *display-name aliases*, applied once in the Contentsquare /
Heap **event management** UI for the Tokyo environment — not changes to the app code:

- The app keeps firing **stable English event keys** (`ride_booked`, `telco_purchase_completed`, …).
  That is deliberate: stable keys are what stitch funnels, journeys, and session replay
  together, and they let Tokyo still line up against Singapore / Sydney if ever needed.
- In the dashboard, set each event's **display name** to the Japanese label below. Analysts
  then see 日本語 everywhere; the underlying analytics are unchanged.
- Every event already carries a `market` property (`"Tokyo"`), so you can scope these
  labels / views to the Japanese environment.

> Property **keys** and enum **values** also stay English by design (`result: "approved"`,
> `finance_mode: "installment_24mo"`). If you also want a Japanese glossary for the key
> property *values*, say so and we'll add a second catalog — this file covers event names.

Coverage: **every** `CSQ.trackEvent(...)` in the codebase — string literals plus the
`BillEvent` and `LiveAgentEvent` enums (~120 events).

---

## 乗車 — CSQライド (Ride)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `ride_booked` | 乗車予約完了 | 「予約」確定後 |
| `ride_option_selected` | 乗車オプション選択 | 乗車カードのタップ |
| `ride_cancelled` | 乗車キャンセル | ドライバー確定後のキャンセル |
| `destination_selected` | 目的地選択 | 目的地の選択（履歴／検索） |
| `ride_option_selected` | 乗車タイプ選択 | CSQライド／ブラック等の選択 |

## 配達・ライダー (Delivery / Rider)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `delivery_rider_matched` | 配達ライダー確定 | ライダーがマッチング |
| `rider_call_tapped` | ライダーへ発信 | 電話アイコンのタップ |
| `rider_message_tapped` | ライダーへメッセージ | メッセージアイコンのタップ |

## フード — CSQフード (Food)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `food_restaurant_tapped` | レストラン選択 | 店舗カードのタップ |
| `food_item_added` | 商品をカートに追加 | メニューの追加ボタン |
| `food_order_placed` | 注文確定 | 「注文する」確定 |
| `food_order_failed` | 注文失敗 | 注文処理の失敗 |
| `food_track_order_tapped` | 注文追跡タップ | 注文確認画面の追跡ボタン |
| `recommended_item_added` | おすすめ商品追加 | おすすめ枠からの追加 |

## モバイル — CSQモバイル：プラン・端末 (Telco: plans & devices)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `telco_plan_viewed` | プラン閲覧 | プランカードの表示 |
| `telco_plan_signup_tapped` | プラン申込タップ | 申込CTAのタップ |
| `telco_plan_signup_started` | プラン申込開始 | 申込画面の表示 |
| `telco_plan_sim_selected` | SIMタイプ選択 | eSIM／物理SIM・番号の選択 |
| `telco_addon_tapped` | アドオンタップ | アドオン行のタップ |
| `telco_data_addon_added` | データアドオン追加 | データ追加の確定 |
| `telco_roaming_selected` | ローミング選択 | 海外ローミングの選択 |
| `telco_topup_confirmed` | チャージ確定 | プリペイドチャージの確定 |
| `telco_device_viewed` | 端末閲覧 | 端末詳細の表示 |
| `telco_device_variant_selected` | 端末バリエーション選択 | 色／容量の選択 |
| `telco_device_financing_selected` | 支払い方法選択（分割／一括） | 分割・一括の選択 |
| `telco_device_plan_attached` | 端末にプラン紐付け | プランチップの選択 |
| `telco_checkout_started` | チェックアウト開始 | 購入手続き画面の表示 |
| `telco_fulfillment_selected` | 受取方法選択 | 配送／店舗受取の選択 |
| `telco_payment_method_selected` | 支払い方法選択 | カード／ウォレット等の選択 |
| `telco_credit_check_started` | 与信審査開始 | 「与信審査を実行」タップ |
| `telco_credit_check_result` | 与信審査結果 | 審査結果（承認／否決） |
| `telco_credit_recovery_outright` | 一括購入へ切替（与信回復） | 否決後に一括購入へ |
| `telco_purchase_completed` | 購入完了 | 「注文を確定」 |
| `telco_payment_rage_retry` | 支払い連打リトライ（レイジ） | 支払い失敗の連続リトライ |

## モバイル：請求・サポート迷路 (Telco: bills & support "frustration journey")

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `telco_bills_viewed` | 請求一覧閲覧 | 請求画面の表示 |
| `telco_bill_download_tapped` | 請求書ダウンロードタップ | 明細行のDLアイコン |
| `telco_bill_opened` | 請求書を開く | 明細行のタップ |
| `telco_bill_detail_viewed` | 請求明細閲覧 | 明細画面の表示 |
| `telco_bill_pdf_downloaded` | 請求書PDFダウンロード | 「PDFをダウンロード」 |
| `telco_bill_payment_started` | 支払い開始 | 最初の「支払う」 |
| `telco_bill_payment_failed` | 支払い失敗 | 支払いが必ず失敗（CSQ-4012） |
| `telco_bill_payment_retried` | 支払い再試行 | 「再試行」タップ |
| `telco_bill_payment_help_tapped` | 支払いヘルプタップ | 失敗後の「ヘルプ」 |
| `telco_bill_payment_completed` | 支払い完了 | 解決経路ありで支払い成功（最終CV） |
| `telco_help_center_viewed` | ヘルプセンター閲覧 | ヘルプセンター表示 |
| `telco_help_search_performed` | ヘルプ検索実行 | 検索の実行（クエリはマスク） |
| `telco_help_category_tapped` | ヘルプカテゴリタップ | カテゴリタイルのタップ |
| `telco_help_article_tapped` | ヘルプ記事タップ | 記事行のタップ |
| `telco_support_article_viewed` | サポート記事閲覧 | 記事画面の表示 |
| `telco_support_article_feedback` | 記事フィードバック | 「役に立ちましたか？」 |
| `telco_support_article_related_tapped` | 関連記事タップ | 関連記事への遷移（迷路ループ） |
| `telco_support_still_need_help_tapped` | 「まだ解決しない」タップ | 「まだ解決しない」リンク |
| `telco_contact_options_viewed` | 問い合わせ方法閲覧 | 問い合わせ画面の表示 |
| `telco_contact_deflected` | 問い合わせ回避（自己解決誘導） | 有人以外のチャネルへ誘導 |
| `telco_support_bot_opened` | サポートボット起動 | チャットボット表示 |
| `telco_support_bot_message_sent` | ボットへメッセージ送信 | ボットへの送信 |
| `telco_support_bot_escalation_requested` | 有人対応リクエスト | ボットが初めて有人を提示 |
| `telco_support_bot_escalated` | 有人対応へエスカレーション | 「オペレーターにつなぐ」 |
| `telco_live_chat_queued` | 有人チャット待機 | 順番待ちで表示 |
| `telco_live_chat_connected` | 有人チャット接続 | オペレーター接続 |
| `telco_live_chat_message_sent` | チャットメッセージ送信 | 有人チャットでの送信 |
| `telco_call_us_viewed` | 電話問い合わせ画面閲覧 | 電話画面の表示 |
| `telco_call_number_tapped` | 電話番号タップ | 電話番号行のタップ |
| `telco_support_abandoned` | サポート離脱 | 「あとで対応する」＝離脱シグナル |
| `telco_call_abandoned` | 電話問い合わせ離脱 | 「クイックガイドを試す」 |
| `called_into_call_center` | コールセンター接続 | 電話が接続（タップ1.8秒後） |
| `telco_self_service_resolved` | セルフサービスで解決 | 「これで解決→支払う」 |

## ペイ — CSQペイ (Cash / Wallet)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `cash_send_money_opened` | 送金画面を開く | 送金画面の表示 |
| `cash_send_contact_tapped` | 連絡先選択 | 連絡先のタップ |
| `cash_contact_quick_send_tapped` | クイック送金タップ | クイック送金 |
| `cash_send_manual_initiated` | 手動送金開始 | 手動入力での送金開始 |
| `cash_send_international_initiated` | 海外送金開始 | 海外送金の開始 |
| `cash_send_confirmed` | 送金確定 | 送金の確定 |
| `cash_scan_qr_opened` | QRスキャン画面を開く | QR画面の表示 |
| `cash_add_funds_opened` | チャージ画面を開く | チャージ画面の表示 |
| `cash_withdraw_opened` | 出金画面を開く | 出金画面の表示 |
| `cash_transaction_tapped` | 取引明細タップ | 取引行のタップ |
| `cash_view_all_transactions_tapped` | 全取引を見るタップ | 「すべて見る」 |
| `cash_qr_camera_permission_requested` | カメラ許可リクエスト | カメラ権限の要求 |
| `cash_qr_camera_permission_granted` | カメラ許可承認 | カメラ権限の許可 |
| `cash_qr_camera_permission_denied` | カメラ許可拒否 | カメラ権限の拒否 |
| `cash_qr_camera_preview_active` | カメラプレビュー開始 | プレビュー開始 |
| `cash_qr_scanner_session_started` | QRスキャン開始 | スキャン開始 |
| `cash_qr_scanner_session_ended` | QRスキャン終了 | スキャン終了 |
| `cash_qr_scanning_initialized` | QRスキャン初期化 | スキャナ初期化 |
| `cash_qr_scanning_resumed` | QRスキャン再開 | スキャン再開 |
| `cash_qr_torch_toggled` | ライト切替 | トーチの切替 |
| `cash_qr_code_detected` | QRコード検出 | コード検出 |
| `cash_qr_demo_scan_initiated` | デモスキャン開始 | デモ用スキャン |
| `cash_qr_payment_sheet_presented` | 支払いシート表示 | 支払いシート表示 |
| `cash_qr_payment_confirm_tapped` | 支払い確認タップ | 「確認」タップ |
| `cash_qr_payment_confirmed` | 支払い確定 | 支払い確定 |
| `cash_qr_payment_processing_started` | 支払い処理開始 | 処理開始 |
| `cash_qr_payment_success` | 支払い成功 | 支払い成功 |
| `cash_qr_payment_cancelled` | 支払いキャンセル | 支払いのキャンセル |
| `cash_qr_payment_sheet_cancel_tapped` | 支払いシートキャンセル | シートで「キャンセル」 |
| `cash_qr_insufficient_funds_detected` | 残高不足検出 | 残高不足の検出 |

## エア — CSQエア (Air / Flights)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `air_search_tapped` | フライト検索タップ | 検索の実行 |
| `air_swap_tapped` | 出発地・目的地入替 | 出発地⇄目的地 |
| `air_results_shown` | 検索結果表示 | 結果一覧の表示 |
| `air_filter_toggled` | フィルター切替 | フィルターの切替 |
| `air_sort_tapped` | 並び替えタップ | 並び替え |
| `air_flight_selected` | フライト選択 | フライトの選択 |
| `air_fare_selected` | 運賃選択 | 運賃クラスの選択 |
| `air_book_tapped` | 予約タップ | 予約CTA |
| `air_booking_completed` | 予約完了 | 予約の完了 |
| `air_booking_done_tapped` | 予約完了「完了」タップ | 完了画面の「完了」 |
| `air_popular_dest_tapped` | 人気の目的地タップ | おすすめ目的地 |

## マート・精肉 (Grocery / Meat)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `meat_category_viewed` | 精肉カテゴリ閲覧 | カテゴリ画面の表示 |
| `meat_subcategory_tapped` | サブカテゴリタップ | サブカテゴリの選択 |
| `partner_banner_tapped` | パートナーバナータップ | 提携バナー |

## ライブエージェント (Live Agent — new-feature adoption)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `live_agent_button_impression` | エージェントボタン表示 | FAB表示 |
| `live_agent_button_tapped` | エージェントボタンタップ | FABタップ |
| `live_agent_chat_opened` | チャット開始 | チャット表示 |
| `live_agent_message_sent` | メッセージ送信 | ユーザー送信 |
| `live_agent_chat_dismissed` | チャットを閉じる | シートを閉じる |
| `live_agent_agent_typing_shown` | エージェント入力中表示 | 入力中インジケータ |
| `live_agent_quick_reply_tapped` | クイック返信タップ | 定型返信チップ |

## 共通・システム (Shared / System)

| Event key | 日本語ラベル | 何を計測するか |
|-----------|-------------|----------------|
| `service_tile_tapped` | サービスタイルタップ | ホームのサービスタイル |
| `tab_switched` | タブ切替 | タブバーの切替 |
| `promo_tapped` | プロモバナータップ | プロモのタップ |
| `promo_code_invalid` | プロモコード無効 | 無効なクーポン |
| `promo_rage_apply` | プロモ連打（レイジ） | 無効コードの「適用」連打 |
| `market_selected` | マーケット選択 | マーケット切替 |
| `payment_method_picker_opened` | 支払い方法ピッカー表示 | 支払いピッカー |
| `payment_method_selected` | 支払い方法選択 | 支払い方法の選択 |
| `payment_error` | 支払いエラー | 支払いエラー |
| `api_error` | APIエラー | API呼び出しエラー |
| `page_scroll_started` | ページスクロール開始 | スクロール開始 |
| `checkout_scroll_blocked` | チェックアウトスクロール制限 | スクロール制限の発火 |

---

## 適用メモ (Notes for the team)

- **Stable keys, localized labels** — only the *display name* changes; the event key
  fired by the app stays English, so existing funnels/segments keep working.
- **Scope to Tokyo** — filter or build these views on `market = "Tokyo"` to keep the
  Japanese labels in the Japanese environment.
- **Screen names** are localized separately at runtime (`CSQ.trackScreenview`) — this
  catalog is event names only.
- Keep this file in sync: when a new event is added in code, add its row here in the
  same PR (the loop will do this going forward).
