load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        "//db:connect",
        "//db/models:lobby",
        "//db/models:user",
        "//lib:flask_utils",
        "//util:error",
        "//util:mongo",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("Flask-Sockets"),
        requirement("grpcio"),
    ],
)
