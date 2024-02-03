# @description Creates a repository in GitHub if it does not exist: skipping if
#   the repository exists.
# @note The command gh repo create is made idempotent by ignoring the error
# returned when the repository exists.
# @example
#   gh_repo_create <project_directory> <organization_name> <repository_name>
#
# @arg $1 string Required project directory.
# @arg $2 string Required organization name.
# @arg $3 string Required repository name.
#
# @exitcode 0 If successful.
# @exitcode 1 On error.
gh_repo_create() {
  if [ "$#" -ne 3 ]; then
    print_status "error" "gh_repo_create" "Usage gh_repo_create <project_directory> <organization_name> <repository_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local organization_name="$2"
  local repository_name="$3"

  local gh_repo_create_output
  gh_repo_create_output=$(execute_call_in "$project_directory" gh repo create "$repository_name" --public)
  local gh_repo_create_result=$?

  if [ "$gh_repo_create_result" -eq 0 ]; then
    print_status "success" "gh_repo_create" "Create repository ${organization_name}/${repository_name} on GitHub"
    return 0
  else
    if [[ "$gh_repo_create_output" == *"Name already exists on this account"* ]]; then
      print_status "skipped" "gh_repo_create" "Repository ${organization_name}/${repository_name} exists in GitHub"
      return 0
    else
      print_status "error" "gh_repo_create" "Error calling gh repo create. Message: $gh_repo_create_output"
      return $gh_repo_create_result
    fi
  fi
}

# @description Gets the issue number from Github based on the issue title
# @example
#   gh_issue_number_from_title <issue_title>
#
# @arg $1 string Required project directory.
# @arg $2 string Required issue title.
#
# @exitcode 0 If successful.
# @exitcode 1 On error.
# @exitcode 2 If issue is closed.
# @exitcode 3 If issue not found.
gh_issue_number_from_title() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "gh_issue_number_from_title" "Usage gh_issue_number_from_title <project_directory> <issue_title>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local issue_title="$2"

  local gh_issue_list_output
  gh_issue_list_output=$(execute_call_in "$project_directory" gh issue list --state=all --json number,title,closed -q "[.[] | select(.title == \"$issue_title\") | {number, closed}]")
  local gh_issue_list_status=$?

  if [ "$gh_issue_list_status" -ne 0 ]; then
    print_status "error" "gh_issue_number_from_title" "Error calling gh issue list. Message: $gh_issue_list_output"
    return $gh_issue_list_status
  fi

  local issue_count
  issue_count=$(echo "$gh_issue_list_output" | jq length)
  local issue_number
  issue_number=$(echo "$gh_issue_list_output" | jq -r '.[0].number')
  local issue_closed
  issue_closed=$(echo "$gh_issue_list_output" | jq -r '.[0].closed')

  if [ "$issue_count" -gt 1 ]; then
    print_status "warning" "gh_issue_number_from_title" "More than one issue found with title '$issue_title'. This should not happen because we consider the title to be unique. Using latest issue number $issue_number"
  fi

  if [ "$issue_count" -eq 0 ]; then
    echo "Not found"
    return 3  # No issue existed
  else 
    if [ "$issue_closed" == "true" ]; then
      echo "$issue_number"
      return 2  # Issue is closed
    else
      echo "$issue_number"
      return 0  # Issue is open
    fi
  fi
}

