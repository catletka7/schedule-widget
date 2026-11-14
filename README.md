# ScheduleWidget — Виджет «Следующая пара» для iOS

Готовый Xcode-проект с виджетом (Small) и приложением для iPhone. Сборка работает **без Мака** через GitHub Actions.

---

## Что внутри

| Компонент | Описание |
|-----------|----------|
| **ScheduleApp** | Приложение: текущая/следующая пара, расписание на неделю, переключение чётная/нечётная |
| **ScheduleWidget** | WidgetKit (Small): следующая пара + обратный отсчёт до начала |
| **Shared** | Общие модели (`ScheduleModels.swift`) + `schedule.json` с твоим расписанием |
| **App Groups** | Синхронизация данных между приложением и виджетом |
| **GitHub Actions** | Автоматическая сборка `.ipa` на macOS-раннерах GitHub |

---

## Быстрый старт (без Мака)

### 1. Создай репозиторий на GitHub
```bash
# На GitHub.com: New repository → schedule-widget → Public
# НЕ инициализируй README/license/gitignore
```

### 2. Загрузи проект
```bash
cd schedule-widget
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/ТВОЙ_ЮЗЕР/schedule-widget.git
git push -u origin main
```

### 3. Запусти сборку
- Зайди в репозиторий → **Actions** → **Build & Export IPA** → **Run workflow** → **Run workflow**
- Подожди 3–5 минут
- В **Artifacts** скачай `ScheduleWidget-ipa.zip` → распакуй → получишь `ScheduleWidget.ipa`

### 4. Установи на iPhone

#### Вариант А: AltStore (рекомендую, бесплатно)
1. На ПК/ноутбуке установи [AltServer](https://altstore.io/)
2. Подключи iPhone кабелем → в AltServer выбери **Install AltStore** на свой iPhone
3. На iPhone: **Настройки → Основные → VPN и управление устройствами** → доверь свой Apple ID
4. Открой AltStore на iPhone → **My Apps → +** → выбери скачанный `.ipa`
5. Виджет появится в **Долгое нажатие на рабочий стол → + → Расписание**

#### Вариант Б: Sideloadly (Windows)
1. Скачай [Sideloadly](https://sideloadly.io/) на Windows
2. Подключи iPhone → выбери устройство → укажи `.ipa` → **Start**
3. Введи Apple ID/пароль (нужен для подписи)
4. На iPhone доверь профиль как в варианте А

#### Вариант В: GitHub Pages (прямая ссылка)
- Включи в репо: **Settings → Pages → Deploy from branch → gh-pages**
- После сборки `.ipa` появится на `https://ТВОЙ_ЮЗЕР.github.io/schedule-widget/ScheduleWidget.ipa`
- Открой ссылку на iPhone в Safari → **Загрузить** → **Разрешить** → установи через **Настройки → Основные → VPN и управление устройствами**

> ⚠️ Бесплатная подпись Apple действует **7 дней**. Через неделю переподпиши и переустанови (AltStore делает это автоматически в фоне).

---

## Настройка расписания

Файл: `Shared/schedule.json`

```json
{
  "group": "11 КІ",
  "timeSlots": [
    { "index": 0, "start": "08:15", "end": "09:15" },
    { "index": 1, "start": "09:25", "end": "10:45" }
    // ...
  ],
  "schedule": {
    "monday": {
      "even": [{ "slot": 1, "subject": "Математика", "room": "Каб. 25", "teacher": "Шеремет Х.Б." }],
      "odd":  [...]
    }
    // ...
  }
}
```

- `index` — номер слота в `timeSlots` (0-based)
- `even` / `odd` — чётная/нечётная неделя (определяется автоматически по номеру недели года)
- Изменил JSON → запушь в main → GitHub Actions пересоберёт → скачай новый `.ipa`

---

## Локальная разработка (есть Mac)

```bash
# Открыть проект
open ScheduleWidget.xcodeproj

# В Xcode:
# 1. Выбери команду ScheduleWidget (не Extension)
# 2. Signing & Capabilities → Automatically manage signing → твой Team
# 3. Product → Archive → Distribute App → Development → Export
```

---

## Структура проекта

```
schedule-widget/
├── ScheduleWidget.xcodeproj/
├── ScheduleApp/
│   ├── ScheduleAppApp.swift      # @main
│   ├── ContentView.swift         # Главный экран
│   ├── Info.plist
│   └── ScheduleApp.entitlements  # App Group
├── ScheduleWidget/
│   ├── ScheduleWidget.swift      # WidgetKit + Timeline
│   ├── Info.plist
│   └── ScheduleWidget.entitlements
├── Shared/
│   ├── ScheduleModels.swift      # Все модели + логика
│   └── schedule.json             # Твоё расписание
├── fastlane/
│   ├── Fastfile                  # Альтернативная сборка
│   └── Gemfile
└── .github/workflows/
    └── build.yml                 # CI/CD без Мака
```

---

## Как работает чётная/нечётная неделя

```swift
static func current(for date: Date = Date()) -> WeekParity {
    let weekOfYear = Calendar.current.component(.weekOfYear, from: date)
    return weekOfYear % 2 == 0 ? .even : .odd
}
```

- Неделя считается по ISO (понедельник = 1-й день)
- Переключение происходит в воскресенье
- В приложении можно принудительно переключить селектором

---

## Виджет: что показывает

| Состояние | Отображение |
|-----------|-------------|
| Пара идёт сейчас | 🟢 «Сейчас» + предмет, каб., учитель + прогресс-бар + таймер «Осталось: Хм Yс» |
| Пар нет, есть следующая | 🔵 «Следующая» + предмет, каб., учитель + время начала + таймер «Через: Хм Yс» |
| Пар нет вообще | ✅ «Пар нет / Отдыхай!» |

Обновление: каждую минуту + при смене пары (Timeline entries).

---

## Полезные ссылки

- [WidgetKit документация](https://developer.apple.com/documentation/widgetkit)
- [App Groups](https://developer.apple.com/documentation/foundation/nsfilemanager/1411239-containerurlforsecurityapplicatio)
- [AltStore FAQ](https://altstore.io/faq/)
- [GitHub Actions macOS runners](https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md)

---

## Лицензия

MIT — делай что хочешь.