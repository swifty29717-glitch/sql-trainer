-- Schema for app DB (tasks catalog)
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  short_desc TEXT NOT NULL,
  level TEXT NOT NULL,             -- Easy | Medium | Hard | Advanced
  full_desc TEXT NOT NULL,
  dataset_sql TEXT NOT NULL,
  seed_sql TEXT NOT NULL,
  solution_sql TEXT NOT NULL,
  check_mode TEXT NOT NULL DEFAULT 'unordered' -- unordered | ordered
);

DELETE FROM tasks; -- for easy re-init in pet project

-- TASK 1: Users + Orders (LEFT JOIN + COUNT)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Заказы пользователей',
  'Вывести пользователей и количество их заказов (включая тех, у кого 0).',
  'Easy',
  'Сформируйте запрос, который вернёт список пользователей и число их заказов. В результате должны быть все пользователи, даже если у них нет заказов.

Ожидаемые колонки: name, orders_cnt',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );
  ',
  '
  INSERT INTO users (id, name) VALUES
    (1, ''Alice''),
    (2, ''Bob''),
    (3, ''Charlie''),
    (4, ''Diana'');

  INSERT INTO orders (id, user_id, amount, created_at) VALUES
    (1, 1, 100, ''2026-01-10''),
    (2, 1, 50,  ''2026-01-11''),
    (3, 2, 30,  ''2026-01-12'');
  ',
  '
  SELECT
    u.name AS name,
    COUNT(o.id) AS orders_cnt
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  GROUP BY u.id, u.name;
  ',
  'unordered'
);

-- TASK 2: Orders revenue per user (SUM + GROUP BY)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Выручка по пользователям',
  'Посчитать суммарную выручку по каждому пользователю.',
  'Easy',
  'Напишите запрос, который вернёт пользователей и суммарную выручку (total_amount) по их заказам.

Требования:
- Пользователи без заказов тоже должны быть в выдаче (total_amount = 0).

Ожидаемые колонки: name, total_amount',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );
  ',
  '
  INSERT INTO users (id, name) VALUES
    (1, ''Alice''),
    (2, ''Bob''),
    (3, ''Charlie''),
    (4, ''Diana'');

  INSERT INTO orders (id, user_id, amount) VALUES
    (1, 1, 100),
    (2, 1, 50),
    (3, 2, 30),
    (4, 2, 70),
    (5, 4, 25);
  ',
  '
  SELECT
    u.name AS name,
    COALESCE(SUM(o.amount), 0) AS total_amount
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  GROUP BY u.id, u.name;
  ',
  'unordered'
);

-- TASK 3: Products not ordered (NOT EXISTS)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Товары без заказов',
  'Найти товары, которые ни разу не покупали.',
  'Medium',
  'Даны таблицы товаров и строк заказов.
Найдите товары, которые не встречаются ни в одной строке заказа.

Ожидаемые колонки: product_name',
  '
  CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  );

  CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id)
  );
  ',
  '
  INSERT INTO products (id, name) VALUES
    (1, ''Keyboard''),
    (2, ''Mouse''),
    (3, ''Monitor''),
    (4, ''USB Cable''),
    (5, ''Laptop Stand'');

  INSERT INTO order_items (id, order_id, product_id, qty) VALUES
    (1, 101, 1, 1),
    (2, 101, 2, 2),
    (3, 102, 2, 1),
    (4, 103, 3, 1),
    (5, 103, 1, 1);
  ',
  '
  SELECT
    p.name AS product_name
  FROM products p
  WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.id
  );
  ',
  'unordered'
);

-- TASK 4: Top category by sales
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Лучшая категория по продажам',
  'Определить категорию с максимальной выручкой.',
  'Medium',
  'Есть товары с категориями и строки заказов.
Найдите категорию, у которой суммарная выручка (qty * price) максимальна.

Ожидаемые колонки: category, revenue',
  '
  CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price INTEGER NOT NULL
  );

  CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    qty INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id)
  );
  ',
  '
  INSERT INTO products (id, name, category, price) VALUES
    (1, ''Keyboard'',     ''Peripherals'', 100),
    (2, ''Mouse'',        ''Peripherals'', 50),
    (3, ''Monitor'',      ''Displays'',    300),
    (4, ''USB Cable'',    ''Accessories'', 10),
    (5, ''Laptop Stand'', ''Accessories'', 25);

  INSERT INTO order_items (id, order_id, product_id, qty) VALUES
    (1, 201, 1, 1),
    (2, 201, 2, 2),
    (3, 202, 3, 1),
    (4, 203, 4, 5),
    (5, 203, 5, 2),
    (6, 204, 2, 1);
  ',
  '
  SELECT
    p.category AS category,
    SUM(oi.qty * p.price) AS revenue
  FROM order_items oi
  JOIN products p ON p.id = oi.product_id
  GROUP BY p.category
  ORDER BY revenue DESC, category ASC
  LIMIT 1;
  ',
  'unordered'
);

