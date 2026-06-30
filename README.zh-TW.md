# claude-anima

**為 Claude Code 加上「持久記憶 + 會自己排程的心跳」。**

> 語言：**繁體中文** ・ [English](./README.md)

你的 AI 會按排程自己醒來，跑過一份你自訂的檢查清單，做有用的背景工作，**只有在真的需要你時**才用 Telegram 通知你——然後把學到的東西跨對話、跨裝置記下來。

靈感來自 [OpenClaw](https://github.com/OpenClaw) / Hermes。授權 MIT-0。

---

## 你會得到什麼

| 元件 | 功能 |
|---|---|
| **心跳 Heartbeat** | 一個每位使用者各自的 launchd agent（macOS），按排程（預設白天每小時）喚醒無頭 Claude。前面有一道免費的 shell **前置閘門**——只有真的有變動（git 差異、未 push 的 commit、或週期保底）才喚醒模型，多數心跳在毫秒內結束、**零 token**。真要喚醒時才讀 `HEARTBEAT.md` 清單、只在值得時用 Telegram 通知你。 |
| **記憶 Memory** | OpenClaw 風格的 `IDENTITY` / `USER` / `SOUL` / `MEMORY` 結構，加上每日筆記與定期蒸餾。可選 **git 備援**——`setup.sh` 能幫你 init 一個私有 repo，讓記憶跟著你跨裝置（stop hook + 心跳自動同步）。 |
| **Hooks** | `SessionStart` 自動把記憶載入脈絡；`PreCompact` 在對話被壓縮前提醒 agent 先寫入持久記憶。 |
| **Telegram 通知** | `tg_notify.sh` 用 Telegram Bot API 發一行訊息，token 與 chat id 從一個 gitignore 的 `.env` 讀取。 |

---

## 安裝

```
/plugin install claude-anima
```

接著在 plugin 根目錄跑一次性設定：

```
bash scripts/setup.sh
```

`setup.sh` 可重複執行（idempotent），會詢問：

- **Telegram bot token + chat id**（通知用）
- **專案／記憶目錄**（`HEARTBEAT.md` 和記憶放哪）
- **清醒時段**（讓它半夜安靜）

…然後寫一個 gitignore 的 `.env`（chmod 600），把記憶與 `HEARTBEAT.md` 模板種進去（**不會覆蓋**你已有的東西），安裝並載入每位使用者的 launchd agent（非 macOS 退回 cron），最後發一則測試 Telegram 訊息讓你確認接線正常。

---

## 設定

- **`HEARTBEAT.md`**（在你的專案裡）——心跳輪流檢查的清單。保持精簡，一行一件事，自由編輯。
- **`.env`**——bot token、chat id、專案／記憶目錄、清醒時段。**永不入庫**。
- **`templates/`**——可複製填寫的起始 `IDENTITY.md`、`USER.md`、`SOUL.md`、`HEARTBEAT.md`。
- **launchd 排程**——編輯已安裝的 agent（或重跑 `setup.sh`）來改頻率或清醒時段。

心跳技能會從 `.env` 解析你的記憶目錄，或往上層找 `HEARTBEAT.md`。在沒有記憶工作區的地方，hooks 是安靜的 no-op，所以裝了 plugin 也不會干擾無關專案。

---

## 安全

- **機密只留本機。** bot token 與 chat id 只存在 gitignore 的 `.env`（chmod 600）。`.gitignore` 也排除 `*.log` 與 `heartbeat-state.json`。**不會把任何個資 commit 進去。**
- **心跳預設保守。** 只有需要你做決定時才通知；例行「一切正常」靜音。
- **它不會自己做不可逆的事**，除非你的 `HEARTBEAT.md` 明確叫它做——預設姿態是「把事情攤出來，讓人決定」。
- 啟用前先看過 `HEARTBEAT.md`：你列在那裡的任何項目，agent 都可能在無人看管時去做。

---

## 已知問題

Claude 是**每次心跳開一個獨立的無頭 session**——不是單一常駐 loop。如果你同時跑一個雙向 Telegram bot（例如 `--channels` session），心跳醒來時開的新 session 可能也載入 Telegram，去爭搶**唯一的 bot token 消費者**（`getUpdates`），把常駐 bot 擠掉。建議：

1. 別把雙向 channel plugin 全專案啟用；給它專屬 session。
2. 心跳通知用單向的 `tg_notify.sh`（只發送、不輪詢）。
3. 心跳預設單例（atomic lock），兩個心跳不會重疊。

完整說明與已驗證的修法見 [`KNOWN-ISSUES.md`](./KNOWN-ISSUES.md)。

---

## 目錄結構

```
.claude-plugin/plugin.json   plugin 清單（接 hooks）
hooks/                       session_start.sh, pre_compact.sh, hooks.json
scripts/                     heartbeat.sh, tg_notify.sh, setup.sh
skills/heartbeat/            心跳 SOP（SKILL.md）
skills/memory/               記憶 SOP（SKILL.md）
templates/                   IDENTITY / USER / SOUL / HEARTBEAT 起始檔 + plist 模板
```

---

## 致謝

記憶模型與心跳概念靈感來自 **OpenClaw / Hermes**。由一個心跳 agent 自主建置與維護。MIT-0——隨你使用，不需署名。
