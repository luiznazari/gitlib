#!/usr/bin/env bash
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.3
# - 
# - Author: Luiz Felipe Nazari
# -         luiz.nazari.42@gmail.com
# - All rights reserved.
# - 
# --------------------------------------------------------------------------------

# ------------------------------
# - Utility
# ------------------------------

# - Constants
# --------------------

GL_NO_COLOR="\033[0m"
GL_BOLD="\033[1m"
GL_RED="\033[0;31m"
GL_GREEN="\033[0;32m"
GL_CYAN="\033[0;36m"
GL_YELLOW="\033[1;33m"

# - General functions
# --------------------

_log() {
    case $1 in
		err* )   str="ERROR"; level=0; logColor=$GL_RED; shift ;;
		war* )   str="WARN "; level=1; logColor=$GL_YELLOW; shift ;;
		inf* )   str="INFO "; level=2; logColor=$GL_GREEN; shift ;;
		debug* ) str="DEBUG"; level=3; logColor=$GL_CYAN; shift ;;
        *)       str=" G L "; level=0; logColor=$GL_NO_COLOR ;;
    esac
    
    if [ $GL_LOGLEVEL -ge $level ]; then
        printf '[%s] %b%s%b\n' "$str" "$logColor" "$*" "$GL_NO_COLOR"
    fi
}

_getopts() {
    echo "$@" | sed -E 's/(^|[[:space:]])[[:alpha:]]+//g'
}

_gl_read_line() {
    if ! _gl_is_interactive; then
        _log err "Interactive input required but stdin is not a terminal."
        return 1
    fi
    printf '%s' "$1"
    IFS= read -r GL_READ_RESULT
}

_gl_is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

# Returns the current branch name. e.g.: master
_get_current_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

_hasUnpushedCommitsFor() {
    [[ -n "$(git diff origin/HEAD..$1)" ]] && return 0 || return 1
}

_hasUnpushedCommits() {
    branch="$(_get_current_git_branch)"
    return $(_hasUnpushedCommitsFor $branch)
}

# args:
# 	$1 - [Optional] the text complement for the confirm question
_check_if_path_is_repository_root_and_confirm() {
	if _check_if_path_is_repository_root; then
		messageComplement="$1"
		if [ -n "$1" ]; then
			messageComplement=", $1"
		fi

		if _yes_no "You are not on REPOSITORY ROOT directory$messageComplement. Confirm operation?"; then
			return 0
		else 
			return 1
		fi
	fi
}

