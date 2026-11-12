#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  source "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/share/01_links.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format/02_wrap_block.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format/03_list_block.sh"
}

invoke_with_sentinels() {
  local rc=0
  shell_md_readi_format_list_block "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

assert_list() {
  local expected=${1}
  shift
  run --separate-stderr invoke_with_sentinels "${@}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_format_list_block "${@}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK}" >&2
    return 1
  fi
}

@test "omitted, empty, blank, and non-list input clear stale output" {
  SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=stale
  assert_list ""
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} ]] || return 1

  local input="
not a list
+ unsupported bullet
* unsupported bullet
  1.unsupported number
"
  SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=stale
  assert_list "" "${input}"
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} ]]
}

@test "unordered markers cycle by tab depth while ordered markers and indentation are preserved" {
  local input="- root
	- child
		- grandchild
			- great-grandchild
	- sibling
12. numbered
	3. nested number
+ unsupported plus
* unsupported star
"
  local expected="- root
  + child
    * grandchild
      - great-grandchild
  + sibling
12. numbered
  3. nested number
"
  assert_list "${expected}" "${input}"
}

@test "same-depth spacing respects the 3, 4, 6, and 7 formatted-line thresholds" {
  declare -A MOCK_LINES=()
  shell_md_readi_format_wrap_block() {
    local text=${1} first=${2} rest=${3} count=${MOCK_LINES[${1}]:-1} line=0
    SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""
    for ((line = 0; line < count; line++)); do
      if ((line == 0)); then
        SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${first}${text}${codeNL}"
      else
        SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${rest}${text}-cont${codeNL}"
      fi
    done
  }
  mock_expected_item() {
    local text=${1} depth=${2} count=${3} indent= token= first= rest= line=0
    local -a tokens=("-" "+" "*")
    printf -v indent "%*s" "$((depth * 2))" ""
    token=${tokens[$((depth % 3))]}
    first="${indent}${token} "
    printf -v rest "%*s" "$((depth * 2 + 2))" ""
    MOCK_ITEM=""
    for ((line = 0; line < count; line++)); do
      if ((line == 0)); then MOCK_ITEM+="${first}${text}${codeNL}"
      else MOCK_ITEM+="${rest}${text}-cont${codeNL}"; fi
    done
    MOCK_ITEM="${MOCK_ITEM%${codeNL}}"
  }

  local input="- heavy
- next
" expected= spacing=0 count=0 line=0
  for count in 3 4 6 7; do
    MOCK_LINES=()
    MOCK_LINES[heavy]=${count}
    MOCK_LINES[next]=1
    shell_md_readi_format_list_block "${input}" || return 1
    mock_expected_item heavy 0 "${count}"
    expected="${MOCK_ITEM}${codeNL}"
    if ((count >= 7)); then spacing=2
    elif ((count >= 4)); then spacing=1
    else spacing=0; fi
    for ((line = 0; line < spacing; line++)); do expected+=${codeNL}; done
    mock_expected_item next 0 1
    expected+="${MOCK_ITEM}${codeNL}"
    [[ ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} == "${expected}" ]] || {
      printf "line count %s: expected %q, got %q\n" "${count}" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK}" >&2
      return 1
    }
  done
}

@test "a heavy item propagates a one-line floor to light peers at its depth" {
  declare -A MOCK_LINES=([light]=1 [heavy]=4 [light-again]=1)
  shell_md_readi_format_wrap_block() {
    local text=${1} first=${2} rest=${3} count=${MOCK_LINES[${1}]:-1} line=0
    SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""
    for ((line = 0; line < count; line++)); do
      if ((line == 0)); then SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${first}${text}${codeNL}"
      else SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${rest}${text}-cont${codeNL}"; fi
    done
  }
  local expected="- light

- heavy
  heavy-cont
  heavy-cont
  heavy-cont

- light-again
"
  shell_md_readi_format_list_block "- light
- heavy
- light-again
" || return 1
  [[ ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} == "${expected}" ]] || { printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK}" >&2; return 1; }
}

@test "parent-child transitions use local density and contamination from either depth" {
  declare -A MOCK_LINES=([parent-heavy]=4 [child-light]=1 [parent-light]=1 [child-heavy]=4 [parent-again]=1)
  shell_md_readi_format_wrap_block() {
    local text=${1} first=${2} rest=${3} count=${MOCK_LINES[${1}]:-1} line=0
    SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""
    for ((line = 0; line < count; line++)); do
      if ((line == 0)); then SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${first}${text}${codeNL}"
      else SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK+="${rest}${text}-cont${codeNL}"; fi
    done
  }
  local input="- parent-heavy
	- child-light
- parent-light
	- child-heavy
- parent-again
"
  local expected="- parent-heavy
  parent-heavy-cont
  parent-heavy-cont
  parent-heavy-cont

  + child-light

- parent-light
  + child-heavy
    child-heavy-cont
    child-heavy-cont
    child-heavy-cont

- parent-again
"
  shell_md_readi_format_list_block "${input}" || return 1
  [[ ${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK} == "${expected}" ]] || { printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK}" >&2; return 1; }
}
