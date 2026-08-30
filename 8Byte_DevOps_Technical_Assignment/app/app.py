import json
import logging
import os
from flask import Flask, jsonify

app = Flask(__name__)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('%(message)s'))
app.logger.handlers = [handler]
app.logger.setLevel(logging.INFO)

@app.get("/healthz")
def healthz():
    app.logger.info(json.dumps({"event": "healthcheck", "status": "ok"}))
    return jsonify(status="ok"), 200

@app.get("/readyz")
def readyz():
    # The starter service has no migration dependency. Add an actual DB probe here
    # when application persistence is enabled.
    return jsonify(status="ready", database_configured=bool(os.getenv("DATABASE_URL"))), 200

@app.get("/")
def index():
    return jsonify(service="8byte-demo", version=os.getenv("IMAGE_TAG", "local")), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
