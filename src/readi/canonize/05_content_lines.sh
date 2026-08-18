#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY
# 
# Description:
# - A volatile global string register acting as a direct memory pass-through for
#   the prose and list item character insulation routine.
# - Eliminates performance degradation by preventing subshell forks during repetitive
#   orthographic macro normalization phases.
declare -g SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY=""



# _shell_md_readi_canonize_prose_safety — Low-level, zero-subshell string translator
# that normalizes standalone punctuation characters to prevent down-stream parsing
# collisions.
# 
# Description:
# - Sweeps the incoming text block using native parameter expansions to intercept
#   literal hyphen, plus, and asterisk characters when bounded by space wrappers.
# 
# Arguments:
# - $1: String — The raw prose string or active list description payload to be insulated.
_shell_md_readi_canonize_prose_safety() {
  local line="${1:-}"
  local indent="${line%%[![:space:]]*}"
  local rawline="${line#"${line%%[![:space:]]*}"}"

  local newline="${rawline}"
  newline="${newline// - / — }"
  newline="${newline// '+' / ＋ }"
  newline="${newline// '*' / ∗ }"

  SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY="${indent}${newline}"
}





# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES
# 
# Description:
# - A global string buffer that acts as the primary pipeline conveyor for unified,
#   canonized text streams.
# - Stores the processed document layout where raw lines of text belonging to the
#   same logical block (Paragraphs or List Items) have been systematically un-wrapped
#   and stitched into uninterrupted single physical lines.
# 
# Usage Notes:
# - This variable is highly volatile and MUST be purged to an empty string ("") immediately
#   upon function entry to guarantee a clean state isolated from previous operations.
declare -g SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=""


