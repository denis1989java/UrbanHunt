# Dark Mode Implementation

## ✅ Что добавлено:

### 1. ThemeManager.swift
- Singleton класс для управления темой
- Поддержка 3 режимов: System, Light, Dark
- Сохранение выбора в UserDefaults
- Автоматическое применение темы ко всем окнам

### 2. SettingsView обновлен
- Добавлена секция "Theme" / "Tema"
- 3 варианта выбора:
  - System (следует системной теме)
  - Light (светлая тема)
  - Dark (темная тема)

### 3. Локализация
**English:**
- theme = "Theme"
- theme_system = "System"
- theme_light = "Light"
- theme_dark = "Dark"

**Spanish:**
- theme = "Tema"
- theme_system = "Sistema"
- theme_light = "Claro"
- theme_dark = "Oscuro"

### 4. Color+Theme.swift
- Расширение Color с адаптивными цветами
- Автоматически адаптируется под светлую/темную тему
- Использует UIKit's semantic colors

### 5. UrbanHuntApp.swift
- Инициализация ThemeManager при запуске
- Применение сохраненной темы

## 🎨 Как работает:

1. **При запуске приложения:**
   - ThemeManager загружает сохраненную тему из UserDefaults
   - Применяет тему ко всем окнам приложения

2. **При выборе темы в настройках:**
   - ThemeManager.currentTheme меняется
   - Автоматически применяется к UIWindow.overrideUserInterfaceStyle
   - Вся UI мгновенно обновляется

3. **Адаптивные цвета:**
   - Color.theme.background - фон (белый/черный)
   - Color.theme.text - текст (черный/белый)
   - Color(uiColor: .systemBackground) автоматически меняется

## 🚀 Использование:

### В коде:
```swift
// Адаптивный фон
.background(Color.theme.background)

// Адаптивный текст
.foregroundColor(Color.theme.text)

// Системный цвет
.background(Color(uiColor: .systemBackground))
```

### В настройках:
1. Откройте боковое меню (бургер)
2. Settings / Configuración
3. Theme / Tema
4. Выберите: System / Light / Dark

## 📱 Тестирование:

1. Запустите приложение
2. Откройте Settings
3. Выберите "Dark" - приложение станет темным ⚫
4. Выберите "Light" - приложение станет светлым ⚪
5. Выберите "System" - следует системной теме 🔄

## 🎯 Преимущества:

- ✅ Мгновенное переключение без перезапуска
- ✅ Сохранение выбора пользователя
- ✅ Поддержка системной темы
- ✅ Все стандартные SwiftUI компоненты автоматически адаптируются
- ✅ Полная локализация

## 📝 Примечания:

- Большинство SwiftUI компонентов (Text, Button, List) автоматически адаптируются
- Кастомные цвета нужно заменить на семантические (Color.theme.*)
- Asset каталог может содержать разные изображения для Light/Dark режимов