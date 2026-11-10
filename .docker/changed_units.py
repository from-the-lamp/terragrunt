#!/usr/bin/env python3
"""List the Terragrunt units affected by changed files, without evaluating HCL.

Walk static HCL references transitively, including root.hcl, environment configs,
and _common includes. Resolve find_in_parent_folders from each consuming unit so
a shared _common file can read a different env.hcl in each environment. Arbitrary
computed paths are not supported.

Usage:
    python3 .docker/changed_units.py <changed-file> [<changed-file> ...]
    python3 .docker/changed_units.py --diff-base <ref>

Prints one repo-relative unit directory per line. Only the standard library is used.
"""
import argparse
import os
import re
import subprocess
import sys

SKIP_DIRS = {".git", ".terragrunt-cache", ".terraform", "_modules", "node_modules"}
# Preserve strings while removing comments (including inline and block comments).
TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|\#[^\n]*|/\*[\s\S]*?\*/')
REF = re.compile(r'"([^"\n]+\.hcl)"')
PARENT_REF = re.compile(r'\bfind_in_parent_folders\(\s*"([^"\n]+\.hcl)"\s*\)')
REPO_PREFIX = "${get_repo_root()}/"


def hcl_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith(".hcl"):
                yield os.path.relpath(os.path.join(dirpath, name), root)


def config_refs(root, rel, unit, text, changed):
    """Repo-relative HCL references, with parent lookups scoped to the consumer."""
    found = set()
    for match in PARENT_REF.finditer(text):
        parent = unit
        while True:
            target = os.path.normpath(os.path.join(parent, match.group(1)))
            # A deleted parent config still affects the units that used to read it.
            if target in changed or os.path.isfile(os.path.join(root, target)):
                found.add(target)
                break
            if not parent:
                break
            parent = os.path.dirname(parent)

    # The quoted filename in a parent lookup is not a relative path from _common.
    text = PARENT_REF.sub("", text)
    for match in REF.finditer(text):
        ref = match.group(1)
        if ref.startswith(REPO_PREFIX):
            target = ref[len(REPO_PREFIX):]
        elif ref.startswith("_common/"):
            target = ref
        else:
            target = os.path.join(os.path.dirname(rel), ref)
        target = os.path.normpath(target)
        if "${" in target or os.path.isabs(target) or target.startswith("../"):
            continue
        # Keep missing targets too: deleting a referenced file must not hide its readers.
        found.add(target)
    return found


def affected_units(root, changed):
    changed = {os.path.normpath(f) for f in changed}
    files = list(hcl_files(root))
    texts = {}
    for rel in files:
        with open(os.path.join(root, rel), encoding="utf-8", errors="replace") as fh:
            texts[rel] = TOKEN.sub(
                lambda m: m.group(0) if m.group(0).startswith('"') else " ", fh.read()
            )
    units = sorted(
        os.path.dirname(f) for f in files
        if os.path.basename(f) == "terragrunt.hcl" and not f.startswith("_common/")
    )

    affected = []
    for unit in units:
        if any(f.startswith(unit + "/") for f in changed):
            affected.append(unit)
            continue

        seen, todo = set(), [os.path.join(unit, "terragrunt.hcl")]
        while todo:
            rel = todo.pop()
            if rel in seen:
                continue
            seen.add(rel)
            if rel in texts:
                todo.extend(config_refs(root, rel, unit, texts[rel], changed) - seen)
        if changed & seen:
            affected.append(unit)
    return affected


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--diff-base", help="Read changed paths from git diff, including deletions")
    parser.add_argument("files", nargs="*")
    args = parser.parse_args(argv)
    changed = args.files
    if args.diff_base:
        # Read NUL-delimited paths directly, without xargs or a shell pipeline that
        # can turn a failed diff/selector into a successful empty selection.
        try:
            output = subprocess.check_output(
                ["git", "diff", "--name-only", "--no-renames", "-z", args.diff_base, "--"],
                text=True,
            )
        except subprocess.CalledProcessError as exc:
            return exc.returncode
        changed = changed + [f for f in output.split("\0") if f]
    if changed:
        for unit in affected_units(os.getcwd(), changed):
            print(unit)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
