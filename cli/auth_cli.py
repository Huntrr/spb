"""
CLI for common SPB auth operations.
"""
import uuid

import click

from db import connect
from db.models import server_auth

@click.group()
def cli() -> None:
    connect.connect()
    pass


@cli.command()
def update_server_auth() -> None:
    """Regenerates the ServerAuth key."""
    auth_key = str(uuid.uuid4())
    server_auth.ServerAuth.set_key(auth_key)
    click.echo(f'Set a new server auth key:\n{auth_key}')


if __name__ == '__main__':
    cli()
