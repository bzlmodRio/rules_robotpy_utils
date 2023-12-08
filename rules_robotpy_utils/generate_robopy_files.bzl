load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@rules_robotpy_utils//rules_robotpy_utils/private:generate_source_files.bzl", "generate_source_files")
load("@rules_robotpy_utils//rules_robotpy_utils/private:generate_project_files.bzl", "generate_project_files")

def generate_robopy_files(
        name,
        config_file,
        python_deps = [],
        projects = None,
        headers = [],
        disable = False):
    
    if disable:
        return
        

    ###############################
    print(name)
    internal_project_dependencies = []
    if name == "apriltag":
        internal_project_dependencies.append("wpiutil")
        internal_project_dependencies.append("wpimath")
    if name == "wpinet":
        internal_project_dependencies.append("wpiutil")
    if name == "wpimath":
        internal_project_dependencies.append("wpiutil")
    if name == "hal":
        internal_project_dependencies.append("wpiutil")
    if name == "ntcore":
        internal_project_dependencies.append("wpiutil")
        internal_project_dependencies.append("wpinet")
    if name == "cscore":
        internal_project_dependencies.append("wpiutil")
        internal_project_dependencies.append("wpinet")
        internal_project_dependencies.append("ntcore")
    if name == "wpilib":
        internal_project_dependencies.append("wpiutil")
        internal_project_dependencies.append("hal")
        internal_project_dependencies.append("wpimath")
        internal_project_dependencies.append("wpinet")
        internal_project_dependencies.append("ntcore")
    ###############################

    projects = [name] if projects == None else projects
    generate_project_files(
        name = name,
        config_file = config_file,
        projects = projects,
        python_deps = python_deps,
        internal_project_dependencies = internal_project_dependencies,
    )

    generate_source_files(
        name = name,
        config_file = config_file,
        python_deps = python_deps,
        headers = headers,
        internal_project_dependencies = internal_project_dependencies,
    )
