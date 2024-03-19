import os
import threading
from flask import Flask, render_template, request, Response, stream_with_context
app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'

# Speichert die logcat-Ausgaben für jedes Gerät
device_logs = {}
last_sent_logs = {}  # Speichert die zuletzt gesendeten Logs für jedes Gerät
lock = threading.Lock()

# Verarbeitet die eingehenden logcat-Daten
@app.route('/logcat', methods=['POST'])
def receive_logcat():
    device_name = request.form.get('device_name')
    log_data = request.form.get('log_data')
    if device_name and log_data:
        with lock:
            if device_name in device_logs:
                device_logs[device_name].extend(log_data.split('\n'))
            else:
                device_logs[device_name] = log_data.split('\n')
        # Sende die neuen Log-Zeilen an alle Clients
        send_new_log_lines(device_name, log_data)
    return 'OK'

# Rendert die Hauptseite mit allen Geräten und ihren Logs
@app.route('/')
def index():
    return render_template('index.html', devices=device_logs.keys())

# Streamt die Logs für ein bestimmtes Gerät
@app.route('/logs/<device_name>')
def device_logs_page(device_name):
    def generate_logs():
        with app.app_context():
            while True:
                with lock:
                    logs = device_logs.get(device_name, [])
                    new_lines = logs[len(last_sent_logs.get(device_name, [])):]
                    last_sent_logs[device_name] = logs[:]
                    log_data = '\n'.join(new_lines)
                if log_data:
                    yield f'data: {log_data}\n\n'

    return Response(stream_with_context(generate_logs()), mimetype='text/event-stream')

# Sendet die neuen Log-Zeilen an alle Clients
def send_new_log_lines(device_name, log_data):
    with lock:
        for client in device_logs.keys():
            if client != device_name:
                send_to_client(log_data, client)

# Sendet eine Nachricht an einen bestimmten Client
def send_to_client(message, client):
    with app.test_request_context():
        app.sse.publish(message, type='log', channel=client)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5005, debug=True)
