## Задание 6. Настройка трейсинга

### Что реализовано

1. **API endpoint для запуска ETL-задачи** - `POST /api/jobs/import-products`. Job больше не запускается автоматически при старте приложения (`spring.batch.job.enabled=false`).
2. **Клиентское приложение** - shell-скрипт, который ожидает готовности приложения и дважды вызывает API (демонстрируя уникальные traceId для каждого запроса).
3. **Трейсинг в логах** - каждое лог-событие содержит:
   - `traceId` - уникальный идентификатор трейса запроса (Micrometer Tracing + Brave)
   - `spanId` - идентификатор спана в рамках трейса
   - `uri` - HTTP метод + URI запроса (через MDC-фильтр)
4. **100% sampling** - все запросы трейсятся (`management.tracing.sampling.probability=1.0`).

### Запуск

Из директории `task-6/initial/`:

```bash
docker compose up -d --build
```

### Компоненты

| Сервис               | URL                                     | Описание                    |
| :------------------- | :-------------------------------------- | :-------------------------- |
| **batch-processing** | [localhost:8080](http://localhost:8080) | Spring Batch ETL (API)      |
| **etl-client**       | -                                       | Клиент, вызывающий API      |
| **PostgreSQL**       | `localhost:5432`                        | БД `productsdb`             |
| **Filebeat**         | -                                       | Сбор логов из shared volume |
| **Logstash**         | `localhost:5044`                        | Приём и трансформация логов |
| **Elasticsearch**    | [localhost:9200](http://localhost:9200) | Хранение и индексация логов |
| **Kibana**           | [localhost:5601](http://localhost:5601) | Визуализация логов          |
| **Prometheus**       | [localhost:9090](http://localhost:9090) | Сбор метрик                 |
| **Grafana**          | [localhost:3000](http://localhost:3000) | Дашборды (admin/admin)      |

### Ручной запуск ETL-задачи

```bash
curl -X POST http://localhost:8080/api/jobs/import-products
```

### Проверка трейсинга в логах

1. Посмотрите логи приложения:

```bash
docker logs batch-processing --tail 30
```

В JSON-логах будут поля `traceId`, `spanId`, `uri`.

2. Откройте Kibana: [localhost:5601](http://localhost:5601) → Index Pattern `filebeat-*` → Discover.
3. В логах найдите события с полями `traceId`, `spanId`, `uri` - все события в рамках одного HTTP-запроса имеют одинаковый `traceId`.

### Остановка

```bash
docker compose down -v
```
