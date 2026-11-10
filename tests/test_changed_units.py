import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / ".docker/changed_units.py"
SPEC = importlib.util.spec_from_file_location("changed_units", SCRIPT)
selector = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(selector)


class ChangedUnitsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.write("root.hcl", "locals {}")
        self.write("homelab/env.hcl", "locals {}")
        self.write("prod/env.hcl", "locals {}")
        self.write("_common/service.hcl", '''
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  settings = read_terragrunt_config("${get_repo_root()}/settings/shared.hcl")
}
''')
        self.write("settings/shared.hcl", "locals {}")
        for unit in ("homelab/service", "prod/service"):
            self.write(unit + "/terragrunt.hcl", '''
include "root" { path = find_in_parent_folders("root.hcl") }
include "common" { path = "${get_repo_root()}/_common/service.hcl" }
''')

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def select(self, *paths):
        return selector.affected_units(str(self.root), paths)

    def cli(self, *args):
        return subprocess.run(
            [sys.executable, "-B", str(SCRIPT), *args],
            cwd=self.root, text=True, capture_output=True,
        )

    def init_git(self):
        for args in (["init", "-q"], ["add", "."],
                     ["-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                      "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false",
                      "commit", "-qm", "fixture"]):
            subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True)

    def test_root_config_selects_all_readers(self):
        self.assertEqual(self.select("root.hcl"), ["homelab/service", "prod/service"])

    def test_environment_is_resolved_from_each_consuming_unit(self):
        self.assertEqual(self.select("homelab/env.hcl"), ["homelab/service"])
        self.assertEqual(self.select("prod/env.hcl"), ["prod/service"])

    def test_nearest_parent_config_shadows_outer_config(self):
        self.write("homelab/nested/env.hcl", "locals {}")
        self.write("homelab/nested/service/terragrunt.hcl",
                   'include "common" { path = "${get_repo_root()}/_common/service.hcl" }')
        self.assertEqual(self.select("homelab/env.hcl"), ["homelab/service"])
        self.assertEqual(self.select("homelab/nested/env.hcl"), ["homelab/nested/service"])

    def test_transitive_references_outside_common(self):
        self.write("settings/shared.hcl", 'locals { extra = read_terragrunt_config("./extra.hcl") }')
        self.write("settings/extra.hcl", "locals {}")
        self.assertEqual(self.select("settings/extra.hcl"), ["homelab/service", "prod/service"])

    def test_relative_common_reference_and_cycles(self):
        self.write("_common/service.hcl", 'locals { other = read_terragrunt_config("../settings/shared.hcl") }')
        self.write("settings/shared.hcl", 'locals { other = read_terragrunt_config("../_common/service.hcl") }')
        self.assertEqual(self.select("settings/shared.hcl"), ["homelab/service", "prod/service"])

    def test_direct_unit_changes_include_deleted_files(self):
        self.assertEqual(self.select("homelab/service/deleted-values.yaml"), ["homelab/service"])

    def test_deleted_shared_file_still_selects_readers(self):
        (self.root / "settings/shared.hcl").unlink()
        self.assertEqual(self.select("settings/shared.hcl"), ["homelab/service", "prod/service"])

    def test_deleted_parent_config_still_selects_readers(self):
        (self.root / "homelab/env.hcl").unlink()
        self.assertEqual(self.select("homelab/env.hcl"), ["homelab/service"])

    def test_comments_do_not_add_dependencies(self):
        self.write("_common/service.hcl", '''
# read_terragrunt_config("${get_repo_root()}/settings/comment.hcl")
locals {} // read_terragrunt_config("${get_repo_root()}/settings/comment.hcl")
/*
read_terragrunt_config("${get_repo_root()}/settings/comment.hcl")
*/
''')
        self.write("settings/comment.hcl", "locals {}")
        self.assertEqual(self.select("settings/comment.hcl"), [])

    def test_unrelated_files_and_empty_selection(self):
        self.assertEqual(self.select("README.md"), [])
        self.assertEqual(self.select(), [])
        result = self.cli()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_git_diff_includes_deleted_parent_config(self):
        self.init_git()
        (self.root / "homelab/env.hcl").unlink()
        result = self.cli("--diff-base", "HEAD")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["homelab/service"])

    def test_failed_git_diff_is_not_a_successful_empty_selection(self):
        self.init_git()
        result = self.cli("--diff-base", "missing-ref")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing-ref", result.stderr)

    @unittest.skipUnless(shutil.which("task"), "go-task is not installed")
    def test_task_preserves_selector_failure_and_targets_override(self):
        self.init_git()
        shutil.copy(REPO / "Taskfile.yml", self.root)
        shutil.copytree(REPO / ".tasks", self.root / ".tasks")
        (self.root / ".docker").mkdir()
        shutil.copy(SCRIPT, self.root / ".docker/changed_units.py")
        env = dict(os.environ, DIFF_BASE="missing-ref", TARGETS="")
        result = subprocess.run(
            ["task", "--taskfile", "Taskfile.yml", "list:changed"],
            cwd=self.root, env=env, text=True, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing-ref", result.stderr)

        env["TARGETS"] = "homelab/service"
        result = subprocess.run(
            ["task", "--taskfile", "Taskfile.yml", "list:changed"],
            cwd=self.root, env=env, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), ["homelab/service"])
