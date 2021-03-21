load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "game_server_manager",
    srcs = ["game_server_manager.py"],
    deps = [
        ":ws_manager",
        "//db/models:ship",
        "//lib:redis_client",
        "//util:error",
        requirement("absl-py"),
        requirement("grpcio"),
    ],
)

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        ":game_server_manager",
        ":ws_manager",
        "//db:connect",
        "//db/models:server_auth",
        "//lib:flask_utils",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("Flask-Sockets"),
    ],
)

py_library(
    name = "ws_manager",
    srcs = ["ws_manager.py"],
    deps = [
        requirement("absl-py"),
    ],
)
