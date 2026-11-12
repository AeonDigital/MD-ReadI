#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  source "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format.sh"

  SHELL_MD_READI_RESULT_FORMAT="stale"
  SHELL_MD_READI_BLOCK_TYPE=()
  SHELL_MD_READI_BLOCK_START=()
  SHELL_MD_READI_BLOCK_END=()
  SHELL_MD_READI_BLOCK_LINES=()
  MOCK_WRAP_ARGS=()
  MOCK_LIST_ARGS=()
  MOCK_TABLE_ARGS=()
  MOCK_SPACING_ARGS=()
  MOCK_SPACING_RESULT=0

  shell_md_readi_format_wrap_block() {
    MOCK_WRAP_ARGS+=("${1}")
    SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK="W<${1}>${codeNL}"
  }
  shell_md_readi_format_list_block() {
    MOCK_LIST_ARGS+=("${1}")
    SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK="L<${1}>${codeNL}"
  }
  shell_md_readi_format_table_block() {
    MOCK_TABLE_ARGS+=("${1}")
    SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK="T<${1}>${codeNL}"
  }
  shell_md_readi_format_compute_spacing() {
    MOCK_SPACING_ARGS+=("${1}|${2}|${3}|${4}|${5}")
    SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING=${MOCK_SPACING_RESULT}
  }
}

set_blocks() {
  SHELL_MD_READI_BLOCK_TYPE=("${@}")
}

assert_formatted() {
  local input=${1}
  local expected=${2}
  shell_md_readi_format "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_FORMAT} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT}" >&2
    return 1
  fi
}

