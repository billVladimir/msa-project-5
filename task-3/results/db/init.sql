CREATE TABLE IF NOT EXISTS shipments (
    shipment_id    SERIAL PRIMARY KEY,
    client_id      INT            NOT NULL,
    driver_id      INT            NOT NULL,
    vehicle_id     INT            NOT NULL,
    origin         VARCHAR(255)   NOT NULL,
    destination    VARCHAR(255)   NOT NULL,
    status         VARCHAR(32)    NOT NULL,
    weight_kg      NUMERIC(10,2)  NOT NULL,
    cost           NUMERIC(12,2)  NOT NULL,
    created_at     TIMESTAMP      NOT NULL DEFAULT NOW(),
    delivered_at   TIMESTAMP
);

INSERT INTO shipments (client_id, driver_id, vehicle_id, origin, destination, status, weight_kg, cost, created_at, delivered_at)
SELECT
    (random() * 999 + 1)::int,
    (random() * 499 + 1)::int,
    (random() * 199 + 1)::int,
    (ARRAY['Москва','Санкт-Петербург','Казань','Новосибирск','Екатеринбург','Краснодар','Нижний Новгород','Самара','Ростов-на-Дону','Уфа'])[floor(random()*10+1)::int],
    (ARRAY['Владивосток','Хабаровск','Иркутск','Красноярск','Омск','Челябинск','Пермь','Волгоград','Воронеж','Тюмень'])[floor(random()*10+1)::int],
    (ARRAY['created','in_transit','delivered','cancelled','delayed'])[floor(random()*5+1)::int],
    (random() * 9900 + 100)::numeric(10,2),
    (random() * 490000 + 10000)::numeric(12,2),
    NOW() - (random() * 30 || ' days')::interval,
    CASE WHEN random() > 0.4 THEN NOW() - (random() * 10 || ' days')::interval ELSE NULL END
FROM generate_series(1, 500);
