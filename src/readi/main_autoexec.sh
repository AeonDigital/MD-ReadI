#!/usr/bin/env bash

# Ensure the script is being executed directly and not sourced by another script
if [ "${BASH_SOURCE}" = "${0}" ]; then
  for arg in "$@"; do
    if [[ "${arg}" == -* ]]; then
      case ${arg} in
        -h|--help)
          shell_md_readi_help
          exit $?
          ;;
      esac
    fi
  done

  # Execute the main command
  shell_md_readi "$@"
fi
