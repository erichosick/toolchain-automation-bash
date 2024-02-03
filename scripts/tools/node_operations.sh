package_json_create() {
  if [ "$#" -ne 10 ]; then
    print_status "error" "package_json_create" "Usage package_json_create <project_directory> <project_name> <project_license> <project_description> <github_org_name> <repository_name> <author_name> <author_email> <author_url> <project_keywords>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local project_name="$2"
  local project_license="$3"
  local project_description="$4"
  local github_org_name="$5"
  local repository_name="$6"
  local author_name="$7"
  local author_email="$8"
  local author_url="$9"
  local project_keywords="${10}"
  
  if file_exists "$project_directory/package.json"; then
    print_status "skipped" "package_json_create" "package.json exists"
    return 0
  fi

  local echo_output
  echo_output=$(echo '{
  "name": "'"$project_name"'",
  "version": "1.0.0",
  "license": "'"$project_license"'",
  "private": true,
  "description": "'"$project_description"'",
  "keywords": [],
  "homepage": "https://github.com/'"$github_org_name"'/'"$repository_name"'#readme",
  "bugs": {
    "url": "https://github.com/'"$github_org_name"'/'"$repository_name"'/issues",
    "email": "'"$author_email"'"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/'"$github_org_name"'/'"$repository_name"'.git"
  },
  "author": {
    "name": "'"$author_name"'",
    "email": "'"$author_email"'",
    "url": "'"$author_url"'"
  },
  "contributors": [],
  "engines": {
    "node": "^18.18.0 || ^20.9.0 || >=21.1.0"
  },
  "scripts": {}
}' > "$project_directory/package.json")
    local echo_output_result=$?

  jq --argjson keywords "$(echo $PROJECT_KEYWORDS | jq -R 'split(",")')" '.keywords = $keywords' "$project_directory/package.json" > "$project_directory/package.json.tmp" && mv "$project_directory/package.json.tmp" "$project_directory/package.json"

  if [ "$echo_output_result" -ne 0 ]; then
    print_status "error" "package_json_create" "Failed to create package.json"
    return 1
  fi

  print_status "success" "action" "Setup package.json"

  return 0
}