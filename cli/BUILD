load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "auth_cli",
    srcs = ["auth_cli.py"],
    deps = [
         "//db:connect",
         "//db/models:server_auth",
        requirement("click"),
    ],
)

py_binary(
    name = "ship_cli",
    srcs = ["ship_cli.py"],
    deps = [
         "//db:connect",
         "//db/models:ship",
        requirement("click"),
    ],
)
