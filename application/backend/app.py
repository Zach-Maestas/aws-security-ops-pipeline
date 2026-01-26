from flask import Flask, request, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import boto3
from botocore.exceptions import ClientError
import json
from flask_cors import CORS
import logging

# ------------------------------------------------------------------------------
# Flask App Configuration
# ------------------------------------------------------------------------------
app = Flask(__name__)

# Restrict CORS to known frontend origin (add https variant if needed)
CORS(app, resources={
    r"/db/*": {"origins": [
        "http://secure-capstone-frontend.s3-website-us-east-1.amazonaws.com",
        "https://secure-capstone-frontend.s3-website-us-east-1.amazonaws.com"
    ]}
})

# ------------------------------------------------------------------------------
# Load secrets from AWS Secrets Manager
# ------------------------------------------------------------------------------
def load_secret():
    """Fetch DB credentials from AWS Secrets Manager and set as env vars."""
    secret_name = os.environ.get("SECRET_NAME", "capstone/secureaws/db-credentials")
    region_name = os.environ.get("AWS_REGION", "us-east-1")

    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])

        # Instead of mutating os.environ globally, could store in DB_CONFIG = secret
        os.environ.update({
            "DB_USER": secret["username"],
            "DB_PASSWORD": secret["password"],
            "DB_HOST": secret["host"],
            "DB_PORT": str(secret["port"]),
            "DB_NAME": secret["db_name"]
        })
        logging.info("✅ Secrets loaded successfully from AWS Secrets Manager.")

    except ClientError as e:
        logging.error(f"❌ Failed to load DB secret: {e}")
        # Optionally exit if secrets are critical
        # raise SystemExit("Missing required DB secrets, terminating.")

load_secret()

# ------------------------------------------------------------------------------
# Environment Validation
# ------------------------------------------------------------------------------
required_vars = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]
missing = [v for v in required_vars if not os.environ.get(v)]
if missing:
    logging.warning(f"⚠️ Missing DB env vars: {', '.join(missing)}. DB routes may fail.")

# ------------------------------------------------------------------------------
# DB Connection Helper
# ------------------------------------------------------------------------------
def get_db_connection():
    """Return a new PostgreSQL connection with SSL enforced."""
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", 5432)),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        sslmode="require"
    )

# ------------------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------------------
@app.route("/", methods=["GET"])
def health():
    """Basic health check for the Flask app."""
    return jsonify(status="ok"), 200


@app.route("/db/health", methods=["GET"])
def db_health():
    """Check connectivity to the database."""
    try:
        with get_db_connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1;")
        return jsonify(db="ok"), 200
    except Exception as e:
        logging.exception("Database health check failed.")
        return jsonify(error="DB connection failed"), 500


@app.route("/db/items", methods=["GET"])
def list_items():
    """Retrieve all items from the database."""
    try:
        with get_db_connection() as conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, name, created_at FROM items ORDER BY id;")
            return jsonify(items=cur.fetchall()), 200
    except Exception as e:
        logging.exception("Error listing items.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/db/items", methods=["POST"])
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
        logging.exception("Error inserting new item.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/db/items/<int:item_id>", methods=["GET"])
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
        logging.exception("Error retrieving item.")
        return jsonify(error="Internal Server Error"), 500


@app.route("/db/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    """Delete an item by ID."""
    try:
        with get_db_connection() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM items WHERE id=%s;", (item_id,))
            deleted = cur.rowcount
            conn.commit()
            return jsonify(deleted=deleted), 200
    except Exception:
        logging.exception("Error deleting item.")
        return jsonify(error="Internal Server Error"), 500


# ------------------------------------------------------------------------------
# Global CORS and Header Config
# ------------------------------------------------------------------------------
@app.after_request
def after_request(response):
    """Add CORS and security headers."""
    response.headers.add("Access-Control-Allow-Origin", "http://secure-capstone-frontend.s3-website-us-east-1.amazonaws.com")
    response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization")
    response.headers.add("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS")
    response.headers.add("Cache-Control", "no-store")
    return response


# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    # Disable debug mode for production environments
    app.run(host="0.0.0.0", port=5000, debug=False)
