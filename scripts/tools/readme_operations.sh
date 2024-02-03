readme_template_create() {
  if [ "$#" -ne 3 ]; then
    print_status "error" "readme_template_create" "Usage readme_template_create <project_directory> <project_name> <project_description>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local project_name="$2"
  local project_description="$3"
  local author_name="$4"
  local author_email="$5"
  local author_url="$6"
  local readme_additional="$7"

  local project_directory_resolved
  project_directory_resolved=$(resolve_directory "$project_directory") || return $?
  local readme_template_file="$project_directory_resolved/README_TEMPLATE.md"

  touch_file "$readme_template_file" || return $?
  tokens_add "$readme_template_file" "TITLE, DESCRIPTION, DETAILS, BADGES, QUICK_SETUP, FEATURES, TABLE_OF_CONTENTS, INSTALLATION USAGE_START, FEATURES, DEPENDENCIES, CONFIGURATION, DOCUMENTATION, EXAMPLES, FAQ, LICENSE, ADDITIONAL_NOTES" || return $?

  # readme_project_heading "$project_directory/README.md" "$project_name" "$project_description" || return $?

}