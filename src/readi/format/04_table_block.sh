#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK
# 
# Description:
# - A global string buffer acting as the official transport register for the finalized,
#   geometrically justified, and column-aligned table layout stream.
# - Stores the beautifully structured Markdown table payload where column dimensions
#   have been dynamically balanced, cell contents padded, and syntax dividers normalized.
# 
# Usage Notes:
# - Volatile execution state registry consumed directly by the main formatting loop
#   ('shell_md_readi_format'). It MUST be forcefully reset to an empty string ("")
#   upon function entry to guarantee atomic file execution.
declare -g SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK=""


# shell_md_readi_format_table_block — Two-pass structural layout matrix engine that
# computes dynamic column widths, normalizes syntax boundaries, and programmatically
# justifies data cells via precise padding distribution.
# 
# Description:
# - Implements the human-centric plain-text table rendering rules established by
#   the MD-ReadI standard, ensuring grid structures remain clean and scannable directly
#   inside standard text editors (Specification Section 4.2).
# - Drives a multi-pass token processing framework executed entirely in memory using
#   native Bash arrays:
#   1. Pass 1 (Analytical Dimensional Scan): Strips external edge pipes, tokenizes
#      cells via structural IFS='|' splitting, discovers look-ahead data widths,
#      and indexes max column limits ('col_max_lengths') along with alignment rules.
#   2. Pass 2 (Geometric Justification & Padding): Re-iterates through row arrays,
#      tracking alignment indices:
#      - Divider Rows: Generates exact-length hyphen pools ('-') embedded with parametric
#        boundary colons (Specification Sec 4.2).
#      - Data Rows: Measures cell string volumes against target column boundaries,
#        computing accurate delta offsets ('delta_spaces') to inject balanced padding
#        spaces on the fly (Left, Right, or Centered split blocks).
# - Stabilizes fallback behaviors by enforcing a universal minimum column width of
#   3 characters and default left-alignment whenever explicit typographic positioning
#   symbols are absent.
# 
# Arguments:
# - $1: String — The raw, unaligned Markdown table structure chunk intercepted by
#   the parser engine.
# 
# Returns:
# - Mutates the global transit register 'SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK'
#   with the perfectly justified, grid-aligned plain-text table element stream.
# 
# Return Codes:
# - 0: Complete table grid successfully scanned, widths computed, and padding geometries
#   frozen.
# 
# Specification Links:
# - Ref: Section 2.1.1 (Structure Element — Tables Visual Definition)
# - Ref: Section 4.2 (Tables Formatting — Dynamic Column Alignment Protocol)
shell_md_readi_format_table_block() {
  SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK=""

  local raw_table_content="${1:-}"
  local output_buffer=""
  local current_line=""
  local trimmed_line=""
  local old_ifs=""
  local clean_cell=""
  local -a cells=()
  local -a normalized_cells=()
  local -a col_max_lengths=()
  local -a col_alignments=()
  local is_divider_row=0
  local row_buffer=""
  local cell_idx=0
  local col_idx=0
  local total_cells=0
  local current_len=0
  local current_max=0
  local target_width=0
  local core_width=0
  local hyphen_pool=""
  local cell_value=""
  local cell_len=0
  local delta_spaces=0
  local padding_string=""
  local left_pad=0
  local right_pad=0
  local left_pad_str=""
  local right_pad_str=""
  local align_mode=0

  # First pass: collect max column widths and alignment modes
  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"
    trimmed_line="${trimmed_line%"${trimmed_line##*[![:space:]]}"}"
    [ -z "${trimmed_line}" ] && continue

    old_ifs="${IFS}"; IFS='|'; cells=(); read -r -a cells <<< "${trimmed_line}"; IFS="${old_ifs}"
    normalized_cells=(); total_cells="${#cells[@]}"
    for ((cell_idx = 0; cell_idx < total_cells; cell_idx++)); do
      clean_cell="${cells[${cell_idx}]}"
      clean_cell="${clean_cell#"${clean_cell%%[![:space:]]*}"}"
      clean_cell="${clean_cell%"${clean_cell##*[![:space:]]}"}"
      [ "${cell_idx}" -eq 0 ] && [ -z "${clean_cell}" ] && continue
      [ "${cell_idx}" -eq $(( total_cells - 1 )) ] && [ -z "${clean_cell}" ] && continue
      normalized_cells+=("${clean_cell}")
    done
    [ "${#normalized_cells[@]}" -eq 0 ] && continue

    is_divider_row=1
    for clean_cell in "${normalized_cells[@]}"; do
      [[ ! "${clean_cell}" =~ ^:?-+:?$ ]] && is_divider_row=0 && break
    done

    if [ "${is_divider_row}" -eq 1 ]; then
      for ((col_idx = 0; col_idx < ${#normalized_cells[@]}; col_idx++)); do
        clean_cell="${normalized_cells[${col_idx}]}"
        align_mode=0
        [[ "${clean_cell}" =~ ^:.*:$ ]] && align_mode=2
        [[ "${align_mode}" -eq 0 && "${clean_cell}" =~ :$ ]] && align_mode=1
        col_alignments[${col_idx}]="${align_mode}"
      done
    else
      for ((col_idx = 0; col_idx < ${#normalized_cells[@]}; col_idx++)); do
        current_len="${#normalized_cells[${col_idx}]}"
        current_max="${col_max_lengths[${col_idx}]:-0}"
        [ "${current_len}" -gt "${current_max}" ] && col_max_lengths[${col_idx}]="${current_len}"
      done
    fi
  done <<< "${raw_table_content}"

  # Second pass: render each row with justified padding
  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"
    trimmed_line="${trimmed_line%"${trimmed_line##*[![:space:]]}"}"
    [ -z "${trimmed_line}" ] && continue

    old_ifs="${IFS}"; IFS='|'; cells=(); read -r -a cells <<< "${trimmed_line}"; IFS="${old_ifs}"
    normalized_cells=(); total_cells="${#cells[@]}"
    for ((cell_idx = 0; cell_idx < total_cells; cell_idx++)); do
      clean_cell="${cells[${cell_idx}]}"
      clean_cell="${clean_cell#"${clean_cell%%[![:space:]]*}"}"
      clean_cell="${clean_cell%"${clean_cell##*[![:space:]]}"}"
      [ "${cell_idx}" -eq 0 ] && [ -z "${clean_cell}" ] && continue
      [ "${cell_idx}" -eq $(( total_cells - 1 )) ] && [ -z "${clean_cell}" ] && continue
      normalized_cells+=("${clean_cell}")
    done
    [ "${#normalized_cells[@]}" -eq 0 ] && continue

    is_divider_row=1
    for clean_cell in "${normalized_cells[@]}"; do
      [[ ! "${clean_cell}" =~ ^:?-+:?$ ]] && is_divider_row=0 && break
    done

    row_buffer="|"
    for ((col_idx = 0; col_idx < ${#normalized_cells[@]}; col_idx++)); do
      cell_value="${normalized_cells[${col_idx}]}"
      target_width="${col_max_lengths[${col_idx}]:-3}"
      [ "${target_width}" -lt 3 ] && target_width=3
      align_mode="${col_alignments[${col_idx}]:-0}"

      if [ "${is_divider_row}" -eq 1 ]; then
        case "${align_mode}" in
          2)
            core_width=$(( target_width - 2 ))
            [ "${core_width}" -lt 1 ] && core_width=1
            hyphen_pool="$(printf "%${core_width}s" "")"
            hyphen_pool="${hyphen_pool// /-}"
            row_buffer+=" :${hyphen_pool}: |"
            ;;
          1)
            core_width=$(( target_width - 1 ))
            [ "${core_width}" -lt 1 ] && core_width=1
            hyphen_pool="$(printf "%${core_width}s" "")"
            hyphen_pool="${hyphen_pool// /-}"
            row_buffer+=" ${hyphen_pool}: |"
            ;;
          *)
            hyphen_pool="$(printf "%${target_width}s" "")"
            hyphen_pool="${hyphen_pool// /-}"
            row_buffer+=" ${hyphen_pool} |"
            ;;
        esac
      else
        cell_len="${#cell_value}"
        delta_spaces=$(( target_width - cell_len ))
        padding_string=""
        [ "${delta_spaces}" -gt 0 ] && padding_string="$(printf "%${delta_spaces}s" "")"
        case "${align_mode}" in
          1)
            row_buffer+=" ${padding_string}${cell_value} |"
            ;;
          2)
            left_pad=$(( delta_spaces / 2 ))
            right_pad=$(( delta_spaces - left_pad ))
            left_pad_str=""; right_pad_str=""
            [ "${left_pad}" -gt 0 ]  && left_pad_str="$(printf "%${left_pad}s" "")"
            [ "${right_pad}" -gt 0 ] && right_pad_str="$(printf "%${right_pad}s" "")"
            row_buffer+=" ${left_pad_str}${cell_value}${right_pad_str} |"
            ;;
          *)
            row_buffer+=" ${cell_value}${padding_string} |"
            ;;
        esac
      fi
    done
    output_buffer+="${row_buffer}"${codeNL}
  done <<< "${raw_table_content}"

  SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK="${output_buffer}"
}
