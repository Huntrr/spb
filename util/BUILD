load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

py_library(
    name = "error",
    srcs = ["error.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("flask"),
        requirement("grpcio"),
    ],
)

py_library(
    name = "mongo",
    srcs = ["mongo.py"],
    visibility = ["//visibility:public"],
    deps = [
        ":error",
        requirement("grpcio"),
        requirement("mongoengine"),
    ],
)
