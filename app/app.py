
from flask import Flask
app = Flask(__name__)

@app.route('/')
def dashboard():
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
        </body>
    </html>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
