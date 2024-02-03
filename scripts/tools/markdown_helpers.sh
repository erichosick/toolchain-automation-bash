# Purpose:
#   Adds content at a specified location within a Markdown file based on the
#   provided token and direction.
#
# Parameters:
#   - file_path: The path to the Markdown file.
#   - token: The token around which content is to be added. The token must be
#            defined in the markdown file as <!-- TOKEN_START --> and
#            <!-- TOKEN_END -->.
#   - direction: Determines where to add the content relative to the token
#                ('above' or 'below').
#   - content: The content to be added. If not provided, it will be read from
#              stdin.
#
# Usage:
#   token_add_content README.md TITLE above "New content"
#   echo "New content" | token_add_content README.md TITLE above
#
# Behavior:
#   Inserts the given content either directly above or below the specified token
#   in the file. If the content is not provided as an argument, it prompts the
#   user to enter it manually.
token_add_content() {

  if [[ "$#" -ne 3 && "$#" -ne 4 ]]; then
    print_status "error" "token_add_content" "Usage token_add_content <file_path> <token> <direction> [content] where <direction> must be 'above' or 'below'. Use echo 'content' | token_add_content ... to pipe content instead. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"
  local token="$2"
  local direction="$3"
  local content="$4"

  local token_suffix=""

  # Determine the suffix based on the direction
  if [[ "$direction" == "below" ]]; then
    token_suffix="_START"
  elif [[ "$direction" == "above" ]]; then
    token_suffix="_END"
  else
    print_status "error" "token_add_content" "The <direction> must be 'above' or 'below'."
    return 1
  fi

  # Format the token to match the specific pattern <!-- {TOKEN_SUFFIX} -->
  local formatted_token="<!-- ${token}${token_suffix} -->"

  # Check if the file exists
  if [[ ! -f "$file_path" ]]; then
    echo "Error: File '$file_path' does not exist."
    return 1
  fi

  # Check if the formatted token exists in the file
  if ! grep -q "$formatted_token" "$file_path"; then
    echo "Error: Token '$formatted_token' not found in the file."
    return 1
  fi

  if [[ -z "$content" ]]; then
    # Read content from stdin if it's not provided as an argument
    if [ -t 0 ]; then  # Check if stdin is a terminal (i.e., not piped input)
      echo "Please type in the HTML content to add to $token. Press Enter then Ctrl-D when done (or ctrl-c to cancel)."
      content=$(cat)
    else
      content=$(cat)  # Read content from piped input
    fi
  fi

  print_status "debug" "content" "$formatted_token"

  # Use sed to insert content based on the direction
  # (compatible with BSD sed on macOS)
  if [[ "$direction" == "above" ]]; then
    sed -i '' "/$formatted_token/i\\
$content
" "$file_path"
  else
    sed -i '' "/$formatted_token/a\\
$content
" "$file_path"
  fi
}


# # Purpose:
# #   Clears content between specified start and end tokens in a Markdown file.
# #
# # Parameters:
# #   - file_path: The path to the Markdown file.
# #   - token: The token whose content is to be cleared. The token must be
# #            defined in the markdown file as <!-- TOKEN_START --> and
# #            <!-- TOKEN_END -->.
# # Usage:
# #   token_clear README.md DESCRIPTION
# #
# # Behavior:
# #   Removes all content found between the <!-- TOKEN_START --> and
# #   <!-- TOKEN_END --> markers. Ensures that no other tokens are present within
# #   this range before clearing. Returns an error if the specified tokens are not
# #   found or if nested tokens are detected.
# token_clear() {
#   if [ "$#" -ne 2 ]; then
#     print_status "error" "token_clear" "Usage token_clear <file_path> <token>. Values(s) passed were '$#'"
#     return 1
#   fi

#   local file_path="$1"
#   local token="$2"

#   # Format the start and end tokens
#   local start_token="<!-- ${token}_START -->"
#   local end_token="<!-- ${token}_END -->"

#   # Check if the file exists
#   if [[ ! -f "$file_path" ]]; then
#     print_status "error" "token_clear" "File '$file_path' does not exist"
#     return 1
#   fi

#   # Check if the formatted tokens exist in the file
#   if ! grep -q "$start_token" "$file_path"; then
#     print_status "error" "token_clear" "Start token '$start_token' not found in the file"
#     return 1
#   fi
#   if ! grep -q "$end_token" "$file_path"; then
#     print_status "error" "token_clear" "End token '$end_token' not found in the file"
#     return 1
#   fi

#   # Check for the presence of any tokens between the start and end tokens
#   if sed -n "/$start_token/,/$end_token/{
#     /<!--/p
#   }" "$file_path" | grep -qvE "$start_token|$end_token"; then
#     print_status "error" "token_clear" "Cannot clear out a token range that contains other tokens"
#     return 1
#   fi

#   # Use sed to delete content between start and end tokens
#   # (compatible with BSD sed on macOS)
#   sed -i '' "/$start_token/,/$end_token/{
#     /$start_token/!{
#       /$end_token/!d;
#     }
#   }" "$file_path"

#   return 0  

# }

# # Purpose:
# #   Sorts the content alphabetically for a given token in a Markdown file.
# #
# # Parameters:
# #   - file_path: The path to the Markdown file.
# #   - token: The token within which content is to be sorted. The token must be
# #            defined in the markdown file as <!-- TOKEN_START --> and
# #            <!-- TOKEN_END -->.
# #
# # Usage:
# #   token_sort README.md CONTRIBUTORS
# #
# # Behavior:
# #   Alphabetically sorts lines of content found between the <!-- TOKEN_START -->
# #   and <!-- TOKEN_END --> markers.
# #   Returns an error if the specified tokens are not found or the file does
# #   not exist.
# token_sort() {
#   if [ "$#" -ne 2 ]; then
#     print_status "error" "token_sort" "Usage token_sort <file_path> <token>. Values(s) passed were '$#'"
#     return 1
#   fi