# @description Creates a GitHub issue if an issue with the same title does not
# exist.
# @example
#   gh_issue_create <project_directory> <repository_name> <issue_title> <issue_body> <issue_label> <issue_assignee>
#
# @arg $1 string Required project directory.
# @arg $2 string Required repository name.
# @arg $3 string Required issue title.
# @arg $4 string Required issue body.
# @arg $5 string Required issue label.
# @arg $6 string Required issue assignee.
#
# @exitcode 0 If successful.
# @exitcode 1 On error.
gh_issue_create() {
  if [ "$#" -ne 6 ]; then
    print_status "error" "gh_issue_create" "Usage gh_issue_create <project_directory> <repository_name> <issue_title> <issue_body> <issue_label> <issue_assignee>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local repository_name="$2"
  local issue_title="$3"
  local issue_body="$4"
  local issue_label="$5"
  local issue_assignee="$6"

  print_status "action" "gh_issue_create" "Create GitHub issue"

  local issue_number
  issue_number=$(gh_issue_number_from_title "$project_directory" "$issue_title")
  local issue_from_title_result=$?

  if [ "$issue_from_title_result" -eq 0 ]; then
    print_status "skipped" "gh_issue_create" "Issue (#$issue_number) '$issue_title' exists"
    echo "$issue_number"
    return 0
  fi

  if [ "$issue_from_title_result" -eq 1 ]; then
    print_status "error" "gh_issue_create" "Error calling gh_issue_number_from_title: $issue_number"
    echo "error"
    return 1
  fi

  if [ "$issue_from_title_result" -eq 2 ]; then
    print_status "skipped" "gh_issue_create" "Issue (#$issue_number) '$issue_title' exists and is closed"
    echo "$issue_number"
    return 0
  fi


  if [ "$issue_from_title_result" -eq 3 ]; then
    # Create a GitHub issue
    local new_issue_number
    new_issue_number=$(execute_call_in "$project_directory" gh issue create --title "$issue_title" --body "$issue_body" --label "$issue_label" --assignee "$issue_assignee" | awk -F '/' '{print $NF}')
    local new_issue_number_status=$?

    if [ "$new_issue_number_status" -ne 0 ]; then
      print_status "error" "gh_issue_create" "Failed to create GitHub issue."
      return $new_issue_number_status
    fi

    # Return the issue number
    print_status "success" "gh_issue_create" "Create GitHub issue #$new_issue_number"
    echo "$new_issue_number"
    return 0
  fi

  print_status "error" "gh_issue_create" "Errir in gh_issue_create. This should not happen"
  return 0
}

# @description Closes a GitHub issue if it exists.
# @example
#   gh_issue_close <project_directory> <issue-number> <organization_name> <repository_name>
#
# @arg $1 string Required project directory.
# @arg $2 string Required issue number.
# @arg $3 string Required organization name.
# @arg $4 string Required repository name.
#
# @exitcode 0 If successful.
# @exitcode 1 On error.
gh_issue_close() {
  if [ "$#" -ne 4 ]; then
    print_status "error" "gh_issue_close" "Usage ggh_issue_closeh_issue_close <project_directory> <issue-number> <organization_name> <repository_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local issue_number="$2"
  local organization_name="$3"
  local repository_name="$4"

  print_status "action" "gh_issue_close" "Close GitHub issue $issue_number"

  if ! is_git_repository "$project_directory"; then
    print_status "error" "gh_issue_close" "Unable to close issue $issue_number. Not a git repository"
    return 1
  fi

  local current_head
  current_head=$(git_current_head "$project_directory")
  local current_head_status=$?

  if [ "$current_head_status" -ne 0 ]; then
    print_status "error" "gh_issue_close" "Unable to close issue $issue_number. Error calling git_current_head"
    return 1
  fi

  local current_head_short
  current_head_short=$(git_current_head_short "$project_directory")
  local current_head_short_status=$?

  if [ "$current_head_short_status" -ne 0 ]; then
    print_status "error" "gh_issue_close" "Unable to close issue $issue_number. Error calling git_current_head_short"
    return 1
  fi

  local issue_view_output
  issue_view_output=$(execute_call_in "$project_directory" gh issue view $issue_number --json closed)
  local issue_view_status=$?

  if [ "$issue_view_status" -ne 0 ]; then
    print_status "error" "gh_issue_close" "Failed to view issue #$issue_number. Message: $issue_view_output"
    return $issue_view_status
  fi

  local closed_value
  closed_value=$(echo "$issue_view_output" | jq '.closed')

  if [ "$closed_value" == "true" ]; then
    print_status "skipped" "gh_issue_close" "Issue #$issue_number already closed"
    return 0
  fi


  local issue_close_output
  issue_close_output=$(execute_call_in "$project_directory" gh issue close $issue_number \
    --reason completed \
    --comment "fixed by: [#$current_head_short](https://github.com/$organization_name/$repository_name/commit/$current_head)")
  local issue_close_result=$?

  if [ "$issue_close_result" -ne 0 ]; then
    print_status "error" "gh_issue_close" "Failed to close issue #$issue_number. Message: $issue_close_output"
    return $issue_close_result
  fi

  print_status "success" "gh_issue_close" "Close issue #$issue_number"
  return 0
}