# shell_md_readi_canonize_content_lines — Stateful stream parser that defragments
# prose and list data into single logical lines while protecting syntactic structural
# markers and normalizing isolated list-triggering punctuation tokens.
# 
# Description:
# - Conducts a line-by-line streaming loop to resolve and reconstruct sentence flow
#   by merging fragmented, multi-line prose blocks back into single continuous strings.
# - Intercepts and shields special technical blocks (triple-backtick code layers,
#   pre-formatted 4-space blocks, raw HTML, and table structures) from any text collapsing
#   actions (Specification Sections 3.3, 4.2, 4.3 & 4.5).
# - Translates non-compliant syntax elements on-the-fly, such as normalizing prohibited
#   ordered list parenthesis suffixes (e.g., '1)') into standard dot notation ('1.')
#   (Specification Section 4.1.2).
# - Evaluates trailing whitespace markers ('^[[:space:]]{2,}$') to respect and preserve
#   native Markdown forced hard line break formatting rules.
# - Normalizes literal structural tokens ('-', '+', '*') within unified prose paragraphs
#   by programmatically converting them into non-syntactic Unicode equivalents ('—',
#   '＋', '∗') during buffer flushes, preventing downstream line-wrapping engine false
#   positives (Ref: Sec 3.1 & 4.1).
# - Flushes accumulated paragraph and list item state registers programmatically
#   whenever structural boundaries or true Empty Lines are encountered in the document
#   stream.
# 
# Arguments:
# - $1: String — The multi-line Markdown text payload requiring semantic structural
#   defragmentation and alignment cleaning.
# 
# Returns:
# - Mutates the global transit register 'SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES'
#   with the flattened, structurally predictable content layout stream.
# 
# Return Codes:
# - 0: Complete stream parsed, list/prose segments unified, and syntax states preserved.
# 
# Specification Links:
# - Ref: Section 2.1 (Physical Elements — Empty Line / Paragraph / List Item)
# - Ref: Section 3.3 (Indented Pre-formatted Text Blocks)
# - Ref: Section 4.1 (Lists & Bullet Points Architecture — Ordered/Unordered Rules)
shell_md_readi_canonize_content_lines() {
  SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=""

  local value="${1}"
  local current_line=""
  local output_buffer=""
  local in_special_block=0
  local paragraph_buffer=""
  local list_item_buffer=""
  local clean_line=""
  local line_body=""
  local cont=""
  local hard_break_marker=""
  local regex_code_block='^[[:space:]]*```'
  local regex_nbsp_meta='^([[:space:]]*&nbsp;[[:space:]]*[0-9]+/[0-9]+/[0-9]+)'
  local regex_nbsp_line='^[[:space:]]*&nbsp;[[:space:]]*$'
  local regex_separator='^[[:space:]]*([-_*][[:space:]]*){3,}$'
  local regex_unordered_list='^([[:space:]]*)([-+*])[[:space:]]+(.*)$'
  local regex_ordered_list='^([[:space:]]*)([0-9]+)([.)])[[:space:]]+(.*)$'
  local regex_hard_break='([[:space:]]{2,})$'

  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    clean_line="${current_line%"${current_line##*[![:space:]]}"}"

    if [[ "${current_line}" =~ ${regex_code_block} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      if [ "${in_special_block}" -eq 0 ]; then in_special_block=1; else in_special_block=0; fi
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [ "${in_special_block}" -eq 1 ]; then
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [[ "${current_line}" =~ ${regex_nbsp_meta} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+="${BASH_REMATCH[1]}"${codeNL}
      continue
    fi

    if [[ "${current_line}" =~ ${regex_nbsp_line} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    if [[ "${current_line}" =~ ${regex_separator} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+="---"${codeNL}
      continue
    fi

    if [ -z "${clean_line}" ]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+=${codeNL}
      continue
    fi

    if [[ "${current_line}" =~ ${regex_hard_break} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      hard_break_marker="${BASH_REMATCH[1]}"
      line_body="${current_line%"${hard_break_marker}"}"
      line_body="${line_body#"${line_body%%[![:space:]]*}"}"
      output_buffer+="${line_body}${hard_break_marker}"${codeNL}
      continue
    fi

    if [[ "${current_line}" =~ ${regex_unordered_list} ]]; then
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}
      fi
      list_item_buffer="${BASH_REMATCH[1]}- ${BASH_REMATCH[3]}"
      list_item_buffer="${list_item_buffer%"${list_item_buffer##*[![:space:]]}"}"
      continue
    fi

    if [[ "${current_line}" =~ ${regex_ordered_list} ]]; then
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}
      fi
      list_item_buffer="${BASH_REMATCH[1]}${BASH_REMATCH[2]}. ${BASH_REMATCH[4]}"
      list_item_buffer="${list_item_buffer%"${list_item_buffer##*[![:space:]]}"}"
      continue
    fi

    # List item continuation: whitespace-indented line that is not a structural element.
    # Joins the continuation into the pending list item as one logical line.
    if [ -n "${list_item_buffer}" ] && [[ "${current_line}" =~ ^[[:space:]] ]]; then
      cont="${current_line#"${current_line%%[![:space:]]*}"}"
      # Allow structural markers (blockquote, table, tag, heading) to break the context
      if [[ "${cont}" =~ ^\> ]] || [[ "${cont}" =~ ^\| ]] || [[ "${cont}" =~ ^'<' ]] || [[ "${cont}" =~ ^\# ]]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      else
        cont="${cont%"${cont##*[![:space:]]}"}"
        if [ -n "${cont}" ]; then
          list_item_buffer="${list_item_buffer%"${list_item_buffer##*[![:space:]]}"}"
          list_item_buffer+=" ${cont}"
        fi
        continue
      fi
    fi

    local regex_pipe='^[[:space:]]*\|'
    local regex_comment='^[[:space:]]*#+'
    local regex_quote='^[[:space:]]*>([[:space:]]|$)'
    local regex_tag='^[[:space:]]*</?[[:alpha:]!]'

    if [[ "${current_line}" =~ ${regex_pipe} ]] ||
       [[ "${current_line}" =~ ${regex_comment} ]] ||
       [[ "${current_line}" =~ ${regex_quote} ]] ||
       [[ "${current_line}" =~ ${regex_tag} ]]; then
      if [ -n "${list_item_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; list_item_buffer=""
      fi
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+="${clean_line}"${codeNL}
      continue
    fi

    # 4-space pre-formatted text block (§ 3.3): only outside a list item context
    if [ -z "${list_item_buffer}" ] && [ "${current_line:0:4}" = "    " ] && [ "${current_line:4:1}" != " " ] && [ "${current_line:4:1}" != $'\t' ] && [ -n "${current_line:4:1}" ]; then
      if [ -n "${paragraph_buffer}" ]; then
        _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
        output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}; paragraph_buffer=""
      fi
      output_buffer+="${current_line}"${codeNL}
      continue
    fi

    # Flush any pending list item before joining into paragraph buffer
    if [ -n "${list_item_buffer}" ]; then
      _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
      output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}
      list_item_buffer=""
    fi

    line_body="${current_line#"${current_line%%[![:space:]]*}"}"
    line_body="${line_body%"${line_body##*[![:space:]]}"}"
    if [ -z "${paragraph_buffer}" ]; then
      paragraph_buffer="${line_body}"
    else
      paragraph_buffer+=" ${line_body}"
    fi
  done <<< "${value}"

  if [ -n "${list_item_buffer}" ]; then
    _shell_md_readi_canonize_prose_safety "${list_item_buffer}"
    output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}
  fi
  if [ -n "${paragraph_buffer}" ]; then
    _shell_md_readi_canonize_prose_safety "${paragraph_buffer}"
    output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}"${codeNL}
  fi

  SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES="${output_buffer}"
}
