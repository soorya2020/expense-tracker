# Tally

A deliberately simple income and spending tracker for Android, built with Flutter.

- Log each income as it arrives (Salary, Extra, Help, Borrowed).
- Log spending as lump sums whenever you like.
- See your balance and how much of your spending your salary actually covered.
- Everything runs on your own pay cycle (for example the 3rd to the 2nd).
- Locked with a 4-digit PIN and optional fingerprint. All data stays on the phone.

## Install

Every push builds an APK with GitHub Actions. Open the **Releases** page on your phone,
download the newest `tally-N.apk`, and open it to install.

## Develop

```
flutter pub get
dart run build_runner build
flutter run
```
