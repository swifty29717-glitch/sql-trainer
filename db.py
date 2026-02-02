import sqlite3
from pathlib import Path
from collections import Counter

APP_DB = Path("data/app.db")
DATASETS_DIR = Path("data/datasets")

# Fixed difficulty order for UI
LEVELS_ORDER = ["Easy", "Medium", "Hard", "Advanced"]


def connect_app_db():
    """Connection to catalog DB (tasks list)."""
    conn = sqlite3.connect(APP_DB)
    conn.row_factory = sqlite3.Row
    return conn


def init_app_db(schema_path: Path = Path("schema.sql")):
    """
    Create and seed app.db if it doesn't exist yet.
    Safe for local pet project: we run schema.sql once when app.db is missing.
    """
    if APP_DB.exists():
        return

    APP_DB.parent.mkdir(parents=True, exist_ok=True)
    sql = schema_path.read_text(encoding="utf-8")

    conn = sqlite3.connect(APP_DB)
    try:
        conn.executescript(sql)
        conn.commit()
    finally:
        conn.close()


def get_levels():
    """
    Return difficulty levels in desired order.
    If some levels are not used yet, we still show them in UI (it's fine).
    """
    return LEVELS_ORDER[:]


def get_tasks(level: str | None = None):
    """
    Get tasks list. If level is provided, filter by level.
    """
    sql = "SELECT id, title, short_desc, level FROM tasks"
    params = []

    if level:
        if level in LEVELS_ORDER:
            sql += " WHERE level = ?"
            params.append(level)

    sql += " ORDER BY id"

    with connect_app_db() as conn:
        return conn.execute(sql, params).fetchall()


def get_task(task_id: int):
    with connect_app_db() as conn:
        return conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()


def dataset_path(task_id: int) -> Path:
    DATASETS_DIR.mkdir(parents=True, exist_ok=True)
    return DATASETS_DIR / f"task_{task_id}.db"


def ensure_dataset(task_row):
    """Create dataset DB for a task if missing."""
    path = dataset_path(task_row["id"])
    if path.exists():
        return

    conn = sqlite3.connect(path)
    try:
        conn.executescript(task_row["dataset_sql"])
        conn.executescript(task_row["seed_sql"])
        conn.commit()
    finally:
        conn.close()


def reset_dataset(task_row):
    """Recreate dataset DB from scratch."""
    path = dataset_path(task_row["id"])
    if path.exists():
        path.unlink()
    ensure_dataset(task_row)


def run_user_sql(task_id: int, sql: str, limit: int = 500):
    """
    Execute SQL against dataset DB of given task.
    Returns (columns, rows) for SELECT-like queries, otherwise (None, None).
    """
    path = dataset_path(task_id)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row

    try:
        cur = conn.cursor()

        # Disallow multiple statements separated by ';'
        cleaned = sql.strip()
        if ";" in cleaned.rstrip(";"):
            raise ValueError("Пожалуйста, выполните один SQL-запрос без нескольких команд через ';'.")

        cur.execute(cleaned)

        if cur.description is not None:
            cols = [d[0] for d in cur.description]
            rows = cur.fetchmany(limit)
            return cols, rows

        conn.commit()
        return None, None
    finally:
        conn.close()


def compare_results(user_cols, user_rows, sol_cols, sol_rows, mode: str):
    """
    Compare user's result to solution result.
    - Column names must match (case-insensitive).
    - Data compare:
        ordered   -> exact row order matters
        unordered -> order doesn't matter (multiset compare, duplicates are counted)
    Returns: (is_ok: bool, message: str)
    """
    if user_cols is None or sol_cols is None:
        return False, "Запрос должен возвращать табличный результат (SELECT/WITH)."

    if [c.lower() for c in user_cols] != [c.lower() for c in sol_cols]:
        return False, f"Колонки отличаются. Ожидалось: {sol_cols}"

    user_tuples = [tuple(r[c] for c in user_cols) for r in user_rows]
    sol_tuples = [tuple(r[c] for c in sol_cols) for r in sol_rows]

    mode = (mode or "unordered").lower()
    if mode == "ordered":
        ok = user_tuples == sol_tuples
        return ok, ("Совпадает." if ok else "Значения/порядок строк не совпадают с ожидаемыми.")
    else:
        ok = Counter(user_tuples) == Counter(sol_tuples)
        return ok, ("Совпадает (порядок строк не важен)." if ok else "Значения не совпадают с ожидаемыми.")
