#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING
# 
# Description:
# - A volatile global integer register utilized as the official data transport path
#   for the vertical spacing calculation engine.
# - Stores the programmatically determined number of pure Empty Lines (\n) that must
#   be injected directly beneath the currently processed Relevant Element.
# 
# Usage Notes:
# - Relied upon continuously by the main formatting loop ('shell_md_readi_format').
#   It is forcefully initialized to an empty string ("") at the entry threshold of
#   the function to isolate consecutive block calculation states.
declare -g SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING=""


# shell_md_readi_format_compute_spacing — Parametric decision engine that evaluates
# visual weight densities, upstream heading hierarchy thresholds, and block exceptions
# to calculate exact vertical margins.
# 
# Description:
# - Translates the dynamic spatial rules of the MD-ReadI layout matrix into a deterministic
#   line count, balancing text dispersion and visual breathing areas (Specification
#   Section 3.5.1).
# - Evaluates document termination vectors ('next_type') and active hardbreak flags
#   to dynamically enforce an absolute 'Spacing: 0' margin on operational boundaries
#   (Specification Section 3.1 & 3.5.1.2).
# - Maps raw physical block line volume ('density') into a progressive four-tiered
#   spatial scale running from Light (1 line) up to Massive (4 lines) voids.
# - Applies Upstream Spacing rules whenever a Header follows, executing a look-ahead
#   case routing that programmatically takes the greater of the density spacing or
#   the required Header level baseline (up to H1: 5 lines).
# - Enforces strict cognitive load constraints by bounding contiguous element layouts:
#   1. Contiguous Paragraphs: Imposes a strict structural ceiling of maximum 2 lines
#      (Specification Sec 3.5.1.1.1).
#   2. Paragraph Blocks: Caps text-to-element structural transitions to a maximum
#      of 3 lines (Specification Sec 3.5.1.1.2).
#   3. Contiguous Structures: Guarantees an execution floor of minimum 2 lines between
#      tables, lists, and code logs, while preserving conservative non-intervention
#      for adjacent blockquotes (Specification Sec 3.5.1.1.3 & 4.4).
#   4. Contiguous Headers: Overrides density matrices to compress parent-child heading
#      margins to exactly 1 line (Specification Sec 3.5.1.1.4).
# - Resolves contextual grammatical syntax anchors by capturing trailing colon indicators
#   ('colon' flag) to explicitly trigger the single-line override protocol (Specification
#   Section 3.5.1.1.5).
# 
# Arguments:
# - $1: Integer (Default: 1) — The total raw/physical line count (visual weight mass)
#   of the active element.
# - $2: String (Optional) — The semantic classification token of the element currently
#   being processed.
# - $3: String (Optional) — The semantic classification token of the immediate next
#   upcoming block in the stream.
# - $4: Integer (Default: 0) — The prefix tier level (1 to 6) of the subsequent block
#   if it represents a Header.
# - $5: String (Optional) — Visual constraint override switches mapped during stream
#   evaluation ('hardbreak', 'colon').
# 
# Returns:
# - Mutates the global transit register 'SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING'
#   with the mathematically determined vertical line count string.
# 
# Return Codes:
# - 0: Spatial computation completed and localized boundaries successfully resolved.
# 
# Specification Links:
# - Ref: Section 3.1 (Hard Wrapping Constraints — Atomic Context Voids)
# - Ref: Section 3.5.1 (Density and Spacing Weight Matrix Criteria)
# - Ref: Section 3.5.1.1 (Specialized Spacing Adjustments Subroutines)
# - Ref: Section 4.4 (Blockquotes & Quoted Prose Blocks Preservation)
shell_md_readi_format_compute_spacing() {
  SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING=""

  local density="${1:-1}"
  local current_type="${2:-}"
  local next_type="${3:-}"
  local next_level="${4:-0}"
  local flags="${5:-}"
  local spacing=1
  local hmin=0
  local is_struct_curr=0
  local is_struct_next=0

  # End of document: no trailing blank lines
  if [ -z "${next_type}" ]; then
    SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="0"
    return 0
  fi

  # Hard break: continuation line, no blank line gap (§ 3.1)
  if [ "${flags}" = "hardbreak" ]; then
    SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="0"
    return 0
  fi

  # Base density table (§ 3.5.1)
  if [ "${density}" -lt 7 ]; then
    spacing=1
  elif [ "${density}" -lt 15 ]; then
    spacing=2
  elif [ "${density}" -lt 22 ]; then
    spacing=3
  else
    spacing=4
  fi

  # Upstream spacing minimum for following header; take the greater (§ 3.5.1)
  if [ "${next_type}" = "HEADER" ]; then
    case "${next_level}" in
      1) hmin=5 ;;
      2) hmin=4 ;;
      3) hmin=3 ;;
      *) hmin=2 ;;
    esac
    if [ "${hmin}" -gt "${spacing}" ]; then spacing="${hmin}"; fi
  fi

  # Contiguous paragraphs: cap at 2 (§ 3.5.1.1.1)
  if [ "${current_type}" = "PARAGRAPH" ] && [ "${next_type}" = "PARAGRAPH" ]; then
    if [ "${spacing}" -gt 2 ]; then spacing=2; fi
  fi

  # Paragraph block followed by different element: cap at 3 (§ 3.5.1.1.2)
  if [ "${current_type}" = "PARAGRAPH" ] && [ "${next_type}" != "PARAGRAPH" ] && [ "${next_type}" != "HEADER" ]; then
    if [ "${spacing}" -gt 3 ]; then spacing=3; fi
  fi

  # Contiguous structural elements: floor at 2 (§ 3.5.1.1.3)  
  # Exception: blockquote-to-blockquote follows density only (conservative § 4.4)
  case "${current_type}" in LIST|TABLE|CODE_BLOCK|BLOCKQUOTE|HTML_BLOCK) is_struct_curr=1 ;; esac
  case "${next_type}" in LIST|TABLE|CODE_BLOCK|BLOCKQUOTE|HTML_BLOCK) is_struct_next=1 ;; esac
  if [ "${is_struct_curr}" -eq 1 ] && [ "${is_struct_next}" -eq 1 ]; then
    if [ "${current_type}" != "BLOCKQUOTE" ] || [ "${next_type}" != "BLOCKQUOTE" ]; then
      if [ "${spacing}" -lt 2 ]; then spacing=2; fi
    fi
  fi

  # Contiguous headers (parent→child or peer): exactly 1 (§ 3.5.1.1.4)
  if [ "${current_type}" = "HEADER" ] && [ "${next_type}" = "HEADER" ]; then
    spacing=1
  fi

  # Colon exception: exactly 1 (§ 3.5.1.1.5)
  if [ "${flags}" = "colon" ]; then
    spacing=1
  fi

  SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="${spacing}"
}
