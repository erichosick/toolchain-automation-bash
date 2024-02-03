#!/bin/bash

# @file project_create
# @brief Create a new project or update an existing project.
# @description
#   Operation to create a new project or update an existing project.
#   Operations to verify that all features required by the project are present
#   and defined correctly.


# @description To ensure that all dependencies are available before running any
#   operations, we automatically source all dependencies for the project
#   operations that are defined in the 'tools' directory.
# @example
#   project_source_dependencies
#
# @noargs
#
# @exitcode 0  If all dependencies were sourced successfully.
# @exitcode 1  If any error occurred.
project_source_dependencies() {
  source "$PWD/tools/print_operations.sh"

  local tools_dir="$PWD/tools"

  # Check if the directory exists
  if [ ! -d "$tools_dir" ]; then
    print_status "error" "project_source_dependencies" "Directory '$tools_dir' not found"
    return 1
  fi

  # Iterate over each shell script file (.sh) in the tools directory
  for file in "$tools_dir"/*.sh; do
    # Exclude specific files
    if [[ $(basename "$file") == "print_operations.sh" || $(basename "$file") == "project.sh" ]]; then
      continue  # Skip the file
    fi

    # Check if the file is a regular file and not a directory
    if [ -f "$file" ]; then
      source "$file"
    fi
  done
}


# @description Verify that all features required by the project are present
#   and defined correctly.
#
# @example
#   project_verify_features
#
# @exitcode 0  If all features are present and defined correctly.
# @exitcode 1  If any feature is missing or not defined correctly.
#
# @note Expects an environment variable 'PROJECT_FEATURES'.
project_verify_features() {
  if ! is_array "${PROJECT_FEATURES[@]}"; then
    print_status "error" "project_create" "The environment variable 'PROJECT_FEATURES' must be an array. Values was'${PROJECT_FEATURES[@]}'"
    return 1
  fi

  local missing_features=""
  local invalid_features=""

  for feature in "${PROJECT_FEATURES[@]}"; do
    local verify_feature
    verify_feature=$(real_path "$feature" "-q")
    if [ -z "$verify_feature" ]; then
      # Append the missing feature to the string, followed by a comma and space
      missing_features+="${feature}, "
    fi

    # make sure that in this scope, project_feature is not defined
    unset project_feature
    # we want to verify that each feature file exports a function called
    # 'project_feature'
    # TODO: Also export a project_feature_environment variables. Get that
    # list and then verify that the required environment variables are set
    # before running all the features.
    source "$verify_feature"
    if ! function_exists "project_feature"; then
      invalid_features=+="${feature}, "
    fi
    unset project_feature
  done

  # Remove the trailing comma and space
  local missing_features=${missing_features%, }
  local expected_features=${PROJECT_FEATURES[@], }
  
  # Initialize an empty string to store the result
  local expected_features=""

  # Iterate through the array and concatenate elements with commas
  for feature in "${PROJECT_FEATURES[@]}"; do
    # If result is not empty, add a comma before the next element
    if [ -n "$expected_features" ]; then
      expected_features="${feature}, "
    fi
    expected_features="${expected_features}${feature}"
  done

  # Check and print the missing features
  if [ -n "$missing_features" ]; then
    print_status "error" "project_create" "Of the expected features '$expected_features', the following feature files do not exist: '$missing_features'. Please check the PROJECT_FEATURES environment variable"
    return 1
  fi

  # Check and print the invalid features
  if [ -n "$invalid_features" ]; then
    print_status "error" "project_create" "The following features did not export a 'project_feature' function: '$invalid_features'"
    return 1
  fi
}



project_pre_feature() {
  if [ "$#" -ne 9 ]; then
    print_status "error" "project_pre_feature" "Usage project_pre_feature <project_directory> <feature_name> <feature_description> <required_vars> <github_org_name> <github_assignee> <repository_name> <branch_name> <issue_description>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_name="$2"
  local feature_description="$3"
  local required_vars_string="$4"
  local github_org_name="$5"
  local repository_name="$6"
  local github_assignee="$7"
  local branch_name="$8"
  local issue_description="$9"

  print_status "feature" "$feature_name" "$feature_description"

  # Convert the required variables string to an array
  IFS=',' read -r -a required_vars <<< "$required_vars_string"  

  # Verify the required environment variables exist
  environment_variables_verify "${required_vars[@]}" || { echo "no_issue_env_var_invalid"; return $?; } 

  # only continue feature does not exist
  feature_exists_status "$project_directory" "$feature_name" || { echo "no_issue_feature_exists"; return 1; }

  # Initialize git, add remote repository and setup remote origin
  # git_setup "$project_directory" "$github_org_name" "$repository_name"

  # Create and switch to the main branch
  git_checkout "$project_directory" "$branch_name" || { echo "no_issue_checkout_fail"; return $?; } 

  local issue_number
  issue_number=$(gh_issue_create \
    "$project_directory" \
    "$repository_name" \
    "setup $branch_title" \
    "$issue_description" \
    "enhancement" \
    "$github_assignee")
  local issue_number_result=$?

  if ! is_integer "$issue_number"; then
    print_status "error" "project_feature" "Error calling gh_issue_create. Issue number $issue_number was not an integer"
    { echo "gh_issue_create_error"; return 1; }
  fi

  if [ "$issue_number_result" -eq 0 ]; then
    { echo "$issue_number"; return 0; }
  else
    { echo "gh_issue_create_error"; return 1; }
  fi
}

project_post_feature() {
  if [[ "$#" -ne 10 && "$#" -ne 11 ]]; then
    print_status "error" "project_post_feature" "Usage project_post_feature <project_directory> <github_org_name> <repository_name> <branch_name> <commit_type> <commit_scope> <branch_title> <branch_details> <feature_name> <issue_number> [git_commit_options]. Values(s) passed were '$#'"
    
    return 1
  fi

  local project_directory="$1"
  local github_org_name="$2"
  local repository_name="$3"
  local branch_name="$4"
  local commit_type="$5"
  local commit_scope="$6"
  local branch_title="$7"
  local branch_details="$8"
  local feature_name="$9"
  local issue_number="${10}"
  local git_commit_options="${11}"

  git_add "$project_directory" "$branch_name" || return $?

  # commit the feature
  git_feature_commit "$project_directory" "$branch_name" "$commit_type" "$commit_scope" "$branch_title" "$branch_details" "$feature_name" "$issue_number" "$git_commit_options" || return $?

  # Push the main branch to the remote repository
  git_push_origin "$project_directory" "$branch_name" || return $?

  # Close the GitHub issue and add a completion comment
  gh_issue_close "$project_directory" "$issue_number" "$github_org_name" "$repository_name" || return $?

  print_status "action" "project_feature" "Tag and push features"

  # Tag the feature
  git_tag_feature "$project_directory" "$feature_name"  "$commit_type" "commit_scope" || return $?

  # push the feature tag
  git_push_tags "$project_directory" || return $?
}

# @description Create or update an existing project.
#
# @example
#   project_create <project_directory> <environment_file>
#
# @arg $1 The directory of the project.
# @arg $2 The environment file containing the required variables.
#
# @exitcode 0  If the project was created or updated successfully.
# @exitcode 1  If any error occurred.
project_create() {
  project_source_dependencies || return $?

  if [ "$#" -ne 2 ]; then
    print_status "error" "project_create" "Usage project_create <project_directory> <environment_file>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local environment_file="$2"

  print_status "project" "project_create" "Create or update project"

  local project_directory_resolved
  project_directory_resolved=$(normalize_path "$project_directory") || return $?
  
  local environment_file_resolved
  environment_file_resolved=$(normalize_path "$environment_file") || return $?

  source "$environment_file_resolved"


  local required_vars=(
    "GITHUB_TOKEN" "GITHUB_ORG_NAME" "GITHUB_ASSIGNEE"
    "PROJECT_NAME" "AUTHOR_NAME" "AUTHOR_EMAIL" "AUTHOR_URL"
    "PROJECT_DESCRIPTION" "PROJECT_LICENSE" "PROJECT_KEYWORDS"
    "README_ADDITIONAL" "PUBLISH_TO_GITHUB" "REPOSITORY_NAME"
    "PROJECT_FEATURES"
  )

  # exit if there are any missing environment variables
  # TODO: This should be moved to each feature file: letting them verify
  # the environment variables needed.
  environment_variables_verify "${required_vars[@]}" || return $?

  project_verify_features || return $?

  for feature in "${PROJECT_FEATURES[@]}"; do
    local verify_feature_resolved
    verify_feature_resolved=$(normalize_path "$feature") || return $?
    source "$verify_feature_resolved"
    project_feature "$project_directory_resolved" || return $?

    # When we source a feature file, it creates a function called
    # 'project_feature'. To cleanup, let's remove that specific project_feature
    # function from the current shell environment.
    unset project_feature
  done

  # ./feature_node_project.sh
  # ./setup_glp3_license.sh
  # ./setup_git_ignore.sh
  # ./setup_pnpm_only.sh
  # ./setup_husky.sh
  # ./setup_commit_lint.sh
  # ./setup_standard_version.sh
  # ./setup_eslint_v8_flat_config.sh
  # ./setup_eslint_v8_watch_with_nodemon.sh
  # ./setup_eslint_debug.sh

  print_status "project" "project_create" "Finished successfully"

  return 0
}

project_create "$@"
