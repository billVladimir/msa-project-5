## Задание 5. Мониторинг, логирование и оповещение для Spring Batch ETL

### Подготовка окружения

1. Установите Docker и Docker Compose.
2. Опционально для просмотра кода: JDK 17, Gradle 8.x или IntelliJ IDEA.

### Запуск

Из директории `task-5/initial/`:

```bash
docker-compose up --build
```

Dockerfile использует multi-stage build - локальная сборка не требуется.

При первом запуске PostgreSQL автоматически создаёт таблицы и загружает справочные данные из `schema-all.sql`.

### Получаемые компоненты

| Сервис | URL | Описание |
| :- | :- | :- |
| **PostgreSQL** | `localhost:5432` | БД `productsdb` |
| **batch-processing** | `localhost:8080` | Spring Batch ETL-приложение |
| **Prometheus** | [localhost:9090](http://localhost:9090) | Сбор метрик |
| **Grafana** | [localhost:3000](http://localhost:3000) | Дашборды (admin/admin) |
| **Elasticsearch** | [localhost:9200](http://localhost:9200) | Хранение логов |
| **Kibana** | [localhost:5601](http://localhost:5601) | Визуализация логов |
| **Logstash** | `localhost:5044` | Приём логов от Filebeat |
| **Filebeat** | - | Сбор логов Docker-контейнеров |

### Проверка метрик

1. Откройте Prometheus: [localhost:9090/targets](http://localhost:9090/targets) - убедитесь, что target `batch-processing` в состоянии UP.
2. Откройте Grafana: [localhost:3000](http://localhost:3000) (admin/admin) → дашборд «Batch Processing Dashboard».
3. Метрики приложения доступны по: [localhost:8080/actuator/prometheus](http://localhost:8080/actuator/prometheus).

### Проверка логирования

1. Откройте Kibana: [localhost:5601](http://localhost:5601).
2. Создайте Index Pattern: `filebeat-*`.
3. Перейдите в Discover - должны быть видны JSON-логи приложения batch-processing.

### Проверка алертов

1. Откройте Prometheus: [localhost:9090/alerts](http://localhost:9090/alerts) - настроены алерты `HighCpuUsage` и `HighMemoryUsage`.

### Остановка и очистка

```bash
docker-compose down -v
```

### Документация

- [MONITORING.md](./MONITORING.md) - обоснование выбора метрик, логирования и оповещений.
- [diagrams/c4-monitoring.puml](./diagrams/c4-monitoring.puml) - C4 диаграмма архитектуры.
