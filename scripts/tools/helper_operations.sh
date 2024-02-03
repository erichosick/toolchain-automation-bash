is_integer() {
  local value="$1"
  if [[ "$value" =~ ^-?[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

# # #!/bin/bash

# # # @description: Splits a given string into a comma seperated list of
# # # the split elements.
# # # @param: string - The string to split
# # # @param: delimiter - The character to split by
# # # @example: split_string_by_delimiter "one of/the things/is/../that" "/"
# # #   result: "one of","the things","is","..","that"
# # # @echo: A new comma seperated list of the split elements
# # # @return: 0 if successful, 1 if not
# # split_string_by_delimiter() {
# #   if [ "$#" -ne 2 ]; then
# #     print_status "error" "split_string_by_delimiter" "Usage split_string_by_delimiter <string> <delimiter> where string is the string to split and delimiter is the character to split by. Values(s) passed were '$#'"
# #     return 1
# #   fi

# #   local string="$1"
# #   local delimiter="$2"
# #   local s="$string$delimiter"
# #   local array=()

# #   while [[ "$s" ]]; do
# #     array+=( "${s%%"$delimiter"*}" )
# #     s=${s#*"$delimiter"}
# #   done

# #   # Echo the array elements joined by a newline
# #   local IFS=$'\n'
# #   echo "${array[*]}"
# #   return 0
# # }

# use() {
#   local path="one of/the things/is/../that"

#   IFS='/' read -rA path_array <<< "$path"
#   local arr=()
#   local current_segment="$path_array[0]"

#   for segment in "${path_array[@]}"; do
#     if [[ "$segment" != ".." ]]; then
#       arr+=("$current_segment")
#       current_segment=$segment
#     fi
#   done  

#   local IFS='/'
#   echo "${arr[*]}"

#   # local path_comma_output
#   # path_comma_output=$(split_string_by_delimiter "$path" "/") || return $?

#   # echo "$path_comma_output" | while read -A segment;
#   #   # do the push/pop here
#   #   do echo $segment[1]
#   # done

# }

# use

# normalize_path() {
#   if [ "$#" -ne 1 ]; then
#     print_status "error" "normalize_path" "Usage normalize_path <file_path>. Values(s) passed were '$#'"
#     return 1
#   fi

#   # Expand initial tilde to $HOME
#   local path="${1/#\~/$HOME}"

#   # Split the path into components
#   IFS='/' read -r path_components <<< "$path"
#   local resolved_components=()

#   for component in "${path_components[@]}"; do
#     case "$component" in
#       ""|".")
#         # Ignore empty or current directory components
#         ;;
#       "..")
#         # Pop the last directory for parent directory components
#         [ ${#resolved_components[@]} -gt 0 ] && unset resolved_components[-1]
#         ;;
#       *)
#         # Append valid components
#         resolved_components+=("$component")
#         ;;
#     esac
#   done

#   # Reconstruct the path from components
#   local resolved_path="/${resolved_components[*]}"
  
#   # Replace spaces with slashes to reconstruct the path correctly
#   resolved_path="${resolved_path// /\/}"

#   # Handling the special case for paths that resolve to the root directory
#   [[ $resolved_path == '//' ]] && resolved_path='/'

#   local cleaned_resolved_path=$(echo "$resolved_path" | tr -d '\\')

#   # Print the resolved path
#   echo "$cleaned_resolved_path"
# }


  # local IFS=/ initial_slashes='' comp comps=()

  # # Handle leading slashes
  # if [[ $path == /* ]]; then
  #   initial_slashes='/'
  #   [[ $path == //* && $path != ///* ]] && initial_slashes='//'
  # fi

  # # Split the path and iterate over components
  # for comp in $path; do
  #   # Ignore empty or current directory (.) components
  #   [[ -z $comp || $comp == '.' ]] && continue
  #   # Handle parent directory (..) components
  #   if [[ $comp != '..' || (-z $initial_slashes && ${#comps[@]} -eq 0) || (\
  #     ${#comps[@]} -gt 0 && ${comps[-1]} == '..') ]]; then
  #     comps+=("$comp")
  #   elif (( ${#comps[@]} )); then
  #     unset 'comps[-1]'
  #   fi
  # done

  # # # Join components back together
  # # comp="${initial_slashes}${comps[*]}"
  # # # Replace spaces with slashes
  # # comp="${comp// /\/}"
  # # Print the normalized path
  # echo "$comp"