# Публикация Beauty Trust в TestFlight

## Текущие параметры

| Параметр | Значение |
|---|---|
| Bundle ID | `ru.beautytrust.app` |
| Team ID | `R8A654N8BA` |
| Display name | Beauty Trust |
| API | `https://apis.beautytrust.ru` |
| Export | `ios/ExportOptions.plist` |

## Один раз в Apple Developer / App Store Connect

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → App IDs → Bundle ID `ru.beautytrust.app`.
2. [App Store Connect](https://appstoreconnect.apple.com) → **Мои приложения** → **+**:
   - Name: `Beauty Trust`
   - Bundle ID: `ru.beautytrust.app`
3. Заполните карточку приложения (иконка 1024×1024, описание, категория, возраст, скриншоты iPhone).

## Сборка IPA

```bash
# при необходимости поднять build number в pubspec.yaml: 1.0.0+2
bash deploy/scripts/build-testflight.sh
```

IPA: `build/ios/ipa/*.ipa`

## Загрузка

```bash
open -a Transporter build/ios/ipa/*.ipa
```

Или в Xcode: **Product → Archive → Distribute App → App Store Connect**.

## TestFlight

1. Дождитесь обработки билда в App Store Connect → TestFlight.
2. Первый билд проходит короткую проверку для тестирования.
3. Добавьте тестеров: **Internal** (команда) или **External** (почта / публичная ссылка).

## Важно

- На iPhone появится **новое** приложение (новый Bundle ID), старое `com.tbank.test...` можно удалить.
- Каждая новая загрузка — новый build number (`+N` в `pubspec.yaml`).
- Для установки с Mac локально по-прежнему: `flutter install --release -d 00008150-001E448A3C88401C`.
