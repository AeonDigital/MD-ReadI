#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS
# 
# Description:
# - A global string buffer acting as the official transport register for the table
#   structural normalization and cell canonization routine.
# - Stores the completely sanitized documentation stream where embedded Markdown
#   tables have had their spacing normalized, cell content trimmed, and alignment
#   markers programmatically unified.
# 
# Usage Notes:
# - This register is highly volatile and MUST be explicitly cleared to an empty string
#   at the entry threshold of 'shell_md_readi_canonize_table_cells' to avoid multi-file
#   state contamination.
declare -g SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=""


# shell_md_readi_canonize_table_cells — Architectural stream linter that parses,
# sanitizes, and normalizes alignment syntax for Markdown table structures.
# 
# Description:
# - Monitors input line blocks via stateful evaluation, ensuring that code blocks
#   remain completely insulated from table formatting engines (Specification Section
#   4.3).
# - Discovers Markdown tables by verifying structural outer pipe boundaries using
#   precise regular expressions ('^\|.*\|$').
# - Tokenizes row strings by temporarily mutating the Internal Field Separator (IFS="|")
#   to programmatically isolate, loop, and trim visual data inside individual cells.
# - Evaluates table separator rows to intercept alignment indicators (center, left,
#   right), automatically rewriting custom padding into a predictable parametric
#   syntax token.
# - Universally forces left-alignment syntax (' ----- |') as the global default standard
#   whenever explicit alignment colons are absent (Specification Section 4.2).
# 
# Arguments:
# - $1: String — The cumulative raw documentation text stream containing potential
#   embedded table data structures.
# 
# Returns:
# - Mutates the global transport register 'SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS'
#   with the structured, space-normalized table elements.
# 
# Return Codes:
# - 0: Stream successfully processed, cells trimmed, and alignment geometry normalized.
# 
# Specification Links:
# - Ref: Section 2.1.1 (Structure Element — Tables)
# - Ref: Section 4.2 (Tables Formatting)
shell_md_readi_canonize_table_cells() {
  SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=""

  local full_content="${1}"
  local current_line=""
  local output_buffer=""
  local in_code_block=0
  local clean_row=""
  local old_ifs=""
  local cells=()
  local row_buffer=""
  local cell_idx=0
  local raw_cell=""
  local clean_cell=""
  local is_divider=0
  local cell_counter=0
  local regex_code_block='^```'
  local regex_table_row='^\|.*\|$'
  local regex_table_divider='^\|([[:space:]]*:?-+:?[[:space:]]*\|)+$'
  local regex_center='^:.*:$'
  local regex_left='^:'
  local regex_right=':$'

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    clean_row="${current_line#"${current_line%%[![:space:]]*}"}"
    clean_row="${clean_row%"${clean_row##*[![:space:]]}"}"

    if [[ "${clean_row}" =~ ${regex_code_block} ]]; then
      if [ "${in_code_block}" -eq 0 ]; then
        in_code_block=1
      else
        in_code_block=0
      fi
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [ "${in_code_block}" -eq 1 ]; then
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [[ "${clean_row}" =~ ${regex_table_row} ]]; then
      old_ifs="${IFS}"
      IFS="|"
      cells=()
      read -r -a cells <<< "${clean_row}"
      IFS="${old_ifs}"

      row_buffer="|"
      is_divider=0
      if [[ "${clean_row}" =~ ${regex_table_divider} ]]; then
        is_divider=1
      fi

      for ((cell_idx = 0; cell_idx < ${#cells[@]}; cell_idx++)); do
        raw_cell="${cells[cell_idx]}"

        if [ "${cell_idx}" -eq 0 ] && [ -z "${raw_cell}" ]; then
          continue
        fi

        clean_cell="${raw_cell#"${raw_cell%%[![:space:]]*}"}"
        clean_cell="${clean_cell%"${clean_cell##*[![:space:]]}"}"

        if [ "${is_divider}" -eq 1 ]; then
          if [ -n "${clean_cell}" ] || [ "${cell_idx}" -lt $(( ${#cells[@]} - 1 )) ]; then
            if [[ "${clean_cell}" =~ ${regex_center} ]]; then
              row_buffer+=" :---: |"
            elif [[ "${clean_cell}" =~ ${regex_left} ]]; then
              row_buffer+=" :---- |"
            elif [[ "${clean_cell}" =~ ${regex_right} ]]; then
              row_buffer+=" ----: |"
            else
              row_buffer+=" ----- |"
            fi
          fi
          continue
        fi

        if [ -n "${clean_cell}" ]; then
          row_buffer+=" ${clean_cell} |"
        else
          row_buffer+="  |"
        fi
      done

      output_buffer+="${row_buffer}"${codeNL}
    else
      output_buffer+="${current_line}"${codeNL}
    fi
  done <<< "${full_content}"

  SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS="${output_buffer}"
}
