load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@rules_python//python:defs.bzl", "py_binary")

def generate_robotpy_project_files(
        name,
        config_file,
        python_deps = [],
        headers = [],
        internal_project_dependencies = [],
        disable_gen_test = False,
        visibility = None,
        init_file = None,
        parent_folder = ""):
    py_binary(
        name = name + ".pybind_on_build_dl_exe",
        main = "pybind_on_build_dl_shim.py",
        srcs = ["@rules_robotpy_utils//robotbuild_generation:pybind_on_build_dl_shim.py"],
        deps = python_deps + [
            "@rules_robotpy_utils//robotbuild_generation:pybind_on_build_dl",
        ],
        data = native.glob(["gen/**"]),
    )

    cmd = "$(locations " + name + ".pybind_on_build_dl_exe" + ") --config=$(location " + config_file + ") --output_files $(OUTS)"
    if parent_folder:
        cmd += " --parent_folder=" + parent_folder
    if internal_project_dependencies:
        cmd += " --internal_project_dependencies " + " ".join(internal_project_dependencies)

    file_mapping = {}
    generated_files = []

    init_file_name = name
    if init_file_name.startswith("_"):
        init_file_name = init_file_name[1:]

    init_file = init_file or "_init_{}.py".format(init_file_name)
    file_mapping[init_file] = "__filtered_gen_{}_init".format(name)
    generated_files.append("on_build_dl/{}{}/".format(parent_folder, name) + init_file)
    filter_srcs(
        name = "__filtered_gen_{}_init".format(name),
        srcs = ":generate_on_build_dl_files",
        filter = init_file,
    )

    pkg_file = "pkgcfg.py"
    file_mapping[pkg_file] = "__filtered_gen_{}_pkg".format(name)
    generated_files.append("on_build_dl/{}{}/".format(parent_folder, name) + pkg_file)
    filter_srcs(
        name = "__filtered_gen_{}_pkg".format(name),
        srcs = ":generate_on_build_dl_files",
        filter = pkg_file,
    )

    native.genrule(
        name = "generate_on_build_dl_files",
        srcs = [config_file],
        outs = generated_files,
        cmd = cmd,
        tools = [name + ".pybind_on_build_dl_exe"],
        visibility = ["//wpimath:__subpackages__"],
    )

    write_source_files(
        name = "write_on_build_dl_files",
        files = file_mapping,
        suggested_update_target = "//:write_on_build_dl_files",
        visibility = ["//visibility:public"],
        diff_test = not disable_gen_test,
    )

    native.filegroup(
        name = "pkgcfg",
        srcs = [pkg_file],
        visibility = visibility,
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
