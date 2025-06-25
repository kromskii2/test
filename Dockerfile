# Используем официальный образ Node.js с Alpine Linux
FROM node:18-alpine AS base

# Устанавливаем рабочую директорию
WORKDIR /usr/src/app

# Копируем файлы зависимостей
COPY package*.json ./

# Устанавливаем зависимости в production-режиме
RUN npm ci --production

# Копируем исходный код
COPY . .

# Указываем порт (хотя для polling-бота он не обязателен)
EXPOSE 80

# Финальный этап сборки
FROM base AS production

# Задаем переменную окружения NODE_ENV
ENV NODE_ENV=production

# Запускаем бота
CMD ["node", "index.js"]
