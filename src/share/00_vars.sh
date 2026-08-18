#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: codeNL
# 
# Description:
# - A read-only, global string containing the native newline character control byte
#   (\n).
# - Serves as the localized layout conveyor sequence to append deterministic line
#   breaks across all buffer concatenation routines without spawning subshell hooks.
# 
# Usage Notes:
# - Enclosed in a state check guard to safely default to a physical newline token
#   if not predefined by the parent pipeline environment.
if [ -z "${codeNL+x}" ]; then
  declare -gr codeNL=$'\n'
fi





# =============================================================================
# PARSER ENGINE STRUCTURAL REGEX SWITCHES  
# [Ref: SPECS Section 2.1 & 4]
# =============================================================================

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK Description: Read-only
#                    regex targeting the initialization/termination wall of a code
#                    block segment. Enforces strict non-intervention for advanced
#                    technical assets (Ref: Sec 4.3).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK='^```'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_NBSP_META Description: Read-only
#                    regex intercepting the custom vertical void density metadata
#                    tags (L/N/T). Captures space-compression tallies to evaluate
#                    downstream reflection layout logic (Ref: Sec 3.4.3).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_NBSP_META+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_NBSP_META='^&nbsp;[[:space:]]+([0-9]+)/([0-9]+)/([0-9]+)'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_HEADER Description: Read-only regex
#                    discovering ATX-style header prefixes to route hierarchy states.
#                    Anchors the beginning of a logical document Section (Ref: Sec
#                    2.1 & 5).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_HEADER+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_HEADER='^#'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_TABLE Description: Read-only regex
#                    locating external pipe walls to intercept embedded table architectures.
#                    Identifies multidimensional structural blocks for dimensional
#                    calculations (Ref: Sec 2.1.1 & 4.2).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_TABLE+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_TABLE='^[[:space:]]*\|'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_LIST Description: Read-only regex
#                    filtering classic unordered bullets (- or *) or numerical dot
#                    counters (1.). Discovers structural row hooks to initiate nesting
#                    evaluation subroutines (Ref: Sec 4.1).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_LIST+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_LIST='^[-*][[:space:]]+|^[0-9]+\.[[:space:]]+'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_SEPARATOR Description: Read-only
#                    regex validating horizontal dashes or stars used as structural
#                    cognitive breaks. Feeds the context engine to evaluate standalone
#                    vs decorator separator flags (Ref: Sec 2.3.3 & 4.6).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_SEPARATOR+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_SEPARATOR='^[[:space:]]*([-_*][[:space:]]*){3,}$'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE Description: Read-only
#                    regex isolating quotation tokens (>) to track text layer boundaries.
#                    Ensures the quote payload remains fully insulated from destructive
#                    rewriting loops (Ref: Sec 4.4).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE='^[[:space:]]*>+[[:space:]]*.*$'
fi

# _GLOBAL_VARIABLE_: SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK Description: Read-only
#                    regex identifying inline tags or block level raw HTML elements.
#                    Safeguards non-markdown embedded segments under the conservative
#                    preservation rule (Ref: Sec 4.5).
if [ -z "${SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK+x}" ]; then
  declare -gr SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK='^[[:space:]]*</?[[:alpha:]!][^>]*>.*$'
fi





# =============================================================================
# GEOMETRIC FORMATTING TEMPLATES AND PIPELINE VOLATILES  
# [Ref: SPECS Section 5]
# =============================================================================

# _GLOBAL_VARIABLE_: SHELL_MD_READI_FORMAT_LINES
# 
# Description:
# - A global indexed array acting as a temporary in-memory snapshot of the active
#   canonized document stream currently targeted by the geometric layout machine.
# - Provides look-ahead indexing capabilities for line-by-line chunk extractions
#   without suffering performance degradation from system disk reads.
declare -ga SHELL_MD_READI_FORMAT_LINES=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_FMT_H1_DEC through SHELL_MD_READI_FMT_H6_DEC
#                    Description: Read-only global string anchors defining the core
#                    character geometry pattern overlays for Header levels H1 through
#                    H6, derived directly from the Parametric Matrix. Total Width
#                    Specs: Replicated programmatically via the repetition scale
#                    matrix to form deterministic physical line boundaries (Ref:
#                    Sec 5.1 & 5.2).
if [ -z "${SHELL_MD_READI_FMT_H1_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H1_DEC='**********'
fi
if [ -z "${SHELL_MD_READI_FMT_H2_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H2_DEC='__________'
fi
if [ -z "${SHELL_MD_READI_FMT_H3_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H3_DEC='---- ---- '
fi
if [ -z "${SHELL_MD_READI_FMT_H4_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H4_DEC='---   - - '
fi
if [ -z "${SHELL_MD_READI_FMT_H5_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H5_DEC='---  -   -'
fi
if [ -z "${SHELL_MD_READI_FMT_H6_DEC+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_H6_DEC='   ---'
fi



# _GLOBAL_VARIABLE_: SHELL_MD_READI_FMT_SEP
# 
# Description:
# - A read-only global string pattern establishing the literal rhythmic sequence
#   for standalone semantic dividers: exactly 2 spaces, 5 hyphens, and 3 trailing
#   spaces.
# - Replicated exactly 7 times by the formatting loop to compile a strict 70-character
#   isolated visual boundary across content blocks.
# 
# Specification Links:
# - Ref: Section 4.6.2 (Standalone Semantic State Geometry)
if [ -z "${SHELL_MD_READI_FMT_SEP+x}" ]; then
  declare -gr SHELL_MD_READI_FMT_SEP='  -----   '
fi





# ==============================================================================
# RESULTS OF STRUCTURAL ELEMENT MAPPING
# ==============================================================================

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_TYPE Description: Indexed array storing
#                    the determined semantic classification (e.g., HEADER, CODE_BLOCK,
#                    NBSP_BLOCK, SEPARATOR, EMPTY_LINE, BLOCKQUOTE) for each parsed
#                    segment.
declare -ga SHELL_MD_READI_BLOCK_TYPE=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_START Description: Indexed array mapping
#                    the precise physical starting line number index of each localized
#                    token block within the canonized stream.
declare -ga SHELL_MD_READI_BLOCK_START=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_END Description: Indexed array mapping
#                    the precise physical terminating line number index of each localized
#                    token block within the canonized stream.
declare -ga SHELL_MD_READI_BLOCK_END=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_LINES Description: Indexed array recording
#                    the total visual mass/density (physical line count) of each
#                    block, serving as the source-of-truth for Density Scaling (Ref:
#                    Sec 3.5.1).
declare -ga SHELL_MD_READI_BLOCK_LINES=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_HAS_SEP Description: Indexed array binary
#                    flag (1 or 0) tracking if a specific block zone is actively
#                    intercepted by a Vertical Separator or meta-whitespace element.
declare -ga SHELL_MD_READI_BLOCK_HAS_SEP=()

# _GLOBAL_VARIABLE_: SHELL_MD_READI_BLOCK_LAST_RELEVANT Description: Indexed array
#                    maintaining architectural state history by mapping the type
#                    of the immediate preceding semantically relevant element (Ref:
#                    Sec 2.3).
declare -ga SHELL_MD_READI_BLOCK_LAST_RELEVANT=()
