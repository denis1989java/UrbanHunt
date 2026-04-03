# Инструкция по запуску UrbanHunt с динамической локализацией

## ✅ Что уже сделано:

### Backend:
- ✅ Бэкенд запущен в фоне (mvn spring-boot:run)
- ✅ Endpoint `/api/locales` доступен без аутентификации
- ✅ В базе данных: English и Español

### iOS:
- ✅ Xcode открыт с проектом UrbanHunt
- ✅ Все новые файлы на месте:
  - `Helpers/LocalizationManager.swift` - менеджер локализации
  - `Helpers/LocalizedView.swift` - обертка для динамического обновления
  - `Models/AppLocale.swift` - модель локали
  - `Views/SettingsView.swift` - экран настроек
  - `Views/SideMenuView.swift` - боковое меню
- ✅ Старый `LocalizationHelper.swift` удален
- ✅ Все views обновлены для поддержки динамической локализации

## 📱 Что делать в Xcode:

1. **Добавьте новые файлы в проект** (если они не в Project Navigator):
   - Project Navigator → UrbanHunt → Models
   - Правый клик → Add Files to "UrbanHunt"
   - Выберите `AppLocale.swift` (если не виден)
   - Повторите для Helpers и Views

2. **Clean Build Folder:**
   - `Cmd + Shift + K`

3. **Build:**
   - `Cmd + B`
   - Если будут ошибки - проверьте что файлы добавлены в проект

4. **Run:**
   - `Cmd + R`

## 🎯 Тестирование:

1. Откройте приложение
2. Нажмите бургер-меню (три полоски)
3. Нажмите "Settings" / "Configuración"
4. Выберите язык:
   - **English** (English)
   - **Spanish** (Español)
5. **Язык меняется мгновенно во всем приложении без перезапуска!** 🎉

## 🔧 Как это работает:

1. **LocalizationManager** - Singleton ObservableObject
   - Хранит `currentLanguage` (Published)
   - Метод `localizedString()` загружает строки из нужного .lproj

2. **String.localized** extension:
   - Использует `LocalizationManager.shared.localizedString()`

3. **LocalizedView** wrapper:
   - Оборачивает views
   - При изменении `currentLanguage` - обновляет view через `.id()`

4. **SettingsView**:
   - При выборе языка → `localizationManager.currentLanguage = code`
   - Триггерит обновление всех LocalizedView

## 📝 Примечания:

- Язык сохраняется в UserDefaults
- При запуске приложения загружается сохраненный язык
- Все тексты в приложении используют `.localized`
- Backend endpoint `/api/locales` возвращает список языков из Firestore

## 🐛 Если что-то не работает:

1. Проверьте что бэкенд запущен: `curl http://localhost:8080/api/locales`
2. Проверьте что все файлы добавлены в Xcode проект
3. Проверьте консоль Xcode на ошибки
4. Clean и rebuild проект