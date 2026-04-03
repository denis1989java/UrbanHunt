# Deep Linking в Urban Hunt

## Обзор

Urban Hunt поддерживает deep linking для прямого перехода к челленджам через специальные ссылки.

## URL Схема

**Формат:** `urbanhunt://challenge/{challengeId}`

**Примеры:**
- `urbanhunt://challenge/abc123` - открывает челлендж с ID "abc123"
- `urbanhunt://challenge/xyz789` - открывает челлендж с ID "xyz789"

## Как это работает

### 1. Шаринг челленджа
Когда пользователь нажимает кнопку "Поделиться" на карточке челленджа:
- Создается deep link вида `urbanhunt://challenge/{id}`
- Открывается нативный iOS Share Sheet
- Пользователь может отправить ссылку через любой канал (Messages, WhatsApp, Email и т.д.)

### 2. Открытие deep link
Когда пользователь кликает на полученную ссылку:
- iOS открывает приложение Urban Hunt
- Приложение парсит URL и извлекает ID челленджа
- Открывается детальный экран челленджа (`ChallengeDetailView`)

### 3. Обработка при логауте
Если пользователь не залогинен:
- Deep link сохраняется в памяти
- После входа челлендж автоматически открывается

## Технические детали

### Info.plist конфигурация
```xml
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.urbanhunt.deeplink</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>urbanhunt</string>
    </array>
</dict>
```

### Обработчик в UrbanHuntApp.swift
```swift
.onOpenURL { url in
    handleDeepLink(url)
}

private func handleDeepLink(_ url: URL) {
    if url.scheme == "urbanhunt", url.host == "challenge" {
        if let challengeId = url.pathComponents.last {
            deepLinkChallengeId = challengeId
            showDeepLinkedChallenge = true
        }
    }
}
```

## API Эндпоинт

### GET /api/challenges/{id}
Получить конкретный челлендж по ID для отображения в детальном экране.

**Запрос:**
```
GET /api/challenges/abc123
Authorization: Bearer {firebase-token}
```

**Ответ (200 OK):**
```json
{
  "id": "abc123",
  "title": "Find the Hidden Street Art",
  "country": "Germany",
  "cityName": "Berlin",
  "status": "ACTIVE",
  "prizePhotoUrl": "https://...",
  "hints": [...],
  "createdBy": "user123",
  "creator": {
    "name": "John Doe",
    "pictureUrl": "https://..."
  },
  "commentsCount": 42,
  "createdAt": "2024-04-01T12:00:00Z",
  "nextHintDate": "2024-04-05T15:00:00Z"
}
```

## Экраны

### ChallengeDetailView
Детальный экран челленджа, который показывает:
- Информацию об авторе (с возможностью открыть профиль)
- Кнопку "Поделиться" (share)
- Название челленджа
- Локацию (страна и город)
- Статус (Active, Completed, Draft, Archived)
- Фото приза
- Дату следующей подсказки (если есть)
- Кнопки "Hints" и "Comments" с счетчиками
- Время создания челленджа

### Навигация из ленты
Теперь вся карточка челленджа в ленте кликабельна:
- Клик на карточку → открывает `ChallengeDetailView`
- Клик на аватар автора → открывает профиль автора
- Клик на кнопку share → открывает Share Sheet

## Тестирование

### Симулятор iOS
```bash
xcrun simctl openurl booted "urbanhunt://challenge/test-id"
```

### Safari (на устройстве)
1. Откройте Safari
2. Введите в адресной строке: `urbanhunt://challenge/test-id`
3. Приложение должно открыться автоматически

### Через команду в терминале (устройство подключено)
```bash
adb shell am start -a android.intent.action.VIEW -d "urbanhunt://challenge/test-id"
```

## Universal Links (будущее улучшение)

В будущем можно добавить поддержку Universal Links для более удобного шаринга:
- `https://urbanhunt.app/challenge/{id}` - работает как обычная веб-ссылка
- При клике на iOS автоматически откроется приложение (если установлено)
- Если приложение не установлено → откроется в браузере

Для этого потребуется:
1. Настроить Associated Domains в Xcode
2. Разместить файл `apple-app-site-association` на сервере
3. Обработать Universal Links в приложении
