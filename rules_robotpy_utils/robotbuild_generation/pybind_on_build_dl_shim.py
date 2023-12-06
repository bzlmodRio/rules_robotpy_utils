import sys

# print("\n".join(sys.path))
from rules_robotpy_utils.robotbuild_generation.pybind_on_build_dl import main

if __name__ == "__main__":
    print(sys.argv)
    main(sys.argv[1:])
