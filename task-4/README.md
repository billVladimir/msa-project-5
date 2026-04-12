## Задание 4. ETL с использованием Spring Batch

### Подготовка окружения

1. Установите Docker и Docker Compose.
2. Для просмотра и редактирования кода (опционально):
   - JDK 17
   - Gradle 8.x или IntelliJ IDEA (со встроенным Gradle)

### Запуск приложения

Сборка и запуск выполняются одной командой из директории `task-4/initial/`:

```bash
docker-compose up --build
```

Dockerfile использует multi-stage build:
- **Этап сборки** - Gradle 8.8 + JDK 17 собирают jar внутри контейнера.
- **Этап запуска** - лёгкий образ OpenJDK 17 запускает собранный jar.

При первом запуске PostgreSQL автоматически:
- Создаёт таблицы `products` и `loyality_data` (из `schema-all.sql`).
- Заполняет таблицу `loyality_data` данными программы лояльности.

Spring Batch автоматически создаёт служебные таблицы `BATCH_*` для метаданных заданий.

### Локальная сборка (без Docker)

Если JDK 17 и Gradle установлены локально:

```bash
./gradlew build
```

### Получаемые компоненты

- **PostgreSQL** (порт 5432) - база данных `productsdb`
- **batch-processing** - Spring Batch приложение (ETL-пайплайн)

### ETL-пайплайн

1. **Extract:** чтение CSV-файла `product-data.csv` (5 товаров).
2. **Transform:** обогащение данных из таблицы `loyality_data` - обновление поля `productData` по ключу `productSku`.
3. **Load:** batch-вставка обработанных записей в таблицу `products`.

### Проверка результатов

После завершения работы приложения в логах будут видны:
- Трансформация каждого товара (до и после).
- Финальное содержимое таблицы `products`.

Для ручной проверки через psql:

```bash
docker exec -it initial-postgresdb-1 psql -U postgres -d productsdb -c "SELECT * FROM products;"
```

### Остановка и очистка

```bash
docker-compose down -v
```
