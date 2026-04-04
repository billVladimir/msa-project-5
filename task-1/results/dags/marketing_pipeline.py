"""
Marketing Pipeline DAG — пайплайн пакетной обработки данных маркетингового отдела.

Шаги:
1. Чтение CSV-файла с данными о доставках (файловая система).
2. Чтение данных о заказах из PostgreSQL.
3. Объединение данных и анализ.
4. Ветвление: если процент проблемных доставок > порога — аномальный отчёт,
   иначе — стандартный отчёт.
5. Email-уведомления при успехе и неуспехе.
6. Retry-политика на каждом шаге.
"""

from __future__ import annotations

import csv
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.email import EmailOperator
from airflow.operators.python import BranchPythonOperator, PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

logger = logging.getLogger(__name__)

FAILURE_RATE_THRESHOLD = 0.20
CSV_PATH = "/opt/airflow/data/deliveries.csv"
SOURCE_DB_CONN_ID = "source_postgres"

PROBLEM_STATUSES = {"failed", "returned"}

default_args = {
    "owner": "marketing",
    "depends_on_past": False,
    "email": ["marketing@example.com"],
    "email_on_failure": True,
    "email_on_success": True,
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=15),
}


def _read_deliveries_csv(**context):
    """Читает CSV-файл с данными о статусах доставок."""
    path = Path(CSV_PATH)
    if not path.exists():
        raise FileNotFoundError(f"CSV file not found: {CSV_PATH}")

    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        deliveries = list(reader)

    logger.info("Loaded %d delivery records from CSV", len(deliveries))
    context["ti"].xcom_push(key="deliveries", value=deliveries)
    return len(deliveries)


def _read_orders_from_db(**context):
    """Читает данные о заказах и платежах из PostgreSQL."""
    hook = PostgresHook(postgres_conn_id=SOURCE_DB_CONN_ID)

    orders_sql = """
        SELECT o.order_id, o.user_id, o.product, o.amount, o.status,
               o.created_at::text,
               p.method  AS payment_method,
               p.status  AS payment_status
        FROM orders o
        LEFT JOIN payments p ON o.order_id = p.order_id
        ORDER BY o.order_id;
    """
    rows = hook.get_records(orders_sql)
    columns = [
        "order_id", "user_id", "product", "amount", "status",
        "created_at", "payment_method", "payment_status",
    ]
    orders = [dict(zip(columns, row)) for row in rows]

    for order in orders:
        if order.get("amount") is not None:
            order["amount"] = float(order["amount"])

    logger.info("Loaded %d order records from PostgreSQL", len(orders))
    context["ti"].xcom_push(key="orders", value=orders)
    return len(orders)


def _analyze_and_branch(**context):
    """Анализирует данные и выбирает ветку пайплайна."""
    ti = context["ti"]
    deliveries = ti.xcom_pull(task_ids="read_deliveries_csv", key="deliveries")
    orders = ti.xcom_pull(task_ids="read_orders_from_db", key="orders")

    total = len(deliveries)
    problem_count = sum(
        1 for d in deliveries if d.get("status") in PROBLEM_STATUSES
    )
    failure_rate = problem_count / total if total > 0 else 0.0

    total_revenue = sum(o.get("amount", 0) for o in orders if o.get("status") == "completed")
    cancelled_count = sum(1 for o in orders if o.get("status") in ("cancelled", "refunded"))

    summary = {
        "total_deliveries": total,
        "problem_deliveries": problem_count,
        "failure_rate": round(failure_rate, 4),
        "total_orders": len(orders),
        "total_revenue": round(total_revenue, 2),
        "cancelled_orders": cancelled_count,
    }
    ti.xcom_push(key="summary", value=summary)
    logger.info("Analysis summary: %s", json.dumps(summary, ensure_ascii=False))

    if failure_rate > FAILURE_RATE_THRESHOLD:
        logger.warning(
            "Failure rate %.1f%% exceeds threshold %.1f%% — branching to anomaly report",
            failure_rate * 100,
            FAILURE_RATE_THRESHOLD * 100,
        )
        return "generate_anomaly_report"

    logger.info("Failure rate %.1f%% is within norm — generating standard report", failure_rate * 100)
    return "generate_standard_report"


def _generate_anomaly_report(**context):
    """Формирует отчёт об аномалиях (высокий процент проблемных доставок)."""
    summary = context["ti"].xcom_pull(task_ids="analyze_and_branch", key="summary")
    report = (
        f"⚠ ANOMALY REPORT\n"
        f"{'='*40}\n"
        f"Failure rate: {summary['failure_rate']*100:.1f}%\n"
        f"Problem deliveries: {summary['problem_deliveries']} / {summary['total_deliveries']}\n"
        f"Cancelled orders: {summary['cancelled_orders']} / {summary['total_orders']}\n"
        f"Total revenue (completed): {summary['total_revenue']:,.2f} RUB\n"
        f"{'='*40}\n"
        f"ACTION REQUIRED: Review delivery partners and refund policies.\n"
    )
    logger.info("\n%s", report)
    context["ti"].xcom_push(key="report", value=report)


def _generate_standard_report(**context):
    """Формирует стандартный отчёт."""
    summary = context["ti"].xcom_pull(task_ids="analyze_and_branch", key="summary")
    report = (
        f"Standard Report\n"
        f"{'='*40}\n"
        f"Total deliveries: {summary['total_deliveries']}\n"
        f"Failure rate: {summary['failure_rate']*100:.1f}%\n"
        f"Total orders: {summary['total_orders']}\n"
        f"Total revenue (completed): {summary['total_revenue']:,.2f} RUB\n"
        f"Cancelled orders: {summary['cancelled_orders']}\n"
        f"{'='*40}\n"
        f"All metrics within normal range.\n"
    )
    logger.info("\n%s", report)
    context["ti"].xcom_push(key="report", value=report)


with DAG(
    dag_id="marketing_pipeline",
    default_args=default_args,
    description="Пайплайн пакетной обработки данных маркетингового отдела",
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["marketing", "batch", "poc"],
) as dag:

    read_csv = PythonOperator(
        task_id="read_deliveries_csv",
        python_callable=_read_deliveries_csv,
    )

    read_db = PythonOperator(
        task_id="read_orders_from_db",
        python_callable=_read_orders_from_db,
    )

    analyze = BranchPythonOperator(
        task_id="analyze_and_branch",
        python_callable=_analyze_and_branch,
    )

    anomaly_report = PythonOperator(
        task_id="generate_anomaly_report",
        python_callable=_generate_anomaly_report,
    )

    standard_report = PythonOperator(
        task_id="generate_standard_report",
        python_callable=_generate_standard_report,
    )

    notify_success = EmailOperator(
        task_id="notify_success",
        to="marketing@example.com",
        subject="Marketing Pipeline — {{ ds }} — SUCCESS",
        html_content="""
        <h2>Pipeline completed successfully</h2>
        <p>Execution date: {{ ds }}</p>
        <p>Report has been generated. Check Airflow logs for details.</p>
        """,
        trigger_rule="none_failed_min_one_success",
    )

    notify_failure = EmailOperator(
        task_id="notify_failure",
        to="marketing@example.com",
        subject="Marketing Pipeline — {{ ds }} — FAILURE",
        html_content="""
        <h2>Pipeline failed</h2>
        <p>Execution date: {{ ds }}</p>
        <p>Please check Airflow logs for error details.</p>
        """,
        trigger_rule="one_failed",
    )

    [read_csv, read_db] >> analyze
    analyze >> [anomaly_report, standard_report]
    [anomaly_report, standard_report] >> notify_success
    [anomaly_report, standard_report] >> notify_failure
