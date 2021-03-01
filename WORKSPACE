load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
git_repository(
    name = "rules_python",
    remote = "https://github.com/bazelbuild/rules_python.git",
    commit = "6135186f93d46ab8551d9fe52bac97bf0c2de1ab",
)

load("@rules_python//python:pip.bzl", "pip_install")
pip_install(
   name = "py_deps",
   requirements = "//third_party/py:requirements.txt",
   python_interpreter = "python3",
)
