CREATE TABLE IF NOT EXISTS orders (
    order_id   SERIAL PRIMARY KEY,
    user_id    INT          NOT NULL,
    product    VARCHAR(128) NOT NULL,
    amount     NUMERIC(10,2) NOT NULL,
    status     VARCHAR(32)  NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id  SERIAL PRIMARY KEY,
    order_id    INT          NOT NULL REFERENCES orders(order_id),
    amount      NUMERIC(10,2) NOT NULL,
    method      VARCHAR(32)  NOT NULL,
    status      VARCHAR(32)  NOT NULL,
    paid_at     TIMESTAMP
);

INSERT INTO orders (order_id, user_id, product, amount, status, created_at) VALUES
(1001, 10, 'Ноутбук',       89990.00, 'completed',  '2025-03-01 10:00:00'),
(1002, 11, 'Смартфон',      49990.00, 'completed',  '2025-03-01 11:30:00'),
(1003, 12, 'Наушники',       7990.00, 'cancelled',  '2025-03-02 09:00:00'),
(1004, 13, 'Монитор',       34990.00, 'completed',  '2025-03-02 14:00:00'),
(1005, 14, 'Клавиатура',     4990.00, 'processing', '2025-03-03 08:15:00'),
(1006, 15, 'Мышь',           2990.00, 'completed',  '2025-03-03 12:00:00'),
(1007, 16, 'Планшет',       29990.00, 'refunded',   '2025-03-04 16:30:00'),
(1008, 17, 'Веб-камера',     5990.00, 'completed',  '2025-03-04 10:00:00'),
(1009, 18, 'SSD диск',      11990.00, 'cancelled',  '2025-03-05 13:45:00'),
(1010, 19, 'Оперативная память', 6990.00, 'completed', '2025-03-05 09:30:00'),
(1011, 20, 'Видеокарта',    59990.00, 'completed',  '2025-03-06 15:00:00'),
(1012, 21, 'Процессор',     24990.00, 'cancelled',  '2025-03-06 11:20:00'),
(1013, 22, 'Блок питания',   8990.00, 'completed',  '2025-03-07 08:00:00'),
(1014, 23, 'Корпус',        12990.00, 'processing', '2025-03-07 14:30:00'),
(1015, 24, 'Кулер',          3990.00, 'completed',  '2025-03-08 10:15:00'),
(1016, 25, 'Роутер',         6990.00, 'refunded',   '2025-03-08 16:00:00'),
(1017, 26, 'Принтер',       14990.00, 'completed',  '2025-03-09 09:00:00'),
(1018, 27, 'Сканер',        19990.00, 'cancelled',  '2025-03-09 12:30:00'),
(1019, 28, 'Колонки',        9990.00, 'completed',  '2025-03-10 11:00:00'),
(1020, 29, 'Микрофон',       7990.00, 'completed',  '2025-03-10 15:45:00')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO payments (order_id, amount, method, status, paid_at) VALUES
(1001, 89990.00, 'card',     'success',  '2025-03-01 10:05:00'),
(1002, 49990.00, 'card',     'success',  '2025-03-01 11:35:00'),
(1003,  7990.00, 'card',     'refunded', '2025-03-02 09:10:00'),
(1004, 34990.00, 'sbp',      'success',  '2025-03-02 14:05:00'),
(1005,  4990.00, 'card',     'pending',  NULL),
(1006,  2990.00, 'sbp',      'success',  '2025-03-03 12:05:00'),
(1007, 29990.00, 'card',     'refunded', '2025-03-04 17:00:00'),
(1008,  5990.00, 'sbp',      'success',  '2025-03-04 10:05:00'),
(1009, 11990.00, 'card',     'refunded', '2025-03-05 14:00:00'),
(1010,  6990.00, 'card',     'success',  '2025-03-05 09:35:00'),
(1011, 59990.00, 'sbp',      'success',  '2025-03-06 15:05:00'),
(1012, 24990.00, 'card',     'refunded', '2025-03-06 11:30:00'),
(1013,  8990.00, 'card',     'success',  '2025-03-07 08:05:00'),
(1014, 12990.00, 'sbp',      'pending',  NULL),
(1015,  3990.00, 'card',     'success',  '2025-03-08 10:20:00'),
(1016,  6990.00, 'card',     'refunded', '2025-03-08 16:10:00'),
(1017, 14990.00, 'sbp',      'success',  '2025-03-09 09:05:00'),
(1018, 19990.00, 'card',     'refunded', '2025-03-09 12:40:00'),
(1019,  9990.00, 'card',     'success',  '2025-03-10 11:05:00'),
(1020,  7990.00, 'sbp',      'success',  '2025-03-10 15:50:00');
