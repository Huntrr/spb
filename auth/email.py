"""
Helpers for sending authentication-related emails.
"""
from lib import email_utils

_VERIFICATION_EMAIL_ADDRESS = 'no-reply@spacepirategame.com'
_VERIFICATION_EMAIL_SUBJECT = 'Verify your SPB account'

_VERIFICATION_EMAIL_TEMPLATE = """
{to_user},
<br/><br/>
Welcome to SPB! Please follow this link to verify your account:
<br/>
<a href="{verification_link}">{verification_link}</a>
<br/>

Thanks,
The Pirate King
""".strip()

def send_verification_email(
        to_email: str, to_user: str, verification_link: str) -> None:
    email_utils.send_email(
        from_email=_VERIFICATION_EMAIL_ADDRESS,
        to_email=to_email,
        subject=_VERIFICATION_EMAIL_SUBJECT,
        content=_VERIFICATION_EMAIL_TEMPLATE.format(
            to_user=to_user,
            verification_link=verification_link))
