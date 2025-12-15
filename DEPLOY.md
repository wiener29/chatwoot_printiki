# Инструкция по деплою Chatwoot на сервер

## Предварительные требования

- Сервер с Ubuntu/Debian
- Docker и Docker Compose установлены
- Домен chatwoot.udobno.tech резолвится на IP сервера (193.107.239.228)
- Открыты порты: 80, 443, 22

## Быстрый старт

### 1. Подключитесь к серверу

```bash
ssh root@193.107.239.228
```

### 2. Установите необходимые пакеты (если еще не установлены)

```bash
# Обновление системы
apt update && apt upgrade -y

# Установка Docker (если не установлен)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Установка Docker Compose
apt install docker-compose-plugin -y

# Установка Git
apt install git -y
```

### 3. Клонируйте репозиторий

```bash
cd /opt
git clone https://github.com/wiener29/chatwoot_printiki.git chatwoot
cd chatwoot
git checkout develop
```

### 4. Настройте переменные окружения

```bash
# Скопируйте пример конфигурации
cp .env.production.example .env.production

# Сгенерируйте секретные ключи
SECRET_KEY=$(openssl rand -hex 64)
POSTGRES_PASS=$(openssl rand -hex 32)
REDIS_PASS=$(openssl rand -hex 32)

# Отредактируйте файл
nano .env.production
```

Замените следующие значения в `.env.production`:

```env
FRONTEND_URL=https://chatwoot.udobno.tech
SECRET_KEY_BASE=<вставьте_сгенерированный_SECRET_KEY>
POSTGRES_PASSWORD=<вставьте_сгенерированный_POSTGRES_PASS>
REDIS_PASSWORD=<вставьте_сгенерированный_REDIS_PASS>
REDIS_URL=redis://:<вставьте_сгенерированный_REDIS_PASS>@redis:6379
```

**ВАЖНО**: Сохраните эти пароли в безопасном месте!

### 5. Первоначальный запуск (без SSL)

Для получения SSL сертификата нужно сначала запустить сервис:

```bash
# Запуск контейнеров
docker-compose -f docker-compose.deploy.yml up -d

# Проверка статуса
docker-compose -f docker-compose.deploy.yml ps

# Просмотр логов
docker-compose -f docker-compose.deploy.yml logs -f rails
```

Подождите 1-2 минуты, пока сервисы запустятся.

### 6. Инициализация базы данных

```bash
# Создание БД и миграции
docker-compose -f docker-compose.deploy.yml exec rails bundle exec rails db:prepare

# Создание первого пользователя (администратора)
docker-compose -f docker-compose.deploy.yml exec rails bundle exec rails chatwoot:db:seed
```

**ВАЖНО**: Сохраните логин и пароль администратора, который будет выведен!

### 7. Получение SSL сертификата

```bash
# Получение сертификата через Certbot
docker-compose -f docker-compose.deploy.yml run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d chatwoot.udobno.tech

# Активация SSL конфигурации
mv nginx/conf.d/chatwoot-init.conf nginx/conf.d/chatwoot-init.conf.disabled
mv nginx/conf.d/chatwoot.conf.disabled nginx/conf.d/chatwoot.conf

# Перезапуск nginx
docker-compose -f docker-compose.deploy.yml restart nginx
```

### 8. Проверка работы

Откройте в браузере: https://chatwoot.udobno.tech

Вы должны увидеть страницу входа Chatwoot.

## Управление

### Просмотр логов

```bash
# Все сервисы
docker-compose -f docker-compose.deploy.yml logs -f

# Только Rails
docker-compose -f docker-compose.deploy.yml logs -f rails

# Только Sidekiq
docker-compose -f docker-compose.deploy.yml logs -f sidekiq
```

### Перезапуск сервисов

```bash
# Все сервисы
docker-compose -f docker-compose.deploy.yml restart

# Конкретный сервис
docker-compose -f docker-compose.deploy.yml restart rails
```

### Остановка и запуск

```bash
# Остановка
docker-compose -f docker-compose.deploy.yml down

# Запуск
docker-compose -f docker-compose.deploy.yml up -d
```

### Обновление до новой версии

```bash
# Используйте deploy скрипт
chmod +x deploy.sh
./deploy.sh
```

Или вручную:

```bash
# Получение обновлений
git pull origin develop

# Получение нового образа
docker-compose -f docker-compose.deploy.yml pull

# Перезапуск с новой версией
docker-compose -f docker-compose.deploy.yml up -d

# Миграции (если есть)
docker-compose -f docker-compose.deploy.yml exec rails bundle exec rails db:migrate
```

## Резервное копирование

### Бэкап базы данных

```bash
# Создание бэкапа
docker-compose -f docker-compose.deploy.yml exec postgres pg_dump \
  -U postgres chatwoot_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление из бэкапа
docker-compose -f docker-compose.deploy.yml exec -T postgres psql \
  -U postgres chatwoot_production < backup_20250101_120000.sql
```

### Бэкап файлов (загруженные медиа)

```bash
# Создание архива
docker run --rm \
  -v chatwoot_storage_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/storage_backup_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

## Устранение проблем

### Проверка здоровья контейнеров

```bash
docker-compose -f docker-compose.deploy.yml ps
```

### Перезапуск всех сервисов

```bash
docker-compose -f docker-compose.deploy.yml down
docker-compose -f docker-compose.deploy.yml up -d
```

### Проверка подключения к БД

```bash
docker-compose -f docker-compose.deploy.yml exec postgres psql -U postgres -d chatwoot_production -c "SELECT 1;"
```

### Очистка логов

```bash
# Очистка Docker логов
docker system prune -a --volumes
```

### Rails консоль

```bash
docker-compose -f docker-compose.deploy.yml exec rails bundle exec rails console
```

## Полезные ссылки

- Документация Chatwoot: https://www.chatwoot.com/docs
- GitHub репозиторий: https://github.com/wiener29/chatwoot_printiki
- Оригинальный Chatwoot: https://github.com/chatwoot/chatwoot

## Безопасность

1. **Регулярно обновляйте пароли** в `.env.production`
2. **Настройте firewall** (ufw):
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```
3. **Регулярно делайте бэкапы** БД и файлов
4. **Мониторьте логи** на предмет подозрительной активности
5. **Обновляйте систему**:
   ```bash
   apt update && apt upgrade -y
   ```

## Контакты для поддержки

Если возникли проблемы, создайте issue в GitHub: https://github.com/wiener29/chatwoot_printiki/issues
