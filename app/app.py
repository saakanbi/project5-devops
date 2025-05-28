from flask import Flask
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Create metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')
DASHBOARD_VIEWS = Counter('app_dashboard_views', 'Dashboard page views')

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
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
