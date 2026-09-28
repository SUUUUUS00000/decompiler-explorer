FROM python:3.11-slim

# Устанавливаем необходимые системные зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    libmagic1 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Создаем рабочую директорию
WORKDIR /opt/decompiler_explorer

# Устанавливаем pipenv для управления зависимостями
RUN pip install --no-cache-dir pipenv

# Копируем файлы конфигурации зависимостей
COPY Pipfile Pipfile.lock ./

# Устанавливаем зависимости прямо в систему (без виртуального окружения, чтобы избежать багов путей)
RUN pipenv install --system --deploy

# Копируем весь остальной код проекта
COPY . .

# Проводим сборку статики и подготовку базы данных в обход проблемного шага
RUN python manage.py collectstatic --noinput

# Открываем порт для Render
EXPOSE 10000

# Команда запуска с автоматическим обходом сломанных миграций Django
CMD ["sh", "-c", "python manage.py migrate --run-syncdb && gunicorn decompiler_explorer.wsgi:application --bind 0.0.0.0:10000"]