_check_if_path_is_repository_root() {
	repositoryRootDir="$(git rev-parse --show-toplevel)"

	# Fix for GitForWindows compatibility, transforms "C:/path/repo" into "/c/path/repo"
	case "$repositoryRootDir" in
		[A-Z]:/*)
			drive_letter="$(printf '%s' "${repositoryRootDir%%:*}" | tr 'A-Z' 'a-z')"
			repositoryRootDir="/$drive_letter/${repositoryRootDir#?:/}"
			;;
	esac

	[[  "$repositoryRootDir" != "$PWD" ]] && return 0 || return 1
}

# args:
# 	$1 - the text to be trimmed
_trim() {
    local text="$*"
    # remove leading whitespace characters
    text="${text#"${text%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    text="${text%"${text##*[![:space:]]}"}"   
    printf '%s' "$text"
}

# if _yes_no "message"; then
#	[...]
# fi
_yes_no() {
    # input_message="Deseja Prosseguir? (y/n)`echo $'\n> '`"
    # read -p "Mensagem. $input_message" input
    retval=0
    
	printf '%s\n' "$1 (y/n)"
    while true; do
		_gl_read_line "> " || return 1
		response="$GL_READ_RESULT"
        case $response in
            [SsYy] ) retval=0; break;;
            [Nn] ) retval=1; break;;
            *) printf '\n'
        esac

		printf '%s\n' "Confirm? (y/n)"
    done
    
    printf '\n' # quebra de linha para próximos comandos
    return "$retval"
}

# - Functions
# --------------------

# args:
# 	$1 - commit message
#   $2 - commit task prefix
# 	$3 - commits only already stagged files
#   $4 - yess to all
_do_commit() {
	commit_message="$1"
	commit_task_prefix="$2"
	stagged_only=$3
	yesToAll=$4
	aborted=false

	# Auxiliar funcions are declared internally due to "returned values" and "echo" calls.
	# If functions are called inside a command substituion, echoed messages cannot be seen.

	_format_commit_message() {
		commit_refs=""

		_extract_task_data_from_branch() {
			branch_name="$1"
			extracted_prefix=""
			extracted_ids=""
			path_part=""

			case "$branch_name" in
				*b_task_*)
					extracted_ids="${branch_name#*b_task_}"
					;;
				release/*)
					# release branches do not force refs
					;;
				b_*_*)
					path_part="${branch_name#b_}"
					extracted_prefix="${path_part%%_*}"
					extracted_ids="${path_part#*_}"
					case "$extracted_prefix:$extracted_ids" in
						*[![:alnum:]]*:*|*:*[![:digit:]]*)
							extracted_prefix=""
							extracted_ids=""
							;;
					esac
					;;
				*/*-*)
					path_part="${branch_name#*/}"
					extracted_prefix="${path_part%%-*}"
					rest_part="${path_part#*-}"
					extracted_ids="${rest_part%%-*}"

					case "$extracted_prefix" in
						""|*[![:alpha:]]) extracted_prefix="" ;;
					esac

					case "$extracted_ids" in
						""|*[![:alnum:]]) extracted_ids="" ;;
					esac

					if [ -z "$extracted_prefix" ] || [ -z "$extracted_ids" ]; then
						extracted_prefix=""
						extracted_ids=""
					fi
					;;
				*/*)
					path_part="${branch_name#*/}"
					case "$path_part" in
						*[!A-Za-z0-9_-]*|"")
							;;
						*)
							extracted_ids="$path_part"
							;;
					esac
					;;
			esac

			printf '%s|%s\n' "$extracted_prefix" "$extracted_ids"
		}

		_request_task_id() {
			branch=$(_get_current_git_branch)
			task_ids=""

			extracted_branch_data="$(_extract_task_data_from_branch "$branch")"
			if [ -z "$commit_task_prefix" ]; then
				commit_task_prefix="${extracted_branch_data%%|*}"
			fi
			task_ids="${extracted_branch_data#*|}"

			# -- Prompt commit_task_prefix --
			if [ "$yesToAll" = true ]; then
				commit_task_prefix=""

			elif [ -z "$commit_task_prefix" ]; then
			
				continue_msg="Continue? (y/n/task prefix)"
				printf '%s\n' "The TASK PREFIX could not be determined. $continue_msg"
				while true; do
					_gl_read_line "> " || return 1
					response="$GL_READ_RESULT"

					if [[ $response =~ ^[YySs]$ ]]; then
						commit_task_prefix=""
						break

					elif [[ $response =~ ^[Nn]$ ]]; then
						aborted=true
						return "1"

					elif [[ $response =~ ^[[:alnum:]]+$ ]]; then
						commit_task_prefix="$response"
						break
					fi

					printf '%s\n' "$continue_msg"
				done
				
			fi

			# -- Prompt task_ids --
			if [ "$yesToAll" = true ]; then
				task_ids=""

			elif [ -z "$task_ids" ]; then
			
				continue_msg="Continue? (y/n/comma separated task numbers)"
				printf '%s\n' "The TASK NUMBER(S) could not be determined. $continue_msg"
				while true; do
					_gl_read_line "> " || return 1
					response="$GL_READ_RESULT"

					if [[ $response =~ ^[YySs]$ ]]; then
						task_ids=""
						break

					elif [[ $response =~ ^[Nn]$ ]]; then
						aborted=true
						return "1"

					elif [[ $response =~ ^[[:digit:][:space:],]{1,}$ ]]; then
						task_ids="$response"
						break
					fi

					printf '%s\n' "$continue_msg"
				done
				
			fi
			# -- --------------- --

			commit_refs=$(_format_tasks_message "$commit_task_prefix" "$task_ids")
		}

		_request_commit_hash() {
			hash=""
			continue_msg="Continue? (n/commit hash)"
			printf '%s\n' "Insert the commit hash (SHA1 ID). $continue_msg"

			while true; do
				_gl_read_line "> " || return 1
				response="$GL_READ_RESULT"

				if [[ -z $response ]]; then
					continue
				
				elif [[ $response =~ ^[Nn]$ ]]; then
					aborted=true
					return "1"
					
				else
					hash=$response
					break
				fi

				printf '%s\n' "$continue_msg"
			done

			commit_refs="$hash"
		}

		_request_task_id

		if [ -n "$commit_refs" ]; then
			commit_message="[$commit_refs]: $commit_message"
		fi
	}

	# Commit logic:

	# Outputs to 'commit_message'
	_format_commit_message "$1"

	if [ "$aborted" = true ]; then
		_log warn "Commit aborted"
		return "1"
	fi

	if [ "$stagged_only" = false ]; then
		_log debug "Commiting unstagged, stagged and new files"
		_log debug "git add ."
	else
		_log debug "Commiting stagged files"
	fi
	_log debug "git commit -m \"$commit_message\""
	
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		if [ "$stagged_only" = false ]; then
			git add .
		fi
		git commit -m "$commit_message"
	fi
	
	#Returns the exit status of "git commit"
	return "$?"
}

