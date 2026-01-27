from flask import Flask, request, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor
import logging

# ------------------------------------------------------------------------------
# Load Flask App & Logging
# ------------------------------------------------------------------------------
app = Flask(__name__)

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    force=True,
)

logger = logging.getLogger("api")
logger.info("api_starting")

# ------------------------------------------------------------------------------
# Environment Validation
# ------------------------------------------------------------------------------
required_vars = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]
missing = [v for v in required_vars if not os.environ.get(v)]
if missing:
    logger.warning(f"⚠️ Missing DB env vars: {', '.join(missing)}. DB routes may fail.")

# ------------------------------------------------------------------------------
# DB Connection Helper
# ------------------------------------------------------------------------------
def get_db_connection():
    """Return a new PostgreSQL connection with SSL enforced."""
    sslmode = os.environ.get("DB_SSLMODE", "prefer")
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", 5432)),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        sslmode=sslmode
    )

# ------------------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------------------
@app.route("/health", methods=["GET"])
def health():
    """Basic health check for the Flask app."""
    return jsonify(status="ok"), 200


@app.route("/ready", methods=["GET"])
def db_health():
    """Check connectivity to the database."""
    try:
        with get_db_connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1;")
        return jsonify(status="ready"), 200
    except Exception:
        logger.exception("❌ Database health check failed.")
        return jsonify(error="DB connection failed"), 503


@app.route("/items", methods=["GET"])
def list_items():
    """Retrieve all items from the database."""
    try:
        with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name, created_at FROM items ORDER BY id;")
            return jsonify(items=cur.fetchall()), 200
    except Exception:
        logger.exception("❌ Error listing items.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/items", methods=["POST"])
def create_item():
    """Insert a new item into the database."""
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    if not name:
        return jsonify(error="name is required"), 400

    try:
        with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id, name, created_at;", (name,))
            row = cur.fetchone()
            conn.commit()
            return jsonify(row), 201
    except Exception:
        logger.exception("❌ Error inserting new item.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/items/<int:item_id>", methods=["GET"])
def get_item(item_id):
    """Retrieve a single item by ID."""
    try:
        with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name, created_at FROM items WHERE id=%s;", (item_id,))
            row = cur.fetchone()
            if not row:
                return jsonify(error="not found"), 404
            return jsonify(row), 200
    except Exception:
        logger.exception("❌ Error retrieving item.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    """Delete an item by ID."""
    try:
        with get_db_connection() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM items WHERE id=%s;", (item_id,))
            deleted = cur.rowcount
            conn.commit()
            return jsonify(deleted=deleted), 200
    except Exception:
        logger.exception("❌ Error deleting item.")
        return jsonify(error="Internal Server Error"), 500

# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("APP_PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=False)
