load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        "//db:connect",
        "//db/models:server_auth",
        "//lib:flask_utils",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("Flask-Sockets"),
    ],
)
