load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        "//db:connect",
        "//db/model:ship",
        "//db/model:user",
        "//lib:flask_utils",
        "//util:error",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("grpcio"),
    ],
)
