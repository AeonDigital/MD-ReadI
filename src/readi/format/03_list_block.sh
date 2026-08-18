#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK
# 
# Description:
# - A global string buffer dedicated as the master transport registry for the finalized,
#   geometrically formatted list structure pipeline.
# - Stores the unified multi-tier list block where bullets have been cycled, indentation
#   alignments fixed, and vertical spacing uniformly propagated based on content
#   density.
# 
# Usage Notes:
# - Volatile execution state registry consumed directly by the main layout loop ('shell_md_readi_format').
#   It MUST be explicitly cleared to an empty string ("") upon function entry to
#   guarantee stateless execution across consecutive list block Normalization workflows.
declare -g SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=""


# shell_md_readi_format_list_block — Stateful three-pass execution engine that unifies
# unordered token cascades, calculates hanging line indentations, and enforces the
# cascading list propagation protocol.
# 
# Description:
# - Interprets tab characters (\t) from the canonized text stream to determine explicit
#   nested hierarchies, translating them into uniform soft-space alignments (Specification
#   Section 3.2).
# - Executes a multi-pass analytical routine entirely in memory to format lists through
#   separate computational phases:
#   1. Pass 1 (Token Cascade & Wrap): Triggers a cyclic 3-token rotating sequence
#      (-, +, *) based on nesting depth indexes and programmatically normalizes ordered
#      lists to dot notation. Computes exact physical line counts using native string
#      modifications (Specification Section 4.1.1 & 4.1.2).
#   2. Pass 2 (Contamination Lookup): Scans compiled line weights per depth layer.
#      If a single item matches a Medium or Heavy weight classification (>= 4 lines),
#      it marks the depth flag (Specification Section 3.5.1.2.1).
#   3. Pass 3 (Homogenous Spacing Emission): Reconstructs the list layout, enforcing
#      vertical scaling rules. Whenever a depth tier is flagged as contaminated,
#      the default 'Spacing: 0' for light elements is overridden to apply a uniform
#      1-line breathing void, preserving continuous sequence proximity.
# - Integrates precise boundary logic to manage parent-child indent transitions and
#   dynamic returns from nested sub-list contexts back to higher-level elements (Specification
#   Section 3.5.1.2.2).
# 
# Arguments:
# - $1: String — The raw, tab-prefixed list content chunk captured by the analytical
#   parser loop.
# 
# Returns:
# - Mutates the global transit register 'SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK'
#   with the geometrically aligned, cascading space-normalized list structure.
# 
# Return Codes:
# - 0: Complete list sequence successfully parsed, tokens cycled, and propagation
#   protocols applied.
# 
# Specification Links:
# - Ref: Section 3.2 (Contextual Indentation Standard — Hanging Descriptions Depth)
# - Ref: Section 3.5.1.2 (Spacing Adjustments for List Items and Nested Lists Matrix)
# - Ref: Section 3.5.1.2.1 (The List Propagation Protocol Matrix)
# - Ref: Section 4.1 (Lists & Bullet Points Architecture — Cyclic Token Cascade)
shell_md_readi_format_list_block() {
  SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=""

  local raw_content="${1:-}"
  local output=""
  local current_line=""
  local tabs=""
  local depth=0
  local body=""
  local tok=""
  local tok_idx=0
  local indent=""
  local pfx_first=""
  local pfx_rest=""
  local item_text=""
  local num=""
  local num_width=0
  local wrapped=""
  local newlines_str=""
  local line_count=0
  local total_items=0
  local i=0
  local j=0
  local prev_depth=0
  local curr_depth=0
  local prev_lines=0
  local spacing_lines=0
  local -a list_tokens=("-" "+" "*")
  local -a item_depths=()
  local -a item_texts=()
  local -a item_lines=()
  local -A contaminated_at_depth=()

  # ── Pass 1: format each item and measure its formatted line count ─────────
  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    [ -z "${current_line}" ] && continue

    tabs="${current_line%%[^$'\t']*}"
    depth="${#tabs}"
    body="${current_line:${depth}}"

    if [[ "${body}" =~ ^([0-9]+)\.[[:space:]]+(.*)$ ]]; then
      num="${BASH_REMATCH[1]}"
      item_text="${BASH_REMATCH[2]}"
      indent="$(printf "%$(( depth * 2 ))s" "")"
      num_width=$(( ${#num} + 2 ))
      pfx_first="${indent}${num}. "
      pfx_rest="$(printf "%$(( depth * 2 + num_width ))s" "")"
    elif [[ "${body}" =~ ^-[[:space:]]+(.*)$ ]]; then
      tok_idx=$(( depth % 3 ))
      tok="${list_tokens[${tok_idx}]}"
      item_text="${BASH_REMATCH[1]}"
      indent="$(printf "%$(( depth * 2 ))s" "")"
      pfx_first="${indent}${tok} "
      pfx_rest="$(printf "%$(( depth * 2 + 2 ))s" "")"
    else
      continue
    fi

    shell_md_readi_format_wrap_block "${item_text}" "${pfx_first}" "${pfx_rest}"
    wrapped="${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK:0: -1}"
    if [ -n "${wrapped}" ]; then
      newlines_str="${wrapped//[^$'\n']/}"
      line_count=$(( ${#newlines_str} + 1 ))
    else
      line_count=1
    fi

    item_depths+=("${depth}")
    item_texts+=("${wrapped}")
    item_lines+=("${line_count}")
    (( total_items++ ))
  done <<< "${raw_content}"

  if [ "${total_items}" -eq 0 ]; then
    SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK="${output}"
    return "0"
  fi

  # ── Pass 2: detect propagation per depth (global per depth, § 3.5.1.2.1)
  for (( i = 0; i < total_items; i++ )); do
    depth="${item_depths[${i}]}"
    line_count="${item_lines[${i}]}"
    if [ "${line_count}" -ge 4 ]; then
      contaminated_at_depth["${depth}"]=1
    fi
  done

  # ── Pass 3: emit items with density-based spacing and propagation floor ──
  output+="${item_texts[0]}"${codeNL}
  prev_depth="${item_depths[0]}"

  for (( i = 1; i < total_items; i++ )); do
    curr_depth="${item_depths[${i}]}"
    prev_lines="${item_lines[$((i - 1))]}"

    if [ "${curr_depth}" -gt "${prev_depth}" ]; then
      # Parent → child: specific parent item density, capped at 1 (§ 3.5.1.2.2)
      if [ "${prev_lines}" -ge 4 ]; then spacing_lines=1; else spacing_lines=0; fi

    elif [ "${curr_depth}" -eq "${prev_depth}" ]; then
      # Same depth: full density table ＋ propagation floor
      if   [ "${prev_lines}" -ge 7 ]; then spacing_lines=2
      elif [ "${prev_lines}" -ge 4 ]; then spacing_lines=1
      else spacing_lines=0; fi
      if [ "${contaminated_at_depth["${curr_depth}"]+x}" ] && [ "${spacing_lines}" -lt 1 ]; then
        spacing_lines=1
      fi

    else
      # Child → parent: max propagation from both levels (§ 3.5.1.2.2)
      spacing_lines=0
      if [ "${contaminated_at_depth["${curr_depth}"]+x}" ] || [ "${contaminated_at_depth["${prev_depth}"]+x}" ]; then
        spacing_lines=1
      fi
    fi

    for (( j = 0; j < spacing_lines; j++ )); do output+=${codeNL}; done
    output+="${item_texts[${i}]}"${codeNL}
    prev_depth="${curr_depth}"
  done

  SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK="${output}"
}
