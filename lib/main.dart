name: Build Flutter APK

# IMPORTANT: workflow_dispatch must NOT have any inputs
# The app pushes code directly to the repo file before triggering this workflow
on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22.0"
          channel: "stable"

      - name: Install dependencies
        run: flutter pub get

      - name: Build release APK
        run: flutter build apk --release

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
          retention-days: 7
