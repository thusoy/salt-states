import os
import random

from flask import Flask, request
from requests import Session
from requests.exceptions import RequestException

app = Flask(__name__)
app.config['SAMPLING_RATE'] = int(os.environ.get('SENTRY_SAMPLING_RATE', '1'))
session = Session()


@app.route('/')
def root():
    # Useful for healthchecking and similar
    return ''


@app.route('/<path:path>', methods=['POST'])
def main(path):
    if random.randint(1, app.config['SAMPLING_RATE']) != 1:
        return '', 202

    uri = 'https://sentry.io%s/' % request.path
    headers = {}
    for header in ('X-Sentry-Auth', 'User-Agent', 'Content-Encoding'):
        headers[header] = request.headers.get(header)

    status_code = 503
    try:
        response = session.post(uri,
            headers=headers,
            data=request.data,
            timeout=(4, 12),
        )
        status_code = response.status_code
    except RequestException as e:
        app.logger.exception('Failed to forward crash to sentry')

    return '', status_code
