#!/usr/bin/sh
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.0
# - 
# - Author: Luiz Felipe Nazari
# -        luiz.nazari.42@gmail.com
# - All rights reserved.
# - 
# --------------------------------------------------------------------------------

# ------------------------------
# - GitLib
# ------------------------------

# - Constants
# --------------------

GL_REFS_STRING="refs #0000"
GL_REFS_REGEX="refs[[:space:]]+#[[:digit:]]*[^[:alpha:]]"

# - Commands
# --------------------

gcommit() {
	branch=$(_get_curr_branch);
	args=${@##-*}
		
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
    	return "1"
		
    elif [ -z "$args" ]; then
        _log err "Please, insert a message to confirm the commit"
		return "1"
		
    else
		if ! _do_commit "$branch" "$args"; then
			return "1"
		fi
		
		let "OPTIND = 1";
		while getopts "p" opcao
		do
			case "$opcao" in
				"p") gpush "$branch" ;;
				"?") _log warn "Unknown option \"$OPTARG\"" ;;
				":") _log err "Arguments not specified for option \"$OPTARG\"" ;;
			esac
		done
		
	fi
	
	return "0"
}

gpull() {
	if [ $# -eq 1 ]; then
		branch="$1"
	else
		branch=$(_get_curr_branch)
	fi
	
	_log debug "Pulling from branch $branch"
	_log debug "git pull origin $branch"
	
	git pull origin "$branch"
}

gpush() {
	if [ $# -eq 1 ]; then
		branch="$1"
	else
		branch=$(_get_curr_branch)
	fi
	
	_log debug "Pushing to branch $branch"
	_log debug "git push origin $branch"
	
	git push origin "$branch"
}

gout() {
	if [ $# -eq 1 ]; then
        _log debug "Switching current branch to $1"
        _log debug "git checkout $1"
		git checkout "$1"
        
	elif [ $# -eq 2 ]; then
        _log debug "Switching current branch to $2"
        _log debug "git checkout $1 $2"
		git checkout "$1" "$2"
        
	else
		_log err "Branch name not specified"
	fi
}

gmerge() {
	branch=$(_get_curr_branch)
	
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
		
	elif [[ $# -gt 0 && -n $1 ]]; then
		_log info "Step 1: Pulling from current branch..."
		gpull
		
		_log info "Step 2: Merging $1 -> $branch"
		_log debug "git merge $1"
		git merge "$1"
		
	else
		_log err "Branch name not specified"
	fi
}

gstatus() {
    _log debug "git status"
	git status
}

# - Functions
# --------------------

_do_commit() {
	comentario=$(_commit_refs $1 "$2")

	if ! [[ $comentario =~ $GL_REFS_REGEX ]]; then
	
		while true; do
            echo -e "The commit does not refers to a task, e.g.: \"$GL_REFS_STRING\". Continue? (y/n/task number)"
			read -p "> " response

			if [[ $response =~ ^[YySs]$ ]]; then
				break
				
			elif [[ $response =~ ^[Nn]$ ]]; then
				_log warn "Commit cancelado"
				return "1"

			elif [[ $response =~ ^[[:digit:]]{1,}$ ]]; then
				comentario=$(_commit_refs "b_task_$response" "$2")
				break
			fi
		done
		
	fi

	_log debug "Commiting all files"
	_log debug "git add ."
	_log debug "git commit -m \"$comentario\""
	
	git add .
	git commit -m "$comentario"
	
	#Returns the exit status of "git commit"
	return "$?"
}

_commit_refs() {
	if [[ $1 == *b_task_* ]]; then
        task="${1#*b_task_}"
		commitRefs="${GL_REFS_STRING/\#[[:digit:]]*/#$task/}"
        
	elif [[ $1 == *b_* ]]; then
		commitRefs="${1#*b_}"
        
	else
		commitRefs="$1"
	fi
    
    expr "$commitRefs [$2]"
}
