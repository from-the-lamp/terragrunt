include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "common" {
  path = "${get_repo_root()}/_common/gitlab/project.hcl"
}

inputs = {
  namespace_path = "from-the-lamp"
  name           = "blog"
  description    = "Personal blog - from-the-lamp"
}
