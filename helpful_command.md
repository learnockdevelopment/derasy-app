# Helpful Commands that you can use

<!-- Change Package Name Android Command -->
flutter pub run change_app_package_name:main com.new.package.name

<!-- Change Splash Screen & logo -->
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons:main

<!-- BUILD APK FOR TEST -->
flutter build apk --split-per-abi --obfuscate --split-debug-info=./private/data/

<!-- BUILD APPBUNDLE FOR RELEASE in Playstore (Android) -->
flutter build appbundle --obfuscate --split-debug-info=./private/data/

<!-- BUILD APPBUNDLE FOR RELEASE in AppStore (iOS) -->
flutter build ipa --obfuscate --split-debug-info=./private/data/ --build-name=1.0.0+1 --build-number=1

<!-- -------------------------------- -->
Test Your App Links via: this command:

adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://newspro.uixxy.com/elon-musk-bought-twitter/"'
