from flask import Flask, render_template, request, redirect, url_for, flash
import db

app = Flask(__name__)
app.secret_key = "dev-secret-key"

# Flask 3.x: before_first_request removed, so init at startup
db.init_app_db()


# ===== Lectures catalog (static pages) =====
LECTURES = [
    {
        "slug": "sql_basics",
        "title": "SQL basics",
        "summary": "SELECT, FROM, базовые типы данных и простые условия.",
        "level": "Базовый",
        "icon": "📘",
    },
    {
        "slug": "where",
        "title": "WHERE — фильтрация строк",
        "summary": "Условия, операторы сравнения, BETWEEN/IN/LIKE, NULL.",
        "level": "Базовый",
        "icon": "🔎",
    },
    {
        "slug": "group-by",
        "title": "GROUP BY — агрегаты",
        "summary": "COUNT/SUM/AVG, группировки, HAVING, частые ошибки.",
        "level": "Средний",
        "icon": "🧮",
    },
    {
        "slug": "joins",
        "title": "JOIN",
        "summary": "INNER/LEFT JOIN, ключи, типичные ловушки и дубликаты.",
        "level": "Средний",
        "icon": "🔗",
    },
    {
        "slug": "window_functions",
        "title": "Оконные функции в SQL",
        "summary": "OVER(PARTITION BY ...), ROW_NUMBER, ранжирование и аналитика.",
        "level": "Продвинутый",
        "icon": "🪟",
    },
]



@app.route("/", methods=["GET", "POST"])
def index():
    # Some apps (e.g. Steam) may POST to localhost:5000. We ignore it.
    if request.method == "POST":
        return ("", 204)

    selected_level = request.args.get("level")  # Easy/Medium/Hard/Advanced or empty
    levels = db.get_levels()
    tasks = db.get_tasks(level=selected_level)

    return render_template(
        "index.html",
        tasks=tasks,
        levels=levels,
        selected_level=selected_level,
    )


@app.route("/task/<int:task_id>", methods=["GET", "POST"])
def task_page(task_id: int):
    task = db.get_task(task_id)
    if task is None:
        return "Task not found", 404

    db.ensure_dataset(task)

    sql = ""
    columns = None
    rows = None
    error = None

    verdict = None
    verdict_msg = None

    if request.method == "POST":
        action = request.form.get("action", "run")
        sql = request.form.get("sql", "").strip()

        if action == "reset":
            db.reset_dataset(task)
            flash("Датасет сброшен к исходному состоянию.", "info")
            return redirect(url_for("task_page", task_id=task_id))

        if not sql:
            error = "Введите SQL-запрос."
        else:
            try:
                columns, rows = db.run_user_sql(task_id, sql)

                sol_cols, sol_rows = db.run_user_sql(task_id, task["solution_sql"])
                verdict, verdict_msg = db.compare_results(
                    columns, rows,
                    sol_cols, sol_rows,
                    task["check_mode"]
                )
            except Exception as e:
                error = str(e)

    return render_template(
        "task.html",
        task=task,
        sql=sql,
        columns=columns,
        rows=rows,
        error=error,
        verdict=verdict,
        verdict_msg=verdict_msg,
    )



@app.route("/lectures")
def lectures_index():
    selected_level = request.args.get("level")  # Базовый/Средний/Продвинутый or empty

    levels = sorted({l["level"] for l in LECTURES})
    lectures = LECTURES
    if selected_level:
        lectures = [l for l in LECTURES if l["level"] == selected_level]

    return render_template(
        "lectures/index.html",
        lectures=lectures,
        levels=levels,
        selected_level=selected_level,
    )


@app.route("/lectures/<slug>")
def lecture_page(slug: str):
    allowed = {
        "where": "lectures/where.html",
        "group-by": "lectures/group_by.html",
        "joins": "lectures/joins.html",
        "window_functions": "lectures/window_functions.html",
        "sql_basics": "lectures/sql_basics.html",

    }
    template = allowed.get(slug)
    if not template:
        return "Lecture not found", 404
    return render_template(template)


@app.route("/about")
def about():
    return render_template("about.html")


if __name__ == "__main__":
    app.run(debug=True)
