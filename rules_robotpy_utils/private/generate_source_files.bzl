
load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")


def generate_source_files(
        name,
        config_file,
        python_deps,
        headers,
        internal_project_dependencies):

    print(native.glob(["gen/**"]))
    py_binary(
        name = name + ".generate_pybind_exe",
        main = "pybind_on_build_gen_shim.py",
        srcs = ["@rules_robotpy_utils//robotbuild_generation:pybind_on_build_gen_shim.py"],
        deps = python_deps + [
            "@rules_robotpy_utils//robotbuild_generation:pybind_on_build_gen",
        ],
        data = headers + native.glob(["gen/**"]),
    )

    native.filegroup(
        name = "gen_files",
        srcs = native.glob(["gen/**"])
    )

    print(headers)

    __generate_on_build_gen_files(
        name = "generate_on_build_gen",
        tool = name + ".generate_pybind_exe",
        config_file = config_file,
        gen_dir = "_gen_on_build",
        headers = headers,
        gen_files =  "gen_files",
        project_name = name,
        internal_project_dependencies = internal_project_dependencies,
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


def __generate_on_build_gen_files_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.gen_dir)

    args = ctx.actions.args()
    args.add("--output_directory", output_dir.path)
    args.add("--config", ctx.files.config_file[0].path)
    args.add("--project_name", ctx.attr.project_name)
    if ctx.attr.internal_project_dependencies:
        args.add("--internal_project_dependencies")
        for dep in ctx.attr.internal_project_dependencies:
            args.add(dep)

    print("****************************")
    print(ctx.files.headers)
    print("****************************")

    ctx.actions.run(
        inputs = ctx.files.config_file + ctx.files.gen_files + ctx.files.headers,
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
        "headers": attr.label_list(
            allow_files = True,
        ),
        "internal_project_dependencies": attr.string_list(),
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
