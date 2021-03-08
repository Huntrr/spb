load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "publish_news",
    srcs = ["publish_news.py"],
    deps = [
        "//db:connect",
        "//db/models:news",
    ],
)