# args:
# 	$1 - task prefix
# 	$2 - comma separated string containing the task numbers
_format_tasks_message() {
	tasks_message=""
	task_prefix=""
	task_ids=""

	if [ -z "$2" ]; then
		tasks_message="$1"
	else
		task_ids="$2"
		if [ -z "$1" ]; then
			task_prefix=""
		else
			task_prefix="$1-"
		fi

		old_ifs="$IFS"
		IFS=','
		set -- $task_ids
		IFS="$old_ifs"
		for task_id in "$@"; do
			tasks_message+="$task_prefix$(_trim $task_id) "
		done
	fi

	printf '%s\n' "$(_trim "$tasks_message")"
}

# args:
#   $1 - [Optional] filter string
# Returns a string containing known branches separated by space.
_get_git_branches_str() {
	LINE_BREAK='
'
	# Returns all remote branches, one by line, removes first line 'HEAD',
	# then replaces spaces (followed by origin/) and '*' character (current branch identifier).
	remote_branches=$(git branch --list --remote | sed -e '1d' | sed -E 's/(^\*|[[:space:]](origin\/)?)//g')
	local_branches=$(git branch --list --all | sed -E 's/(^\*|[[:space:]](remotes\/origin\/.*)?|HEAD[[:space:]]->.*)//g')

	# Join remote and local branches
	branches="$remote_branches$LINE_BREAK$local_branches"

	# Remove duplicates, filter and sort
	if [ -n "$1" ]; then
		branches=$(printf '%s\n' "$branches" | grep "$1" | sort -u)
	else
		branches=$(printf '%s\n' "$branches" | sort -u)
	fi

	# Replaces all line breaks by space, thus, resulting in an string with branches separated by space.
	printf '%s' "$branches" | tr '\n' ' '
}

# $1 - variable to write branch name to
# $2 - filter
_choose_branch() {
	cancel_option="--CANCEL--"
	branches_str="$(_get_git_branches_str "$2") $cancel_option"

	if [ "$branches_str" == "  --CANCEL--" ]; then
		_log warn "No branch found"
		return 1;
	fi

	_select_option $branches_str
	selected_option=$?

	branches_array=($branches_str)
	if [ -n "$ZSH_VERSION" ]; then
		selected_branch="${branches_array[$((selected_option + 1))]}"
	else
		selected_branch="${branches_array[$selected_option]}"
	fi
	unset branches_array

	if [ "$selected_branch" == "$cancel_option" ]; then
		return 1;
	elif [ -n "$1" ]; then
		eval "$1=\"\$selected_branch\""
	else
		printf '%s\n' "$selected_branch"
	fi
}
