"""
Helpers for sending emails.
"""
import functools
import os

import sendgrid
from sendgrid.helpers import mail

_SENDGRID_API_ENV = 'SENDGRID_API_KEY'


@functools.lru_cache()
def _sg() -> sendgrid.SendGridAPIClient:
    """Returns a cached SendGridAPIClient."""
    return sendgrid.SendGridAPIClient(api_key=os.environ.get(_SENDGRID_API_ENV))


def send_email(
        from_email: str, to_email: str, subject: str, content: str) -> None:
    """Sends an email."""
    from_email = Email(from_email)
    to_email = To(to_email)
    subject = subject
    content = Content("text/html", content)
    mail = Mail(from_email, to_email, subject, content)
    response = _sg().client.mail.send.post(request_body=mail.get())
    assert response.status_code == 200
