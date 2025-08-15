import datetime
import os
import re
import textwrap
import time
import binascii

import requests
from laim import Laim, before_log, log
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


PACKAGE_SPEC_RE = re.compile(
    r"^(?P<package>.+) \((?P<version>.+)\) (?P<distributions>.+);(?P<metadata>.*)$"
)
MAINTAINER_SPEC_RE = re.compile(r"^-- (?P<maintainer>.+)  (?P<date>.+)$")


class SlackHoneycombHandler(Laim):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.session = requests.Session()
        self.session.headers.update(
            {
                # Explicitly set charset to avoid warnings from slack
                "Content-Type": "application/json; charset=utf-8",
            }
        )

        retry_kwargs = {
            "total": 6,
            "status_forcelist": (429, 500, 502, 503, 504),
            "backoff_factor": 2,
        }
        allowed_methods_name = "allowed_methods"
        if hasattr(Retry.DEFAULT, "method_whitelist"):
            # urllib3 renamed this property, thus depending on version we need to set the correct name
            allowed_methods_name = "method_whitelist"
        retry_kwargs[allowed_methods_name] = (
            "GET",
            "HEAD",
            "POST",
            "DELETE",
            "PUT",
            "OPTIONS",
            "TRACE",
        )

        self.session.mount("https://", HTTPAdapter(max_retries=Retry(**retry_kwargs)))

        self.channel_id = self.config["slack-channel-id"]
        self.dataset = self.config["honeycomb-dataset"]
        self.honeycomb_key = self.config["honeycomb-key"]
        self.slack_token = self.config["slack-token"]
        self.honeycomb_base_context = {
            "service.name": "laim",
            "host": self.config["hostname"],
        }

        @before_log.connect
        def logs_to_honeycomb(sender, log_data):
            if not log_data.pop("skip_honeycomb", False):
                self._post_data_to_honeycomb(
                    [
                        {
                            "data": dict(log_data, **self.honeycomb_base_context),
                        }
                    ]
                )

        # Preseve a strong reference to the handler to prevent it from being garbage collected
        self.logs_to_honeycomb = logs_to_honeycomb

    def handle_message(self, sender, recipients, message):
        subject = message.get("Subject", "")
        is_plaintext = message.get_content_type() == "text/plain"
        trace_id = create_id(16)
        root_span_id = create_id(8)
        log_context = {
            "trace.span_id": root_span_id,
            "trace.trace_id": trace_id,
        }
        if subject.startswith("apt-listchanges: changelogs for ") and is_plaintext:
            try:
                self.post_to_honeycomb(recipients, message, trace_id, root_span_id)
                log_context["handler"] = "honeycomb"
                return log_context
            except ValueError as e:
                log_context["listchanges_error"] = str(e)

        log_context["handler"] = "slack"
        self.post_to_slack(recipients, message)
        return log_context

    def post_to_honeycomb(self, recipients, message, trace_id, parent_id):
        upgrades = parse_package_upgrades(message)
        context = {
            "name": "package-upgrade",
            "to": recipients,
            "from": message.get("From"),
            "subject": message.get("Subject"),
            "trace.parent_id": parent_id,
            "trace.trace_id": trace_id,
        }
        context.update(self.honeycomb_base_context)
        for upgrade in upgrades:
            log(
                dict(
                    context,
                    **upgrade,
                    **{
                        "skip_honeycomb": True,
                    }
                ),
                sender=self,
            )

        body = [
            {"data": dict(context, **up, **{"trace.span_id": create_id(8)})}
            for up in upgrades
        ]
        self._post_data_to_honeycomb(body)

    def _post_data_to_honeycomb(self, data):
        # The data is logged in addition to being sent to honeycomb, so we can
        # ignore failures here as long as we also include details about the failure
        start_time = time.time()
        log_data = {
            "name": "post-honeycomb",
            "skip_honeycomb": True,
        }
        try:
            response = self.session.post(
                "https://api.honeycomb.io/1/batch/%s" % self.dataset,
                timeout=60,
                json=data,
                headers={
                    "X-Honeycomb-Team": self.honeycomb_key,
                },
            )
            log_data["response.status_code"] = response.status_code
        except requests.RequestException as e:
            log_data["error_msg"] = str(e)
            log_data["error"] = e.__class__.__name__

        log(log_data, start_time, sender=self)

    def post_to_slack(self, recipients, message):
        initial_message = textwrap.dedent(
            """\
            `%s` received mail for %s
            *From*: %s
            *To*: %s
            *Subject*: %s
        """
        ) % (
            self.config["hostname"],
            ", ".join(recipients),
            message.get("From"),
            message.get("To"),
            message.get("Subject"),
        )

        initial_response = self.session.post(
            "https://slack.com/api/chat.postMessage",
            timeout=60,
            json={
                "channel": self.channel_id,
                "text": initial_message,
            },
            headers={
                "Authorization": "Bearer %s" % self.slack_token,
            },
        )
        initial_body = initial_response.json()
        if not initial_body["ok"]:
            raise ValueError("Failed to post initial message to slack, got %r", initial_body)

        thread_ts = initial_body["message"]["ts"]

        # Post the message content in the thread
        content_response = self.session.post(
            "https://slack.com/api/chat.postMessage",
            timeout=60,
            json={
                "channel": self.channel_id,
                "thread_ts": thread_ts,
                "text": f"```\n{message.get_payload()}\n```",
            },
            headers={
                "Authorization": "Bearer %s" % self.slack_token,
            },
        )
        content_body = content_response.json()
        if not content_body["ok"]:
            raise ValueError("Failed to post message content to slack thread, got %r", content_body)


