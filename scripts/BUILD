load("@rules_python//python:defs.bzl", "py_binary")
load("@py_deps//:requirements.bzl", "requirement")

py_binary(
    name = "publish_news",
    srcs = ["publish_news.py"],
    deps = [
        "//db:connect",
        "//db/models:news",
    ]
)
