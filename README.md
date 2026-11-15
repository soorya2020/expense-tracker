<p align="center"><img src="docs/design/icon.png" width="96" alt="Tally icon"></p>

<h1 align="center">Tally</h1>

<p align="center"><b>Know where your money came from.</b><br>
A deliberately simple income and spending tracker for Android, built with Flutter.</p>

<p align="center">
  <img src="docs/screenshots/home.png" width="230" alt="Home">
  <img src="docs/screenshots/add-income.png" width="230" alt="Add income">
  <img src="docs/screenshots/report.png" width="230" alt="Cycle report">
</p>

Tally answers one question: *"I earn ₹30,000, so how did I spend ₹33,000?"* You log each income as it arrives, log spending as one lump whenever you like, and Home shows your balance and how much of your spending your salary actually covered.

Everything stays on your phone. There is no account and no server.

---

## Contents

- [Features](#features)
- [Screens](#screens)
- [Design](#design)
- [Install](#install)
- [How the numbers work](#how-the-numbers-work)
- [Develop](#develop)
- [Project layout](#project-layout)

---

## Features

### Money in, money out
- **Four kinds of income**, each with its own colour: **Salary** (blue), **Extra** (amber: pocket money, gifts, refunds), **Help** (teal: money family gave you to get through a hard month) and **Borrowed** (money you will pay back).
- **Spending in lumps.** No receipts or categories. Add one total for *Today*, *This week*, *Since last entry* or any date range.
- **Unexpected spending.** Mark a one-off hit (medical, vehicle, insurance, family) so it is kept apart from normal spending. Mark it **yearly** and Tally tells you how much to set aside each cycle.
- **Help links to what it paid for.** Help income can point at the spending it covered.
- **Borrowed money** shows on Home as *"You owe Arjun ₹5,000 · Mark repaid"*. Marking it repaid logs the repayment for you.
- Tap any entry to edit it. Swipe to delete, with undo.

### Your own pay cycle
- The cycle starts on the day your salary lands, from the 1st to the 28th, or the last day of the month. Home, History and reports all follow it.
- **Follow my salary.** If your salary arrives 1–7 days early or late, Tally offers to move the cycle just this once or for good.

### Reports and insights
- **End-of-cycle report** as tap-through story cards: what you saved, the gap between your salary and your spending, how much came from extra money, unexpected costs, and your trend against earlier cycles. A notification at 9 AM on the first day of the new cycle opens it.
- **Supported cycle badge** for months you only got through with help.
- **Download PDF.** A two-page A4 report with the summary, insights, a 6-cycle chart and every entry, ready to save or share.
- **Big picture.** Your last 6 cycles in one chart against your salary, plus how often you needed help, regular spending as a share of salary, and surprises per cycle. If the same squeeze shows up in 3 of 6 cycles, it suggests asking for a raise, switching jobs or upskilling.

### Bank SMS (Android)
- Reads your bank's credit and debit SMS for the **current pay cycle**. OTPs, reminders and personal messages are ignored.
- **Debits** and **Credits** tabs. Tap a message to add it, or long-press several debits and **Add as one** spending.
- Skip a message, or always skip an account you don't want to track.
- ↻ refetches the whole cycle. Anything already added or skipped stays that way.
- The envelope on Home shows how many messages are new, and the newest credit appears as a card on Home with an **Add** button.

### Recurring entries
- Add salary, rent, EMIs or subscriptions once. Tally logs them on their day every cycle.
- An optional reminder at 9 AM the day before a bill is due.
- A new rule whose day has already passed this cycle starts next cycle, so nothing you logged by hand is counted twice.

### Backup and restore
- **Back up now** saves everything (entries, cycles, bank SMS, recurring items and settings) to one JSON file. Save it to Drive, Files, WhatsApp or anywhere the share sheet offers.
- **Restore from a backup** brings it all back on any phone. Your PIN is never included.
- Optional backup reminder every payday.

### Everything else
- **4-digit PIN** with optional **fingerprint** unlock. The app locks again after a minute in the background.
- **Check for updates** in Settings finds the newest build and downloads it. Updates install over the current version and keep your data.
- Light and dark themes, a two-colour ₹ app icon, Inter Tight type and controls placed in easy thumb reach.

---

## Screens

These are real screens from the app, rendered with sample data by `tool/screens/screens_test.dart`.

| Lock | Home | Home (dark) |
|:-:|:-:|:-:|
| <img src="docs/screenshots/lock.png" width="240"> | <img src="docs/screenshots/home.png" width="240"> | <img src="docs/screenshots/home-dark.png" width="240"> |
| **Add income** | **Add spending** | **History** |
| <img src="docs/screenshots/add-income.png" width="240"> | <img src="docs/screenshots/add-spending.png" width="240"> | <img src="docs/screenshots/history.png" width="240"> |
| **Cycle report** | **Big picture** | **Bank SMS** |
| <img src="docs/screenshots/report.png" width="240"> | <img src="docs/screenshots/big-picture.png" width="240"> | <img src="docs/screenshots/bank-sms.png" width="240"> |
| **Settings** | **Recurring** | |
| <img src="docs/screenshots/settings.png" width="240"> | <img src="docs/screenshots/recurring.png" width="240"> | |

### PDF report

<img src="docs/design/pdf-report.png" width="480" alt="Two-page PDF cycle report">

---

## Design

The design went from wireframes to mockups in the chosen **Big Number** style: one huge number, one plain sentence and big thumb-sized controls.

**Colours:** ink `#0F1115` on white · salary `#2B4CFF` · extra `#F29F05` · help `#12A594` · over salary `#E5484D` · dark mode background `#0A0E17`.
**Type:** Inter Tight.

### Wireframes
<img src="docs/design/wireframes.png" alt="Wireframes: lock, home, add sheet, history">

### Mockups

**Getting in**
<img src="docs/design/mockups-getting-in.png" alt="Setup and lock mockups">

**Everyday**
<img src="docs/design/mockups-everyday.png" alt="Home, add, history and settings mockups">

**Pay cycle and reports**
<img src="docs/design/mockups-reports.png" alt="Report and pay cycle mockups">

**Tough months**
<img src="docs/design/mockups-tough-months.png" alt="Help, unexpected spending and big picture mockups">

**Bank SMS**
<img src="docs/design/mockups-bank-sms.png" alt="Bank SMS mockups">

**Dark mode**
<img src="docs/design/mockups-dark-mode.png" alt="Dark mode mockups">

**Thumb-friendly layout:** controls moved to the bottom of the screen.
<img src="docs/design/thumb-layout.png" alt="Thumb-friendly layout">

**Recurring entries, and backup and restore**
<img src="docs/design/addons-recurring-backup.png" width="720" alt="Recurring and backup mockups">

---

## Install

Every push builds a signed APK with GitHub Actions and publishes it on the [Releases](https://github.com/soorya2020/expense-tracker/releases) page as `tally-N.apk`.

1. Open the newest release on your Android phone, download the APK and open it.
2. **Play Protect may block it** because Tally asks to read SMS. Open the Play Store, tap your profile picture, then **Play Protect**, then the gear, and turn off **Scan apps with Play Protect** while you install. Turn it back on afterwards.
3. **To allow SMS access**, go to *Settings › Apps › Tally*, tap **⋮** and choose **Allow restricted settings**. Then allow SMS.

After that, use **Settings › Check for updates** inside Tally.

Requires Android 8.0 (API 26) or newer.

---

## How the numbers work

```
Balance       = starting balance + all income − all spending   (from the setup date)
This cycle    = income this cycle − spending this cycle
Past salary   = spending this cycle − salary this cycle         (if above 0, extra money covered it)
Set aside     = yearly unexpected costs ÷ 12, per cycle
```

Amounts are stored in paise. Spending that covers a range of days counts on its last day.

---

## Develop

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift database code
flutter test
flutter run
```

Regenerate the screenshots in `docs/screenshots/`:

```bash
flutter test --update-goldens tool/screens/screens_test.dart
```

**Stack:** Flutter · Riverpod · drift (SQLite) · go_router · flutter_local_notifications · local_auth · flutter_secure_storage · pdf · share_plus · file_picker.

**CI** (`.github/workflows/build-apk.yml`) runs analyze and tests, builds the release APK with the build number, and publishes it as a prerelease. Builds are signed with a fixed key in the repo so each APK installs over the last. To sign with your own key, add `KEYSTORE_BASE64` and `KEYSTORE_PASSWORD` repository secrets.

---

## Project layout

```
lib/
  app/        theme, providers, router
  core/       money formatting, pay-cycle maths
  data/       drift database, repository, stats, settings, recurring, backup
  features/
    auth/     setup, lock, PIN and fingerprint
    home/     balance, story sentence, cycle track, dock
    entry/    add / edit income and spending
    history/  every entry grouped by cycle
    cycle/    pay-cycle settings
    report/   story-card reports, big picture, PDF, notifications
    sms/      bank SMS parser, inbox scan, Bank SMS page
    settings/ settings, recurring, check for updates
android/      MainActivity (SMS inbox + open URL channels), manifest, icons
tool/         screenshot and PDF render helpers
docs/         screenshots and design images used in this README
```
