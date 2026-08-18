#!/usr/bin/env bash

# ==============================================================================
# SINGLE-FILE DISTRIBUTION SHELL PACKAGE 
# 
# PROJECT:     MD-ReadI
# ORIGIN URL:  https://github.com/AeonDigital/MD-ReadI
# EXPORTED AT: 2026-08-18 19:04:54
# LICENSE:     MIT [ https://github.com/AeonDigital/MD-ReadI/LICENSE ] 
# ==============================================================================



if [ -z "${codeNL+x}" ]; then
declare -gr codeNL=$'\n'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK='^```'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_NBSP_META+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_NBSP_META='^&nbsp;[[:space:]]+([0-9]+)/([0-9]+)/([0-9]+)'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_HEADER+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_HEADER='^#'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_TABLE+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_TABLE='^[[:space:]]*\|'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_LIST+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_LIST='^[-*][[:space:]]+|^[0-9]+\.[[:space:]]+'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_SEPARATOR+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_SEPARATOR='^[[:space:]]*([-_*][[:space:]]*){3,}$'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE='^[[:space:]]*>+[[:space:]]*.*$'
fi
if [ -z "${SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK+x}" ]; then
declare -gr SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK='^[[:space:]]*</?[[:alpha:]!][^>]*>.*$'
fi
declare -ga SHELL_MD_READI_FORMAT_LINES=()
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
if [ -z "${SHELL_MD_READI_FMT_SEP+x}" ]; then
declare -gr SHELL_MD_READI_FMT_SEP='  -----   '
fi
declare -ga SHELL_MD_READI_BLOCK_TYPE=()
declare -ga SHELL_MD_READI_BLOCK_START=()
declare -ga SHELL_MD_READI_BLOCK_END=()
declare -ga SHELL_MD_READI_BLOCK_LINES=()
declare -ga SHELL_MD_READI_BLOCK_HAS_SEP=()
declare -ga SHELL_MD_READI_BLOCK_LAST_RELEVANT=()


