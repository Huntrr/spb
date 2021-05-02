load("@rules_python//python:defs.bzl", "py_library")
load("@py_deps//:requirements.bzl", "requirement")

package(default_visibility=["//visibility:public"])

py_library(
    name = "news",
    srcs = ["news.py"],
    deps = [
        requirement("mongoengine"),
    ],
)

py_library(
    name = "player",
    srcs = ["player.py"],
    deps = [
        ":ship",
        requirement("mongoengine"),
    ],
)

py_library(
    name = "ship",
    srcs = ["ship.py"],
    deps = [
        requirement("mongoengine"),
    ],
)

py_library(
    name = "user",
    srcs = ["user.py"],
    deps = [
        ":player",
        "//auth:security",
        "//auth:jwt_context",
        "//util:error",
        requirement("blinker"),
        requirement("grpcio"),
        requirement("jwt"),
        requirement("mongoengine"),
    ],
)

py_library(
    name = "server_auth",
    srcs = ["server_auth.py"],
    deps = [
        ":player",
        "//auth:security",
        "//auth:jwt_context",
        "//util:error",
        requirement("grpcio"),
        requirement("jwt"),
        requirement("mongoengine"),
    ],
)

py_library(
    name = "lobby",
    srcs = ["lobby.py"],
    deps = [
        ":ship",
        ":user",
        "//auth:security",
        requirement("mongoengine"),
    ],
)