-- TASK 5: Find only red cars (your task)
INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Найти все красные машины',
  'Найти только машины красного цвета.',
  'Easy',
  'У вас есть перечень автомобилей различных марок. Необходимо найти все машины красного цвета.

Ожидаемые колонки: car',
  '
  CREATE TABLE cars (
    id INTEGER PRIMARY KEY,
    car_name TEXT NOT NULL,
    color TEXT NOT NULL,
    price INTEGER NOT NULL
  );
  ',
  '
  INSERT INTO cars (id, car_name, color, price) VALUES
    (1, ''Nissan'',     ''Red'',     324000),
    (2, ''BMW'',        ''Yellow'',  1540000),
    (3, ''Audi'',       ''Green'',   2357000),
    (4, ''LADA'',       ''Red'',     1),
    (5, ''Opel'',       ''Black'',   2),
    (6, ''Mitsubishi'', ''Orange'',  100000);
  ',
  '
  SELECT
    car_name AS car
  FROM cars
  WHERE color = ''Red'';
  ',
  'unordered'
);
-- =========================
-- EASY TASKS
-- =========================

INSERT INTO tasks (title, short_desc, level, full_desc, dataset_sql, seed_sql, solution_sql, check_mode)
VALUES (
  'Пользователи старше 30',
  'Найти всех пользователей старше 30 лет',
  'Easy',
  'Выведите имена пользователей, чей возраст больше 30 лет.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
  );',
  '
  INSERT INTO users VALUES
  (1, ''Alice'', 25),
  (2, ''Bob'', 35),
  (3, ''Charlie'', 40),
  (4, ''Diana'', 30);',
  '
  SELECT name
  FROM users
  WHERE age > 30;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Все пользователи',
  'Вывести всех пользователей',
  'Easy',
  'Выведите всех пользователей из таблицы users.
Ожидаемые колонки: id, name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT
  );',
  '
  INSERT INTO users VALUES
  (1, ''Ann''),
  (2, ''Ben''),
  (3, ''Chris'');',
  '
  SELECT id, name FROM users;',
  'ordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Количество заказов',
  'Посчитать количество заказов',
  'Easy',
  'Подсчитайте общее количество заказов.
Ожидаемая колонка: orders_cnt',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY
  );',
  '
  INSERT INTO orders VALUES (1),(2),(3),(4);',
  '
  SELECT COUNT(*) AS orders_cnt FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Самый дорогой заказ',
  'Найти максимальную сумму заказа',
  'Easy',
  'Найдите максимальную сумму заказа.
Ожидаемая колонка: max_total',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    total INTEGER
  );',
  '
  INSERT INTO orders VALUES
  (1, 50),
  (2, 120),
  (3, 80);',
  '
  SELECT MAX(total) AS max_total FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи без возраста',
  'Найти пользователей с NULL возрастом',
  'Easy',
  'Выведите имена пользователей, у которых не указан возраст.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
  );',
  '
  INSERT INTO users VALUES
  (1, ''Tom'', NULL),
  (2, ''Jerry'', 20);',
  '
  SELECT name FROM users WHERE age IS NULL;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Топ-2 заказов',
  'Два самых дорогих заказа',
  'Easy',
  'Выведите два самых дорогих заказа по убыванию суммы.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    total INTEGER
  );',
  '
  INSERT INTO orders VALUES
  (1, 10),
  (2, 300),
  (3, 200);',
  '
  SELECT id, total FROM orders ORDER BY total DESC LIMIT 2;',
  'ordered'
);

-- =========================
-- MEDIUM TASKS
-- =========================

INSERT INTO tasks VALUES (
  NULL,
  'Заказы по пользователям',
  'Количество заказов у каждого пользователя',
  'Medium',
  'Для каждого пользователя посчитайте количество его заказов.
Ожидаемые колонки: name, orders_cnt',
  '
  CREATE TABLE users (id INTEGER, name TEXT);
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO users VALUES (1,''Alice''),(2,''Bob'');
  INSERT INTO orders VALUES (1,1),(2,1),(3,2);',
  '
  SELECT u.name, COUNT(o.id) AS orders_cnt
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Средний чек по статусу',
  'Средняя сумма заказов по статусу',
  'Medium',
  'Посчитайте среднюю сумму заказов для каждого статуса.
Ожидаемые колонки: status, avg_total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER, status TEXT);',
  '
  INSERT INTO orders VALUES
  (1,100,''done''),
  (2,200,''done''),
  (3,50,''new'');',
  '
  SELECT status, AVG(total) AS avg_total
  FROM orders
  GROUP BY status;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи без заказов',
  'Найти пользователей без заказов',
  'Medium',
  'Выведите пользователей, у которых нет заказов.
