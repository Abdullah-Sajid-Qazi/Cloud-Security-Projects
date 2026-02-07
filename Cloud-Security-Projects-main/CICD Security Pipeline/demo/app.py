"""
Intentionally vulnerable Flask app for CI/CD security pipeline demo.
These issues should be caught by Semgrep SAST scanning.
"""

import os
import sqlite3
import subprocess
import yaml  # type: ignore[import-unresolved]  # pyyaml in requirements.txt
from flask import Flask, request, render_template_string  # type: ignore[import-unresolved]

app = Flask(__name__)

# ISSUE: Hardcoded secret (should be caught by secret scanning)
API_KEY = "AKIA3EXAMPLE1234567X"
DB_PASSWORD = "SuperSecret123!"


# ISSUE: SQL Injection vulnerability (Semgrep: python.lang.security.audit.sqli)
@app.route("/user")
def get_user():
    username = request.args.get("username")
    conn = sqlite3.connect("app.db")
    cursor = conn.cursor()
    # BAD: String concatenation in SQL query
    cursor.execute("SELECT * FROM users WHERE username = '" + username + "'")
    result = cursor.fetchone()
    conn.close()
    return str(result)


# ISSUE: Command injection vulnerability (Semgrep: python.lang.security.audit.subprocess)
@app.route("/ping")
def ping():
    host = request.args.get("host")
    # BAD: User input passed directly to shell command
    output = subprocess.check_output("ping -c 1 " + host, shell=True)
    return output


# ISSUE: Server-Side Template Injection (SSTI)
@app.route("/greet")
def greet():
    name = request.args.get("name", "World")
    # BAD: User input in template string
    template = "<h1>Hello " + name + "!</h1>"
    return render_template_string(template)


# ISSUE: Insecure deserialization with PyYAML
@app.route("/config", methods=["POST"])
def load_config():
    data = request.get_data()
    # BAD: yaml.load without safe Loader
    config = yaml.load(data)
    return str(config)


# ISSUE: Debug mode enabled in production
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
