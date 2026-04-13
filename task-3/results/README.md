# Задание 3. Distributed Scheduling с K8s CronJob

## Описание решения

Kubernetes CronJob `shipments-exporter` каждый день в 20:00 запускает Pod с Node.js-скриптом, который:

1. Подключается к PostgreSQL внутри кластера.
2. Выполняет `SELECT * FROM shipments`.
3. Записывает результат в CSV-файл на PersistentVolume.
4. Pod завершается и уничтожается.

## Конфигурация CronJob

| Параметр                     | Значение     | Описание                               |
| ---------------------------- | ------------ | -------------------------------------- |
| `schedule`                   | `0 20 * * *` | Каждый день в 20:00                    |
| `concurrencyPolicy`          | `Forbid`     | Не допускать параллельных запусков     |
| `backoffLimit`               | `3`          | 3 повторные попытки при сбое           |
| `activeDeadlineSeconds`      | `600`        | Таймаут 10 минут                       |
| `restartPolicy`              | `OnFailure`  | Перезапуск контейнера при ошибке       |
| `successfulJobsHistoryLimit` | `7`          | Хранить историю успешных Job за неделю |
| `failedJobsHistoryLimit`     | `3`          | Хранить 3 последних неуспешных Job     |

---

## Пошаговая инструкция запуска в MiniKube

### Предварительные требования

- Установлен [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- Установлен [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Установлен [Docker](https://docs.docker.com/get-docker/)

### Шаг 1. Запуск Minikube

```bash
minikube start --driver=docker
```

### Шаг 2. Сборка Docker-образа внутри Minikube

Чтобы CronJob мог использовать образ без push в registry, собираем его прямо в Docker-демоне Minikube:

```bash
eval $(minikube docker-env)

cd task-3/results/exporter

# WSL/Linux: если сборка падает с «docker-credential-desktop.exe: exec format error»
# используйте минимальный docker-config из репозитория (без credsStore Docker Desktop):
export DOCKER_CONFIG="$(cd ../docker-config && pwd)"

docker build -t shipments-exporter:latest .
```

### Шаг 3. Применение K8s-манифестов

```bash
cd ../k8s

# Создать namespace
kubectl apply -f namespace.yaml

# Применить все ресурсы
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f pvc.yaml
kubectl apply -f postgres.yaml
kubectl apply -f cronjob.yaml
```

### Шаг 4. Дождаться готовности PostgreSQL

```bash
kubectl -n logistics get pods -w
```

Дождитесь, пока Pod `postgres-*` перейдёт в статус `Running` и `READY 1/1`.

### Шаг 5. Проверить CronJob

```bash
kubectl -n logistics get cronjob
```

### Шаг 6. Запустить Job вручную (не ждать 20:00)

```bash
kubectl -n logistics create job --from=cronjob/shipments-exporter shipments-export-test
```

### Шаг 7. Проверить выполнение Job

```bash
# Статус Job
kubectl -n logistics get jobs

# Статус Pod
kubectl -n logistics get pods -l app=shipments-exporter
```

### Шаг 8. Посмотреть логи

```bash
kubectl -n logistics logs job/shipments-export-test
```

### Шаг 9. Описать все ресурсы (итоговая проверка)

```bash
kubectl -n logistics get all
kubectl -n logistics get pvc
kubectl -n logistics get cronjob
```

## Очистка

```bash
kubectl delete namespace logistics
minikube stop
```
