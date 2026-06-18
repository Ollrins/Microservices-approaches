#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Генерация трафика для микросервисов${NC}"
echo -e "${BLUE}========================================${NC}"

# Получение токена
echo -e "${YELLOW}📝 Получение JWT токена...${NC}"
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"login":"bob", "password":"qwe123"}' \
  http://localhost:8080/v1/token | tr -d '"')

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Не удалось получить токен!${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Токен получен${NC}"

# Создание тестового файла
echo "test content for upload" > test.jpg

# Функция для случайной задержки
random_sleep() {
  sleep $(awk -v min=0.1 -v max=0.8 'BEGIN{srand(); print min+rand()*(max-min)}')
}

# Счётчики
TOTAL_REQUESTS=0
SUCCESS_REQUESTS=0
ERROR_REQUESTS=0

echo -e "\n${BLUE}📊 Начинаем генерацию трафика...${NC}\n"

# Цикл на 100 итераций
for i in {1..100}; do
  # Случайный выбор действия
  ACTION=$((RANDOM % 5))
  
  case $ACTION in
    0)
      # GET /v1/user - 20% запросов
      echo -n "🔵 GET /v1/user "
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:8080/v1/user)
      ;;
    1)
      # POST /v1/upload - 20% запросов
      echo -n "🟢 POST /v1/upload "
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: octet/stream' --data-binary @test.jpg http://localhost:8080/v1/upload)
      ;;
    2)
      # POST /v1/token - 20% запросов (получение нового токена)
      echo -n "🟡 POST /v1/token "
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' http://localhost:8080/v1/token)
      ;;
    3)
      # GET /v1/user с ошибкой (неправильный токен) - 20% запросов
      echo -n "🔴 GET /v1/user (invalid token) "
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalid_token" http://localhost:8080/v1/user)
      ;;
    4)
      # GET /v1/user с ошибкой (без токена) - 20% запросов
      echo -n "🔴 GET /v1/user (no token) "
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/user)
      ;;
  esac
  
  # Обновление счётчиков
  TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
  if [ $RESPONSE -ge 200 ] && [ $RESPONSE -lt 400 ]; then
    SUCCESS_REQUESTS=$((SUCCESS_REQUESTS + 1))
    echo -e "${GREEN}$RESPONSE${NC}"
  else
    ERROR_REQUESTS=$((ERROR_REQUESTS + 1))
    echo -e "${RED}$RESPONSE${NC}"
  fi
  
  # Случайная задержка
  random_sleep
  
  # Прогресс каждые 10 запросов
  if [ $((i % 10)) -eq 0 ]; then
    echo -e "${BLUE}--- Прогресс: $i/100 запросов ---${NC}"
  fi
done

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}📊 Статистика:${NC}"
echo -e "${GREEN}✅ Успешных запросов: $SUCCESS_REQUESTS${NC}"
echo -e "${RED}❌ Ошибок: $ERROR_REQUESTS${NC}"
echo -e "${BLUE}📊 Всего запросов: $TOTAL_REQUESTS${NC}"
echo -e "${BLUE}========================================${NC}"

# Дополнительная генерация для MinIO метрик
echo -e "\n${YELLOW}📦 Генерация трафика для MinIO...${NC}"
for i in {1..10}; do
  # Загрузка файлов разного размера
  dd if=/dev/urandom of=file_$i.bin bs=$((RANDOM % 100 + 1))k count=1 2>/dev/null
  curl -s -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: octet/stream' --data-binary @file_$i.bin http://localhost:8080/v1/upload > /dev/null
  echo -n "."
  rm file_$i.bin
  sleep 0.2
done
echo -e "${GREEN} ✅ MinIO трафик сгенерирован${NC}"

echo -e "\n${GREEN}🎉 Генерация трафика завершена!${NC}"
