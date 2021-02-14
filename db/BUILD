load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "connect",
    srcs = ["connect.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("dnspython"),
        requirement("mongoengine"),
    ]
)
