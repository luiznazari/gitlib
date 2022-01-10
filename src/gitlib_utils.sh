#!/usr/bin/env bash
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.2-SENIOR
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
        echo -e "[$str] $logColor$@$GL_NO_COLOR"
    fi
}

_getopts() {
    echo "$@" | sed -E 's/(^|[[:space:]])[[:alpha:]]+//g'
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
		if _yes_no "You are not on repository root directory$messageComplement. Confirm operation?"; then
			return 0
		else 
			return 1
		fi
	fi
}

_check_if_path_is_repository_root() {
	repositoryRootDir="$(git rev-parse --show-toplevel)"

	# Fix for GitForWindows compatibility, transforms "C:/path/repo" into "/c/path/repo"
	repositoryRootDir="$(echo "$repositoryRootDir" | sed  -E "s/^([A-Z]):\//\/\L\1\//")"

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
    echo -n "$text"
}

# if _yes_no "message"; then
#	[...]
# fi
_yes_no() {
    # input_message="Deseja Prosseguir? (y/n)`echo $'\n> '`"
    # read -p "Mensagem. $input_message" input
    retval=0
    
	echo "$1 (y/n)"
    while true; do
        read -p "> " response
        case $response in
            [SsYy] ) retval=0; break;;
            [Nn] ) retval=1; break;;
            *) echo ""
        esac

		echo "Confirm? (y/n)"
    done
    
    echo "" # quebra de linha para próximos comandos
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

		_request_task_id() {
			branch=$(_get_current_git_branch)
			task_ids=""

			if [[ $branch == *b_task_* ]]; then
				task_ids="${branch#*b_task_}"

			elif [[ $branch =~ ^release\/(.*) ]]; then
				commit_task_prefix=""
				task_ids=""

			elif [[ $branch =~ ^b_([[:alnum:]]+)_([[:digit:]]+)$ || $branch =~ ^[[:alpha:]]+\/([[:alnum:]]+)-([[:digit:]]+)$ ]]; then
				commit_task_prefix="${BASH_REMATCH[1]^^}" ## ^^ = to uppercase
				task_ids="${BASH_REMATCH[2]}"

			elif [[ $branch =~ ^[[:alpha:]]+\/([A-Za-z0-9_-]+)$ ]]; then
				task_ids="${BASH_REMATCH[1]}"

			fi

			# -- Prompt commit_task_prefix --
			if [ "$yesToAll" = true ]; then
				commit_task_prefix=""

			elif [ -z "$commit_task_prefix" ]; then
			
				continue_msg="Continue? (y/n/task prefix)"
				echo "The TASK PREFIX could not be determined. $continue_msg"
				while true; do
					read -p "> " response

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

					echo $continue_msg
				done
				
			fi

			# -- Prompt task_ids --
			if [ "$yesToAll" = true ]; then
				task_ids=""

			elif [ -z "$task_ids" ]; then
			
				continue_msg="Continue? (y/n/comma separated task numbers)"
				echo "The task NUMBER(S) could not be determined. $continue_msg"
				while true; do
					read -p "> " response

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

					echo $continue_msg
				done
				
			fi
			# -- --------------- --

			commit_refs=$(_format_tasks_message "$commit_task_prefix" "$task_ids")
		}

		_request_commit_hash() {
			hash=""
			continue_msg="Continue? (n/commit hash)"
			echo "Insert the commit hash (SHA1 ID). $continue_msg"

			while true; do
				read -p "> " response

				if [[ -z $response ]]; then
					continue
				
				elif [[ $response =~ ^[Nn]$ ]]; then
					aborted=true
					return "1"
					
				else
					hash=$response
					break
				fi

				echo $continue_msg
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

		IFS=',' read -ra task_id_array <<< "$task_ids"
		for task_id in "${task_id_array[@]}"; do
			tasks_message+="#$task_prefix$(_trim $task_id) "
		done
	fi

	expr "$(_trim $tasks_message)"
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
	expr "$branches" | tr '\n' ' '
}

# $1 - variable to write branch name to
# $2 - filter
_choose_branch() {
	cancel_option="--CANCEL--"
	branches_str="$(_get_git_branches_str "$2") $cancel_option"

	_log debug "-$branches_str-"
	if [ "$branches_str" == "  --CANCEL--" ]; then
		_log warn "No branch found"
		return 1;
	fi

	_select_option $branches_str
	selected_option=$?

	branches_array=($branches_str)
	selected_branch="${branches_array[selected_option]}"
	unset branches_array

	if [ "$selected_branch" == "$cancel_option" ]; then
		return 1;
	elif [ -n "$1" ]; then
		read -ra $1 <<< "$selected_branch"
	else
		expr "$selected_branch"
	fi
}