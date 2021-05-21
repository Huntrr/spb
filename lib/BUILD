load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "email_utils",
    srcs = ["email_utils.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("sendgrid"),
    ],
)

py_library(
    name = "flask_utils",
    srcs = ["flask_utils.py"],
    visibility = ["//visibility:public"],
    deps = [
        "//db/models:user",
        "//db/models:server_auth",
        "//util:error",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("grpcio"),
    ],
)

py_library(
    name = "redis_client",
    srcs = ["redis_client.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("redis"),
    ],
)
