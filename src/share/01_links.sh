#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_LINK_SPANS
# 
# Description:
# - An indexed array acting as the transport register for the inline link detection
#   routine ('shell_md_readi_link_spans').
# - Each entry follows the format 'START:END' where START is the zero-based index
#   of the opening '[' and END is the exclusive index right after the closing ')'
#   of an inline Markdown link ('[label](destination)').
# 
# Usage Notes:
# - Volatile register. It is reset to an empty array upon every call to 'shell_md_readi_link_spans'.
declare -ga SHELL_MD_READI_LINK_SPANS=()


# shell_md_readi_link_spans — Zero-subshell scanner that locates every inline Markdown
# link ('[label](destination)') inside a single line of text.
# 
# Description:
# - Balances nested brackets in the label and nested parentheses in the destination,
#   so names such as '[A [b]](file (1).md)' are captured as a single link.
# - Honors backslash escapes ('\[', '\]', '\(', '\)').
# - Image links ('![alt](src)') are detected through their '[alt](src)' portion.
# - Links are treated as atomic by the prose safety and wrapping engines (Specification
#   Sections 1.3 and 3.1).
# 
# Arguments:
# - $1: String — The single line of text to be scanned.
# 
# Returns:
# - Mutates the global register 'SHELL_MD_READI_LINK_SPANS'.
# 
# Return Codes:
# - 0: Always.
shell_md_readi_link_spans() {
  SHELL_MD_READI_LINK_SPANS=()

  local text="${1:-}"
  local len="${#text}"
  local i=0
  local j=0
  local start=0
  local depth=0
  local ch=""

  while [ "${i}" -lt "${len}" ]; do
    ch="${text:${i}:1}"
    if [ "${ch}" = "\\" ]; then i=$(( i + 2 )); continue; fi
    if [ "${ch}" != "[" ]; then i=$(( i + 1 )); continue; fi

    start="${i}"
    depth=0
    j="${i}"
    while [ "${j}" -lt "${len}" ]; do
      ch="${text:${j}:1}"
      if [ "${ch}" = "\\" ]; then j=$(( j + 2 )); continue; fi
      if [ "${ch}" = "[" ]; then
        depth=$(( depth + 1 ))
      elif [ "${ch}" = "]" ]; then
        depth=$(( depth - 1 ))
        [ "${depth}" -eq 0 ] && break
      fi
      j=$(( j + 1 ))
    done

    if [ "${j}" -ge "${len}" ] || [ "${text:$(( j + 1 )):1}" != "(" ]; then
      i=$(( start + 1 ))
      continue
    fi

    j=$(( j + 1 ))
    depth=0
    while [ "${j}" -lt "${len}" ]; do
      ch="${text:${j}:1}"
      if [ "${ch}" = "\\" ]; then j=$(( j + 2 )); continue; fi
      if [ "${ch}" = "(" ]; then
        depth=$(( depth + 1 ))
      elif [ "${ch}" = ")" ]; then
        depth=$(( depth - 1 ))
        [ "${depth}" -eq 0 ] && break
      fi
      j=$(( j + 1 ))
    done

    if [ "${j}" -ge "${len}" ]; then
      i=$(( start + 1 ))
      continue
    fi

    SHELL_MD_READI_LINK_SPANS+=("${start}:$(( j + 1 ))")
    i=$(( j + 1 ))
  done

  return 0
}


# shell_md_readi_link_span_contains — Checks whether a character index lies inside
# any span currently stored in 'SHELL_MD_READI_LINK_SPANS'.
# 
# Arguments:
# - $1: Integer — The zero-based character index to test.
# 
# Return Codes:
# - 0: The index belongs to a link.
# - 1: The index is outside every link.
shell_md_readi_link_span_contains() {
  local idx="${1:-0}"
  local span=""

  for span in "${SHELL_MD_READI_LINK_SPANS[@]}"; do
    if [ "${idx}" -ge "${span%%:*}" ] && [ "${idx}" -lt "${span##*:}" ]; then
      return 0
    fi
  done
  return 1
}