Ожидаемая колонка: name',
  '
  CREATE TABLE users (id INTEGER, name TEXT);
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO users VALUES (1,''A''),(2,''B'');
  INSERT INTO orders VALUES (1,1);',
  '
  SELECT u.name
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  WHERE o.id IS NULL;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Максимальный заказ пользователя',
  'Максимальный заказ для каждого пользователя',
  'Medium',
  'Для каждого пользователя найдите максимальную сумму его заказа.
Ожидаемые колонки: user_id, max_total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,300),(3,2,50);',
  '
  SELECT user_id, MAX(total) AS max_total
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Пользователи с >1 заказом',
  'Пользователи с более чем одним заказом',
  'Medium',
  'Выведите пользователей, у которых больше одного заказа.
Ожидаемая колонка: user_id',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO orders VALUES (1,1),(2,1),(3,2);',
  '
  SELECT user_id
  FROM orders
  GROUP BY user_id
  HAVING COUNT(*) > 1;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Сумма заказов пользователя',
  'Общая сумма заказов по пользователям',
  'Medium',
  'Для каждого пользователя посчитайте сумму его заказов.
Ожидаемые колонки: user_id, total_sum',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,50),(3,2,70);',
  '
  SELECT user_id, SUM(total) AS total_sum
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

-- =========================
-- HARD TASKS
-- =========================

INSERT INTO tasks VALUES (
  NULL,
  'Самый дорогой заказ каждого пользователя',
  'Найти топ-заказ по пользователю',
  'Hard',
  'Для каждого пользователя найдите его самый дорогой заказ.
Ожидаемые колонки: user_id, max_total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,200),(3,2,50);',
  '
  SELECT user_id, MAX(total) AS max_total
  FROM orders
  GROUP BY user_id;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Заказы выше среднего',
  'Заказы выше среднего чека',
  'Hard',
  'Выведите заказы, сумма которых выше средней суммы всех заказов.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,50),(2,150),(3,100);',
  '
  SELECT id, total
  FROM orders
  WHERE total > (SELECT AVG(total) FROM orders);',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Ранг заказов',
  'Ранжировать заказы по сумме',
  'Hard',
  'Пронумеруйте заказы по убыванию суммы.
Ожидаемые колонки: id, rank',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,300),(2,100),(3,200);',
  '
  SELECT id,
         RANK() OVER (ORDER BY total DESC) AS rank
  FROM orders;',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Заказы выше среднего по пользователю',
  'Коррелированный подзапрос',
  'Hard',
  'Выведите заказы, которые выше среднего заказа своего пользователя.
Ожидаемые колонки: id, total',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1,100),(2,1,200),(3,2,50);',
  '
  SELECT o.id, o.total
  FROM orders o
  WHERE o.total >
    (SELECT AVG(total)
     FROM orders
     WHERE user_id = o.user_id);',
  'unordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Самый активный пользователь',
  'Пользователь с максимальным числом заказов',
  'Hard',
  'Найдите пользователя с максимальным количеством заказов.
Ожидаемая колонка: user_id',
  '
  CREATE TABLE orders (id INTEGER, user_id INTEGER);',
  '
  INSERT INTO orders VALUES
  (1,1),(2,1),(3,2);',
  '
  SELECT user_id
  FROM orders
  GROUP BY user_id
  ORDER BY COUNT(*) DESC
  LIMIT 1;',
  'ordered'
);

INSERT INTO tasks VALUES (
  NULL,
  'Медианный заказ',
  'Найти медиану суммы заказов',
  'Hard',
  'Найдите медианную сумму заказов.
Ожидаемая колонка: median_total',
  '
  CREATE TABLE orders (id INTEGER, total INTEGER);',
  '
  INSERT INTO orders VALUES (1,10),(2,30),(3,20);',
  '
  SELECT AVG(total) AS median_total
  FROM (
    SELECT total
    FROM orders
    ORDER BY total
    LIMIT 2 - (SELECT COUNT(*) FROM orders) % 2
    OFFSET (SELECT (COUNT(*) - 1) / 2 FROM orders)
  );',
  'unordered'
);
