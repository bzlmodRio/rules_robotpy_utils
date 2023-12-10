load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")


def generate_project_files(
        name,
        config_file,
        python_deps,
        projects,
        headers,
        internal_project_dependencies):
    py_binary(
        name = name + ".pybind_on_build_dl_exe",
        main = "pybind_on_build_dl_shim.py",
        srcs = ["@rules_robotpy_utils//robotbuild_generation:pybind_on_build_dl_shim.py"],
        deps = python_deps + [
            "@rules_robotpy_utils//robotbuild_generation:pybind_on_build_dl",
        ],
        data = native.glob(["gen/**"]),
    )

    generated_files = []
    file_mapping = {}
    pkgcfg_files = []
    for project in projects:
        init_file = "{name}/_init_{project}.py".format(name = name, project = project)
        if name != project:
            init_file = "{name}/{project}/_init_{project2}.py".format(name = name, project = project, project2 = project.replace("_", ""))
        if name == "wpimath" and project == "_impl":
            init_file = "wpimath/_impl/_init_wpimath_cpp.py"
        if name == "wpilib" and project == "_impl":
            init_file = "wpilib/_impl/_init_wpilibc.py"
        if name == "hal" and project == "wpiHal":
            init_file = "{name}/_init_{project}.py".format(name = name, project = project)
        if name == "hal" and project == "simulation":
            init_file = "hal/simulation/_init_simulation.py".format(name = name, project = project)
        generated_files.append("on_build_dl/" + init_file)
        filter_srcs(
            name = "__filtered_gen_" + project + "_init",
            srcs = ":generate_on_build_dl_files",
            filter = init_file,
        )
        file_mapping[init_file] = "__filtered_gen_" + project + "_init"

        pkg_file = "{project}/pkgcfg.py".format(project = project)
        if name != project:
            pkg_file = "{name}/{project}/pkgcfg.py".format(name = name, project = project)
        if name == "hal" and project == "wpiHal":
            pkg_file = "hal/pkgcfg.py".format(project = project)
        generated_files.append("on_build_dl/" + pkg_file)
        filter_srcs(
            name = "__filtered_gen_" + project + "_pkg",
            srcs = ":generate_on_build_dl_files",
            filter = pkg_file,
        )
        file_mapping[pkg_file] = "__filtered_gen_" + project + "_pkg"
        pkgcfg_files.append(pkg_file)

    py_library(
        name = "pkgcfg",
        srcs = pkgcfg_files,
        visibility = ["//visibility:public"],
        data = headers,
        imports = ["."],
    )

    write_source_files(
        name = "write_on_build_dl_files",
        files = file_mapping,
        suggested_update_target = "//:write_on_build_dl_files",
        visibility = ["//visibility:public"],
    )


    cmd = "$(locations " + name + ".pybind_on_build_dl_exe" + ") --config=$(location " + config_file + ") --output_files $(OUTS)"
    if internal_project_dependencies:
        cmd += " --internal_project_dependencies " + " ".join(internal_project_dependencies)

    native.genrule(
        name = "generate_on_build_dl_files",
        srcs = [config_file],
        outs = generated_files,
        cmd = cmd,
        tools = [name + ".pybind_on_build_dl_exe"],
        visibility = ["//wpimath:__subpackages__"],
    )


def _filter_srcs_impl(ctx):
    return DefaultInfo(files = depset([f for f in ctx.files.srcs if f.path.endswith(ctx.attr.filter)]))

filter_srcs = rule(
    implementation = _filter_srcs_impl,
    attrs = {
        "filter": attr.string(mandatory = True),
        "srcs": attr.label(allow_files = True, mandatory = True),
    },
)


def __generate_on_build_dl_files_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.gen_dir)

    args = ctx.actions.args()
    args.add("--output_directory", output_dir.path)
    args.add("--config", ctx.files.config_file[0].path)

    ctx.actions.run(
        inputs = ctx.files.config_file,
        outputs = [output_dir],
        executable = ctx.executable.tool,
        arguments = [args],
    )

    return [DefaultInfo(files = depset([output_dir]))]

__generate_on_build_dl_files = rule(
    implementation = __generate_on_build_dl_files_impl,
    attrs = {
        "config_file": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "gen_dir": attr.string(
            mandatory = True,
        ),
        "gen_files": attr.label(
            allow_files = True,
        ),
        "tool": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)
