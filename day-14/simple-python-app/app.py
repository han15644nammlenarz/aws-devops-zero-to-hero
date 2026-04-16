from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    # Enable debug mode for local development and set host/port explicitly
    app.run(host='0.0.0.0', port=5000, debug=True)
