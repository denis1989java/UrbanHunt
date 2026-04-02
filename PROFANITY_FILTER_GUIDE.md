# Profanity Filter Implementation

## ✅ Что добавлено:

### 1. Backend (Java/Spring Boot)

**ProfanityFilterService.java**
- Сервис для проверки текста на запрещенные слова
- Загружает списки слов из файлов при старте приложения
- Поддержка английского (403 слова) и испанского (68 слов) языков
- Использует открытый репозиторий [LDNOOBW](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words)
- Методы:
  - `containsProfanity(String text)` - проверка наличия мата
  - `validateText(String text, String fieldName)` - валидация с исключением

**Файлы со словами:**
- `src/main/resources/profanity/en.txt` - 403 английских слова
- `src/main/resources/profanity/es.txt` - 68 испанских слов

**ChallengeService.java**
- Добавлена проверка имени челленджа при создании
- Добавлена проверка текста подсказки при добавлении

**GlobalExceptionHandler.java**
- Обработчик для `IllegalArgumentException`
- Возвращает 400 Bad Request с сообщением об ошибке

### 2. iOS Client

**APIService.swift**
- Добавлен новый тип ошибки: `APIError.serverError(String)`
- Парсинг ошибок сервера из JSON response
- Обработка в методах `createChallenge` и `addHint`

**CreateChallengeView.swift**
- Улучшенная обработка ошибок API
- Специальная обработка ошибки profanity filter
- Локализованное сообщение об ошибке

**Localizable.strings**
- English: "inappropriate_content" = "Inappropriate content detected. Please remove offensive language."
- Spanish: "inappropriate_content" = "Se detectó contenido inapropiado. Por favor elimine el lenguaje ofensivo."

## 🎯 Как работает:

1. **Создание челленджа:**
   - Пользователь вводит имя челленджа
   - iOS отправляет запрос на сервер
   - `ChallengeService` проверяет имя через `ProfanityFilterService`
   - Если найден мат → `IllegalArgumentException`
   - `GlobalExceptionHandler` возвращает 400 с сообщением
   - iOS показывает локализованное сообщение об ошибке

2. **Добавление подсказки:**
   - Пользователь вводит текст подсказки
   - iOS отправляет запрос на сервер
   - `ChallengeService.addHint()` проверяет текст
   - Если найден мат → ошибка 400
   - iOS показывает сообщение об ошибке

## 🔍 Примеры запрещенных слов:

**English (403 слова):**
- Базовые: fuck, shit, bitch, ass, damn, dick, pussy, asshole, bastard, slut, whore, cunt
- Фразы: "2 girls 1 cup", "alabama hot pocket", "son of a bitch"
- Полный список: `src/main/resources/profanity/en.txt`

**Spanish (68 слов):**
- Базовые: puta, mierda, coño, joder, cabrón, puto, pendejo, verga, chingar, culero, maricón
- Полный список: `src/main/resources/profanity/es.txt`

**Источник:** [LDNOOBW GitHub Repository](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words)

## 🧪 Тестирование:

**Backend Tests:**
```bash
# Запустить тесты
mvn test -Dtest=ProfanityFilterServiceTest
```

**Manual Testing:**

1. Запустите приложение
2. Попробуйте создать челлендж с именем "This is fucking bad"
3. Должна появиться ошибка: "Inappropriate content detected..."
4. Попробуйте добавить подсказку с текстом "Eres una puta"
5. Должна появиться та же ошибка

## 📝 Настройка:

### Добавление новых слов:

**Вариант 1: Редактировать файлы напрямую**
1. Откройте `src/main/resources/profanity/en.txt` или `es.txt`
2. Добавьте новое слово на новой строке
3. Перезапустите сервер

**Вариант 2: Создать custom список**
1. Создайте файл `src/main/resources/profanity/custom.txt`
2. Добавьте в `ProfanityFilterService` загрузку:
```java
allWords.addAll(loadWordsFromFile("profanity/custom.txt"));
```

### Добавление нового языка:

1. Скачайте список слов:
```bash
# Например, для французского
curl -o src/main/resources/profanity/fr.txt \
  https://raw.githubusercontent.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/fr
```

2. Добавьте в конструктор `ProfanityFilterService`:
```java
allWords.addAll(loadWordsFromFile("profanity/fr.txt"));
```

3. Перезапустите сервер

### Доступные языки в LDNOOBW:
ar, cs, da, de, en, eo, es, fa, fi, fil, fr, fr-CA-u-sd-caqc, hi, hu, it, ja, ko, nl, no, pl, pt, ru, sv, th, tlh, tr, zh

## 🎨 UI/UX:

- ❌ При обнаружении мата: красное сообщение об ошибке под формой
- ✅ При успешном сохранении: закрытие формы и возврат на главный экран
- 🌍 Поддержка локализации (EN/ES)

## 🔒 Безопасность:

- ✅ Проверка на backend (нельзя обойти)
- ✅ Централизованное управление списком слов
- ✅ Case-insensitive проверка
- ✅ Обработка многословных фраз ("son of a bitch", "2 girls 1 cup")
- ✅ Открытые списки от сообщества (регулярно обновляются)
- ✅ Легко добавлять новые языки

## 📦 Зависимости:

Новых зависимостей не требуется - используются стандартные Java библиотеки (regex, Pattern, ClassPathResource)

## 🌍 Преимущества использования LDNOOBW:

1. **Полнота** - 403 английских и 68 испанских слов вместо 20 захардкоженных
2. **Актуальность** - списки регулярно обновляются сообществом
3. **Мультиязычность** - поддержка 30+ языков
4. **Простота обновления** - просто заменить файл .txt
5. **Open Source** - можно контрибьютить и добавлять свои слова