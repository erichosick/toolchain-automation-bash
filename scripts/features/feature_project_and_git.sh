
# @description Setup the project directory and git repository
# @param string $1 The project directory
# @example
#   project_feature "/path/to/project"
# @exitcode 0  If the project feature was setup successfully.
# @exitcode 1  If any error occurred.
# @exitcode 2 If the feature already exists and we are skipping
project_feature() {
  # the feature name is the name of the feature script itself
  # (without the .sh extension) and is used as a git tag. This is how we can
  # verify if a given script has been ran already, verify which scripts
  # dependent, conflicting and overlapping.
  local feature_name
  feature_name=$(basename "${BASH_SOURCE[0]%.*}")

  if [ "$#" -ne 1 ]; then
    print_status "error" "setup_staging_branch" "Usage project_feature <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_description="setup git in ${project_directory}"
  local required_vars="REPOSITORY_NAME, GITHUB_ORG_NAME, GITHUB_ASSIGNEE"

  # TODO: Logic to stop if dependencies are not met
  local feature_dependencies="feature_project_and_git, feature_readme_md"
  local feature_conflicts=""
  local feature_overlaps=""

  local issue_description="Provide source code management for the project by using git. Setup a staging branch."

  local branch_name="${STAGING_BRANCH:-staging}"
  local commit_type="feat"
  local commit_scope="setup"
  local branch_title="project directory, git and staging branch"
  local branch_details="
  * Create project directory
  * Initialize a git repository
  * Create staging branch
  "

  # This feature is a bit different because we are setting up the project
  # directory and the git repository. We can't do this in our
  # project_pre_feature so we need to do all of this here.
  # create the project directory if it dosn't already exist. Only then can we
  # check if the feature exists.
  make_directory "$project_directory" -q || return $?

  # only continue feature does not exist
  feature_exists_status "$project_directory" "$feature_name" || return 2

  # Initialize git, add remote repository and setup remote origin
  git_setup "$project_directory" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME"

  local issue_number
  issue_number=$(project_pre_feature "$project_directory" "$feature_name" "$feature_description" "$required_vars" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$GITHUB_ASSIGNEE" "$branch_name" "$issue_description")
  local issue_number_result=$?

  # START: project_feature

    # For this feature, we are just pushing an empty staging branch.

  # END: project_feature

  if [ "$issue_number_result" -eq 0 ]; then
    project_post_feature "$project_directory" "$GITHUB_ORG_NAME" "$REPOSITORY_NAME" "$branch_name" "$commit_type" "$commit_scope" "$branch_title" "$branch_details" "$feature_name" "$issue_number" "--allow-empty" || return $?
  fi

}
