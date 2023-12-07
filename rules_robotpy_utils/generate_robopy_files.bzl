load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

def generate_robopy_files(
        name,
        config_file,
        python_deps = [],
        projects = None,
        headers = [],
        disable = False):
    if disable:
        return

    projects = [name] if projects == None else projects
    __run_on_dl(
        name = name,
        config_file = config_file,
        projects = projects,
        python_deps = python_deps,
    )

    __run_on_build_gen(
        name = name,
        config_file = config_file,
        python_deps = python_deps,
        headers = headers,
    )

def __run_on_dl(
        name,
        config_file,
        python_deps,
        projects):
    print(python_deps)
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
        imports = ["."],
    )

    write_source_files(
        name = "write_on_build_dl_files",
        files = file_mapping,
        suggested_update_target = "//:write_on_build_dl_files",
        visibility = ["//visibility:public"],
    )

    native.genrule(
        name = "generate_on_build_dl_files",
        srcs = [config_file],
        outs = generated_files,
        cmd = "$(locations " + name + ".pybind_on_build_dl_exe" + ") --config=$(location " + config_file + ") --output_files $(OUTS)",
        tools = [name + ".pybind_on_build_dl_exe"],
        visibility = ["//wpimath:__subpackages__"],
    )

def _filter_srcs_impl(ctx):
    print(ctx.files.srcs)
    print(ctx.attr.filter)
    return DefaultInfo(files = depset([f for f in ctx.files.srcs if f.path.endswith(ctx.attr.filter)]))

filter_srcs = rule(
    implementation = _filter_srcs_impl,
    attrs = {
        "filter": attr.string(mandatory = True),
        "srcs": attr.label(allow_files = True, mandatory = True),
    },
)

def __run_on_build_gen(
        name,
        config_file,
        python_deps,
        headers):
    py_binary(
        name = name + ".generate_pybind_exe",
        main = "pybind_on_build_gen_shim.py",
        srcs = ["@rules_robotpy_utils//robotbuild_generation:pybind_on_build_gen_shim.py"],
        deps = python_deps + [
            "@rules_robotpy_utils//robotbuild_generation:pybind_on_build_gen",
        ],
        data = headers,
    )

    __generate_on_build_gen_files(
        name = "generate_on_build_gen",
        tool = name + ".generate_pybind_exe",
        config_file = config_file,
        gen_dir = "_gen_on_build",
        project_name = name,
    )

    write_source_files(
        name = "write_on_build_gen",
        files = {
            "generated": ":generate_on_build_gen",
        },
        suggested_update_target = "//:write_python_on_build_gen",
        visibility = ["//visibility:public"],
        diff_test = True,
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

def __generate_on_build_gen_files_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.gen_dir)

    args = ctx.actions.args()
    args.add("--output_directory", output_dir.path)
    args.add("--config", ctx.files.config_file[0].path)
    args.add("--project_name", ctx.attr.project_name)

    ctx.actions.run(
        inputs = ctx.files.config_file,
        outputs = [output_dir],
        executable = ctx.executable.tool,
        arguments = [args],
    )

    return [DefaultInfo(files = depset([output_dir]))]

__generate_on_build_gen_files = rule(
    implementation = __generate_on_build_gen_files_impl,
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
        "project_name": attr.string(
            mandatory = True,
        ),
        "tool": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)