def parse_package_upgrades(message):
    message_lines = message.get_payload().split("\n")
    message_iterator = iter(message_lines)
    upgrades = []
    line = next(message_iterator).strip()
    while True:
        try:
            spec_match = PACKAGE_SPEC_RE.match(line)
            if spec_match:
                start_time = time.time()
                spec_dict = spec_match.groupdict()
                upgrade = {
                    "package": spec_dict["package"],
                    "distributions": spec_dict["distributions"],
                    "version": spec_dict["version"],
                }
                for meta in spec_dict["metadata"].split(","):
                    key, val = meta.strip().split("=", 1)
                    upgrade["meta.%s" % key] = val

                line = next(message_iterator).strip()
                while True:
                    maintainer_match = MAINTAINER_SPEC_RE.match(line)
                    if maintainer_match:
                        maintainer_dict = maintainer_match.groupdict()
                        upgrade.update(
                            {
                                "maintainer": maintainer_dict["maintainer"],
                                "release.spec": maintainer_dict["date"],
                                "release.age_seconds": parse_release_spec_age(
                                    maintainer_dict["date"]
                                ),
                            }
                        )
                        break
                    try:
                        line = next(message_iterator).strip()
                    except StopIteration:
                        raise ValueError(
                            "Invalid changelog format: Missing maintainer line"
                        )
                upgrade["duration_ms"] = (time.time() - start_time) * 1000
                upgrades.append(upgrade)
            elif line:
                # Invalid message format, raise so that this can be logged
                raise ValueError("Invalid changelog format: Trailing data")
            line = next(message_iterator).strip()
        except StopIteration:
            break

    return upgrades


def parse_release_spec_age(release_spec):
    parsed = datetime.datetime.strptime(release_spec, "%a, %d %b %Y %H:%M:%S %z")
    return int((utcnow() - parsed).total_seconds())


def utcnow():
    # Separate method to simplify mocking
    return datetime.datetime.now(datetime.timezone.utc)


def create_id(num_bytes):
    return binascii.hexlify(os.urandom(num_bytes)).decode("utf-8")


if __name__ == "__main__":
    handler = SlackHoneycombHandler()
    handler.run()
