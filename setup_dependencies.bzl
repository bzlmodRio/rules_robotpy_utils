load("@rules_python//python:pip.bzl", "pip_parse")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def setup_rules_robotpy_utils_dependencies():

    maybe(
        http_archive,
        name = "pybind11",
        build_file = "@pybind11_bazel//:pybind11-BUILD.bazel",
        strip_prefix = "pybind11-a5b0cdcb937b2853e012489633d692099dab7078",
        integrity = "sha256-ONA//pxfMap4Hs1OtYk/Yk4UMBZ3B0PmIBsVoYIjdFE=",
        urls = ["https://github.com/pybind/pybind11/archive/a5b0cdcb937b2853e012489633d692099dab7078.zip"],
    )

    pip_parse(
        name = "rules_robotpy_utils_pip_deps",
        requirements_darwin = "@rules_robotpy_utils//:requirements_darwin.txt",
        requirements_lock = "@rules_robotpy_utils//:requirements_lock.txt",
        requirements_windows = "@rules_robotpy_utils//:requirements_windows.txt",
    )
