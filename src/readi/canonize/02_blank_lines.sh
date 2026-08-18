#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES
# 
# Description:
# - A global string buffer acting as the official transport register for the vertical
#   void and density normalization phase.
# - Stores the intermediate documentation stream where cumulative erratic whitespace
#   sequences and raw '&nbsp;' tags are compressed and injected with structured density
#   tracking metadata tokens, enabling precise downstream architectural layout alignment.
# 
# Usage Notes:
# - Volatile execution state register. It MUST be forcefully cleared to an empty
#   string ("") upon entry to 'shell_md_readi_blank_lines' to guarantee total memory
#   isolation and prevent cross-file layout pollution.
declare -g SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=""


# shell_md_readi_canonize_blank_lines — Stateful layout parser that compresses multi-line
# vertical voids and encodes spatial breathing density into structured metadata tokens.
# 
# Description:
# - Ingests the unified document text stream into an indexed local array ('doc_lines')
#   to perform complex look-ahead and tracking routines without relying on destructive
#   subshell filters.
# - Strictly respects the non-intervention protocol by shielding code block segments
#   from vertical void normalization or spacing metadata injection (Specification
#   Section 4.3).
# - Intercepts sequential stacks of Non-Relevant Elements (Empty Lines and Vertical
#   Separators) to execute a three-phase state lookup pipeline ('LEADING' -> 'NBSP'
#   -> 'TRAILING').
# - Tallies visual weight and programmatically caps excess whitespace gaps to a structural
#   maximum baseline of 3 lines, mitigating chaos and cognitive fatigue (Specification
#   Section 3.4 & 3.5).
# - Translates raw multi-line spatial voids into a single, highly deterministic meta
#   token string ('&nbsp; L/N/T') to enable downstream formatters to apply precise
#   symmetry algorithms.
# 
# Arguments:
# - $1: String — The multi-line Markdown text stream requiring structural vertical
#   spacing canonization and density encoding.
# 
# Returns:
# - Mutates the global transit register 'SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES'
#   with the space-compressed and meta-tagged document stream layout.
# 
# Return Codes:
# - 0: Stream successfully analyzed, empty voids compressed, and spatial density
#   meta tokens injected.
# 
# Specification Links:
# - Ref: Section 2.3.1 (Non-Relevant Element — Empty Line / Vertical Separator)
# - Ref: Section 3.4 (Vertical Separator Blocks — Usage / Isolation / Symmetry Protocol)
# - Ref: Section 3.5.1 (Density and Spacing Weight Matrix)
shell_md_readi_canonize_blank_lines() {
  SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=""

  local raw_content="${1}"
  local current_line=""
  local output_buffer=""
  local in_code_block=0
  local doc_lines=()
  local total_lines=0
  local l_idx=0
  local clean_row=""
  local leading_blanks=0
  local nbsp_count=0
  local trailing_blanks=0
  local scan_idx=0
  local phase=""
  local peek_line=""
  local clean_peek=""
  local regex_code_block='^```'

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    doc_lines+=("${current_line}")
  done <<< "${raw_content}"

  total_lines=${#doc_lines[@]}

  for ((l_idx = 0; l_idx < total_lines; l_idx++)); do
    current_line="${doc_lines[l_idx]}"
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

    if [ -z "${clean_row}" ] || [ "${clean_row}" = "&nbsp;" ]; then
      leading_blanks=0
      nbsp_count=0
      trailing_blanks=0
      scan_idx="${l_idx}"
      phase="LEADING"

      while [ "${scan_idx}" -lt "${total_lines}" ]; do
        peek_line="${doc_lines[scan_idx]}"
        clean_peek="${peek_line#"${peek_line%%[![:space:]]*}"}"
        clean_peek="${clean_peek%"${clean_peek##*[![:space:]]}"}"

        if [ -n "${clean_peek}" ] && [ "${clean_peek}" != "&nbsp;" ] && [[ ! "${clean_peek}" =~ ${regex_code_block} ]]; then
          break
        fi

        if [[ "${clean_peek}" =~ ${regex_code_block} ]]; then
          break
        fi

        if [ -z "${clean_peek}" ]; then
          if [ "${phase}" = "LEADING" ]; then
            ((leading_blanks++))
          elif [ "${phase}" = "NBSP" ]; then
            phase="TRAILING"
            ((trailing_blanks++))
          else
            ((trailing_blanks++))
          fi
        elif [ "${clean_peek}" = "&nbsp;" ]; then
          if [ "${phase}" = "LEADING" ] || [ "${phase}" = "NBSP" ] || [ "${phase}" = "TRAILING" ]; then
            phase="NBSP"
            ((nbsp_count++))
          fi
        fi

        ((scan_idx++))
      done

      l_idx=$((scan_idx - 1))

      if [ "${nbsp_count}" -gt 0 ]; then
        [ "${leading_blanks}" -gt 3 ] && leading_blanks=3
        [ "${trailing_blanks}" -gt 3 ] && trailing_blanks=3
        output_buffer+="&nbsp; ${leading_blanks}/${nbsp_count}/${trailing_blanks}"${codeNL}
      else
        output_buffer+=${codeNL}
      fi
      continue
    fi

    output_buffer+="${current_line}"${codeNL}
  done

  SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES="${output_buffer}"
}
