FROM python:3.7-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000 9090

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]