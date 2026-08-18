#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK
# 
# Description:
# - A global string buffer serving as the official output register for the hard column
#   wrapping and layout indentation engine.
# - Stores the programmatically reconstructed, multi-line paragraph or list payload
#   where sentences have been bound to the strict 80-120 character width limits.
# 
# Usage Notes:
# - Volatile pipeline registry consumed continuously by text content and list processing
#   blocks. It MUST be forcefully cleared to an empty string ("") at the function
#   entry threshold to prevent layout artifacts from bleeding across consecutive
#   text wrapper actions.
declare -g SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""


# shell_md_readi_format_wrap_block — Deterministic line wrapper that enforces strict
# 80-120 column geometry, handles dual-state block indentation, and insulates atomic
# tokens from text splitting.
# 
# Description:
# - Implements the core horizontal layout canvas algorithm of the MD-ReadI specification,
#   transforming flattened single-line prose fragments into beautifully structured
#   plain-text paragraphs (Specification Section 3.1).
# - Isolates native Markdown forced hard line break formatting elements ('hard_break_suffix')
#   from the content stream, tracking and programmatically injecting them exclusively
#   into the absolute terminating row of the block.
# - Manages a dual-state indentation depth engine via prefix parameters ('pfx_first'
#   and 'pfx_rest'), allowing multi-line list elements or descriptions to inherit
#   precise hanging indent alignments (Specification Section 3.2).
# - Drives a string processing look-ahead window between column indexes 80 and 120
#   (accounting for leading indent space) to discover optimal white-space boundary
#   points, avoiding ugly word hyphenation or fragmentation.
# - Enforces a defensive non-destructive exception rule targeting unbroken atomic
#   tokens (such as raw URLs, long file paths, or cryptographic hashes), ensuring
#   they occupy their own dedicated line unsplit (Specification Section 3.1.4).
# - Strips leading white spaces iteratively from subsequent text fragments and applies
#   a strict 120-character hard column wall as an absolute fallback layout boundary
#   whenever white-space thresholds are exceeded.
# 
# Arguments:
# - $1: String — The continuous raw text payload or prose paragraph to be programmatically
#   wrapped.
# - $2: String (Optional) — The explicit indentation prefix to be applied solely
#   to the first output row.
# - $3: String (Optional) — The hanging indentation prefix applied to all subsequent
#   wrapped rows. Defaults to $2.
# 
# Returns:
# - Mutates the global transport register 'SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK'
#   with the geometrically wrapped and space-padded multi-line string layout.
# 
# Return Codes:
# - 0: Block text successfully parsed, column bounds enforced, and visual parameters
#   frozen.
# 
# Specification Links:
# - Ref: Section 3.1 (Hard Wrapping Constraints — Comfort Window / Atomic Tokens
#   Rules)
# - Ref: Section 3.2 (Contextual Indentation Standard — Hanging Lines Alignment)
shell_md_readi_format_wrap_block() {
  SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""

  local text="${1:-}"
  local pfx_first="${2:-}"
  local pfx_rest="${3:-${pfx_first}}"
  local output=""
  local rest=""
  local hard_break_suffix=""
  local is_first=1
  local pfx=""
  local pfx_len=0
  local available=0
  local break_pos=0
  local seg=""
  local i=0

  # Separate hard break marker from content so it lands on the last output line
  if [[ "${text}" =~ ([[:space:]]{2,})$ ]]; then
    hard_break_suffix="${BASH_REMATCH[1]}"
    rest="${text%"${hard_break_suffix}"}"
  else
    rest="${text}"
  fi

  while [ -n "${rest}" ]; do
    if [ "${is_first}" -eq 1 ]; then pfx="${pfx_first}"; else pfx="${pfx_rest}"; fi
    pfx_len=${#pfx}

    if [ $(( ${#rest} + pfx_len )) -le 80 ]; then
      output+="${pfx}${rest}${hard_break_suffix}"${codeNL}
      hard_break_suffix=""
      break
    fi

    available=$(( 80 - pfx_len ))
    if [ "${available}" -lt 1 ]; then available=1; fi

    break_pos=-1
    for (( i = available; i < $(( 120 - pfx_len )); i++ )); do
      if [ "${i}" -ge "${#rest}" ]; then break; fi
      if [ "${rest:${i}:1}" = " " ]; then break_pos="${i}"; break; fi
    done

    if [ "${break_pos}" -lt 0 ]; then
      # No whitespace in the 80-120 window. If the entire rest has no spaces, it
      # is an atomic token (URL, path, hash) and must stay on its own line unsplit
      # (§ 3.1).
      if [[ ! "${rest}" =~ [[:space:]] ]]; then
        output+="${pfx}${rest}${hard_break_suffix}"${codeNL}
        hard_break_suffix=""
        break
      fi
      # Otherwise apply the 120-char hard limit
      break_pos=$(( 120 - pfx_len ))
      if [ "${break_pos}" -gt "${#rest}" ]; then break_pos="${#rest}"; fi
    fi

    seg="${rest:0:${break_pos}}"
    rest="${rest:${break_pos}}"
    rest="${rest#"${rest%%[![:space:]]*}"}"

    # Attach hard break marker to the very last segment
    if [ -z "${rest}" ] && [ -n "${hard_break_suffix}" ]; then
      output+="${pfx}${seg}${hard_break_suffix}"${codeNL}
      hard_break_suffix=""
    else
      output+="${pfx}${seg}"${codeNL}
    fi
    is_first=0
  done

  # Guard: empty text with only a hard break marker
  if [ -n "${hard_break_suffix}" ]; then
    output+="${pfx_first}${hard_break_suffix}"${codeNL}
  fi

  SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK="${output}"
}
