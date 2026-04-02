# UrbanHunt API - Bruno Collection

Bruno коллекция для тестирования UrbanHunt API.

## Setup

1. Установите [Bruno](https://www.usebruno.com/)
2. Откройте коллекцию: `File > Open Collection` → выберите папку `bruno-collection`
3. Выберите environment: `local` или `production`

## Получение Firebase Token

### Вариант 1: Через мобильное приложение
```kotlin
// Android
Firebase.auth.currentUser?.getIdToken(false)?.await()?.token
```

### Вариант 2: Через Firebase Console
1. Откройте Firebase Console
2. Authentication → Users → выберите пользователя
3. Скопируйте UID
4. Используйте Firebase REST API для получения токена

### Вариант 3: Через gcloud (для тестирования)
```bash
gcloud auth print-identity-token
```

## Environments

### Local
- `baseUrl`: http://localhost:8080
- Требует локальный запуск приложения

### Production
- `baseUrl`: https://your-app.run.app
- Требует деплой в GCP Cloud Run

## Переменные

Отредактируйте environment файлы и замените:
- `firebaseToken` - ваш Firebase ID token
- `challengeId` - будет автоматически заполнен после создания челленджа
- `commentId` - будет автоматически заполнен после создания комментария

## Структура коллекции

```
📁 UrbanHunt API
├── 📁 Health
│   └── Health Check (public)
├── 📁 Challenges
│   ├── Get All Challenges (public)
│   ├── Create Challenge (auth)
│   ├── Get Challenge by ID - Public
│   ├── Get Challenge by ID - Authenticated (with hints)
│   ├── Add Hint (auth)
│   └── Complete Challenge (auth)
├── 📁 Comments
│   ├── Get Comments (public)
│   ├── Create Comment (auth)
│   ├── Get Comments Count (public)
│   └── Delete Comment (auth)
└── 📁 Auth
    ├── Get Current User (auth)
    └── Sync User Profile (auth)
```

## Testing Flow

1. **Health Check** - проверить что API доступен
2. **Sync User Profile** - синхронизировать профиль
3. **Create Challenge** - создать челлендж (сохранится `challengeId`)
4. **Get Challenge (Public)** - проверить что hints пустые
5. **Get Challenge (Authenticated)** - проверить что hints есть
6. **Create Comment** - добавить комментарий (сохранится `commentId`)
7. **Get Comments** - получить список комментариев
8. **Complete Challenge** - завершить челлендж