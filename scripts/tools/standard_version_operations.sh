standard_version_first_release() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "standard_version_first_release" "Usage standard_version_first_release <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  print_status "action" "standard_version_first_release" "($branch_name) Setup first version and CHANGELOG.md"

  git_checkout "$project_directory" "$branch_name" || return $?

  local standard_version_output
  standard_version_output=$(execute_call_in "$project_directory" npx standard-version --first-release)
  local standard_version_result=$?

  if [ "$standard_version_result" -ne 0 ]; then
    print_status "skipped" "standard_version_first_release" "First release already exists"
    return 0
  else
    local version
    version=$(echo "$standard_version_output" | grep -o 'tagging release v[^ ]*' | cut -d ' ' -f3)
    print_status "success" "standard_version_first_release" "First release generated. Version $version"
    return 0
  fi

  git_push_origin "$project_directory" "$branch_name" || return $?
  
  return 0
}
