# SPB

A space pirate battle simulator where you build space ships and battle with
your friends.

Under-documented and under-tested, this is a prototype and a way to learn how
networking works and it feels like that, too.

## Demo videos

[Multiplayer demo](https://drive.google.com/file/d/1E8Y9NJgpvdR3IqF7raZdot3fxxgTgTr6/view?usp=sharing)

[Ship Building Demo](https://drive.google.com/file/d/1gAWShg38_Ud_5RiFuU1zoA_8-MYdmM5j/view?usp=sharing)

## Running

Launch a redis instance, then...

Launch the server binaries:

```bash
bazel run auth:server  # Launch the authentication server.
```

```bash
bazel run gateway:server  # Launch the gateway so users can find game servers
                          # to connect to.
```

```bash
bazel run lobby:server  # Launch the lobby to enable matchmaking.
```

```bash
bazel run universe:server  # Launch the universe, which game servers use to
                           # update persistent player state.
```

(on M1 Macs you might need
```bash
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
```
before you can install grpcio)

Then launch at least one game server for users to connect to:
```bash
cd game
godot --server
```

And then launch as many game clients as you want.
```bash
cd game
godot
```
