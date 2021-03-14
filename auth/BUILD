load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "email_utils",
    srcs = ["email_utils.py"],
    deps = [
        "//lib:email_utils",
    ],
)

py_library(
    name = "jwt_context",
    srcs = ["jwt_context.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("jwt"),
    ],
)

py_library(
    name = "security",
    srcs = ["security.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("passlib"),
    ],
)

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        ":email_utils",
        "//db:connect",
        "//db/models:news",
        "//db/models:user",
        "//db/models:server_auth",
        "//lib:flask_utils",
        "//util:error",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("grpcio"),
        requirement("mongoengine"),
    ],
)
