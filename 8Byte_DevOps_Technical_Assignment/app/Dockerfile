FROM python:3.12-slim AS runtime
RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')"
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
