from flask import Flask, render_template, request
from prometheus_metrics import REQUEST_COUNT, DASHBOARD_VIEWS, HTTP_REQUEST_TOTAL, get_metrics, CONTENT_TYPE_LATEST
import threading
import time

app = Flask(__name__)

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    request_latency = time.time() - request.start_time
    HTTP_REQUEST_TOTAL.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code
    ).inc()
    return response

# Background thread for periodic GC metrics collection
def metrics_collector():
    while True:
        # Update metrics every 15 seconds
        time.sleep(15)

# Start metrics collector thread
collector_thread = threading.Thread(target=metrics_collector, daemon=True)
collector_thread.start()

@app.route('/')
def dashboard():
    REQUEST_COUNT.inc()
    DASHBOARD_VIEWS.inc()
    return '''
    <html>
        <head>
            <title>CEEYIT Dashboard</title>
            <style>
                body { font-family: Arial; background: #fefefe; text-align: center; margin-top: 100px; }
                h1 { color: #2a9d8f; }
                p { font-size: 18px; color: #264653; }
            </style>
        </head>
        <body>
            <h1>CEEYIT Monitoring Dashboard</h1>
            <p>Your DevOps metrics will be visualized here.</p>
            <p><a href="/metrics">View Prometheus Metrics</a></p>
        </body>
    </html>
    '''

@app.route('/metrics')
def metrics():
    REQUEST_COUNT.inc()
    return get_metrics(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
