import argparse
import logging
from rules_robotpy_utils.robotbuild_generation.pybind_gen_utils import Setup
from robotpy_build.wrapper import Wrapper
from robotpy_build.pkgcfg_provider import PkgCfgProvider, PkgCfg
import os
import importlib


def main(argv):
    logging.getLogger().setLevel(logging.DEBUG)
    # print("BUILD DL")
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--parent_folder")
    parser.add_argument("--output_files", nargs="+", required=True)
    parser.add_argument("--internal_project_dependencies", nargs="+")
    args = parser.parse_args(argv)

    output_directory = os.path.dirname(args.output_files[0]) + "/.."
    if args.parent_folder:
        output_directory = output_directory + "/.."

    setup = Setup(args.config, output_directory, args.internal_project_dependencies)

    for wrapper in setup.wrappers:
        wrapper.on_build_dl("", "")

    logging.info(f"Contents of {output_directory}: {os.listdir(output_directory)}")
    for root, _, files in os.walk(output_directory):
        for f in files:
            logging.debug(os.path.join(root, f))

if __name__ == "__main__":
    main(sys.argv[1:])
