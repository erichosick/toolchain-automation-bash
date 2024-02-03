project_feature() {
  local feature_name
  feature_name=$(basename "${BASH_SOURCE[0]%.*}")

  if [ "$#" -ne 1 ]; then
    print_status "error" "setup_node_project" "Usage project_feature <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_description="setup node in project"
  local required_vars="PROJECT_NAME, REPOSITORY_NAME, GITHUB_ORG_NAME, GITHUB_ASSIGNEE, PROJECT_LICENSE, PROJECT_DESCRIPTION, AUTHOR_NAME, AUTHOR_EMAIL, AUTHOR_URL, PROJECT_KEYWORDS, README_ADDITIONAL"

  # TODO: Logic to stop if dependencies are not met
  local feature_dependencies="feature_project_and_git, feature_readme_md"
  local feature_conflicts=""
  local feature_overlaps=""

  local issue_description="Provide support for a node project by creating a package.json file."

  local branch_name="staging"
  local commit_type="feat"
  local commit_scope="setup"
  local branch_title="node package.json"
  local branch_details="
  * Generate package.json
  "

  local issue_number
  issue_number=$(project_pre_feature "$project_directory" "$feature_name" "$feature_description" "$required_vars" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$GITHUB_ASSIGNEE" "$branch_name" "$issue_description")
  local issue_number_result=$?

  # START: project_feature
  package_json_create "$project_directory" "$PROJECT_NAME" "$PROJECT_LICENSE" "$PROJECT_DESCRIPTION" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$AUTHOR_NAME" "$AUTHOR_EMAIL" "$AUTHOR_URL" "$PROJECT_KEYWORDS" || return $?

  # END: project_feature

  if [ "$issue_number_result" -eq 0 ]; then
    project_post_feature "$project_directory" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$branch_name" "$commit_type" "$commit_scope" "$branch_title" "$branch_details" "$feature_name" "$issue_number" "--allow-empty" || return $?
  fi

}
