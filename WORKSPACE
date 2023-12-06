workspace(name = "rules_robotpy_utils")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@rules_robotpy_utils//:download_dependencies.bzl", "download_rules_robotpy_utils_dependencies")

download_rules_robotpy_utils_dependencies()

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

load("@rules_robotpy_utils//:setup_dependencies.bzl", "setup_rules_robotpy_utils_dependencies")

setup_rules_robotpy_utils_dependencies()

load("@rules_robotpy_utils_pip_deps//:requirements.bzl", "install_deps")

install_deps()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies()

# We still require the pybind library.

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
