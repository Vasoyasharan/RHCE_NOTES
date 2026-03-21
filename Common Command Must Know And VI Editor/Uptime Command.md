
---

## ⚡ Basic Command

```bash
uptime
```

---

## 💯 Pro Insight (What Interviewers Want)

If you say this, you stand out:

👉 “Load average represents the number of runnable and waiting processes over time, and must be interpreted relative to CPU core count.”


# 🖥️ Linux `uptime` Command — Explained

## 📟 Command Output

```
14:02:10 up  3:49,  1 user,  load average: 1.03, 0.76, 0.68
```

---

## 🔍 Breaking It Down

|Part|Value|Meaning|
|---|---|---|
|🕐 Current Time|`14:02:10`|It's 2:02:10 PM (24-hour format) when the command was run|
|⏱️ Uptime|`3:49`|System has been running for **3 hours and 49 minutes** since last boot|
|👤 Logged-in Users|`1 user`|Only 1 active user session right now|
|⚡ Load Average|`1.03, 0.76, 0.68`|CPU workload over the last **1, 5, and 15 minutes**|

---

## ⚡ Load Average — Deep Dive

Load average tells you **how many processes were waiting to run** on the CPU.

> Rule of thumb: **1.0 per CPU core = 100% utilization**

|Load Value|Status|Meaning|
|---|---|---|
|`< 1.0`|✅ Idle|CPU has headroom, processes run instantly|
|`1.0 – 1.5`|⚠️ Busy|Some queuing, still normal|
|`> 2.0`|🔴 Overloaded|Processes waiting too long|

### Your Values:

- **1 min ago:** `1.03` ⚠️ Slightly busy
- **5 min ago:** `0.76` ✅ Comfortable
- **15 min ago:** `0.68` ✅ Comfortable

### 📊 Trend Analysis

```
0.68 → 0.76 → 1.03   (rising slightly)
```

Load is **increasing** in the last minute — likely a process that just started. Nothing to worry about!

---

## 💡 Quick Tips

- Run `top` or `htop` to see **which process** is causing high load
- On a **4-core CPU**, a load of `4.0` = 100% — so `1.03` is very light
- Use `watch uptime` to monitor load in real-time every 2 seconds

---

