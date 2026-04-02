# Firestore Indexes Required

## Комментарии (Comments)

Для работы комментариев нужен композитный индекс:

**Collection:** `comments`
**Fields:**
- `challengeId` (Ascending)
- `createdAt` (Descending)

### Как создать:

**Вариант 1: Автоматически через ошибку**
1. Попробуйте загрузить комментарии в приложении
2. В логах backend появится ссылка на создание индекса
3. Откройте ссылку и нажмите "Create Index"

**Вариант 2: Вручную в консоли**
1. Откройте [Firebase Console](https://console.firebase.google.com/project/urbanhunt-491913/firestore/indexes)
2. Перейдите в Firestore → Indexes
3. Нажмите "Create Index"
4. Настройте:
   - Collection: `comments`
   - Field: `challengeId`, Order: Ascending
   - Field: `createdAt`, Order: Descending
5. Нажмите "Create"

### Время создания:
- Обычно 1-2 минуты
- Статус можно проверить в консоли

### Проверка:
После создания индекса комментарии должны загружаться без ошибок.