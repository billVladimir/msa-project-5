# Задание 1. Выбор и реализация решения для пакетной обработки данных

## Обоснование выбора технологического решения

### Выбранное решение: Apache Airflow

Airflow позволяет описывать пайплайны обработки данных как направленные ациклические графы (DAG) на Python, обеспечивая гибкость, масштабируемость и расширяемость.

### Почему Apache Airflow, а не альтернативы

| Критерий                                      | Apache Airflow                                  | Prefect                        | Dagster       | Spring Batch              |
| --------------------------------------------- | ----------------------------------------------- | ------------------------------ | ------------- | ------------------------- |
| Интеграция (BigQuery, Redshift, Kafka, Spark) | Готовые провайдеры                              | Частичная поддержка            | Ограниченная  | Ручная интеграция         |
| Ветвление и условные операторы                | `BranchPythonOperator`, `ShortCircuitOperator`  | Поддерживается через `if/else` | Conditionals  | `Flow` и `Decider`        |
| Retry/fallback                                | Встроенные                                      | Встроенная                     | Встроенная    | Встроенная                |
| Email-уведомления                             | Встроенные                                      | Через Automations              | Через Sensors | Через `ItemWriteListener` |
| Event-triggers                                | Sensors, Dataset-triggers, Deferrable operators | Event-driven из коробки        | Sensors       | Ограниченная              |
| Мониторинг                                    | Веб-интерфейс, интеграция с Prometheus/StatsD   | Cloud Dashboard                | Dagit UI      | Через Spring Actuator     |
| Зрелость и сообщество                         | Очень высокая                                   | Средняя                        | Средняя       | Высокая (Java-экосистема) |
| Облачные managed-решения                      | Google Cloud Composer, Amazon MWAA, Astronomer  | Prefect Cloud                  | Dagster Cloud | Нет                       |

### Интеграция с внешними системами

**BigQuery:**

- Провайдер `apache-airflow-providers-google` содержит `BigQueryInsertJobOperator`, `BigQueryCheckOperator`, `BigQueryGetDataOperator` и другие операторы.
- Поддерживает чтение, запись, выполнение SQL-запросов, проверку данных.

**Redshift:**

- Провайдер `apache-airflow-providers-amazon` содержит `RedshiftSQLOperator`, `S3ToRedshiftOperator`, `RedshiftToS3Operator`.
- Полный цикл ETL: загрузка из S3, трансформация, выгрузка.

**Kafka:**

- Провайдер `apache-airflow-providers-apache-kafka` содержит `ConsumeFromTopicOperator`, `ProduceToTopicOperator`, `AwaitMessageTriggerEvent`.
- Поддерживает чтение/запись сообщений, ожидание событий.

**Spark:**

- Провайдер `apache-airflow-providers-apache-spark` содержит `SparkSubmitOperator`, `SparkSqlOperator`.
- Позволяет запускать Spark-задачи локально, на YARN, Kubernetes или в облаке.

### Ветвление, условные операторы и event-triggers

- **Ветвление:** `BranchPythonOperator` позволяет динамически выбирать ветку DAG на основе Python-логики.
- **Условные операторы:** `ShortCircuitOperator` пропускает downstream-задачи при невыполнении условия.
- **Event-triggers:** Sensors (`FileSensor`, `ExternalTaskSensor`, `KafkaSensor`) ожидают внешних событий. Dataset-triggers в Airflow 2.4+ позволяют запускать DAG при обновлении набора данных.

### Retry, fallback-логика и email-уведомления

- **Retry:** Каждый оператор поддерживает параметры `retries` (количество попыток) и `retry_delay` (задержка между попытками). Поддерживается `retry_exponential_backoff`.
- **Fallback-логика:** `trigger_rule` позволяет запускать задачу при любом исходе upstream-задач (например, `trigger_rule='one_failed'` для обработки ошибок).
- **Email-уведомления:** Параметры `email_on_failure`, `email_on_success` на уровне задачи и `EmailOperator` для отправки письма как шага пайплайна. Также поддерживается `on_failure_callback` и `on_success_callback` для произвольной логики оповещения (Slack, Telegram и т.д.).

### Развёртывание в облачной среде

1. **Google Cloud Composer** - полностью управляемый сервис Airflow в GCP. Автоматическое масштабирование, интеграция с GCS, BigQuery, Dataproc.
2. **Amazon MWAA (Managed Workflows for Apache Airflow)** - управляемый Airflow в AWS. Интеграция с S3, Redshift, EMR.
3. **Kubernetes (self-managed)** - развёртывание через Helm-чарт `apache-airflow`. `KubernetesExecutor` запускает каждую задачу в отдельном Pod, обеспечивая изоляцию и масштабирование. Подходит для мультиоблачных и гибридных сценариев.
4. **Astronomer** - коммерческая платформа на базе Airflow с дополнительными инструментами CI/CD, мониторинга и управления.

Для текущего кейса (объём ~1 млн записей за запуск) достаточно `LocalExecutor` или `CeleryExecutor`. При росте нагрузки можно перейти на `KubernetesExecutor` без изменения DAG-файлов.

---

## POC (Proof of Concept)

### Архитектура POC

Локально развёрнутый Apache Airflow с DAG-пайплайном `marketing_pipeline`, который:

1. **Чтение из CSV-файла** - загрузка данных о статусах доставок из файловой системы.
2. **Чтение из PostgreSQL** - загрузка данных о заказах из БД.
3. **Анализ данных и ветвление** - подсчёт процента проблемных доставок. Если процент превышает порог - формируется отчёт об аномалиях (ветка `high_failure_rate`), иначе - стандартный отчёт (ветка `normal_report`).
4. **Email-уведомления** - настроены уведомления при успешном и неуспешном завершении пайплайна.
5. **Retry-политика** - каждый шаг пайплайна имеет настроенную политику повторных попыток.

### Структура файлов

### Запуск

```bash
# Инициализация Airflow
docker compose up airflow-init

# Запуск всех сервисов
docker compose up -d

# Веб-интерфейс доступен по адресу http://localhost:8080
# Логин: airflow / Пароль: airflow
```

### Остановка

```bash
docker compose down -v
```
