load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "email_utils",
    srcs = ["email_utils.py"],
    deps = [
         requirement("sendgrid"),
    ],
)
