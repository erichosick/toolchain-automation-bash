#!/bin/bash
# @file print_operations
# @brief Operations to print status messages.

# @description Print a status message.
#
# @example
#   print_status "action" "setup_project_directory" "Setup the project directory"
#
# @arg $1 string Action status.
#   One of: project, feature, action, success, skipped, warning, error
# @arg $2 string Action name.
# @arg $3 string Status description.
#
# @exitcode 0  If the status was printed successfully.
# @exitcode 1  If any error occurred.
print_status() {
  if [ "$#" -ne 3 ]; then
    print_status "error" "print_status" "Usage print_status <action_status> <action> <text> where actions_status is one of: project, feature, action, success, skipped, warning, error, debug, todo. Values(s) passed were '$#'"
    return 1
  fi

  local action_status=$1
  local action=$2
  local text=$3

  local escape="\x1B["
  local no_color="${escape}0m"

  # formats
  local bold="1m"
  local normal="2m"
  local italic="3m"
  local underline="4m"

  # colors where 3 is for text and 4 would be for background
  local black="30"
  local red="31"
  local green="32"
  local yellow="33"
  local blue_light="34"
  local purple="35"
  local blue_dark="36"
  local white="37"
  
  local color_code=""
  local status_code=""

  case $action_status in
    "project")
      color_code="${escape}${purple};${bold}"
      status_code="(project)"
      ;;
    "feature")
      color_code="${escape}${blue_light};${bold}"
      status_code="(feature)  "
      ;;
    "action")
      color_code="${escape}${blue_dark};${bold}"
      status_code="(action)     "
      ;;
    "success")
      color_code="${escape}${green};${bold}"
      status_code="(success)      "
      ;;
    "skipped")
      color_code="${escape}${blue_light};${normal}"
      status_code="(skipped)      "
      ;;
    "warning")
      color_code="${escape}${yellow};${normal}"
      status_code="(warning)      "
      ;;
    "error")
      color_code="${escape}${red};${normal}"
      status_code="(error)        "
      ;;
    "debug")
      color_code="${escape}${yellow};${bold}"
      status_code="(debug)        "
      ;;
    "todo")
      color_code="${escape}${black};${bold}"
      status_code="(todo)     "
      ;;
    *)
      print_status "error" "print_status" "Print_status was sent an unsupported action status: $action_status. Supported actions are project, feature, action, success, skipped, warning, error, debug, todo"
      return 1
      ;;
  esac

  # we use >&2 to send stuff to stderr so we can return values from functions
  printf "${color_code}${status_code} ${action}: ${text}${no_color}\n" >&2
}