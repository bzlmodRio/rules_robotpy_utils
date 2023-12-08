import tomli
from robotpy_build.config.pyproject_toml import RobotpyBuildConfig


def load_project_config(config_file):
    try:
        with open(config_file, "rb") as fp:
            pyproject = tomli.load(fp)
    except FileNotFoundError as e:
        raise ValueError("current directory is not a robotpy-build project") from e

    project_dict = pyproject.get("tool", {}).get("robotpy-build", {})

    project = RobotpyBuildConfig(**project_dict)

    return project
