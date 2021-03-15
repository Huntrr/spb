"""
CLI for manipulating ships.
"""
import json

import click

from db import connect
from db.models import ship

@click.group()
def cli() -> None:
    connect.connect()
    pass


@cli.command()
@click.argument('name')
@click.argument('blueprint_path')
@click.option('--station/--ship', default=False, help='True for Space Stations')
@click.option('--spawn/--nospawn', default=False, help='True for spawn locations')
def create_ship(name, blueprint_path: str, spawn: bool, station: bool) -> None:
    """Creates a new overworld space ship."""
    if spawn:
        station = True

    the_ship = ship.SpaceStation() if station else ship.OverworldShip()
    if station:
        the_ship.spawnable = spawn

    the_ship.name = name
    with open(blueprint_path) as fd:
        blueprint = json.loads(fd.read())
    the_ship.blueprint = blueprint

    click.echo(
        f'Creating a new {"station" if station else "ship"} named {name}')
    the_ship.save()


@cli.command()
@click.argument('name')
def delete_ship(name) -> None:
    """Deletes a ship."""
    the_ship = ship.OverworldShip.objects(name=name).first()
    if the_ship is None:
        click.echo(f'No ship named {name}')
        return
    the_ship.delete()
    click.echo(f'Deleted {name}')


if __name__ == '__main__':
    cli()
