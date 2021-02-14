load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

package(default_visibility=["//visibility:public"])

py_library(
    name = "news",
    srcs = ["news.py"],
    deps = [
        requirement("mongoengine"),
    ]
)
