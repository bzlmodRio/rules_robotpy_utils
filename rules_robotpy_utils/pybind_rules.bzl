load("@pybind11_bazel//:build_defs.bzl", "pybind_extension", "pybind_library")
load("@rules_cc//cc:defs.bzl", "cc_library")

def create_pybind_library(
        name,
        strip_include_prefix = None,
        includes = [],
        extra_srcs = [],
        extra_hdrs = [],
        deps = [],
        entry_point = [],
        rpy_include_dir = None,
        generation_dir_prefix = ""):
    generation_subdir = generation_dir_prefix + name

    rpy_hdr_deps = []
    rpy_include_dir = rpy_include_dir or "generated/rpy-include/{}/rpy-include".format(name)
    rpy_includes = native.glob([rpy_include_dir + "/rpygen/*.hpp".format(name)])
    print(name)
    print(rpy_include_dir)
    print(rpy_includes)
    if rpy_includes:
        cc_library(
            name = "{}_rpy_includes".format(name),
            hdrs = rpy_includes,
            strip_include_prefix = rpy_include_dir,
        )
        rpy_hdr_deps.append("{}_rpy_includes".format(name))

    generated_srcs = native.glob(["generated/gensrc/{}/**/*.cpp".format(generation_subdir)])
    pybind_library(
        name = "{}_pybind_library".format(name),
        srcs = generated_srcs + extra_srcs + native.glob(["generated/gensrc/" + generation_subdir + "/*.hpp"]),
        hdrs = extra_hdrs,
        deps = [
            "@rules_robotpy_utils//rules_robotpy_utils/include:robotpy_includes",
        ] + deps + rpy_hdr_deps,
        copts = select({
            "@bazel_tools//src/conditions:darwin": ["-Wno-sign-compare", "-Wno-unused-value", "-Wno-pessimizing-move", "-Wno-delete-abstract-non-virtual-dtor", "-Wno-delete-non-abstract-non-virtual-dtor", "-Wno-overloaded-virtual"],
            "@bazel_tools//src/conditions:windows": ["/wd4407", "/wd4101"],
            "@rules_bzlmodrio_toolchains//constraints/combined:is_linux": ["-Wno-attributes", "-Wno-redundant-move", "-Wno-sign-compare", "-Wno-deprecated", "-Wno-deprecated-declarations", "-Wno-unused-value", "-Wno-unused-but-set-variable", "-Wno-unused-variable"],
        }),
        target_compatible_with = select({
            "@rules_bzlmodrio_toolchains//constraints/is_bullseye32:bullseye32": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_bullseye64:bullseye64": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_raspi32:raspi32": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_roborio:roborio": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
        local_defines = ["RPYBUILD_MODULE_NAME=_{}".format(name), "PYBIND11_DETAILED_ERROR_MESSAGES=1"],
        defines = ["PYBIND11_USE_SMART_HOLDER_AS_DEFAULT=1"],
        strip_include_prefix = strip_include_prefix,
        includes = includes,
        visibility = ["//visibility:public"],
        tags = [
            "no-bullseye",
            "no-raspi",
            "no-roborio",
        ],
    )

    pybind_extension(
        name = "_{}".format(name),
        srcs = entry_point + native.glob(["generated/gensrc/" + generation_subdir + "/*.hpp"]),
        deps = [":{}_pybind_library".format(name)],
        defines = ["RPYBUILD_MODULE_NAME=_{}".format(name)],
        visibility = ["//visibility:private"],
        includes = ["generated/gensrc/" + generation_subdir],
        target_compatible_with = select({
            "@rules_bzlmodrio_toolchains//constraints/is_bullseye32:bullseye32": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_bullseye64:bullseye64": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_raspi32:raspi32": ["@platforms//:incompatible"],
            "@rules_bzlmodrio_toolchains//constraints/is_roborio:roborio": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
        tags = [
            "no-bullseye",
            "no-raspi",
            "no-roborio",
        ],
    )
