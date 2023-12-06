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


class Setup:
    def __init__(self, config_path: str, output_directory: str):
        self.root = output_directory
        self.output_directory = "/home/pjreiniger/git/allwpilib"
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

        unique_deps = set()
        for wrapper in self.wrappers:
            for dep in wrapper.cfg.depends:
                self.__load_dep(dep, unique_deps)

    def __load_dep(self, dep, unique_deps):
        if dep in unique_deps:
            # print(f"Skipping {dep}")
            return
        unique_deps.add(dep)

        print("Trying to load dep ", dep)
        if dep == "wpimath_cpp":
            dep = "wpimath._impl"
        elif dep == "wpimath_controls":
            dep = "wpimath._controls"
        elif "wpimath_" in dep:
            dep = ".".join(dep.split("_"))
        elif dep == "wpiHal":
            dep = "hal"

        try:
            mod = importlib.import_module(dep + ".pkgcfg")
            self.pkgcfg.add_pkg(PkgCfg(mod))

            module_deps = getattr(mod, "depends", [])
            for d in module_deps:
                self.__load_dep(d, unique_deps)
        except ModuleNotFoundError as e:
            print(
                f"  Could not load {dep}, might be ok if it is an internal package {e}, {type(e)}"
            )

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
                    f"{package_name}/src/main/python/" + cfg.generation_data
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