#   local file_path="$1"
#   local token="$2"

#   # Format the start and end tokens
#   local start_token="<!-- ${token}_START -->"
#   local end_token="<!-- ${token}_END -->"

#   # Check if the file exists
#   if [[ ! -f "$file_path" ]]; then
#     print_status "error" "token_sort" "File '$file_path' does not exist"
#     return 1
#   fi

#   # Check if the formatted tokens exist in the file
#   if ! grep -q "$start_token" "$file_path"; then
#     print_status "error" "token_sort" "Start token '$start_token' not found in the file"
#     return 1
#   fi

#   if ! grep -q "$end_token" "$file_path"; then
#     print_status "error" "token_sort" "End token '$end_token' not found in the file"
#     return 1
#   fi

#   # Extract, sort, and replace the content between the tokens
#   # Step 1: Extract and sort the content, save it in a temporary file
#   sed -n "/$start_token/,/$end_token/p" "$file_path" | \
#   sed "/$start_token/d; /$end_token/d" | \
#   sort > tmp_sorted_content.txt

#   # Step 2: Replace the original content with the sorted content, while preserving the tokens
#   awk -v start="$start_token" -v end="$end_token" -v file="tmp_sorted_content.txt" '
#   $0 == start {print; system("cat " file); skip=1; next}
#   $0 == end {skip=0}
#   skip {next}
#   {print}
#   ' "$file_path" > tmpfile && mv tmpfile "$file_path"

#   # Clean up the temporary file
#   rm tmp_sorted_content.txt

#   return 0  
# }

# # Purpose:
# #   Adds new custom token markers into a Markdown file after an existing
# #   specified token.
# # Parameters:
# #   - file_path: The path to the Markdown file.
# #   - existing_token: The existing token after which the new tokens will be
# #                     added.
# #   - new_token: The new token to be added.
# # Note: The token must be defined in the markdown file as <!-- TOKEN_START -->
# #        and <!-- TOKEN_END -->.
# # Usage:
# #   token_new README.md BADGES TABLE_OF_CONTENTS
# # Behavior:
# #   Inserts new start and end tokens for the specified new token immediately
# #   following the end token of the existing token. Checks for the existence of
# #   the new tokens before adding to avoid duplicates. Returns an error if the
# #   specified existing token is not found, or the new token exists.
# token_new() {
#   if [ "$#" -ne 3 ]; then
#     print_status "error" "token_new" "Usage token_new <file_path> <existing_token> <new_token>. Values(s) passed were '$#'"
#     return 1
#   fi

#   local file_path="$1"
#   local existing_token="$2"
#   local new_token="$3"

#   # Format the existing end token and new tokens
#   local existing_end_token="<!-- ${existing_token}_END -->"
#   local new_start_token="<!-- ${new_token}_START -->"
#   local new_end_token="<!-- ${new_token}_END -->"

#   # Check if the file exists
#   if [[ ! -f "$file_path" ]]; then
#     print_status "error" "token_new" "File '$file_path' does not exist"
#     return 1
#   fi

#   # Check if the existing end token exists in the file
#   if ! grep -q "$existing_end_token" "$file_path"; then
#     print_status "error" "token_new" "End token for '$existing_token' not found in the file. Unable to add a new token after it"
#     return 1
#   fi

#   # Check if the new tokens already exist in the file
#   if grep -q "$new_start_token" "$file_path" || grep -q "$new_end_token" "$file_path"; then
#     print_status "error" "token_new" "Token '$new_token' already exist in the file"
#     return 1
#   fi

#   # Use sed to insert new tokens after the existing end token
#   sed -i '' "/$existing_end_token/a\\
# \\
# $new_start_token\\
# $new_end_token\\
# " "$file_path"

#   return 0
# }


token_exists() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "token_exists" "Usage token_exists <file_path> <token>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"
  local token="$2"
  local start_token="<!-- ${token}_START -->"

  file_exists_status "$file_path" || return $?

  # Check if the new start token already exists in the file
  if grep -qF "$start_token" "$file_path"; then
    print_status "skipped" "token_append" "Token '${token}' already exists in the file."
    return 2
  fi

  return 0
}

# @description Appends a new token to the end of a Markdown file.
# @example
#  token_append_to_file "README.md" "TITLE"
# @arg $1 string File path.
# @arg $2 string New token.
# @exitcode 0  If the token was successfully appended to the file.
# @exitcode 1  If any error occurred.
token_append_to_file() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "token_append" "Usage token_append <file_path> <new_token>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"
  local new_token="$2"

  local new_start_token="<!-- ${new_token}_START -->"
  local new_end_token="<!-- ${new_token}_END -->"

  token_exists "$file_path" "$new_token" || return $?

  # Append new token to the end of the file
  echo -e "\n$new_start_token\n$new_end_token" >> "$file_path"

  return 0
}

tokens_add() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "tokens_add" "Usage tokens_add <file_path> <tokens>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"
  local tokens_string="$2"
  
  # Convert the comma-separated list of tokens into an array
  IFS=',' read -ra tokens <<< "$tokens_string"
  
  # Iterate over the tokens and append each to the file
  for token in "${tokens[@]}"; do
    # Trim leading and trailing whitespace from token
    local token_clean
    token_clean=$(echo "$token" | xargs)

    # Call token_append_to_file for each token
    token_append_to_file "$file_path" "$token_clean"
    local token_append_status=$?

    if [[ "$token_append_status" -ne 0 && "$token_append_status" -ne 2 ]]; then
      return $token_append_status
    fi
  done
}