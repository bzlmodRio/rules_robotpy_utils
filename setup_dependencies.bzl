load("@rules_python//python:pip.bzl", "pip_parse")

def setup_rules_robotpy_utils_dependencies():
    pip_parse(
        name = "rules_robotpy_utils_pip_deps",
        requirements_darwin = "@rules_robotpy_utils//:requirements_darwin.txt",
        requirements_lock = "@rules_robotpy_utils//:requirements_lock.txt",
        requirements_windows = "@rules_robotpy_utils//:requirements_windows.txt",
    )
