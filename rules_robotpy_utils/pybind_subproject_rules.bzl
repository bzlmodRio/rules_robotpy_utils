load("@//shared/bazel/rules/python/pybind_generator:generate_robotpy_project_files.bzl", "generate_robotpy_project_files")
load("@//shared/bazel/rules/python/pybind_generator:pybind_rules.bzl", "create_pybind_library")

def create_robotpy_pybind_subproject(
        name,
        config_file,
        visibility,
        internal_project_dependencies = [],
        python_deps = [],
        parent_folder = "",
        **pybind_library_kwargs):
    generate_robotpy_project_files(
        name = name,
        config_file = config_file,
        internal_project_dependencies = internal_project_dependencies,
        python_deps = python_deps,
        parent_folder = parent_folder,
        visibility = visibility,
    )

    create_pybind_library(
        name,
        extension_visibility = visibility,
        **pybind_library_kwargs
    )

    native.filegroup(
        name = "python_files",
        srcs = native.glob(["**/*.py"]),
        visibility = visibility,
    )
