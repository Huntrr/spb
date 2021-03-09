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
    from_email = mail.Email(from_email)
    to_email = mail.To(to_email)
    subject = subject
    content = mail.Content("text/html", content)
    the_mail = mail.Mail(from_email, to_email, subject, content)
    response = _sg().client.mail.send.post(request_body=the_mail.get())
    assert response.status_code == 202
