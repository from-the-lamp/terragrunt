#!/usr/bin/env python3
"""List the terragrunt units a CI pipeline should plan/apply for a given set of changed files.

Plain `git diff` directory-matching misses one real case: a change to a shared
`_common/*.hcl` file touches no unit directory by itself, but every unit whose
terragrunt.hcl includes it (directly or transitively through another _common
file) is actually affected. This walks the repo's own _common include graph to
catch that case too - same idea as currencycom/platform-iac's
tools/atlantis/include_projects.py, trimmed to just "list affected units"
(no atlantis.yaml involved here).

Usage:
    python3 tools/changed_units.py <changed-file> [<changed-file> ...]

Prints one unit directory per line (repo-relative, e.g. "homelab/gitlab/projects/argo-apps/project").
Exits 0 with no output if nothing is affected. Only the standard library is used.
"""
import os
import re
import sys

SKIP_DIRS = {".git", ".terragrunt-cache", ".terraform", "_modules", "node_modules"}
# A quoted string that points at a shared file: "${get_repo_root()}/_common/x.hcl" or "../../_common/x.hcl".
REF = re.compile(r'"((?:\$\{get_repo_root\(\)\}/|(?:\.\./)+)?_common/[^"\s]+\.hcl)"')


def hcl_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith(".hcl"):
                yield os.path.relpath(os.path.join(dirpath, name), root)


def shared_refs(root, rel):
    """_common/*.hcl files (repo-relative) named in one .hcl file."""
    path = os.path.join(root, rel)
    with open(path, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    # Drop comment lines so prose like "same as _common/x.hcl" isn't mistaken for a real reference.
    text = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith(("#", "//")))
    found = set()
    for m in REF.finditer(text):
        ref = m.group(1)
        if ref.startswith("${get_repo_root()}/"):
            target = ref[len("${get_repo_root()}/"):]
        elif ref.startswith("../"):
            target = os.path.normpath(os.path.join(os.path.dirname(rel), ref))
        else:
            target = ref
        if os.path.isfile(os.path.join(root, target)):
            found.add(target)
    return found


def closure(start, refs):
    seen, todo = set(), list(start)
    while todo:
        f = todo.pop()
        if f in seen:
            continue
        seen.add(f)
        todo.extend(refs.get(f, ()))
    return seen


def main(argv):
    if not argv:
        return 0
    root = os.getcwd()
    changed = set(argv)
    changed_dirs = {os.path.dirname(f) for f in changed}

    files = list(hcl_files(root))
    refs = {f: shared_refs(root, f) for f in files}
    units = sorted(
        os.path.dirname(f) for f in files
        if os.path.basename(f) == "terragrunt.hcl" and not f.startswith("_common/")
    )

    affected = []
    for unit in units:
        tg_file = os.path.join(unit, "terragrunt.hcl")
        # Case 1: something inside the unit's own directory changed directly.
        if unit in changed_dirs or any(f.startswith(unit + "/") for f in changed):
            affected.append(unit)
            continue
        # Case 2: the unit (transitively) includes a changed _common/*.hcl.
        deps = closure(refs.get(tg_file, ()), refs)
        if any(f in deps for f in changed if f.startswith("_common/") and f.endswith(".hcl")):
            affected.append(unit)

    for unit in affected:
        print(unit)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