repeat_char() {
  local -n result_ref=${1}
  local char=${2}
  local count=${3}
  printf -v result_ref "%*s" "${count}" ""
  result_ref=${result_ref// /${char}}
}

@test "empty document clears stale output and refreshes the line snapshot" {
  SHELL_MD_READI_RESULT_FORMAT="stale"
  shell_md_readi_format ""
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT} && ${#SHELL_MD_READI_FORMAT_LINES[@]} -eq 1 ]]
}

@test "content classes dispatch to their leaf handlers while technical and unknown blocks pass through" {
  local input="prose${codeNL}- item${codeNL}| cell |${codeNL}code${codeNL}> quote${codeNL}<div>${codeNL}other"
  set_blocks PARAGRAPH LIST TABLE CODE_BLOCK BLOCKQUOTE HTML_BLOCK FUTURE
  SHELL_MD_READI_BLOCK_START=(1 2 3 4 5 6 7)
  SHELL_MD_READI_BLOCK_END=(1 2 3 4 5 6 7)
  SHELL_MD_READI_BLOCK_LINES=(1 1 1 1 1 1 1)

  local expected="W<prose>${codeNL}L<- item${codeNL}>${codeNL}T<| cell |${codeNL}>${codeNL}code${codeNL}> quote${codeNL}<div>${codeNL}other"
  assert_formatted "${input}" "${expected}" || return 1
  [[ ${#MOCK_WRAP_ARGS[@]} -eq 1 && ${MOCK_WRAP_ARGS[0]} == "prose" ]] || return 1
  [[ ${#MOCK_LIST_ARGS[@]} -eq 1 && ${MOCK_LIST_ARGS[0]} == "- item${codeNL}" ]] || return 1
  [[ ${#MOCK_TABLE_ARGS[@]} -eq 1 && ${MOCK_TABLE_ARGS[0]} == "| cell |${codeNL}" ]] || return 1
  [[ ${#MOCK_SPACING_ARGS[@]} -eq 7 ]]
}

@test "ordinary paragraphs forward colon and hard-break context plus look-ahead header level" {
  local input="Ends here:${codeNL}## Next${codeNL}Hard break  ${codeNL}- item"
  set_blocks PARAGRAPH HEADER PARAGRAPH LIST
  SHELL_MD_READI_BLOCK_START=(1 2 3 4)
  SHELL_MD_READI_BLOCK_END=(1 2 3 4)
  SHELL_MD_READI_BLOCK_LINES=(2 1 3 1)

  MOCK_SPACING_RESULT=1
  shell_md_readi_format "${input}" || return 1
  [[ ${MOCK_SPACING_ARGS[0]} == "2|PARAGRAPH|HEADER|2|colon" ]] || return 1
  [[ ${MOCK_SPACING_ARGS[1]} == "3|PARAGRAPH|LIST|0|hardbreak" ]]
}

@test "four-space preformatted paragraph bypasses wrapping but still participates in spacing" {
  local input="    literal"
  set_blocks PARAGRAPH
  SHELL_MD_READI_BLOCK_START=(1)
  SHELL_MD_READI_BLOCK_END=(1)
  SHELL_MD_READI_BLOCK_LINES=(1)
  MOCK_SPACING_RESULT=0

  assert_formatted "${input}" "    literal" || return 1
  [[ ${#MOCK_WRAP_ARGS[@]} -eq 0 && ${MOCK_SPACING_ARGS[0]} == "1|PARAGRAPH||0|" ]]
}

@test "header casing and level-specific geometry are applied without decorator separators" {
  local expected= equals= title= input= level= labels=("# first" "## Mixed Case" "### Keep Case" "#### Keep Case" "##### Keep Case" "###### mixed case")
  local expected_headers=("first" "## MIXED CASE" "### Keep Case" "#### Keep Case" "##### Keep Case" "###### mixed case")
  for level in 1 2 3 4 5 6; do
    title=${labels[$((level - 1))]}
    input=${title}
    set_blocks HEADER
    SHELL_MD_READI_BLOCK_START=(1)
    SHELL_MD_READI_BLOCK_END=(1)
    SHELL_MD_READI_BLOCK_LINES=(1)
    if ((level == 1)); then
      repeat_char equals "=" 32
      expected="first${codeNL}${equals}${codeNL}"
    else
      expected="${expected_headers[$((level - 1))]}${codeNL}"
    fi
    assert_formatted "${input}" "${expected}" || return 1
  done
}

@test "H1 setext underline switches width at title lengths 32, 33, 65" {
  local title= input= expected= equals= length= width=
  for length in 32 33 65; do
    repeat_char title x "${length}"
    if ((length <= 32)); then width=32
    elif ((length <= 64)); then width=64
    else width=80; fi
    repeat_char equals "=" "${width}"
    set_blocks HEADER
    SHELL_MD_READI_BLOCK_START=(1)
    SHELL_MD_READI_BLOCK_END=(1)
    SHELL_MD_READI_BLOCK_LINES=(1)
    expected="${title}${codeNL}${equals}${codeNL}"
    assert_formatted "# ${title}" "${expected}" || return 1
  done
}

@test "each heading decorator consumes its separator and uses the configured repetition count" {
  local level= title= dec= pattern= repetitions= expected= input= index=0 underline= heading=
  local patterns=("${SHELL_MD_READI_FMT_H1_DEC}" "${SHELL_MD_READI_FMT_H2_DEC}" "${SHELL_MD_READI_FMT_H3_DEC}" "${SHELL_MD_READI_FMT_H4_DEC}" "${SHELL_MD_READI_FMT_H5_DEC}" "${SHELL_MD_READI_FMT_H6_DEC}")
  local counts=(8 8 7 6 4 5)
  for level in 1 2 3 4 5 6; do
    title="Title ${level}"
    pattern=${patterns[$((level - 1))]}
    repetitions=${counts[$((level - 1))]}
    dec=""
    for ((index = 0; index < repetitions; index++)); do dec+="${pattern}"; done
    printf -v heading "%${level}s" ""
    heading=${heading// /#}
    input="---${codeNL}${codeNL}${heading} ${title}"
    set_blocks SEPARATOR EMPTY_LINE HEADER
    SHELL_MD_READI_BLOCK_START=(1 2 3)
    SHELL_MD_READI_BLOCK_END=(1 2 3)
    SHELL_MD_READI_BLOCK_LINES=(1 0 1)
    if ((level == 1)); then
      repeat_char underline "=" 32
      expected="&nbsp;${codeNL}${dec}${codeNL}${codeNL}${title}${codeNL}${underline}${codeNL}"
    elif ((level == 2)); then expected="&nbsp;${codeNL}${dec}${codeNL}${codeNL}## TITLE ${level}${codeNL}"
    elif ((level == 6)); then expected="&nbsp;${codeNL}${dec}${codeNL}${codeNL}###### title ${level}${codeNL}"
    else expected="&nbsp;${codeNL}${dec}${codeNL}${codeNL}${heading} ${title}${codeNL}"; fi
    assert_formatted "${input}" "${expected}" || return 1
  done
}

@test "standalone separators normalize to seven patterns and defer the previous margin" {
  local input= expected= index=0
  for ((index = 0; index < 7; index++)); do expected+="${SHELL_MD_READI_FMT_SEP}"; done
  input="prose${codeNL}---${codeNL}after"
  set_blocks PARAGRAPH SEPARATOR PARAGRAPH
  SHELL_MD_READI_BLOCK_START=(1 2 3)
  SHELL_MD_READI_BLOCK_END=(1 2 3)
  SHELL_MD_READI_BLOCK_LINES=(1 1 1)
  MOCK_SPACING_RESULT=2
  assert_formatted "${input}" "W<prose>${codeNL}${codeNL}${codeNL}${expected}${codeNL}${codeNL}${codeNL}W<after>${codeNL}${codeNL}" || return 1
  [[ ${#MOCK_SPACING_ARGS[@]} -eq 2 ]]
}

@test "successful formatting returns zero and emits no channel output" {
  set_blocks HEADER
  SHELL_MD_READI_BLOCK_START=(1)
  SHELL_MD_READI_BLOCK_END=(1)
  SHELL_MD_READI_BLOCK_LINES=(1)
  run --separate-stderr shell_md_readi_format "## title"
  [[ ${status} -eq 0 && -z ${output} && -z ${stderr} ]] || return 1
  shell_md_readi_format "## title" || return 1
  [[ ${SHELL_MD_READI_RESULT_FORMAT} == "## TITLE${codeNL}" ]]
}

@test "nbsp metadata adjacent to a standalone separator mirrors spacing around the composite" {
  local input="before${codeNL}&nbsp; 1/2/3${codeNL}---${codeNL}&nbsp; 1/2/3${codeNL}after"
  local separator= index=0
  for ((index = 0; index < 7; index++)); do separator+="${SHELL_MD_READI_FMT_SEP}"; done
  set_blocks PARAGRAPH NBSP_BLOCK SEPARATOR NBSP_BLOCK PARAGRAPH
  SHELL_MD_READI_BLOCK_START=(1 2 3 4 5)
  SHELL_MD_READI_BLOCK_END=(1 2 3 4 5)
  SHELL_MD_READI_BLOCK_LINES=(1 1 1 1 1)
  MOCK_SPACING_RESULT=2

  shell_md_readi_format "${input}" || return 1
  local expected="W<before>${codeNL}${codeNL}${codeNL}&nbsp;${codeNL}&nbsp;${codeNL}${separator}${codeNL}&nbsp;${codeNL}&nbsp;${codeNL}${codeNL}${codeNL}W<after>${codeNL}${codeNL}"; [[ ${SHELL_MD_READI_RESULT_FORMAT} == "${expected}" ]] || { printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT}" >&2; return 1; }
}

@test "standalone nbsp metadata preserves leading and trailing breathing space" {
  set_blocks NBSP_BLOCK
  SHELL_MD_READI_BLOCK_START=(1)
  SHELL_MD_READI_BLOCK_END=(1)
  SHELL_MD_READI_BLOCK_LINES=(1)

  assert_formatted "&nbsp; 3/1/2" "${codeNL}${codeNL}${codeNL}&nbsp;${codeNL}${codeNL}"
}

@test "nbsp breathing zones are vacuumed when they lead into a decorated header" {
  local input="&nbsp; 2/1/1${codeNL}---${codeNL}&nbsp; 2/1/1${codeNL}# Title"
  local dec= equals= index=0
  for ((index = 0; index < 8; index++)); do dec+="${SHELL_MD_READI_FMT_H1_DEC}"; done
  repeat_char equals "=" 32
  set_blocks NBSP_BLOCK SEPARATOR NBSP_BLOCK HEADER
  SHELL_MD_READI_BLOCK_START=(1 2 3 4)
  SHELL_MD_READI_BLOCK_END=(1 2 3 4)
  SHELL_MD_READI_BLOCK_LINES=(1 1 1 1)

  assert_formatted "${input}" "&nbsp;${codeNL}${dec}${codeNL}${codeNL}Title${codeNL}${equals}${codeNL}"
}
