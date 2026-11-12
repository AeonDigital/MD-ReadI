#!/usr/bin/env bats

# Summary: Load the newline register, link scanner, and content parser.
# Effects: Initializes the sourced global registers.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/share/01_links.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/05_content_lines.sh"
}

# Summary: Invoke the parser with a sentinel on each output channel.
# Parameters: All arguments are forwarded to the parser.
# Returns: The parser status and a sentinel on each channel.
# Effects: Updates globals in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_content_lines "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check status, both channels, and exact result register.
# Parameters: $1 input and $2 expected output, using printf %b escapes.
# Returns: Zero on a match; otherwise nonzero with a diagnostic.
# Effects: Invokes the parser twice and updates its global registers.
assert_content() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_canonize_content_lines "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES}" >&2
    return 1
  fi
}

@test "empty input replaces stale result with one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=stale
  assert_content "" "\n"
}

@test "paragraphs join trimmed physical lines and preserve blank boundaries" {
  assert_content "  first \n\tsecond\nthird\n\n  fourth\n fifth" "first second third\n\nfourth fifth\n"
  assert_content "a\n \t\n\nb" "a\n\n\nb\n"
}

@test "trailing newlines represent extra empty physical lines" {
  assert_content "x\n" "x\n\n"
  assert_content "x\n\n" "x\n\n\n"
}

@test "unordered list markers normalize and retain indentation" {
  assert_content "- a\n+ b\n  * c\n\t- d" "- a\n- b\n  - c\n\t- d\n"
}

@test "ordered markers normalize parentheses and preserve number and indentation" {
  assert_content "1) first\n  002. second\n\t42) third" "1. first\n  002. second\n\t42. third\n"
}

@test "list item payload and indented continuations join across lines" {
  assert_content "- first\n  second \n\tthird\n+ next\n  more" "- first second third\n- next more\n"
  assert_content "1) first\n    continuation\n2. next" "1. first continuation\n2. next\n"
}

@test "nonindented prose ends a list and a following list ends prose" {
  assert_content "- list\nparagraph\ncontinued\n2) next" "- list\nparagraph continued\n2. next\n"
}

@test "blank lines flush list items and distinguish subsequent prose" {
  assert_content "- first\n\n  after\n  more" "- first\n\nafter more\n"
}

@test "list markers require whitespace after the marker" {
  assert_content "-word\n+word\n*word\n1)word\n2.word" "-word +word *word 1)word 2.word\n"
}

@test "separator minimum and mixed markers are normalized before list matching" {
  assert_content "before\n---\n - * _ \nafter" "before\n---\n---\nafter\n"
  assert_content "--\n__" "-- __\n"
}

@test "separators flush paragraph and list buffers" {
  assert_content "paragraph\n***\n- item\n___\nprose" "paragraph\n---\n- item\n---\nprose\n"
}

@test "nbsp metadata is retained through the numeric prefix and flushes buffers" {
  assert_content "paragraph\n  &nbsp; 12/3/45 ignored\n- item\n&nbsp;1/2/3 tail\nafter" "paragraph\n  &nbsp; 12/3/45\n- item\n&nbsp;1/2/3\nafter\n"
}

@test "standalone nbsp retains whitespace and flushes buffers" {
  assert_content "paragraph\n \t&nbsp; \t\n- item\n&nbsp;\nafter" "paragraph\n \t&nbsp; \t\n- item\n&nbsp;\nafter\n"
}

@test "malformed nbsp metadata is ordinary prose" {
  assert_content "a\n&nbsp;1/2\nb" "a &nbsp;1/2 b\n"
}

@test "hard breaks retain two or more trailing whitespace characters" {
  assert_content "  one  \nnext\n\tlast\t \nend" "one  \nnext\nlast\t \nend\n"
}

@test "one trailing space is trimmed while two mark a hard break" {
  assert_content "first \nsecond\nthird  \nfourth" "first second\nthird  \nfourth\n"
}

@test "hard breaks flush pending paragraph or list and take precedence over lists" {
  assert_content "paragraph\nforced  \n- list\n  forced  \n+ raw  \nend" "paragraph\nforced  \n- list\nforced  \n+ raw  \nend\n"
}