declare -g SHELL_MD_READI_RESULT_CANONIZE=""
shell_md_readi_canonize() {
SHELL_MD_READI_RESULT_CANONIZE=""
local raw_content="${1}"
if [ "${raw_content}" = "" ]; then
printf "[ERR] :: Missing content payload for canonization.\n" >&2
return 1
fi
shell_md_readi_canonize_characters "${raw_content}"
shell_md_readi_canonize_blank_lines "${SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS}"
shell_md_readi_canonize_headers "${SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES}"
shell_md_readi_canonize_blockquotes "${SHELL_MD_READI_RESULT_CANONIZE_HEADERS}"
shell_md_readi_canonize_content_lines "${SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES}"
shell_md_readi_canonize_table_cells "${SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES}"
shell_md_readi_canonize_indentation "${SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS}"
SHELL_MD_READI_RESULT_CANONIZE="${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=""
shell_md_readi_canonize_characters() {
SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=""
local value="${1}"
local clean_text="${value}"
local code_ctrl_chars=""
code_ctrl_chars+=$'\000'$'\001'$'\002'$'\003'$'\004'$'\005'$'\006'$'\007'$'\010'
code_ctrl_chars+=$'\013'$'\014'$'\016'$'\017'$'\020'$'\021'$'\022'$'\023'$'\024'
code_ctrl_chars+=$'\025'$'\026'$'\027'$'\030'$'\031'$'\032'$'\033'$'\034'$'\035'
code_ctrl_chars+=$'\036'$'\037'$'\177'
clean_text=$(printf "%s" "${clean_text}" | tr -d "${code_ctrl_chars}")
clean_text="${clean_text//“/\"}"
clean_text="${clean_text//”/\"}"
clean_text="${clean_text//‘/\'}"
clean_text="${clean_text//’/\'}"
clean_text="${clean_text//"$'\u200b'"/}"
clean_text="${clean_text//"$'\uefbbbf'"/}"
SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS="${clean_text}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=""
shell_md_readi_canonize_blank_lines() {
SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=""
local raw_content="${1}"
local current_line=""
local output_buffer=""
local in_code_block=0
local doc_lines=()
local total_lines=0
local l_idx=0
local clean_row=""
local leading_blanks=0
local nbsp_count=0
local trailing_blanks=0
local scan_idx=0
local phase=""
local peek_line=""
local clean_peek=""
local regex_code_block='^```'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
doc_lines+=("${current_line}")
done <<< "${raw_content}"
total_lines=${#doc_lines[@]}
for ((l_idx = 0; l_idx < total_lines; l_idx++)); do
current_line="${doc_lines[l_idx]}"
clean_row="${current_line#"${current_line%%[![:space:]]*}"}"
clean_row="${clean_row%"${clean_row##*[![:space:]]}"}"
if [[ "${clean_row}" =~ ${regex_code_block} ]]; then
if [ "${in_code_block}" -eq 0 ]; then
in_code_block=1
else
in_code_block=0
fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_code_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ -z "${clean_row}" ] || [ "${clean_row}" = "&nbsp;" ]; then
leading_blanks=0
nbsp_count=0
trailing_blanks=0
scan_idx="${l_idx}"
phase="LEADING"
while [ "${scan_idx}" -lt "${total_lines}" ]; do
peek_line="${doc_lines[scan_idx]}"
clean_peek="${peek_line#"${peek_line%%[![:space:]]*}"}"
clean_peek="${clean_peek%"${clean_peek##*[![:space:]]}"}"
if [ -n "${clean_peek}" ] && [ "${clean_peek}" != "&nbsp;" ] && [[ ! "${clean_peek}" =~ ${regex_code_block} ]]; then
break
fi
if [[ "${clean_peek}" =~ ${regex_code_block} ]]; then
break
fi
if [ -z "${clean_peek}" ]; then
if [ "${phase}" = "LEADING" ]; then
((leading_blanks++))
elif [ "${phase}" = "NBSP" ]; then
phase="TRAILING"
((trailing_blanks++))
else
((trailing_blanks++))
fi
elif [ "${clean_peek}" = "&nbsp;" ]; then
if [ "${phase}" = "LEADING" ] || [ "${phase}" = "NBSP" ] || [ "${phase}" = "TRAILING" ]; then
phase="NBSP"
((nbsp_count++))
fi
fi
((scan_idx++))
done
l_idx=$((scan_idx - 1))
if [ "${nbsp_count}" -gt 0 ]; then
[ "${leading_blanks}" -gt 3 ] && leading_blanks=3
[ "${trailing_blanks}" -gt 3 ] && trailing_blanks=3
output_buffer+="&nbsp; ${leading_blanks}/${nbsp_count}/${trailing_blanks}"${codeNL}
else
output_buffer+=${codeNL}
fi
continue
fi
output_buffer+="${current_line}"${codeNL}
done
SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_HEADERS=""
shell_md_readi_canonize_headers() {
SHELL_MD_READI_RESULT_CANONIZE_HEADERS=""
local raw_content="${1}"
local current_line=""
local output_buffer=""
local in_code_block=0
local pending_text_line=""
local pending_separator_line=""
local clean_line=""
local separator_regex='^[[:space:]]*([-_*][[:space:]]*){3,}$'
local regex_code_block='^```'
local regex_h1='^=+$'
local regex_h2='^-+$'
local regex_header='^#+'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
clean_line="${current_line#"${current_line%%[![:space:]]*}"}"
clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"
if [[ "${clean_line}" =~ ${regex_code_block} ]]; then
if [ "${in_code_block}" -eq 0 ]; then
in_code_block=1
else
in_code_block=0
fi
[ -n "${pending_separator_line}" ] && { output_buffer+="${pending_separator_line}"${codeNL}; pending_separator_line=""; }
[ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_code_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ -z "${clean_line}" ]; then
if [ -n "${pending_separator_line}" ]; then
output_buffer+="${pending_separator_line}"${codeNL}
pending_separator_line=""
fi
[ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
output_buffer+=${codeNL}
continue
fi
if [[ "${clean_line}" =~ ${separator_regex} ]]; then
[ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
[ -n "${pending_separator_line}" ] && { output_buffer+="${pending_separator_line}"${codeNL}; }
pending_separator_line="---"
continue
fi
if [[ "${clean_line}" =~ ${regex_h1} ]] && [ -n "${pending_text_line}" ]; then
pending_separator_line=""
output_buffer+="# ${pending_text_line#"${pending_text_line%%[![:space:]]*}"}"${codeNL}
pending_text_line=""
continue
fi
if [[ "${clean_line}" =~ ${regex_h2} ]] && [ -n "${pending_text_line}" ]; then
pending_separator_line=""
output_buffer+="## ${pending_text_line#"${pending_text_line%%[![:space:]]*}"}"${codeNL}
pending_text_line=""
continue
fi
if [[ "${clean_line}" =~ ${regex_header} ]]; then
pending_separator_line=""
[ -n "${pending_text_line}" ] && { output_buffer+="${pending_text_line}"${codeNL}; pending_text_line=""; }
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ -n "${pending_separator_line}" ]; then
output_buffer+="${pending_separator_line}"${codeNL}
pending_separator_line=""
fi
if [ -n "${pending_text_line}" ]; then
output_buffer+="${pending_text_line}"${codeNL}
fi
pending_text_line="${current_line}"
done <<< "${raw_content}"
if [ -n "${pending_separator_line}" ]; then
output_buffer+="${pending_separator_line}"${codeNL}
fi
if [ -n "${pending_text_line}" ]; then
output_buffer+="${pending_text_line}"${codeNL}
fi
SHELL_MD_READI_RESULT_CANONIZE_HEADERS="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES=""
shell_md_readi_canonize_blockquotes() {
SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES=""
local raw_content="${1}"
local current_line=""
local output_buffer=""
local in_code_block=0
local trimmed_line=""
local quote_body=""
local regex_code_block='^```'
local regex_blockquote='^([[:space:]]*)(>+)([[:space:]]*)(.*)$'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"
if [[ "${trimmed_line}" =~ ${regex_code_block} ]]; then
if [ "${in_code_block}" -eq 0 ]; then
in_code_block=1
else
in_code_block=0
fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_code_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [[ "${trimmed_line}" =~ ${regex_blockquote} ]]; then
quote_body="${BASH_REMATCH[4]}"
if [ -z "${quote_body}" ]; then
output_buffer+=">"${codeNL}
else
output_buffer+="> ${quote_body}"${codeNL}
fi
continue
fi
output_buffer+="${current_line}"${codeNL}
done <<< "${raw_content}"
SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=""
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
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
if [ "${in_special_block}" -eq 0 ]; then in_special_block=1; else in_special_block=0; fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_special_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [[ "${current_line}" =~ ${regex_nbsp_meta} ]]; then
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+="${BASH_REMATCH[1]}"${codeNL}
continue
fi
if [[ "${current_line}" =~ ${regex_nbsp_line} ]]; then
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [[ "${current_line}" =~ ${regex_separator} ]]; then
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+="---"${codeNL}
continue
fi
if [ -z "${clean_line}" ]; then
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+=${codeNL}
continue
fi
if [[ "${current_line}" =~ ${regex_hard_break} ]]; then
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
hard_break_marker="${BASH_REMATCH[1]}"
line_body="${current_line%"${hard_break_marker}"}"
line_body="${line_body#"${line_body%%[![:space:]]*}"}"
output_buffer+="${line_body}${hard_break_marker}"${codeNL}
continue
fi
if [[ "${current_line}" =~ ${regex_unordered_list} ]]; then
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; fi
list_item_buffer="${BASH_REMATCH[1]}- ${BASH_REMATCH[3]}"
list_item_buffer="${list_item_buffer%"${list_item_buffer##*[![:space:]]}"}"
continue
fi
if [[ "${current_line}" =~ ${regex_ordered_list} ]]; then
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; fi
list_item_buffer="${BASH_REMATCH[1]}${BASH_REMATCH[2]}. ${BASH_REMATCH[4]}"
list_item_buffer="${list_item_buffer%"${list_item_buffer##*[![:space:]]}"}"
continue
fi
if [ -n "${list_item_buffer}" ] && [[ "${current_line}" =~ ^[[:space:]] ]]; then
cont="${current_line#"${current_line%%[![:space:]]*}"}"
if [[ "${cont}" =~ ^\> ]] || [[ "${cont}" =~ ^\| ]] || [[ "${cont}" =~ ^'<' ]] || [[ "${cont}" =~ ^\# ]]; then
output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""
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
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; list_item_buffer=""; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+="${clean_line}"${codeNL}
continue
fi
if [ -z "${list_item_buffer}" ] && [ "${current_line:0:4}" = "    " ] && [ "${current_line:4:1}" != " " ] && [ "${current_line:4:1}" != $'\t' ] && [ -n "${current_line:4:1}" ]; then
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; paragraph_buffer=""; fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ -n "${list_item_buffer}" ]; then
output_buffer+="${list_item_buffer}"${codeNL}
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
if [ -n "${list_item_buffer}" ]; then output_buffer+="${list_item_buffer}"${codeNL}; fi
if [ -n "${paragraph_buffer}" ]; then output_buffer+="${paragraph_buffer}"${codeNL}; fi
SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=""
shell_md_readi_canonize_table_cells() {
SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=""
local full_content="${1}"
local current_line=""
local output_buffer=""
local in_code_block=0
local clean_row=""
local old_ifs=""
local cells=()
local row_buffer=""
local cell_idx=0
local raw_cell=""
local clean_cell=""
local is_divider=0
local cell_counter=0
local regex_code_block='^```'
local regex_table_row='^\|.*\|$'
local regex_table_divider='^\|([[:space:]]*:?-+:?[[:space:]]*\|)+$'
local regex_center='^:.*:$'
local regex_left='^:'
local regex_right=':$'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
clean_row="${current_line#"${current_line%%[![:space:]]*}"}"
clean_row="${clean_row%"${clean_row##*[![:space:]]}"}"
if [[ "${clean_row}" =~ ${regex_code_block} ]]; then
if [ "${in_code_block}" -eq 0 ]; then
in_code_block=1
else
in_code_block=0
fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_code_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [[ "${clean_row}" =~ ${regex_table_row} ]]; then
old_ifs="${IFS}"
IFS="|"
cells=()
read -r -a cells <<< "${clean_row}"
IFS="${old_ifs}"
row_buffer="|"
is_divider=0
if [[ "${clean_row}" =~ ${regex_table_divider} ]]; then
is_divider=1
fi
for ((cell_idx = 0; cell_idx < ${#cells[@]}; cell_idx++)); do
raw_cell="${cells[cell_idx]}"
if [ "${cell_idx}" -eq 0 ] && [ -z "${raw_cell}" ]; then
continue
fi
clean_cell="${raw_cell#"${raw_cell%%[![:space:]]*}"}"
clean_cell="${clean_cell%"${clean_cell##*[![:space:]]}"}"
if [ "${is_divider}" -eq 1 ]; then
if [ -n "${clean_cell}" ] || [ "${cell_idx}" -lt $(( ${#cells[@]} - 1 )) ]; then
if [[ "${clean_cell}" =~ ${regex_center} ]]; then
row_buffer+=" :---: |"
elif [[ "${clean_cell}" =~ ${regex_left} ]]; then
row_buffer+=" :---- |"
elif [[ "${clean_cell}" =~ ${regex_right} ]]; then
row_buffer+=" ----: |"
else
row_buffer+=" ----- |"
fi
fi
continue
fi
if [ -n "${clean_cell}" ]; then
row_buffer+=" ${clean_cell} |"
else
row_buffer+="  |"
fi
done
output_buffer+="${row_buffer}"${codeNL}
else
output_buffer+="${current_line}"${codeNL}
fi
done <<< "${full_content}"
SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=""
shell_md_readi_canonize_indentation_block() {
SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=""
local block_content="${1}"
local output_buffer=""
local detected_mode="NONE"
local current_line=""
local block_lines=()
local line_idx=0
local prefix=""
local body=""
local spaces_count=0
local tabs_count=0
local tab_prefix=""
local t_idx=0
local level_idx=0
local sorted_level_str=""
local all_preformatted=1
local -a unique_space_levels=()
local -a sorted_levels=()
local -A seen_space_levels=()
local -A space_to_tabs=()
local regex_indented_line='^[[:space:]]+[^[:space:]]'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
block_lines+=("${current_line}")
done <<< "${block_content}"
for current_line in "${block_lines[@]}"; do
[ -z "${current_line}" ] && continue
if [ "${current_line:0:4}" != "    " ] || [ "${current_line:4:1}" = " " ] || [ "${current_line:4:1}" = $'\t' ] || [ -z "${current_line:4:1}" ]; then
all_preformatted=0
break
fi
done
if [ "${all_preformatted}" -eq 1 ] && [ "${#block_lines[@]}" -gt 0 ]; then
for current_line in "${block_lines[@]}"; do
output_buffer+="${current_line}"${codeNL}
done
printf "%s" "${output_buffer}"
return 0
fi
for current_line in "${block_lines[@]}"; do
if [[ "${current_line}" =~ ${regex_indented_line} ]]; then
prefix="${current_line%%[^[:space:]]*}"
if [[ "${prefix}" == *$'\t'* ]]; then
detected_mode="TABS"
break
fi
if [ -n "${prefix}" ]; then
spaces_count=${#prefix}
if [ ! "${seen_space_levels["${spaces_count}"]+x}" ]; then
seen_space_levels["${spaces_count}"]=1
unique_space_levels+=("${spaces_count}")
detected_mode="SPACES"
fi
fi
fi
done
if [ "${detected_mode}" = "SPACES" ] && [ "${#unique_space_levels[@]}" -gt 0 ]; then
if [ ! "${seen_space_levels["0"]+x}" ]; then
unique_space_levels=("0" "${unique_space_levels[@]}")
fi
sorted_level_str="$(printf '%s\n' "${unique_space_levels[@]}" | sort -n | tr '\n' ' ')"
read -r -a sorted_levels <<< "${sorted_level_str}"
for (( level_idx = 0; level_idx < ${#sorted_levels[@]}; level_idx++ )); do
space_to_tabs["${sorted_levels[${level_idx}]}"]="${level_idx}"
done
fi
for ((line_idx = 0; line_idx < ${#block_lines[@]}; line_idx++)); do
current_line="${block_lines[line_idx]}"
if [[ "${current_line}" =~ ${regex_indented_line} ]]; then
prefix="${current_line%%[^[:space:]]*}"
if [ "${detected_mode}" = "SPACES" ] && [ "${#space_to_tabs[@]}" -gt 0 ]; then
spaces_count=${#prefix}
if [ "${space_to_tabs["${spaces_count}"]+x}" ]; then
tabs_count="${space_to_tabs["${spaces_count}"]}"
else
tabs_count=0
fi
tab_prefix=""
for ((t_idx = 0; t_idx < tabs_count; t_idx++)); do
tab_prefix+=$'\t'
done
body="${current_line:${#prefix}}"
output_buffer+="${tab_prefix}${body}"${codeNL}
else
output_buffer+="${current_line}"${codeNL}
fi
else
output_buffer+="${current_line}"${codeNL}
fi
done
SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=""
shell_md_readi_canonize_indentation() {
SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=""
local value="${1}"
local current_line=""
local output_buffer=""
local current_block=""
local in_code_block=0
local block_lines=()
local block_buffer=""
local regex_code_block='^[[:space:]]*```'
while IFS= read -r current_line || [ -n "${current_line}" ]; do
if [[ "${current_line}" =~ ${regex_code_block} ]]; then
if [ "${in_code_block}" -eq 0 ]; then
if [ -n "${current_block}" ]; then
shell_md_readi_canonize_indentation_block "${current_block}"
output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}"
output_buffer+=${codeNL}
current_block=""
fi
in_code_block=1
else
in_code_block=0
fi
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ "${in_code_block}" -eq 1 ]; then
output_buffer+="${current_line}"${codeNL}
continue
fi
if [ -z "${current_line}" ]; then
if [ -n "${current_block}" ]; then
shell_md_readi_canonize_indentation_block "${current_block}"
output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}"
output_buffer+=${codeNL}
current_block=""
fi
output_buffer+=${codeNL}
continue
fi
if [ -n "${current_block}" ]; then
current_block+="${codeNL}"
fi
current_block+="${current_line}"
done <<< "${value}"
if [ -n "${current_block}" ]; then
shell_md_readi_canonize_indentation_block "${current_block}"
output_buffer+="${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}"
fi
SHELL_MD_READI_RESULT_CANONIZE_INDENTATION="${output_buffer}"
}


declare -g SHELL_MD_READI_RESULT_FORMAT=""
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
last_spacing=0
for (( block_idx = 0; block_idx < total_blocks; block_idx++ )); do
current_type="${SHELL_MD_READI_BLOCK_TYPE["${block_idx}"]}"
if [ "${current_type}" = "EMPTY_LINE" ]; then
continue
fi
if [ "${after_separator}" -eq 1 ] && [ "${current_type}" != "NBSP_BLOCK" ]; then
for (( idx = 0; idx < mirror_spacing; idx++ )); do output_buffer+=${codeNL}; done
last_spacing="${mirror_spacing}"
after_separator=0
fi
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
if [ "${after_separator}" -eq 1 ]; then
for (( idx = 0; idx < nbsp_n; idx++ )); do output_buffer+="&nbsp;"${codeNL}; done
for (( idx = 0; idx < mirror_spacing; idx++ )); do output_buffer+=${codeNL}; done
last_spacing="${mirror_spacing}"
after_separator=0
continue
fi
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
if [ "${nbsp_near_decorator}" -eq 1 ]; then
continue
fi
extra_blanks=$(( nbsp_l - last_spacing ))
if [ "${extra_blanks}" -gt 0 ]; then
for (( idx = 0; idx < extra_blanks; idx++ )); do output_buffer+=${codeNL}; done
last_spacing=$(( last_spacing + extra_blanks ))
fi
for (( idx = 0; idx < nbsp_n; idx++ )); do output_buffer+="&nbsp;"${codeNL}; done
if [ "${nbsp_near_sep}" -eq 0 ] && [ "${nbsp_t}" -gt 0 ]; then
for (( idx = 0; idx < nbsp_t; idx++ )); do output_buffer+=${codeNL}; done
fi
continue
fi
if [ "${current_type}" = "SEPARATOR" ] && [ "${decorator_sep["${block_idx}"]+x}" ]; then
continue
fi
raw_chunk=""
for (( idx = SHELL_MD_READI_BLOCK_START["${block_idx}"] - 1; idx < SHELL_MD_READI_BLOCK_END["${block_idx}"]; idx++ )); do
raw_chunk+="${SHELL_MD_READI_FORMAT_LINES[${idx}]}"${codeNL}
done
clean_chunk="${raw_chunk%${codeNL}}"
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
if [ "${current_type}" = "HEADER" ]; then
temp="${clean_chunk#"${clean_chunk%%[![:space:]]*}"}"
header_level=0
while [[ "${temp}" =~ ^# ]]; do (( header_level++ )); temp="${temp#\#}"; done
header_title="${temp#"${temp%%[![:space:]]*}"}"
header_title="${header_title%"${header_title##*[![:space:]]}"}"
if [ "${header_decorated["${block_idx}"]+x}" ]; then
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
output_buffer+=${codeNL}
last_spacing=1
continue
fi
if [ "${current_type}" = "SEPARATOR" ]; then
dec_line=""
for (( idx = 0; idx < 7; idx++ )); do dec_line+="${SHELL_MD_READI_FMT_SEP}"; done
output_buffer+="${dec_line}"${codeNL}
mirror_spacing="${last_spacing}"
after_separator=1
continue
fi
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


declare -g SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING=""
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
if [ -z "${next_type}" ]; then
SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="0"
return 0
fi
if [ "${flags}" = "hardbreak" ]; then
SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="0"
return 0
fi
if [ "${density}" -lt 7 ]; then
spacing=1
elif [ "${density}" -lt 15 ]; then
spacing=2
elif [ "${density}" -lt 22 ]; then
spacing=3
else
spacing=4
fi
if [ "${next_type}" = "HEADER" ]; then
case "${next_level}" in
1) hmin=5 ;;
2) hmin=4 ;;
3) hmin=3 ;;
*) hmin=2 ;;
esac
if [ "${hmin}" -gt "${spacing}" ]; then spacing="${hmin}"; fi
fi
if [ "${current_type}" = "PARAGRAPH" ] && [ "${next_type}" = "PARAGRAPH" ]; then
if [ "${spacing}" -gt 2 ]; then spacing=2; fi
fi
if [ "${current_type}" = "PARAGRAPH" ] && [ "${next_type}" != "PARAGRAPH" ] && [ "${next_type}" != "HEADER" ]; then
if [ "${spacing}" -gt 3 ]; then spacing=3; fi
fi
case "${current_type}" in LIST|TABLE|CODE_BLOCK|BLOCKQUOTE|HTML_BLOCK) is_struct_curr=1 ;; esac
case "${next_type}" in LIST|TABLE|CODE_BLOCK|BLOCKQUOTE|HTML_BLOCK) is_struct_next=1 ;; esac
if [ "${is_struct_curr}" -eq 1 ] && [ "${is_struct_next}" -eq 1 ]; then
if [ "${current_type}" != "BLOCKQUOTE" ] || [ "${next_type}" != "BLOCKQUOTE" ]; then
if [ "${spacing}" -lt 2 ]; then spacing=2; fi
fi
fi
if [ "${current_type}" = "HEADER" ] && [ "${next_type}" = "HEADER" ]; then
spacing=1
fi
if [ "${flags}" = "colon" ]; then
spacing=1
fi
SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING="${spacing}"
}


declare -g SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=""
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
if [[ ! "${rest}" =~ [[:space:]] ]]; then
output+="${pfx}${rest}${hard_break_suffix}"${codeNL}
hard_break_suffix=""
break
fi
break_pos=$(( 120 - pfx_len ))
if [ "${break_pos}" -gt "${#rest}" ]; then break_pos="${#rest}"; fi
fi
seg="${rest:0:${break_pos}}"
rest="${rest:${break_pos}}"
rest="${rest#"${rest%%[![:space:]]*}"}"
if [ -z "${rest}" ] && [ -n "${hard_break_suffix}" ]; then
output+="${pfx}${seg}${hard_break_suffix}"${codeNL}
hard_break_suffix=""
else
output+="${pfx}${seg}"${codeNL}
fi
is_first=0
done
if [ -n "${hard_break_suffix}" ]; then
output+="${pfx_first}${hard_break_suffix}"${codeNL}
fi
SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK="${output}"
}


declare -g SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=""
shell_md_readi_format_list_block() {
SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK=""
local raw_content="${1:-}"
local output=""
local current_line=""
local tabs=""
local depth=0
local body=""
local tok=""
local tok_idx=0
local indent=""
local pfx_first=""
local pfx_rest=""
local item_text=""
local num=""
local num_width=0
local wrapped=""
local newlines_str=""
local line_count=0
local total_items=0
local i=0
local j=0
local prev_depth=0
local curr_depth=0
local prev_lines=0
local spacing_lines=0
local -a list_tokens=("-" "+" "*")
local -a item_depths=()
local -a item_texts=()
local -a item_lines=()
local -A contaminated_at_depth=()
while IFS= read -r current_line || [ -n "${current_line}" ]; do
[ -z "${current_line}" ] && continue
tabs="${current_line%%[^$'\t']*}"
depth="${#tabs}"
body="${current_line:${depth}}"
if [[ "${body}" =~ ^([0-9]+)\.[[:space:]]+(.*)$ ]]; then
num="${BASH_REMATCH[1]}"
item_text="${BASH_REMATCH[2]}"
indent="$(printf "%$(( depth * 2 ))s" "")"
num_width=$(( ${#num} + 2 ))
pfx_first="${indent}${num}. "
pfx_rest="$(printf "%$(( depth * 2 + num_width ))s" "")"
elif [[ "${body}" =~ ^-[[:space:]]+(.*)$ ]]; then
tok_idx=$(( depth % 3 ))
tok="${list_tokens[${tok_idx}]}"
item_text="${BASH_REMATCH[1]}"
indent="$(printf "%$(( depth * 2 ))s" "")"
pfx_first="${indent}${tok} "
pfx_rest="$(printf "%$(( depth * 2 + 2 ))s" "")"
else
continue
fi
shell_md_readi_format_wrap_block "${item_text}" "${pfx_first}" "${pfx_rest}"
wrapped="${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK:0: -1}"
if [ -n "${wrapped}" ]; then
newlines_str="${wrapped//[^$'\n']/}"
line_count=$(( ${#newlines_str} + 1 ))
else
line_count=1
fi
item_depths+=("${depth}")
item_texts+=("${wrapped}")
item_lines+=("${line_count}")
(( total_items++ ))
done <<< "${raw_content}"
if [ "${total_items}" -eq 0 ]; then
SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK="${output}"
return "0"
fi
for (( i = 0; i < total_items; i++ )); do
depth="${item_depths[${i}]}"
line_count="${item_lines[${i}]}"
if [ "${line_count}" -ge 4 ]; then
contaminated_at_depth["${depth}"]=1
fi
done
output+="${item_texts[0]}"${codeNL}
prev_depth="${item_depths[0]}"
for (( i = 1; i < total_items; i++ )); do
curr_depth="${item_depths[${i}]}"
prev_lines="${item_lines[$((i - 1))]}"
if [ "${curr_depth}" -gt "${prev_depth}" ]; then
if [ "${prev_lines}" -ge 4 ]; then spacing_lines=1; else spacing_lines=0; fi
elif [ "${curr_depth}" -eq "${prev_depth}" ]; then
if   [ "${prev_lines}" -ge 7 ]; then spacing_lines=2
elif [ "${prev_lines}" -ge 4 ]; then spacing_lines=1
else spacing_lines=0; fi
if [ "${contaminated_at_depth["${curr_depth}"]+x}" ] && [ "${spacing_lines}" -lt 1 ]; then
spacing_lines=1
fi
else
spacing_lines=0
if [ "${contaminated_at_depth["${curr_depth}"]+x}" ] || [ "${contaminated_at_depth["${prev_depth}"]+x}" ]; then
spacing_lines=1
fi
fi
for (( j = 0; j < spacing_lines; j++ )); do output+=${codeNL}; done
output+="${item_texts[${i}]}"${codeNL}
prev_depth="${curr_depth}"
done
SHELL_MD_READI_RESULT_FORMAT_LIST_BLOCK="${output}"
}


declare -g SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK=""
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


shell_md_readi() {
local source_path="${1:-}"
local target_path="${2:-}"
local source_file=""
local target_file=""
local rel_path=""
local -a source_files=()
if [ -z "${source_path}" ]; then
printf "[ERR] :: Missing source path. Provide a file or directory.\n" >&2
return 1
fi
if [ ! -e "${source_path}" ]; then
printf "[ERR] :: Source path '%s' does not exist.\n" "${source_path}" >&2
return 1
fi
if [ -f "${source_path}" ]; then
if [[ ! "${source_path}" =~ \.md$ ]]; then
printf "[ERR] :: Source file '%s' is not a Markdown (.md) file.\n" "${source_path}" >&2
return 1
fi
if [ -z "${target_path}" ]; then
target_file="${source_path}"
else
if [ -d "${target_path}" ]; then
printf "[ERR] :: Second argument must be a file path when source is a file.\n" >&2
return 1
fi
target_file="${target_path}"
fi
shell_md_readi_process_file "${source_path}" "${target_file}"
return 0
fi
if [ -d "${source_path}" ]; then
shopt -s globstar nullglob
for source_file in "${source_path}"/**/*.md; do
source_files+=("${source_file}")
done
shopt -u globstar nullglob
if [ "${#source_files[@]}" -eq 0 ]; then
printf "[ ! ] :: No Markdown (.md) files found under '%s'.\n" "${source_path}"
return 0
fi
if [ -n "${target_path}" ]; then
if [ -e "${target_path}" ] && [ ! -d "${target_path}" ]; then
printf "[ERR] :: Second argument must be a directory path when source is a directory.\n" >&2
return 1
fi
mkdir -p "${target_path}"
fi
for source_file in "${source_files[@]}"; do
if [ -z "${target_path}" ]; then
target_file="${source_file}"
else
rel_path="${source_file#"${source_path}"/}"
target_file="${target_path}/${rel_path}"
fi
shell_md_readi_process_file "${source_file}" "${target_file}"
done
return 0
fi
printf "[ERR] :: Unsupported source path '%s'.\n" "${source_path}" >&2
return 1
}
shell_md_readi_process_file() {
local source_file="${1:-}"
local target_file="${2:-}"
local raw_content=""
local canonical_content=""
local final_output=""
if [ -z "${source_file}" ]; then
printf "[ERR] :: Missing source file.\n" >&2
return 1
fi
if [ -z "${target_file}" ]; then
printf "[ERR] :: Missing target file.\n" >&2
return 1
fi
raw_content="$(cat "${source_file}")"
shell_md_readi_canonize "${raw_content}"
shell_md_readi_parse "${SHELL_MD_READI_RESULT_CANONIZE}"
shell_md_readi_format "${SHELL_MD_READI_RESULT_CANONIZE}"
mkdir -p "$(dirname "${target_file}")"
printf '%s' "${SHELL_MD_READI_RESULT_FORMAT}" > "${target_file}"
}


shell_md_readi_parse() {
local canonical_content="${1:-}"
local current_line=""
local line_number=0
local block_id=0
local active_state="FREE"
local block_start_line=0
local current_zone_has_sep=0
local last_relevant_structure=""
local trimmed_line=""
local n_count=0
SHELL_MD_READI_BLOCK_TYPE=()
SHELL_MD_READI_BLOCK_START=()
SHELL_MD_READI_BLOCK_END=()
SHELL_MD_READI_BLOCK_LINES=()
SHELL_MD_READI_BLOCK_HAS_SEP=()
SHELL_MD_READI_BLOCK_LAST_RELEVANT=()
while IFS= read -r current_line || [ -n "${current_line}" ]; do
((line_number++))
trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"
trimmed_line="${trimmed_line%"${trimmed_line##*[![:space:]]}"}"
if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_CODE_BLOCK} ]]; then
if [ "${active_state}" != "FREE" ] && [ "${active_state}" != "CODE_BLOCK" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
fi
if [ "${active_state}" = "CODE_BLOCK" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="CODE_BLOCK"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line + 1))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="CODE_BLOCK"
((block_id++))
active_state="FREE"
else
active_state="CODE_BLOCK"
block_start_line="${line_number}"
fi
continue
fi
if [ "${active_state}" = "CODE_BLOCK" ]; then
continue
fi
if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_NBSP_META} ]]; then
n_count="${BASH_REMATCH[2]}"
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
active_state="FREE"
fi
if [ "${n_count}" -gt 0 ]; then
current_zone_has_sep=1
fi
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="NBSP_BLOCK"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]="${current_zone_has_sep}"
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
((block_id++))
continue
fi
if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_HEADER} ]]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
active_state="FREE"
fi
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="HEADER"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]="${current_zone_has_sep}"
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="HEADER"
((block_id++))
current_zone_has_sep=0
continue
fi
if [ -z "${trimmed_line}" ]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
active_state="FREE"
fi
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="EMPTY_LINE"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
((block_id++))
continue
fi
current_zone_has_sep=0
if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_SEPARATOR} ]]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
active_state="FREE"
fi
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="SEPARATOR"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
((block_id++))
continue
fi
if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_BLOCKQUOTE} ]]; then
if [ "${active_state}" != "BLOCKQUOTE" ]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
fi
active_state="BLOCKQUOTE"
block_start_line="${line_number}"
fi
continue
fi
if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_HTML_BLOCK} ]]; then
if [ "${active_state}" != "HTML_BLOCK" ]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
fi
active_state="HTML_BLOCK"
block_start_line="${line_number}"
fi
continue
fi
if [[ "${current_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_TABLE} ]]; then
if [ "${active_state}" != "TABLE" ]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
fi
active_state="TABLE"
block_start_line="${line_number}"
fi
continue
fi
if [[ "${trimmed_line}" =~ ${SHELL_MD_READI_PARSE_REGEX_LIST} ]]; then
if [ "${active_state}" != "LIST" ]; then
if [ "${active_state}" != "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]=$((line_number - 1))
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
last_relevant_structure="${active_state}"
((block_id++))
fi
active_state="LIST"
block_start_line="${line_number}"
fi
continue
fi
if [ "${active_state}" = "FREE" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="PARAGRAPH"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=1
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
if [ "${block_id}" -gt 0 ] && [ "${SHELL_MD_READI_BLOCK_TYPE["$((block_id - 1))"]}" = "PARAGRAPH" ]; then
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="SAME_PARAGRAPH"
else
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
fi
last_relevant_structure="PARAGRAPH"
((block_id++))
fi
done <<< "${canonical_content}"
if [ "${active_state}" != "FREE" ] && [ "${active_state}" != "CODE_BLOCK" ]; then
SHELL_MD_READI_BLOCK_TYPE["${block_id}"]="${active_state}"
SHELL_MD_READI_BLOCK_START["${block_id}"]="${block_start_line}"
SHELL_MD_READI_BLOCK_END["${block_id}"]="${line_number}"
SHELL_MD_READI_BLOCK_LINES["${block_id}"]=$((line_number - block_start_line + 1))
SHELL_MD_READI_BLOCK_HAS_SEP["${block_id}"]=0
SHELL_MD_READI_BLOCK_LAST_RELEVANT["${block_id}"]="${last_relevant_structure}"
fi
}


if [ "${BASH_SOURCE}" = "${0}" ]; then
for arg in "$@"; do
if [[ "${arg}" == -* ]]; then
case ${arg} in
-h|--help)
shell_formatter_help
exit $?
;;
esac
fi
done
shell_md_readi "$@"
fi
