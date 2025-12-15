#!/bin/bash

# Chatwoot Deployment Script
# ==========================

set -e

echo "================================"
echo "Chatwoot Production Deployment"
echo "================================"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка .env.production
if [ ! -f .env.production ]; then
    echo -e "${RED}Ошибка: Файл .env.production не найден!${NC}"
    echo "Скопируйте .env.production.example в .env.production и заполните значения:"
    echo "  cp .env.production.example .env.production"
    exit 1
fi

# Проверка обязательных переменных
echo "Проверка конфигурации..."
source .env.production

if [ "$SECRET_KEY_BASE" == "ЗАМЕНИТЕ_ЭТОТ_КЛЮЧ_НА_СВОЙ" ]; then
    echo -e "${RED}Ошибка: SECRET_KEY_BASE не заменен!${NC}"
    echo "Сгенерируйте новый ключ: openssl rand -hex 64"
    exit 1
fi

if [ "$POSTGRES_PASSWORD" == "ЗАМЕНИТЕ_НА_СЛОЖНЫЙ_ПАРОЛЬ" ]; then
    echo -e "${RED}Ошибка: POSTGRES_PASSWORD не заменен!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Конфигурация проверена${NC}"
echo ""

# Остановка существующих контейнеров
echo "Остановка существующих контейнеров..."
docker-compose -f docker-compose.deploy.yml down || true
echo ""

# Получение последних изменений
echo "Получение последней версии из GitHub..."
git pull origin develop
echo -e "${GREEN}✓ Код обновлен${NC}"
echo ""

# Получение нового образа
echo "Получение последнего Docker образа..."
docker-compose -f docker-compose.deploy.yml pull
echo -e "${GREEN}✓ Образ обновлен${NC}"
echo ""

# Запуск контейнеров
echo "Запуск контейнеров..."
docker-compose -f docker-compose.deploy.yml up -d
echo -e "${GREEN}✓ Контейнеры запущены${NC}"
echo ""

# Ожидание запуска БД
echo "Ожидание запуска PostgreSQL..."
sleep 10
echo ""

# Миграции БД
echo "Выполнение миграций БД..."
docker-compose -f docker-compose.deploy.yml exec -T rails bundle exec rails db:prepare
echo -e "${GREEN}✓ Миграции выполнены${NC}"
echo ""

# Проверка статуса
echo "Проверка статуса контейнеров..."
docker-compose -f docker-compose.deploy.yml ps
echo ""

echo "================================"
echo -e "${GREEN}Деплой завершен успешно!${NC}"
echo "================================"
echo ""
echo "Chatwoot доступен по адресу: https://chatwoot.udobno.tech"
echo ""
echo "Полезные команды:"
echo "  docker-compose -f docker-compose.deploy.yml logs -f          - Просмотр логов"
echo "  docker-compose -f docker-compose.deploy.yml ps               - Статус контейнеров"
echo "  docker-compose -f docker-compose.deploy.yml restart          - Перезапуск"
echo "  docker-compose -f docker-compose.deploy.yml down             - Остановка"
echo ""
