#!/usr/bin/env bash

# shell_md_readi_parse — Master analytical parser and state machine that compiles
# a document token matrix mapping structural elements, geometric boundaries, and
# visual mass.
# 
# Description:
# - Performs a highly deterministic, multi-state streaming evaluation of the canonized
#   Markdown payload to build an abstract syntax representation directly in memory.
# - Manages a persistent lifecycle state router ('active_state') transitioning across
#   multiple syntactic contexts: FREE, CODE_BLOCK, BLOCKQUOTE, HTML_BLOCK, TABLE,
#   and LIST.
# - Strictly implements the conservative non-destructive protocol by detecting and
#   encapsulating raw HTML structures and complex nested blocks, preserving them
#   for downstream layout safety (Specification Sections 4.4 & 4.5).
# - Populates six synchronized global indexed arrays ('SHELL_MD_READI_BLOCK_*') that
#   act as parallel matrices tracking the exact boundaries, visual block mass ('BLOCK_LINES'),
#   and spacing attributes.
# - Tracks look-behind structural history and intercepts sequential paragraph blocks
#   to flag 'SAME_PARAGRAPH' continuity, enabling precise enforcement of the contiguous
#   prose spacing rules (Specification Section 3.5.1.1.1).
# - Guarantees structural closure upon stream termination by automatically trapping
#   and flushing any pending active state registers into the final matrix index.
# 
# Arguments:
# - $1: String — The fully canonized, text-stabilized Markdown documentation stream.
# 
# Globals Populated (Parallel Matrices):
# - SHELL_MD_READI_BLOCK_TYPE      : Array[String]  — Token classification (HEADER,
#   CODE_BLOCK, etc.)
# - SHELL_MD_READI_BLOCK_START     : Array[Integer] — Physical start line index (1-based)
# - SHELL_MD_READI_BLOCK_END       : Array[Integer] — Physical end line index (1-based)
# - SHELL_MD_READI_BLOCK_LINES     : Array[Integer] — Computed visual weight density
#   in lines
# - SHELL_MD_READI_BLOCK_HAS_SEP   : Array[Integer] — Binary flag tracking adjacent
#   vertical separators
# - SHELL_MD_READI_BLOCK_LAST_RELEVANT : Array[String]  — Look-behind structural
#   context anchor
# 
# Return Codes:
# - 0: Complete stream successfully evaluated, context memory mapped, and block boundaries
#   frozen.
# 
# Specification Links:
# - Ref: Section 2.1.1 (Structure Element — Lists, Tables, Code Blocks, HTML, Blockquotes)
# - Ref: Section 2.2 (Logical Elements — Contiguous Paragraphs / Section Blocks)
# - Ref: Section 3.5.1 (Density and Spacing Weight Matrix Calculation)
# - Ref: Section 4.5 (Raw HTML Blocks Interception)
shell_md_readi_parse() {
  local canonical_content="${1:-}"
  local current_line=""
  local line_number=0
  local block_id=0
  local active_state="FREE"
  local block_start_line=0
  local current_zone_has_sep=0
  local last_relevant_structure=""
  local trimmed_line=""
  local n_count=0

  SHELL_MD_READI_BLOCK_TYPE=()
  SHELL_MD_READI_BLOCK_START=()
  SHELL_MD_READI_BLOCK_END=()
  SHELL_MD_READI_BLOCK_LINES=()
  SHELL_MD_READI_BLOCK_HAS_SEP=()
  SHELL_MD_READI_BLOCK_LAST_RELEVANT=()

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    ((line_number++))

    trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"
    trimmed_line="${trimmed_line%"${trimmed_line##*[![:space:]]}"}"

    if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK} ]]; then
      if [ "${active_state}" != "FREE" ] && [ "${active_state}" != "CODE_BLOCK" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="${active_state}"
        ((block_id++))
      fi

      if [ "${active_state}" = "CODE_BLOCK" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="CODE_BLOCK"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line + 1))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="CODE_BLOCK"
        ((block_id++))
        active_state="FREE"
      else
        active_state="CODE_BLOCK"
        block_start_line="${line_number}"
      fi
      continue
    fi

    if [ "${active_state}" = "CODE_BLOCK" ]; then
      continue
    fi

    if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_NBSP_META} ]]; then
      n_count="${BASH_REMATCH[2]}"

      if [ "${active_state}" != "FREE" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="${active_state}"
        ((block_id++))
        active_state="FREE"
      fi

      if [ "${n_count}" -gt 0 ]; then
        current_zone_has_sep=1
      fi

      SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="NBSP_BLOCK"
      SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
      SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]="${current_zone_has_sep}"
      SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
      ((block_id++))
      continue
    fi

    if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_HEADER} ]]; then
      if [ "${active_state}" != "FREE" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="${active_state}"
        ((block_id++))
        active_state="FREE"
      fi

      SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="HEADER"
      SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
      SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]="${current_zone_has_sep}"
      SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
      last_relevant_structure="HEADER"
      ((block_id++))
      current_zone_has_sep=0
      continue
    fi

    if [ -z "${trimmed_line}" ]; then
      if [ "${active_state}" != "FREE" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="${active_state}"
        ((block_id++))
        active_state="FREE"
      fi

      SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="EMPTY_LINE"
      SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
      SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
      SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
      ((block_id++))
      continue
    fi

    current_zone_has_sep=0

    if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_SEPARATOR} ]]; then
      if [ "${active_state}" != "FREE" ]; then
        SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
        SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
        SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
        SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
        SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
        last_relevant_structure="${active_state}"
        ((block_id++))
        active_state="FREE"
      fi

      SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="SEPARATOR"
      SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
      SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
      SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
      ((block_id++))
      continue
    fi

    if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE} ]]; then
      if [ "${active_state}" != "BLOCKQUOTE" ]; then
        if [ "${active_state}" != "FREE" ]; then
          SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
          SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
          SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
          SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
          SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
          SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
          last_relevant_structure="${active_state}"
          ((block_id++))
        fi
        active_state="BLOCKQUOTE"
        block_start_line="${line_number}"
      fi
      continue
    fi

    if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK} ]]; then
      if [ "${active_state}" != "HTML_BLOCK" ]; then
        if [ "${active_state}" != "FREE" ]; then
          SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
          SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
          SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
          SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
          SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
          SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
          last_relevant_structure="${active_state}"
          ((block_id++))
        fi
        active_state="HTML_BLOCK"
        block_start_line="${line_number}"
      fi
      continue
    fi

    if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_TABLE} ]]; then
      if [ "${active_state}" != "TABLE" ]; then
        if [ "${active_state}" != "FREE" ]; then
          SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
          SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
          SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
          SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
          SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
          SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
          last_relevant_structure="${active_state}"
          ((block_id++))
        fi
        active_state="TABLE"
        block_start_line="${line_number}"
      fi
      continue
    fi

    if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_LIST} ]]; then
      if [ "${active_state}" != "LIST" ]; then
        if [ "${active_state}" != "FREE" ]; then
          SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
          SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
          SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
          SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
          SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
          SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
          last_relevant_structure="${active_state}"
          ((block_id++))
        fi
        active_state="LIST"
        block_start_line="${line_number}"
      fi
      continue
    fi

    if [ "${active_state}" = "FREE" ]; then
      SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="PARAGRAPH"
      SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
      SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
      SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0

      if [ "${block_id}" -gt 0 ] && [ "${SHELL_MD_READI_BLOCK_TYPE["$((block_id - 1))"]}" = "PARAGRAPH" ]; then
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="SAME_PARAGRAPH"
      else
        SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
      fi

      last_relevant_structure="PARAGRAPH"
      ((block_id++))
    fi
  done <<< "${canonical_content}"

  if [ "${active_state}" != "FREE" ] && [ "${active_state}" != "CODE_BLOCK" ]; then
    SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
    SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
    SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
    SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line + 1))
    SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
    SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
  fi
}
