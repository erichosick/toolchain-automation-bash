project_feature () {
  local feature_name
  feature_name=$(basename "${BASH_SOURCE[0]%.*}")

  if [ "$#" -ne 1 ]; then
    print_status "error" "publish_first_version" "Usage project_feature <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="${branch_name:-staging}"

  print_status "feature" "publish_first_version" "Publish first version"  
  feature_exists_status "$project_directory" "$feature_name" || return 1

  standard_version_first_release "$project_directory" "$branch_name" || return $?

  # Tag the feature
  git_tag_feature "$project_directory" "$feature_name"  "$commit_type" "commit_scope" || return $?

  git_push_origin "$project_directory" "$branch_name" || return $?

  git_push_tags "$project_directory" || return $?
}