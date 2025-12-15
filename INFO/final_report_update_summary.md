# Итоговый отчет о модификации Chatwoot

Этот документ содержит полное описание всех изменений, внесенных в систему для реализации AI агента, новых каналов связи и разблокировки Enterprise функций.

## 1. Разблокировка Enterprise Функций (Enterprise Unlock)

**Цель:** Обеспечить доступ ко всем функциям Enterprise версии без использования лицензионного ключа.

*   **Модификация кода:**
    *   Создан initializer `config/initializers/02_unlock_enterprise.rb`.
    *   Переопределены методы в модуле `BillingHelper` (`default_plan?`, `subscribed?`), чтобы они всегда возвращали `true` или соответствующие значения для плана "enterprise".
*   **База данных:**
    *   Создана миграция `db/migrate/20251215193500_enable_all_enterprise_features.rb`.
    *   Миграция обновляет `InstallationConfig` и таблицы аккаунтов, принудительно включая все фичи.

## 2. Интеграция AI Агента (Google Gemini)

**Цель:** Создать агента первой линии поддержки, который отвечает на сообщения пользователей и может передавать диалог оператору.

*   **Бэкенд сервис:** `app/services/ai/gemini_service.rb`
    *   Отвечает за взаимодействие с API Google Gemini.
    *   Получает ключ API из конфигурации системы (`InstallationConfig`), а не из переменных окружения, что позволяет менять его через UI.
*   **Асинхронная обработка:** `app/jobs/agent_bots/ai_response_job.rb`
    *   Обрабатывает входящие сообщения в фоновом режиме.
    *   Сохраняет историю диалога для контекста.
    *   Реализует логику эскалации: если AI генерирует токен `[ESCALATE]`, диалог переводится на оператора.
*   **Хук входящих сообщений:**
    *   Модифицирован `app/builders/messages/message_builder.rb`.
    *   Теперь при создании входящего сообщения проверяется флаг `ai_agent_enabled` у инбокса, и если он включен, запускается джоб AI ответа.
*   **Интерфейс (Frontend):**
    *   В настройки инбокса (`Settings.vue`) добавлен переключатель **"Enable AI Agent (Gemini)"**.

## 3. Новые Каналы Связи

Добавлена поддержка трех новых каналов. Для каждого канала реализованы модель, контроллер вебхуков и формы настройки.

### A. WhatsApp (через GreenAPI)
*   **Тип:** `Channel::WhatsappGreenApi`
*   **Компоненты:**
    *   Модель: `app/models/channel/whatsapp_green_api.rb`
    *   Контроллер: `app/controllers/webhooks/whatsapp_green_api_controller.rb`
    *   UI создания: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappGreenApi.vue`
*   **Особенности:** Полноценная обработка текстовых сообщений и файлов.

### B. VKontakte (VK)
*   **Тип:** `Channel::Vk`
*   **Компоненты:**
    *   Модель: `app/models/channel/vk.rb`
    *   Контроллер: `app/controllers/webhooks/vk_controller.rb`
    *   UI создания: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Vk.vue`
    *   Сервис пре-процессинга: `app/services/channel/pre_processing_service.rb`.
*   **Особенности:**
    *   Требует подтверждения сервера (Confirmation Token).
    *   **Pre-processing:** Если у пользователя VK нет номера телефона в системе, бот запрашивает его перед началом диалога.

### C. MAX Messenger
*   **Тип:** `Channel::Max`
*   **Компоненты:**
    *   Модель: `app/models/channel/max.rb`
    *   Контроллер: `app/controllers/webhooks/max_controller.rb`
    *   UI создания: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Max.vue`

## 4. Конфигурация и Развертывание

**Цель:** Обеспечить удобную настройку (через UI) и надежное развертывание.

*   **Управление ключами через UI:**
    *   В `config/installation_config.yml` добавлен `GEMINI_API_KEY` как редактируемый параметр.
    *   Ключ настраивается супер-админом в разделе **Configuration** (Super Admin Console).
*   **Переменные окружения (.env):**
    *   Создан файл `.env.example`, описывающий настройки для локальной разработки и продакшена.
    *   Убрана зависимость от хардкода API ключей в файле `.env`.
*   **Webhooks:**
    *   Frontend (`ConfigurationPage.vue`) обновлен для отображения корректных URL вебхуков для всех новых каналов.
    *   URL формируется динамически на основе `FRONTEND_URL` из настроек окружения.

## 5. Обновление: Настройки AI и Локализация (Refinement)

**Цель:** Перенос настроек AI (модель, промпт) в интерфейс и полный перевод на русский язык.

*   **Бэкенд:**
    *   В таблицу `inboxes` добавлены поля `ai_agent_model` и `ai_agent_prompt`.
    *   Миграция: `db/migrate/20251215201300_add_ai_config_to_inboxes.rb`.
    *   `GeminiService` теперь принимает модель и инструкцию динамически.
*   **Фронтенд:**
    *   В настройках инбокса (Settings -> Inboxes) добавлены поля:
        *   **Модель AI**: (по умолчанию `gemini-1.5-pro`).
        *   **Системный Промпт**: Инструкция для бота на русском.
    *   Все лейблы переведены на русский язык ("Включить AI Агента", "Включено", "Отключено").
*   **Локализация сервисов:**
    *   Сообщения от бота (запрос телефона, подтверждение) переведены на вежливый русский язык.

## Инструкция по запуску обновленной версии

1.  **Создать .env файл:**
    Скопируйте `.env.example` в `.env` и настройте `FRONTEND_URL` (например, `https://monitor.server.com` для продакшена).
2.  **Собрать и запустить контейнеры (если используете Docker):**
    ```bash
    docker-compose build
    docker-compose up -d
    ```
3.  **Выполнить миграции (ВАЖНО!):**
    ```bash
    docker-compose run --rm rails bundle exec rails db:migrate
    ```
4.  **Настроить AI:**
    *   В панели Супер-админа введите ключ Gemini API Key.
    *   В настройках Инбокса включите AI, укажите модель (например, `gemini-1.5-pro`) и напишите системный промпт (инструкцию) на русском языке.
5.  **Создать каналы:**
    В настройках (Settings -> Inboxes -> Add Inbox) выберите нужный канал (WhatsApp, VK или MAX).
