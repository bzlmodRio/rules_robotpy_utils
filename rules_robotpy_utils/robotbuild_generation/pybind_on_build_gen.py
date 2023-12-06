import argparse

from rules_robotpy_utils.robotbuild_generation.load_project_config import (
    load_project_config,
)
from rules_robotpy_utils.robotbuild_generation.pybind_gen_utils import Setup
from robotpy_build.wrapper import Wrapper
import os
import re
import shutil


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--output_directory", required=True)
    parser.add_argument("--project_name", required=True)
    parser.add_argument("--keep_json_files", action="store_true")
    args = parser.parse_args()
    args.keep_json_files = True

    intermediate_directory = args.output_directory + ".intermediate"

    setup = Setup(args.config, intermediate_directory)

    for wrapper in setup.wrappers:
        wrapper.on_build_gen(os.path.join(intermediate_directory, "pybind_gen"))

    # print("Done gen\n\n\n")

    project_name = args.project_name
    # print("COPYING FROM", os.path.join(intermediate_directory, f"{project_name}/rpy-include"))
    # raise

    shutil.copytree(
        os.path.join(intermediate_directory, "pybind_gen"),
        os.path.join(args.output_directory, "gensrc"),
    )

    rpy_include_output_dir = os.path.join(
        args.output_directory, f"rpy-include/{project_name}"
    )

    shutil.copytree(
        os.path.join(intermediate_directory, f"{project_name}"),
        rpy_include_output_dir,
    )

    print("Copying CPP files to src directory")
    for root, _, files in os.walk(rpy_include_output_dir):
        for f in files:
            if f.endswith(".cpp"):
                re_pattern = f"rpy-include/{project_name}(/.*)/rpy-include"
                xxxx = re.search(re_pattern, root)
                print(root, f)
                # print(re_pattern, "->", xxxx)
                if xxxx:
                    subfolder = xxxx[1]
                    actual_directory = os.path.join(
                        args.output_directory,
                        "gensrc",
                        project_name + "_" + subfolder[1:].replace("_", ""),
                    )
                    if project_name == "wpilib" and subfolder == "/shuffleboard":
                        actual_directory = os.path.join(
                            args.output_directory,
                            "gensrc",
                            project_name + "c_" + subfolder[1:].replace("_", ""),
                        )
                    if project_name == "wpilib" and subfolder == "/simulation":
                        actual_directory = os.path.join(
                            args.output_directory,
                            "gensrc",
                            project_name + "c_" + subfolder[1:].replace("_", ""),
                        )

                    if not os.path.exists(actual_directory):
                        os.makedirs(actual_directory)
                    print("Got a match...", subfolder)
                    print("  Putting in ", actual_directory)
                    shutil.move(os.path.join(root, f), actual_directory)
                elif project_name == "wpilib":
                    shutil.move(
                        os.path.join(root, f),
                        os.path.join(
                            args.output_directory, "gensrc", project_name + "_core"
                        ),
                    )
                else:
                    print("  No regex, doing normal copy")

                    shutil.move(
                        os.path.join(root, f),
                        os.path.join(args.output_directory, "gensrc", project_name),
                    )

    if not args.keep_json_files:
        for root, _, files in os.walk(os.path.join(args.output_directory, "gensrc")):
            for f in files:
                if f.endswith(".json"):
                    os.remove(os.path.join(root, f))


if __name__ == "__main__":
    main(sys.argv[1:])