@test "fenced blocks flush prose and list and retain literal content" {
  assert_content "paragraph\n  \`\`\`sh\n- raw  \n\n&nbsp;\n\t\`\`\`\n- item\n\`\`\`\n a + b\n\`\`\`\nafter" "paragraph\n  \`\`\`sh\n- raw  \n\n&nbsp;\n\t\`\`\`\n- item\n\`\`\`\n a + b\n\`\`\`\nafter\n"
}

@test "unclosed fence protects the remainder and resets on the next call" {
  assert_content "before\n\`\`\`\n+ raw\n\n* raw" "before\n\`\`\`\n+ raw\n\n* raw\n"
  assert_content "+ item" "- item\n"
}

@test "fence characters away from the start remain paragraph text" {
  assert_content "prefix \`\`\`\nnext" "prefix \`\`\` next\n"
}

@test "structural lines flush paragraphs and are not joined" {
  assert_content "paragraph\n  # heading\n | table |\n > quote\n <div>\n </div>\n <!comment>\nafter" "paragraph\n  # heading\n | table |\n > quote\n <div>\n </div>\n <!comment>\nafter\n"
}

@test "raw HTML blocks protect enclosed content from collapsing and translation" {
  assert_content "<div>\nalpha + beta\nsecond\n</div>" "<div>\nalpha + beta\nsecond\n</div>\n"
}

@test "indented structural lines end pending list continuations" {
  assert_content "- a\n  > quote\n- b\n  | table\n- c\n  <tag>\n- d\n  # heading" "- a\n  > quote\n- b\n  | table\n- c\n  <tag>\n- d\n  # heading\n"
}

@test "unindented structural lines end list buffers" {
  assert_content "- a\n# heading\n- b\n| table\n- c\n> quote\n- d\n<tag>" "- a\n# heading\n- b\n| table\n- c\n> quote\n- d\n<tag>\n"
}

@test "structural marker recognition requires valid quote and tag starts" {
  assert_content ">word\n<3\ntext" ">word <3 text\n"
  assert_content ">\n#\n|\n<!x" ">\n#\n|\n<!x\n"
}

@test "exactly four leading spaces protect a preformatted line outside lists" {
  assert_content "before\n    code\nafter" "before\n    code\nafter\n"
  assert_content "before\n   three\n     five\n    \t tab\nafter" "before three five tab after\n"
}

@test "indented lines inside list items are continuations rather than code" {
  assert_content "- item\n    code\n     extra\n\tmore" "- item code extra more\n"
}

@test "real safety helper receives unified prose and list content" {
  assert_content "alpha\n- beta\n  x - y\ntail + end" "alpha\n- beta x \u2014 y\ntail \uff0b end\n"
  assert_content "text - [a + b](x)\nend" "text \u2014 [a + b](x) end\n"
}

# Summary: Record flushed values and replace each with a predictable marker.
# Parameters: $1 paragraph or list buffer passed by the parser.
# Returns: Zero with the mocked result register set.
# Effects: Appends to MOCK_FLUSHED and updates the helper result register.
mock_safety() {
  MOCK_FLUSHED+=("${1}")
  SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY="<${1}>"
  return 0
}

@test "buffer flushes call safety in order while structural lines bypass it" {
  local -a MOCK_FLUSHED=()
  _shell_md_readi_canonize_prose_safety() { mock_safety "${@}"; }
  assert_content "a\nb\n- list\n  more\n# heading\nlast" "<a b>\n<- list more>\n# heading\n<last>\n"
  [ "${#MOCK_FLUSHED[@]}" -eq 3 ]
  [ "${MOCK_FLUSHED[0]}" = "a b" ]
  [ "${MOCK_FLUSHED[1]}" = "- list more" ]
  [ "${MOCK_FLUSHED[2]}" = last ]
}

@test "repeated calls reset result and pending state" {
  shell_md_readi_canonize_content_lines "- old"
  local expected=""
  printf -v expected "%b" "- old\n"
  [ "${SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES}" = "${expected}" ]
  assert_content "new" "new\n"
}
