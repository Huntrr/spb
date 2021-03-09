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
        "//util:error",
        requirement("absl-py"),
        requirement("Flask"),
        requirement("grpcio"),
    ],
)
