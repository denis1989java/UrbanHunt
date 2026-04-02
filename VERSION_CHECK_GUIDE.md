# Version Check Implementation Guide

## ✅ Что добавлено:

### 1. Backend (Java/Spring Boot)

**AppVersion.java** - модель для хранения информации о версиях
```java
- platform: "ios" / "android"
- minSupportedVersion: минимальная поддерживаемая версия
- latestVersion: последняя доступная версия
- updateMessage: сообщение для пользователя
- forcedUpdate: обязательное обновление или нет
```

**VersionService.java** - сервис для проверки версий
- Сравнение семантических версий (1.0.0 vs 1.2.0)
- Проверка поддержки версии

**VersionController.java** - endpoint `/api/version/check`
- POST запрос с platform и version
- Возвращает: supported, updateRequired, latestVersion, updateMessage

### 2. iOS Client

**AppVersion.swift** - модели запроса/ответа
```swift
VersionCheckRequest: { platform, version }
VersionCheckResponse: { supported, updateRequired, latestVersion, updateMessage }
```

**APIService.swift** - метод `checkVersion()`
- Автоматически берет версию из Info.plist
- Отправляет POST на `/api/version/check`

**UpdateRequiredView.swift** - экран принудительного обновления
- Большая иконка
- Сообщение об обновлении
- Кнопка перехода в App Store

**UrbanHuntApp.swift** - проверка версии при запуске
- Показывает ProgressView пока проверяется
- Если updateRequired → показывает UpdateRequiredView
- Иначе → нормальный flow (Login/Main)

**Info.plist**
- CFBundleShortVersionString: "1.0.0" - текущая версия

## 🚀 Как использовать:

### 1. Настройка в Firestore:

Создайте коллекцию `app_versions` и документ `ios`:

```json
{
  "platform": "ios",
  "minSupportedVersion": "1.0.0",
  "latestVersion": "1.0.0",
  "updateMessage": "Please update to the latest version to continue",
  "forcedUpdate": true
}
```

### 2. Когда выходит новая версия:

**Сценарий 1: Мягкое обновление** (можно продолжать на старой)
```json
{
  "minSupportedVersion": "1.0.0",  // оставляем старую
  "latestVersion": "1.2.0",        // обновляем на новую
  "forcedUpdate": false            // можно не обновлять
}
```

**Сценарий 2: Принудительное обновление** (старая версия не работает)
```json
{
  "minSupportedVersion": "1.2.0",  // поднимаем минимум
  "latestVersion": "1.2.0",        // текущая версия
  "forcedUpdate": true             // ОБЯЗАТЕЛЬНО обновить
}
```

### 3. Flow проверки:

```
App Launch
    ↓
Check Version (/api/version/check)
    ↓
    ├─ Supported → Continue to Login/Main
    │
    └─ Not Supported → Show Update Screen
                      ↓
                  User taps "Update Now"
                      ↓
                  Open App Store
```

## 📱 Тестирование:

### Test 1: Версия поддерживается
1. В Firestore: `minSupportedVersion: "1.0.0"`
2. В Info.plist: `CFBundleShortVersionString: "1.0.0"`
3. Запустите app → должно открыться нормально

### Test 2: Версия устарела
1. В Firestore: `minSupportedVersion: "2.0.0"`
2. В Info.plist: `CFBundleShortVersionString: "1.0.0"`
3. Запустите app → должен показаться экран обновления

### Test 3: Backend проверка
```bash
curl -X POST http://localhost:8080/api/version/check \
  -H "Content-Type: application/json" \
  -d '{"platform": "ios", "version": "1.0.0"}'
```

## 🎯 Преимущества:

- ✅ Проверка при каждом запуске
- ✅ Нет необходимости обновлять код - всё в Firestore
- ✅ Можно заблокировать старые версии мгновенно
- ✅ Полная локализация (EN/ES)
- ✅ Graceful fallback - если проверка не удалась, app продолжает работать
- ✅ Поддержка нескольких платформ (iOS, Android)

## 📝 Важные заметки:

1. **App Store URL**: Не забудьте заменить в `UpdateRequiredView.swift`:
   ```swift
   if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
   ```

2. **Первый запуск**: При первом запуске нужно создать документ в Firestore

3. **Обновление версии в iOS**:
   - Обновите `CFBundleShortVersionString` в Info.plist ИЛИ
   - В Xcode: Target → General → Version

4. **Semantic Versioning**: Формат MAJOR.MINOR.PATCH
   - MAJOR: несовместимые изменения API
   - MINOR: новая функциональность, обратно совместима
   - PATCH: баг-фиксы