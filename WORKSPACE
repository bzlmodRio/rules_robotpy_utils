workspace(name = "rules_robotpy_utils")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    sha256 = "e85ae30de33625a63eca7fc40a94fea845e641888e52f32b6beea91e8b1b2793",
    strip_prefix = "rules_python-0.27.1",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.27.1/rules_python-0.27.1.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "rules_robotpy_utils_pip_deps",
    requirements_darwin = "//:requirements_darwin.txt",
    requirements_lock = "//:requirements_lock.txt",
    requirements_windows = "//:requirements_windows.txt",
)

load("@rules_robotpy_utils_pip_deps//:requirements.bzl", "install_deps")

install_deps()

http_archive(
    name = "aspect_bazel_lib",
    sha256 = "4d6010ca5e3bb4d7045b071205afa8db06ec11eb24de3f023d74d77cca765f66",
    strip_prefix = "bazel-lib-1.39.0",
    url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.39.0/bazel-lib-v1.39.0.tar.gz",
)

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies()

http_archive(
    name = "pybind11_bazel",
    sha256 = "b72c5b44135b90d1ffaba51e08240be0b91707ac60bea08bb4d84b47316211bb",
    strip_prefix = "pybind11_bazel-b162c7c88a253e3f6b673df0c621aca27596ce6b",
    urls = ["https://github.com/pybind/pybind11_bazel/archive/b162c7c88a253e3f6b673df0c621aca27596ce6b.zip"],
)

# We still require the pybind library.
http_archive(
    name = "pybind11",
    build_file = "@pybind11_bazel//:pybind11.BUILD",
    sha256 = "b4bb373102b8a7f8ffd2fc4560938b635d91ef276d724a9d57a1f6237c566791",
    strip_prefix = "pybind11-7953d19a7c17ff1bfe0b7c4cdfde216d400d5f28",
    urls = ["https://github.com/pybind/pybind11/archive/7953d19a7c17ff1bfe0b7c4cdfde216d400d5f28.tar.gz"],
)

load("@pybind11_bazel//:python_configure.bzl", "python_configure")

python_register_toolchains(
    name = "python3_10",
    ignore_root_user_error = True,
    python_version = "3.10.6",
)

load("@python3_10//:defs.bzl", "interpreter")

python_configure(
    name = "local_config_python",
    python_interpreter_target = interpreter,
)

http_archive(
    name = "bzlmodRio",
    sha256 = "ebcf55589f36f2297450b887f1194eb66f96563d3d40d5b7e99b2fa0bea2fd5a",
    strip_prefix = "bzlmodRio-00cf3776fe594aa245f88acdcb22918f6f938144",
    url = "https://github.com/bzlmodRio/bzlmodRio/archive/00cf3776fe594aa245f88acdcb22918f6f938144.tar.gz",
)

load("@bzlmodRio//private/non_bzlmod:download_dependencies.bzl", "download_dependencies")

download_dependencies(
    allwpilib_version = None,
    apriltaglib_version = None,
    imgui_version = None,
    libssh_version = None,
    local_monorepo_base = "../bzlmodRio/monorepo",
    navx_version = None,
    ni_version = None,
    opencv_version = None,
    phoenix_version = None,
    revlib_version = None,
    rules_bazelrio_version = None,
    rules_checkstyle_version = None,
    rules_pmd_version = None,
    rules_spotless_version = None,
    rules_toolchains_version = "2024-1",
    rules_wpi_styleguide_version = None,
    rules_wpiformat_version = None,
)
