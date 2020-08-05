import json
import os
import random

from flask import Flask, request
from requests import Session
from requests.exceptions import RequestException

app = Flask(__name__)
app.config['SAMPLING_RATE'] = int(os.environ.get('SENTRY_SAMPLING_RATE', '1'))
app.config['USER_AGENT_SAMPLING_RATES'] = json.loads(os.environ.get('USER_AGENT_SAMPLING_RATES', '{}'))
session = Session()


@app.route('/')
def root():
    # Useful for healthchecking and similar
    return ''


@app.route('/<path:path>', methods=['POST'])
def main(path):
    user_agent = request.headers.get('user-agent')
    sampling_rate = app.config['USER_AGENT_SAMPLING_RATES'].get(user_agent, app.config['SAMPLING_RATE'])
    if random.randint(1, sampling_rate) != 1:
        return '', 202

    uri = 'https://sentry.io%s/' % request.path
    if request.args:
        uri += '?' + request.query_string.decode('utf-8')
    headers = {}
    for header in ('X-Sentry-Auth', 'User-Agent', 'Content-Encoding', 'Content-Type'):
        headers[header] = request.headers.get(header)

    status_code = 503
    try:
        response = session.post(uri,
            headers=headers,
            data=request.get_data(),
            timeout=(4, 12),
        )
        status_code = response.status_code
    except RequestException as e:
        app.logger.exception('Failed to forward crash to sentry')

    return '', status_code
