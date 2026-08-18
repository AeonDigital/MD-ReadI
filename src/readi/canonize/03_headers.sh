#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_HEADERS
# 
# Description:
# - A global string buffer acting as the official transport register for the Header
#   syntax conversion and canonization phase.
# - Stores the unified document payload where all historical Setext-style headers
#   (underlined with '=' or '-') have been programmatically normalized into explicit
#   ATX-style prefixed headers (# or ##), establishing syntax stability for downstream
#   parsers.
# 
# Usage Notes:
# - Highly volatile state register. It MUST be explicitly purged to an empty string
#   ("") at the entry threshold of 'shell_md_readi_canonize_headers' to safeguard
#   against stale memory leakage across consecutive formatting executions.
declare -g SHELL_MD_READI_RESULT_CANONIZE_HEADERS=""


# shell_md_readi_canonize_headers — Multi-line context parser that converts Setext
# headings into uniform ATX notation while distinguishing standalone horizontal separators.
# 
# Description:
# - Performs a look-ahead streaming evaluation utilizing look-behind state buffers
#   ('pending_text_line' and 'pending_separator_line') to resolve structural ambiguities
#   in text.
# - Leverages strict block status monitoring ('in_code_block') to keep technical
#   code samples fully insulated from syntax rewriting actions (Specification Section
#   4.3).
# - Detects underline dynamic rows ('^=+$' and '^-+$') and cross-references them
#   against pending prose text to convert implicit headers into deterministic H1
#   ('# ') and H2 ('## ') formats.
# - Distinguishes between sublined text structures and true standalone semantic Horizontal
#   Separators, normalizing the latter to a standard '---' token sequence (Specification
#   Section 4.6).
# - Flushes and stitches accumulated look-behind buffers programmatically when encountering
#   structural boundaries, native ATX prefixes ('#'), or true Empty Lines in the
#   stream.
# 
# Arguments:
# - $1: String — The cumulative raw technical documentation text stream requiring
#   header syntax normalization.
# 
# Returns:
# - Mutates the global transport register 'SHELL_MD_READI_RESULT_CANONIZE_HEADERS'
#   with the unified ATX-prefixed heading stream.
# 
# Return Codes:
# - 0: Complete stream evaluated, headings successfully converted, and separation
#   contexts resolved.
# 
# Specification Links:
# - Ref: Section 2.1 (Canonical Element Glossary — Headers / Horizontal Separator)
# - Ref: Section 4.6 (Horizontal Separators)
# - Ref: Section 5.1 (The Parametric Header Matrix)
shell_md_readi_canonize_headers() {
  SHELL_MD_READI_RESULT_CANONIZE_HEADERS=""

  local raw_content="${1}"
  local current_line=""
  local output_buffer=""
  local in_code_block=0
  local pending_text_line=""
  local pending_separator_line=""
  local clean_line=""
  local separator_regex='^[[:space:]]*([-_*][[:space:]]*){3,}$'
  local regex_code_block='^```'
  local regex_h1='^=+$'
  local regex_h2='^-+$'
  local regex_header='^#+'

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    clean_line="${current_line#"${current_line%%[![:space:]]*}"}"
    clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"

    if [[ "${clean_line}" =~ ${regex_code_block} ]]; then
      if [ "${in_code_block}" -eq 0 ]; then
        in_code_block=1
      else
        in_code_block=0
      fi
      [ -n "${pending_separator_line}" ] && { output_buffer+="${pending_separator_line}"${codeNL}; pending_separator_line=""; }
      [ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [ "${in_code_block}" -eq 1 ]; then
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [ -z "${clean_line}" ]; then
      if [ -n "${pending_separator_line}" ]; then
        output_buffer+="${pending_separator_line}"${codeNL}
        pending_separator_line=""
      fi
      [ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
      output_buffer+=${codeNL}
      continue
    fi

    if [[ "${clean_line}" =~ ${separator_regex} ]]; then
      [ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
      [ -n "${pending_separator_line}" ] && { output_buffer+="${pending_separator_line}"${codeNL}; }
      pending_separator_line="---"
      continue
    fi

    if [[ "${clean_line}" =~ ${regex_h1} ]] && [ -n "${pending_text_line}" ]; then
      pending_separator_line=""
      output_buffer+="# ${pending_text_line#"${pending_text_line%%[![:space:]]*}"}"${codeNL}
      pending_text_line=""
      continue
    fi

    if [[ "${clean_line}" =~ ${regex_h2} ]] && [ -n "${pending_text_line}" ]; then
      pending_separator_line=""
      output_buffer+="## ${pending_text_line#"${pending_text_line%%[![:space:]]*}"}"${codeNL}
      pending_text_line=""
      continue
    fi

    if [[ "${clean_line}" =~ ${regex_header} ]]; then
      pending_separator_line=""
      [ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [ -n "${pending_separator_line}" ]; then
      output_buffer+="${pending_separator_line}"${codeNL}
      pending_separator_line=""
    fi

    if [ -n "${pending_text_line}" ]; then
      output_buffer+="${pending_text_line}"${codeNL}
    fi

    pending_text_line="${current_line}"
  done <<< "${raw_content}"

  if [ -n "${pending_separator_line}" ]; then
    output_buffer+="${pending_separator_line}"${codeNL}
  fi
  if [ -n "${pending_text_line}" ]; then
    output_buffer+="${pending_text_line}"${codeNL}
  fi

  SHELL_MD_READI_RESULT_CANONIZE_HEADERS="${output_buffer}"
}
