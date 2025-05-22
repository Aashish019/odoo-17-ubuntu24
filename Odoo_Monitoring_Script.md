
# Odoo Uptime Monitoring Script

## 📂 File Structure

```
/home/mcmillan/DevOps/alert-site/
├── monitor.py
├── clients.json
├── venv/
└── monitor.log
```

## 🐍 monitor.py

```python
import requests
import json
import time
from datetime import datetime

TELEGRAM_BOT_TOKEN = 'YOUR_TELEGRAM_BOT_TOKEN'
TELEGRAM_CHAT_ID = 'YOUR_TELEGRAM_CHAT_ID'
CLIENTS_FILE_PATH = '/home/mcmillan/DevOps/alert-site/clients.json'
TIMEOUT = 10

def load_clients(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def send_telegram_alert(message):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": message,
        "parse_mode": "HTML"
    }
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
    except Exception as e:
        print(f"❌ Failed to send Telegram alert: {e}")

def check_site(name, url):
    try:
        response = requests.get(url, timeout=TIMEOUT)
        if response.status_code == 200:
            print(f"🟢 {name}: UP")
        else:
            print(f"🔴 {name}: DOWN (Status Code: {response.status_code})")
            send_telegram_alert(
                f"<b>{name.upper()}</b> is <b>DOWN</b>\nURL: {url}\nStatus: {response.status_code}\nTime: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            )
    except requests.exceptions.ConnectionError:
        print(f"🔴 {name}: DOWN (Connection error)")
        send_telegram_alert(
            f"<b>{name.upper()}</b> is <b>DOWN</b>\nURL: {url}\nReason: Connection Error\nTime: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    except requests.exceptions.Timeout:
        print(f"🔴 {name}: DOWN (Timeout)")
        send_telegram_alert(
            f"<b>{name.upper()}</b> is <b>DOWN</b>\nURL: {url}\nReason: Timeout\nTime: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    except Exception as e:
        print(f"🔴 {name}: DOWN (Other Error: {e})")
        send_telegram_alert(
            f"<b>{name.upper()}</b> is <b>DOWN</b>\nURL: {url}\nError: {e}\nTime: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )

def main():
    clients = load_clients(CLIENTS_FILE_PATH)
    for name, url in clients.items():
        check_site(name, url)
        time.sleep(1)

if __name__ == "__main__":
    main()
```

## 🗂 clients.json Format

```json
{
  "erp": "https://erp.mcmillan.solutions",
  "itec17": "https://itec17.mcmillan.solutions",
  "rd-arabia": "https://rd-arabia.mcmillan.solutions"
}
```

> Use double quotes for both keys and values!

## ⏲️ Cron Setup

### Edit crontab:
```bash
crontab -e
```

### Add job (run every 5 minutes):
```cron
*/5 * * * * /home/mcmillan/DevOps/alert-site/venv/bin/python3 /home/mcmillan/DevOps/alert-site/monitor.py >> /home/mcmillan/monitor.log 2>&1
```

## 🧹 Clear Log Daily

```cron
0 0 * * * truncate -s 0 /home/mcmillan/monitor.log
```

## 📲 Telegram Alert Setup

1. Search `@BotFather` on Telegram.
2. Create a bot, get the API token.
3. Get your chat ID via [@userinfobot](https://t.me/userinfobot).
4. Update `monitor.py` with:
```python
TELEGRAM_BOT_TOKEN = 'your_bot_token_here'
TELEGRAM_CHAT_ID = 'your_chat_id_here'
```

---

© Generated on 2025-05-22
