load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "server",
    srcs = ["server.py"],
    deps = [
        "//db:connect",
        "//db/models:news",
        "//db/models:user",
        "//util:error",
        requirement("absl-py"),
        requirement("Flask"),
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
