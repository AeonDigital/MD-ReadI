#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: SHELL_MD_READI_RESULT_FORMAT
# 
# Description:
# - The master output string buffer representing the finalized, formatted, and fully
#   human-readable documentation document payload.
# - Stores the definitive textual layout where horizontal margins, custom title casings,
#   nested lists, beautifully aligned tables, and dynamic vertical voids have been
#   reconstructed according to the MD-ReadI specification rules.
# 
# Usage Notes:
# - This register is the ultimate artifact produced by the pipeline. It MUST be cleared
#   to an empty string ("") upon entry to 'shell_md_readi_format' to guarantee clean,
#   stateless execution across multi-file formatting loops.
declare -g SHELL_MD_READI_RESULT_FORMAT=""


# shell_md_readi_format — Master geometric layout engine that pre-scans contextual
# block structures, resolves vertical void symmetry, and programmatically executes
# the parametric header matrix.
# 
# Description:
# - Ingests the stabilized intermediate token stream and token matrices ('SHELL_MD_READI_BLOCK_*')
#   to reconstruct a perfectly synchronized, human-centric plain-text documentation
#   canvas.
# - Executes an early architectural Pre-Scan phase to identify standalone Horizontal
#   Separators from Header Decorators, mapping their visual behaviors using associative
#   arrays ('decorator_sep' and 'header_decorated') (Specification Sections 2.3.3
#   & 4.6.1).
# - Implements the vertical layout engine to vacuum redundant empty lines and programmatically
#   evaluate block density mass, mapping the dynamic visual weight of segments (Specification
#   Section 3.5.1).
# - Enforces the strict Magnetic Alignment and Symmetry Protocol by unpacking custom
#   metadata tokens ('L/N/T') to mirror vertical voids around standalone composite
#   structures (Specification Section 3.4.3).
# - Houses the Parametric Header Matrix, routing identified heading tokens (H1 through
#   H6) into their respective geometric pipelines to inject visual decorations, dynamic
#   repetition scales, and line buffers:
#   1. Step 1-3 (Decorator Mode): Injects top visual buffers (&nbsp;) and pattern
#      overlays.
#   2. Step 4 (Payload Text Mutation): Transforms text casings strictly according
#      to the level requirements (Forcing uppercase 'UPP' for H2, lowercase 'LOW'
#      for H6, or preserving author original casing).
#   3. Step 5 (Setext Anchor): Programmatically scales the H1 trailing underline
#      length (32, 64, or 80 chars) derived dynamically from the payload string length
#      (Specification Section 5.2.5).
#   4. Step 6 (Downstream Release): Dictates an absolute structural exit margin of
#      exactly 1 Empty Line (\n).
# - Normalizes Standalone Semantic Separators by multiplying the baseline graphic
#   pattern ('SHELL_MD_READI_FMT_SEP') exactly 7 times to establish a strict 70-character
#   rhythmic divider boundary (Specification Section 4.6.2).
# - Routes Content Blocks into specialized downstream leaf handlers ('wrap_block',
#   'list_block', 'table_block'), while ensuring technical assets (CODE_BLOCK, BLOCKQUOTE,
#   HTML_BLOCK) bypass layout mutation (Specification Sec 4).
# - Dispatches visual weights, syntax context indicators, and trailing character
#   markers ('colon', 'hardbreak') to the underlying spacing processor to programmatically
#   output the precise multi-line vertical voids.
# 
# Arguments:
# - $1: String — The fully canonized, text-stabilized Markdown content requiring
#   geometric layout formatting and density wrapping.
# 
# Globals Consumed (Look-Behind Context):
# - SHELL_MD_READI_BLOCK_TYPE      : Array[String]  — Token semantic classifications.
# - SHELL_MD_READI_BLOCK_START     : Array[Integer] — Visual boundary start line
#   indexes.
# - SHELL_MD_READI_BLOCK_END       : Array[Integer] — Visual boundary termination
#   line indexes.
# - SHELL_MD_READI_BLOCK_LINES     : Array[Integer] — Computed visual weight mass
#   in lines.
# - SHELL_MD_READI_BLOCK_HAS_SEP   : Array[Integer] — Tracking indicators for vertical
#   buffers.
# 
# Globals Populated (Output Transport):
# - SHELL_MD_READI_RESULT_FORMAT   : String         — The final, perfectly wrapped,
#   formatted text document payload.
# 
# Return Codes:
# - 0: Complete document successfully processed, column widths wrapped, and spatial
#   geometry frozen.
# 
# Specification Links:
# - Ref: Section 2.3.3 (The Relevance of Horizontal Separator — Standalone vs Decorator
#   Mode)
# - Ref: Section 3.4.3 (Magnetic Alignment and Symmetry Protocol / Composite Block)
# - Ref: Section 3.5.1 (Density and Spacing Weight Matrix Criteria)
# - Ref: Section 4.6 (Horizontal Separators Normalization Behavior)
# - Ref: Section 5.1 (The Parametric Header Matrix)
# - Ref: Section 5.2 (Algorithmic Construction Pipeline — Step 1 to 6)
shell_md_readi_format() {
  SHELL_MD_READI_RESULT_FORMAT=""

  local canonical_content="${1:-}"
  local output_buffer=""
  local current_line=""
  local block_idx=0
  local total_blocks=0
  local current_type=""
  local raw_chunk=""
  local clean_chunk=""
  local header_level=0
  local header_title=""
  local dec_pattern=""
  local dec_reps=0
  local dec_line=""
  local setext_len=0
  local setext_line=""
  local density=0
  local next_type=""
  local next_level=0
  local spacing=0
  local flags=""
  local last_spacing=0
  local scan_idx=0
  local scan_type=""
  local scan_line=""
  local temp=""
  local idx=0
  local trimmed_cc=""
  local nbsp_l=0
  local nbsp_n=0
  local nbsp_t=0
  local nbsp_near_sep=0
  local nbsp_near_decorator=0
  local extra_blanks=0
  local after_separator=0
  local mirror_spacing=0
  local -A decorator_sep=()
  local -A header_decorated=()

  SHELL_MD_READI_FORMAT_LINES=()
  while IFS= read -r current_line || [ -n "${current_line}" ]; do
    SHELL_MD_READI_FORMAT_LINES+=("${current_line}")
  done <<< "${canonical_content}"

  total_blocks="${#SHELL_MD_READI_BLOCK_TYPE[@]}"

  # Pre-scan: identify decorator separators (§ 2.3.3, § 4.6.1)  
  # A SEPARATOR is a decorator when the next relevant block is a HEADER with only
  # EMPTY_LINE or NBSP_BLOCK elements between them.
  for (( block_idx = 0; block_idx < total_blocks; block_idx++ )); do
    [ "${SHELL_MD_READI_BLOCK_TYPE["${block_idx}"]}" != "SEPARATOR" ] && continue
    for (( scan_idx = block_idx + 1; scan_idx < total_blocks; scan_idx++ )); do
      scan_type="${SHELL_MD_READI_BLOCK_TYPE["${scan_idx}"]}"
      if [ "${scan_type}" = "EMPTY_LINE" ] || [ "${scan_type}" = "NBSP_BLOCK" ]; then continue; fi
      if [ "${scan_type}" = "HEADER" ]; then
        decorator_sep["${block_idx}"]=1
        header_decorated["${scan_idx}"]=1
      fi
      break
    done
  done

  # ── Main formatting loop ─────────────────────────────────────────────────
  last_spacing=0
  for (( block_idx = 0; block_idx < total_blocks; block_idx++ )); do
    current_type="${SHELL_MD_READI_BLOCK_TYPE["${block_idx}"]}"

    # Empty lines are vacuumed: spacing is fully computed from density
    if [ "${current_type}" = "EMPTY_LINE" ]; then
      continue
    fi

    # A standalone separator just output its line but deferred its mirror blanks.
    # If the current block is not &nbsp; (no bottom attraction), emit the mirror
    # now.
    if [ "${after_separator}" -eq 1 ] && [ "${current_type}" != "NBSP_BLOCK" ]; then
      for (( idx = 0; idx < mirror_spacing; idx++ )); do output_buffer+=${codeNL}; done
      last_spacing="${mirror_spacing}"
      after_separator=0
    fi

    # NBSP_BLOCK: preserve &nbsp; lines; apply magnetic attraction when adjacent
    # to a standalone SEPARATOR (§ 3.4.3 Composite Block ＋ symmetry rule).
    if [ "${current_type}" = "NBSP_BLOCK" ]; then
      raw_chunk=""
      for (( idx = SHELL_MD_READI_BLOCK_START["${block_idx}"] - 1; idx < SHELL_MD_READI_BLOCK_END["${block_idx}"]; idx++ )); do
        raw_chunk+="${SHELL_MD_READI_FORMAT_LINES[${idx}]}"${codeNL}
      done
      clean_chunk="${raw_chunk%${codeNL}}"
      nbsp_l=0; nbsp_n=0; nbsp_t=0
      if [[ "${clean_chunk}" =~ ^'&nbsp;'[[:space:]]+([0-9]+)/([0-9]+)/([0-9]+)$ ]]; then
        nbsp_l="${BASH_REMATCH[1]}"; nbsp_n="${BASH_REMATCH[2]}"; nbsp_t="${BASH_REMATCH[3]}"
      fi

      # Bottom of Composite Block: &nbsp; below the separator attaches to it with
      # no gap; mirror blanks go after this group (§ 3.4.3 symmetry rule)
      if [ "${after_separator}" -eq 1 ]; then
        for (( idx = 0; idx < nbsp_n; idx++ )); do output_buffer+="&nbsp;"${codeNL}; done
        for (( idx = 0; idx < mirror_spacing; idx++ )); do output_buffer+=${codeNL}; done
        last_spacing="${mirror_spacing}"
        after_separator=0
        continue
      fi
      # Check if next non-empty block is a standalone (non-decorator) SEPARATOR
      nbsp_near_sep=0
      nbsp_near_decorator=0
      for (( scan_idx = block_idx + 1; scan_idx < total_blocks; scan_idx++ )); do
        scan_type="${SHELL_MD_READI_BLOCK_TYPE["${scan_idx}"]}"
        if [ "${scan_type}" = "EMPTY_LINE" ] || [ "${scan_type}" = "NBSP_BLOCK" ]; then continue; fi
        if [ "${scan_type}" = "SEPARATOR" ] && [ ! "${decorator_sep["${scan_idx}"]+x}" ]; then
          nbsp_near_sep=1
        elif [ "${scan_type}" = "SEPARATOR" ] && [ "${decorator_sep["${scan_idx}"]+x}" ]; then
          nbsp_near_decorator=1
        elif [ "${scan_type}" = "HEADER" ] && [ "${header_decorated["${scan_idx}"]+x}" ]; then
          nbsp_near_decorator=1
        fi
        break
      done
      # NBSP adjacent to a decorator zone is vacuumed: the decorator generates its
      # own &nbsp; (§ 5.2 step 1)
      if [ "${nbsp_near_decorator}" -eq 1 ]; then
        continue
      fi
      # Ensure at least L blank lines above (preserve author's breathing zone)
      extra_blanks=$(( nbsp_l - last_spacing ))
      if [ "${extra_blanks}" -gt 0 ]; then
        for (( idx = 0; idx < extra_blanks; idx++ )); do output_buffer+=${codeNL}; done
        last_spacing=$(( last_spacing + extra_blanks ))
      fi
      # Output the &nbsp; lines
      for (( idx = 0; idx < nbsp_n; idx++ )); do output_buffer+="&nbsp;"${codeNL}; done
      # Trailing blanks only for standalone (separator collapses the gap via magnetic
      # attraction)
      if [ "${nbsp_near_sep}" -eq 0 ] && [ "${nbsp_t}" -gt 0 ]; then
        for (( idx = 0; idx < nbsp_t; idx++ )); do output_buffer+=${codeNL}; done
      fi
      continue
    fi

    # Decorator separators: absorbed into their associated header
    if [ "${current_type}" = "SEPARATOR" ] && [ "${decorator_sep["${block_idx}"]+x}" ]; then
      continue
    fi

    # Extract canonical lines for this block
    raw_chunk=""
    for (( idx = SHELL_MD_READI_BLOCK_START["${block_idx}"] - 1; idx < SHELL_MD_READI_BLOCK_END["${block_idx}"]; idx++ )); do
      raw_chunk+="${SHELL_MD_READI_FORMAT_LINES[${idx}]}"${codeNL}
    done
    clean_chunk="${raw_chunk%${codeNL}}"

    # Look ahead for next relevant type and level (skip vacuumed ＋ decorator seps)
    next_type=""
    next_level=0
    for (( scan_idx = block_idx + 1; scan_idx < total_blocks; scan_idx++ )); do
      scan_type="${SHELL_MD_READI_BLOCK_TYPE["${scan_idx}"]}"
      if [ "${scan_type}" = "EMPTY_LINE" ] || [ "${scan_type}" = "NBSP_BLOCK" ]; then continue; fi
      if [ "${scan_type}" = "SEPARATOR" ] && [ "${decorator_sep["${scan_idx}"]+x}" ]; then continue; fi
      next_type="${scan_type}"
      if [ "${next_type}" = "HEADER" ]; then
        scan_line="${SHELL_MD_READI_FORMAT_LINES[$((SHELL_MD_READI_BLOCK_START["${scan_idx}"] - 1))]}"
        temp="${scan_line#"${scan_line%%[![:space:]]*}"}"
        next_level=0
        while [[ "${temp}" =~ ^# ]]; do (( next_level++ )); temp="${temp#\#}"; done
      fi
      break
    done

    # ── HEADER ──────────────────────────────────────────────────────────────
    if [ "${current_type}" = "HEADER" ]; then
      temp="${clean_chunk#"${clean_chunk%%[![:space:]]*}"}"
      header_level=0
      while [[ "${temp}" =~ ^# ]]; do (( header_level++ )); temp="${temp#\#}"; done
      header_title="${temp#"${temp%%[![:space:]]*}"}"
      header_title="${header_title%"${header_title##*[![:space:]]}"}"

      if [ "${header_decorated["${block_idx}"]+x}" ]; then
        # Decorator mode: &nbsp; ＋ pattern ＋ empty line (§ 5.2)
        output_buffer+="&nbsp;"${codeNL}
        dec_pattern=""
        dec_reps=0
        case "${header_level}" in
          1) dec_pattern="${SHELL_MD_READI_FMT_H1_DEC}"; dec_reps=8 ;;
          2) dec_pattern="${SHELL_MD_READI_FMT_H2_DEC}"; dec_reps=8 ;;
          3) dec_pattern="${SHELL_MD_READI_FMT_H3_DEC}"; dec_reps=7 ;;
          4) dec_pattern="${SHELL_MD_READI_FMT_H4_DEC}"; dec_reps=6 ;;
          5) dec_pattern="${SHELL_MD_READI_FMT_H5_DEC}"; dec_reps=4 ;;
          6) dec_pattern="${SHELL_MD_READI_FMT_H6_DEC}"; dec_reps=5 ;;
        esac
        dec_line=""
        for (( idx = 0; idx < dec_reps; idx++ )); do dec_line+="${dec_pattern}"; done
        output_buffer+="${dec_line}"${codeNL}
        output_buffer+=${codeNL}
      fi

      case "${header_level}" in
        1)
          setext_len=32
          if   [ "${#header_title}" -gt 64 ]; then setext_len=80
          elif [ "${#header_title}" -gt 32 ]; then setext_len=64; fi
          setext_line="$(printf "%${setext_len}s" "")"
          setext_line="${setext_line// /=}"
          output_buffer+="${header_title}"${codeNL}
          output_buffer+="${setext_line}"${codeNL}
          ;;
        2)
          output_buffer+="## $(printf '%s' "${header_title^^}")"${codeNL}
          ;;
        6)
          output_buffer+="###### $(printf '%s' "${header_title,,}")"${codeNL}
          ;;
        *)
          temp=""
          for (( idx = 0; idx < header_level; idx++ )); do temp+="#"; done
          output_buffer+="${temp} ${header_title}"${codeNL}
          ;;
      esac

      # Downstream release: exactly 1 empty line after every header (§ 5.2.6)
      output_buffer+=${codeNL}
      last_spacing=1
      continue
    fi

    # ── SEPARATOR (standalone semantic) ─────────────────────────────────────
    if [ "${current_type}" = "SEPARATOR" ]; then
      dec_line=""
      for (( idx = 0; idx < 7; idx++ )); do dec_line+="${SHELL_MD_READI_FMT_SEP}"; done
      output_buffer+="${dec_line}"${codeNL}
      # Defer mirror blanks: if &nbsp; follows (bottom of Composite Block) they attach
      # with no gap; mirror is emitted after them.  If nothing follows, it is emitted
      # when the next non-empty, non-NBSP block is encountered (§ 3.4.3).
      mirror_spacing="${last_spacing}"
      after_separator=1
      continue
    fi

    # ── CONTENT BLOCKS ───────────────────────────────────────────────────────
    case "${current_type}" in
      PARAGRAPH)
        if [ "${clean_chunk:0:4}" = "    " ] && [ "${clean_chunk:4:1}" != " " ] && [ "${clean_chunk:4:1}" != $'\t' ] && [ -n "${clean_chunk:4:1}" ]; then
          output_buffer+="${clean_chunk}"${codeNL}
        else
          shell_md_readi_format_wrap_block "${clean_chunk}"
          output_buffer+="${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK}"
        fi
        ;;
      LIST)
        shell_md_readi_format_list_block "${raw_chunk}"
        output_buffer+="${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK}"
        ;;
      TABLE)
        shell_md_readi_format_table_block "${raw_chunk}"
        output_buffer+="${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK}"
        ;;
      CODE_BLOCK|BLOCKQUOTE|HTML_BLOCK)
        output_buffer+="${raw_chunk}"
        ;;
      *)
        output_buffer+="${raw_chunk}"
        ;;
    esac

    # ── COMPUTE AND INJECT SPACING ───────────────────────────────────────────
    density="${SHELL_MD_READI_BLOCK_LINES["${block_idx}"]}"
    flags=""
    if [ "${current_type}" = "PARAGRAPH" ]; then
      if [[ "${clean_chunk}" =~ [[:space:]]{2,}$ ]]; then
        flags="hardbreak"
      else
        trimmed_cc="${clean_chunk%"${clean_chunk##*[![:space:]]}"}"
        if [[ "${trimmed_cc}" =~ :$ ]]; then
          flags="colon"
        fi
      fi
    fi

    shell_md_readi_format_compute_spacing "${density}" "${current_type}" "${next_type}" "${next_level}" "${flags}"
    spacing="${SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING}"

    for (( idx = 0; idx < spacing; idx++ )); do output_buffer+=${codeNL}; done
    last_spacing="${spacing}"

  done

  SHELL_MD_READI_RESULT_FORMAT="${output_buffer:0: -1}"
}
