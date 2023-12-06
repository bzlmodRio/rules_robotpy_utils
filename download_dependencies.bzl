load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def download_rules_robotpy_utils_dependencies():

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "94750828b18044533e98a129003b6a68001204038dc4749f40b195b24c38f49f",
        strip_prefix = "rules_python-0.21.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.21.0/rules_python-0.21.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "4d6010ca5e3bb4d7045b071205afa8db06ec11eb24de3f023d74d77cca765f66",
        strip_prefix = "bazel-lib-1.39.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.39.0/bazel-lib-v1.39.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "pybind11_bazel",
        sha256 = "b72c5b44135b90d1ffaba51e08240be0b91707ac60bea08bb4d84b47316211bb",
        strip_prefix = "pybind11_bazel-b162c7c88a253e3f6b673df0c621aca27596ce6b",
        urls = ["https://github.com/pybind/pybind11_bazel/archive/b162c7c88a253e3f6b673df0c621aca27596ce6b.zip"],
    )

    maybe(
        http_archive,
        name = "pybind11",
        build_file = "@pybind11_bazel//:pybind11.BUILD",
        sha256 = "b4bb373102b8a7f8ffd2fc4560938b635d91ef276d724a9d57a1f6237c566791",
        strip_prefix = "pybind11-7953d19a7c17ff1bfe0b7c4cdfde216d400d5f28",
        urls = ["https://github.com/pybind/pybind11/archive/7953d19a7c17ff1bfe0b7c4cdfde216d400d5f28.tar.gz"],
    )
