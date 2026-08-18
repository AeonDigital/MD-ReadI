#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK
# 
# Description:
# - A global string buffer utilized as the official transport register for the output
#   of the indentation canonization subroutine.
# - Eliminates downstream subshell forks by acting as a direct memory pass-through,
#   holding the re-mapped text block where spaces have been structurally translated
#   into standard mathematical tab tokens (\t).
# 
# Usage Notes:
# - This variable is volatile and MUST be explicitly cleared or overwritten upon
#   entering 'shell_md_readi_canonize_indentation_block' to prevent stale state propagation.
declare -g SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=""





# shell_md_readi_canonize_indentation_block — Evaluates visual geometry and normalizes
# structural indentation depth within isolated content blocks.
# 
# Description:
# - Scans an incoming multi-line string block to determine its native indentation
#   mode (Spaces vs. Tabs) and enforce structural predictability.
# - Prioritizes and bypasses formatting for isolated 4-space pre-formatted text blocks
#   to strictly protect native Markdown literal structures (Specification Section
#   3.3).
# - Discovers and indexes unique leading whitespace thresholds using an associative
#   array, subsequently sorting them to build a deterministic mathematical space-to-tab
#   map.
# - Programmatically translates multi-space indentation gaps into predictable tabular
#   tokens (\t), establishing an intermediate operational baseline that simplifies
#   downstream nested hierarchy calculations (Specification Section 3.2 & 4.1).
# 
# Arguments:
# - $1: String — The raw, un-canonized textual segment or structure element block
#   currently processed by the normalization routine.
# 
# Returns:
# - Mutates the global register 'SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK'
#   with the structural transformed tabular token string layout.
# 
# Return Codes:
# - 0: Block successfully parsed, converted, and structural integrity confirmed.
# 
# Specification Links:
# - Ref: Section 3.2 (Contextual Indentation Standard)
# - Ref: Section 3.3 (Indented Pre-formatted Text Blocks)
shell_md_readi_canonize_indentation_block() {
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=""

  local block_content="${1}"
  local output_buffer=""
  local detected_mode="NONE"
  local current_line=""
  local block_lines=()
  local line_idx=0
  local prefix=""
  local body=""
  local spaces_count=0
  local tabs_count=0
  local tab_prefix=""
  local t_idx=0
  local level_idx=0
  local sorted_level_str=""
  local all_preformatted=1
  local -a unique_space_levels=()
  local -a sorted_levels=()
  local -A seen_space_levels=()
  local -A space_to_tabs=()
  local regex_indented_line='^[[:space:]]+[^[:space:]]'

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    block_lines+=("${current_line}")
  done <<< "${block_content}"

  # 4-space preformatted block: all non-empty lines start with exactly 4 spaces
  for current_line in "${block_lines[@]}"; do
    [ -z "${current_line}" ] && continue
    if [ "${current_line:0:4}" != "    " ] || [ "${current_line:4:1}" = " " ] || [ "${current_line:4:1}" = $'\t' ] || [ -z "${current_line:4:1}" ]; then
      all_preformatted=0
      break
    fi
  done
  if [ "${all_preformatted}" -eq 1 ] && [ "${#block_lines[@]}" -gt 0 ]; then
    for current_line in "${block_lines[@]}"; do
      output_buffer+="${current_line}"${codeNL}
    done
    printf "%s" "${output_buffer}"
    return 0
  fi

  # Detection pass: collect unique indentation levels in encounter order
  for current_line in "${block_lines[@]}"; do
    if [[ "${current_line}" =~ ${regex_indented_line} ]]; then
      prefix="${current_line%%[^[:space:]]*}"
      if [[ "${prefix}" == *$'\t'* ]]; then
        detected_mode="TABS"
        break
      fi
      if [ -n "${prefix}" ]; then
        spaces_count=${#prefix}
        if [ ! "${seen_space_levels["${spaces_count}"]+x}" ]; then
          seen_space_levels["${spaces_count}"]=1
          unique_space_levels+=("${spaces_count}")
          detected_mode="SPACES"
        fi
      fi
    fi
  done

  # Build space→tab mapping by sorting unique levels and assigning sequential indices
  # Always insert 0 as the base anchor so depth-1 items get tab index 1, not 0
  if [ "${detected_mode}" = "SPACES" ] && [ "${#unique_space_levels[@]}" -gt 0 ]; then
    if [ ! "${seen_space_levels["0"]+x}" ]; then
      unique_space_levels=("0" "${unique_space_levels[@]}")
    fi
    sorted_level_str="$(printf '%s\n' "${unique_space_levels[@]}" | sort -n | tr '\n' ' ')"
    read -r -a sorted_levels <<< "${sorted_level_str}"
    for (( level_idx = 0; level_idx < ${#sorted_levels[@]}; level_idx++ )); do
      space_to_tabs["${sorted_levels[${level_idx}]}"]="${level_idx}"
    done
  fi

  for ((line_idx = 0; line_idx < ${#block_lines[@]}; line_idx++)); do
    current_line="${block_lines[line_idx]}"

    if [[ "${current_line}" =~ ${regex_indented_line} ]]; then
      prefix="${current_line%%[^[:space:]]*}"
      if [ "${detected_mode}" = "SPACES" ] && [ "${#space_to_tabs[@]}" -gt 0 ]; then
        spaces_count=${#prefix}
        if [ "${space_to_tabs["${spaces_count}"]+x}" ]; then
          tabs_count="${space_to_tabs["${spaces_count}"]}"
        else
          tabs_count=0
        fi
        tab_prefix=""
        for ((t_idx = 0; t_idx < tabs_count; t_idx++)); do
          tab_prefix+=$'\t'
        done
        body="${current_line:${#prefix}}"
        output_buffer+="${tab_prefix}${body}"${codeNL}
      else
        output_buffer+="${current_line}"${codeNL}
      fi
    else
      output_buffer+="${current_line}"${codeNL}
    fi
  done

  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK="${output_buffer}"
}
