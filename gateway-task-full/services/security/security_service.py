from flask import Flask, request, jsonify
import jwt
import datetime
from prometheus_client import Counter, generate_latest, REGISTRY

app = Flask(__name__)
SECRET_KEY = "your-secret-key"
users = {"bob": "qwe123"}

# Метрики
requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])

@app.route('/v1/user', methods=['POST'])
def register():
    requests_total.labels(method='POST', endpoint='/v1/user').inc()
    data = request.get_json()
    login = data.get('login')
    password = data.get('password')
    if login in users:
        return jsonify({"error": "User exists"}), 409
    users[login] = password
    return jsonify({"login": login}), 201

@app.route('/v1/token', methods=['POST'])
def token():
    requests_total.labels(method='POST', endpoint='/v1/token').inc()
    data = request.get_json()
    login = data.get('login')
    password = data.get('password')
    if users.get(login) == password:
        payload = {
            "sub": login,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
        return token, 200
    return jsonify({"error": "Invalid credentials"}), 401

@app.route('/v1/token/validation/', methods=['GET'])
def validate_token():
    requests_total.labels(method='GET', endpoint='/v1/token/validation/').inc()
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return "", 401
    token = auth_header.split(' ')[1]
    try:
        jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return "", 200
    except jwt.InvalidTokenError:
        return "", 401

@app.route('/v1/user', methods=['GET'])
def get_user():
    requests_total.labels(method='GET', endpoint='/v1/user').inc()
    return jsonify({"user": "bob", "id": 123}), 200

# Эндпоинт для метрик Prometheus
@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
