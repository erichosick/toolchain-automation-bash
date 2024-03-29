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
  local feature_dependencies="feature_project_and_git"
  local feature_conflicts=""
  local feature_overlaps=""

  local issue_description="Provide a RAEDME.md for the project. The README.md should contain tokens in the form of <!-- TOKEN_START --> and <!-- TOKEN_END -->."


  local branch_name="staging"
  local commit_type="feat"
  local commit_scope="setup"
  local branch_title="readme.md file"
  local branch_details="
  * Generate readme.md file
  "

  local issue_number
  issue_number=$(project_pre_feature "$project_directory" "$feature_name" "$feature_description" "$required_vars" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$GITHUB_ASSIGNEE" "$branch_name" "$issue_description")
  local issue_number_result=$?


  # START: project_feature

  readme_template_create "$project_directory" "$PROJECT_NAME" "$PROJECT_DESCRIPTION" || return $?

  print_status "debug" "here" "here"
  return 1;

  # END: project_feature

  if [ "$issue_number_result" -eq 0 ]; then
    project_post_feature "$project_directory" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$branch_name" "$commit_type" "$commit_scope" "$branch_title" "$branch_details" "$feature_name" "$issue_number" "--allow-empty" || return $?
  fi

}
