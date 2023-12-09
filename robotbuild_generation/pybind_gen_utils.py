from robotpy_build.pkgcfg_provider import PkgCfgProvider, PkgCfg
from robotpy_build.pkgcfg_provider import PkgCfg
from robotpy_build.config.pyproject_toml import RobotpyBuildConfig, Download
from robotpy_build.wrapper import Wrapper
from robotpy_build.autowrap.writer import WrapperWriter
from robotpy_build.platforms import get_platform, get_platform_override_keys
from robotpy_build.overrides import apply_overrides
from pkg_resources import EntryPoint
from rules_robotpy_utils.robotbuild_generation.load_project_config import (
    load_project_config,
)
import os
import tomli
import importlib
from typing import List


class Setup:
    def __init__(self, config_path: str, output_directory: str, fake_entry_point_projects : List[str]):
        fake_entry_point_projects = fake_entry_point_projects or []
        self.root = output_directory
        self.wrappers = []
        self.static_libs = []

        self.platform = get_platform()

        project_fname = config_path

        try:
            with open(project_fname, "rb") as fp:
                self.pyproject = tomli.load(fp)
        except FileNotFoundError as e:
            raise ValueError("current directory is not a robotpy-build project") from e

        self.project_dict = self.pyproject.get("tool", {}).get("robotpy-build", {})

        # Overrides are applied before pydantic does processing, so that
        # we can easily override anything without needing to make the
        # pydantic schemas messy with needless details
        override_keys = get_platform_override_keys(self.platform)
        apply_overrides(self.project_dict, override_keys)

        try:
            self.project = RobotpyBuildConfig(**self.project_dict)
        except Exception as e:
            raise ValueError(
                f"robotpy-build configuration in pyproject.toml is incorrect"
            ) from e

        # package = self.project.base_package

        # Remove deprecated 'generate' data and migrate
        for wname, wrapper in self.project.wrappers.items():
            if wrapper.generate:
                if wrapper.autogen_headers:
                    raise ValueError(
                        "must not specify 'generate' and 'autogen_headers'"
                    )
                autogen_headers = {}
                for l in wrapper.generate:
                    for name, header in l.items():
                        if name in autogen_headers:
                            raise ValueError(
                                f"{wname}.generate: duplicate key '{name}'"
                            )
                        autogen_headers[name] = header
                wrapper.autogen_headers = autogen_headers
                wrapper.generate = None

        # Shared wrapper writer instance
        self.wwriter = WrapperWriter()

        self.prepare(output_directory)
        
        self.load_fake_eps(fake_entry_point_projects)


    def load_fake_eps(self, fake_entry_point_projects: str):

        def __load(key, value):
            entry_point = pkg_resources.EntryPoint.parse(f'{key} = {value}.pkgcfg', dist=distribution)
            pkg_resources.working_set.add(distribution)
            self.pkgcfg.add_pkg(PkgCfg(entry_point))
        import pkg_resources

        distribution = pkg_resources.Distribution()

        for project in fake_entry_point_projects:
            if project == "wpimath":
                __load("wpimath", "wpimath")
                __load("wpimath_controls", "wpimath._controls")
                __load("wpimath_cpp", "wpimath._impl")
                __load("wpimath_filter", "wpimath.filter")
                __load("wpimath_geometry", "wpimath.geometry")
                __load("wpimath_interpolation", "wpimath.interpolation")
                __load("wpimath_kinematics", "wpimath.kinematics")
                __load("wpimath_spline", "wpimath.spline")
            elif project == "hal":
                __load("hal_simulation", "hal.simulation")
                __load("wpiHal", "hal")
            else:
                __load(project, project)

    def prepare(self, output_directory):

        self.pkgcfg = PkgCfgProvider()

        self.pypi_package = self.project.metadata.name
        self.setup_kwargs = {}
        self.incdir = ["x/"]

        self._collect_wrappers(output_directory=output_directory)

        self.pkgcfg.detect_pkgs()

    def _collect_wrappers(self, output_directory):
        ext_modules = []

        for package_name, cfg in self.project.wrappers.items():
            package_dir = os.path.join(output_directory, package_name)
            if not os.path.exists(package_dir):
                # print("Making package ", package_dir)
                os.makedirs(package_dir)

            if cfg.ignore:
                # print("Ignoring ", cfg)
                continue

            if cfg.generation_data:
                # print("Has gen data", cfg.generation_data)
                cfg.generation_data = (
                    f"{self.project.base_package}/src/main/python/" + cfg.generation_data
                )

            # print(package_name, cfg)
            # self._fix_downloads(cfg, False)
            w = Wrapper(package_name, cfg, self, self.wwriter)
            self.wrappers.append(w)
            self.pkgcfg.add_pkg(w)

            if w.extension:
                ext_modules.append(w.extension)

        if ext_modules:
            self.setup_kwargs["ext_modules"] = ext_modules
