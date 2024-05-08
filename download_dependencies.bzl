load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def download_rules_robotpy_utils_dependencies():
    maybe(
        http_archive,
        name = "rules_python",
        integrity = "sha256-xovcT77CXeW1STuIGc/Id8TqKZwNyxXCRMWgAgjN4xE=",
        strip_prefix = "rules_python-0.31.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.31.0/rules_python-0.31.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        integrity = "sha256-qKkmRecpi79TiqiAExxq20z2I5u9JyMPB3oAQU1Y5M4=",
        strip_prefix = "bazel-lib-2.7.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.7.2/bazel-lib-v2.7.2.tar.gz",
    )

    maybe(
        http_archive,
        name = "pybind11_bazel",
        integrity = "sha256-3BSpYGcrq/baLygweaW1wT5ASpQOp824KXtx+PMWQ6U=",
        strip_prefix = "pybind11_bazel-2.12.0",
        urls = ["https://github.com/pybind/pybind11_bazel/releases/download/v2.12.0/pybind11_bazel-2.12.0.tar.gz"],
    )
