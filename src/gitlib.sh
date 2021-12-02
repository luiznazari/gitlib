#!/usr/bin/env bash
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.1-SENIOR
# - 
# - Author: Luiz Felipe Nazari
# -         luiz.nazari.42@gmail.com
# -         luiz.nazari@senior.com.br
# - All rights reserved.
# - 
# --------------------------------------------------------------------------------

# ------------------------------
# - GitLib
# ------------------------------

# - Global Variables
# --------------------

GL_LOGLEVEL=2 #INFO

# - Commands
# --------------------

gcommit() {
	branch=$(_get_current_git_branch);
	commit_message="${@: -1}" # get last argument only
	commit_task_prefix=""
	yesToAll=false
	
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
    	return "1"

    else
		auto_push=false
		stagged_only=false

		let "OPTIND = 1";
		while getopts "P:spym:" opcao
		do
			case "$opcao" in
				"P") commit_task_prefix="$OPTARG" ;;
				"s") stagged_only=true ;;
				"p") auto_push=true ;;
				"m") commit_message="$OPTARG" ;;
				"y") yesToAll=true ;;
				"?") _log warn "Unknown option \"$OPTARG\"" ;;
				":") _log err "Arguments not specified for option \"$OPTARG\"" ;;
			esac
		done

		if [ -z "$commit_message" ]; then
			_log err "Please, insert a message to confirm the commit"
			return "1"

		elif ! _do_commit "$commit_message" "$commit_task_prefix" $stagged_only $yesToAll; then
			return "1"

		fi

		if [ "$auto_push" = true ]; then
			gpush "$branch"
		fi
		
	fi
	
	return "0"
}

gpull() {
	branch_to_pull=""

	let "OPTIND = 1";
	while getopts "lo" opcao
	do
		case "$opcao" in
			"l")
				if ! _choose_branch branch_to_pull ; then
					return $?
				fi
				;;
			"o")
				branch_to_pull="." # origin
				;;
		esac
	done

	if [ -z "$branch_to_pull" ]; then
		if [ $# -eq 1 ]; then
			branch_to_pull="$1"
		else
			branch_to_pull=$(_get_current_git_branch)
		fi
	fi

    if [ "$branch_to_pull" == "." ]; then
        _log debug "Pulling from origin"
        _log debug "git pull origin"

		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
        	git pull origin
		fi
    else
        _log debug "Pulling from branch $branch_to_pull"
        _log debug "git pull origin $branch_to_pull"

		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
        	git pull origin "$branch_to_pull"
		fi
    fi
}

gpush() {
	branch_to_push=""

	let "OPTIND = 1";
	while getopts "l" opcao
	do
		case "$opcao" in
			"l")
				if ! _choose_branch branch_to_push ; then
					return $?
				fi
				;;
		esac
	done

	if [ -z "$branch_to_push" ]; then
		if [ $# -eq 1 ]; then
			branch_to_push="$1"
		else
			branch_to_push=$(_get_current_git_branch)
		fi
	fi
	
	_log debug "Pushing to branch $branch_to_push"
	_log debug "git push origin $branch_to_push"
	
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git push origin "$branch_to_push"
	fi
}

# -l: choose branch to checkout
gout() {
	branch_to_checkout=""
	branch_to_checkout_prefix=""
	new_branch=false

	let "OPTIND = 1";
	while getopts "lbfrh" opcao
	do
		case "$opcao" in
			"l") 
				if ! _choose_branch branch_to_checkout ; then
					return $?
				fi
				;;
			"b") 
				new_branch=true
				;;
			"f")
				branch_to_checkout_prefix="feature/"
				;;
			"r")
				branch_to_checkout_prefix="release/"
				;;
			"h")
				branch_to_checkout_prefix="hotfix/"
				;;
		esac
	done

	if [ -z "$branch_to_checkout" ]; then
		if [ -z "$1" ]; then
			_log err "Branch name not specified"
			return 1;
		else 
			branch_to_checkout="${@: -1}" # get last argument only
		fi
	fi

	branch_to_checkout="$branch_to_checkout_prefix$branch_to_checkout"

	if [ "$new_branch" = true ]; then
		_log info "Switching current branch to new branch $branch_to_checkout"
		_log debug "git checkout -b $branch_to_checkout"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout -b "$branch_to_checkout"
		fi
	else
		_log info "Switching current branch to $branch_to_checkout"
		_log debug "git checkout $branch_to_checkout"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout "$branch_to_checkout"
		fi
	fi

}

# -l: choose branch to merge
gmerge() {
	current_branch=$(_get_current_git_branch)
	branch_to_merge=""

	if [ -z "$current_branch" ]; then
        _log err "Current directory is not a git repository"
	fi

	let "OPTIND = 1";
	while getopts "l" opcao
	do
		case "$opcao" in
			"l") 
				if ! _choose_branch branch_to_merge ; then
					return $?
				fi
				;;
		esac
	done

	if [[ -z "$branch_to_merge" && $# -eq 1 && "$1" != "-l" ]]; then
		branch_to_merge="$1"
	fi

	if [ -z "$branch_to_merge" ]; then
		_log err "Branch to merge not specified"
		return 1;
	fi

	_log info "Step 1: Pulling from current branch..."
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		gpull
	fi
	
	_log info "Step 2: Merging $branch_to_merge -> $current_branch"
	_log debug "git merge $branch_to_merge"
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git merge "$branch_to_merge"
	fi
}

gstatus() {
    _log debug "git status"
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git status
	fi
}

glog() {
	all_authors=false
	
	let "OPTIND = 1";
	while getopts "a" opcao
	do
		case "$opcao" in
			"a") all_authors=true ;;
		esac
	done

	git_username=""
	if [ "$all_authors" = false ]; then
		git_username="$(git config user.name)"
	fi

	date_format="%d/%m/%Y-%H:%M:%S"
	log_format="%C(yellow)%h%x20%Cgreen%an%Creset%x20%ad%x20%n%s%n"

	_log debug "git log --author=\"$git_username\" --pretty=format:\"$log_format\" --date=format:\"$date_format\""
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git log --author="$git_username" --pretty=format:"$log_format" --date=format:"$date_format"
	fi
}

gbranch() {
	delete_local=false
	delete_remote=false

	let "OPTIND = 1";
	while getopts "dD" opcao
	do
		case "$opcao" in
			"d" )
				delete_local=true
				echo -e "Which branch do you want do delete ${GL_BOLD}LOCALLY${GL_NO_COLOR}?"
				if _choose_branch selected_branch ; then
					_log debug "git branch -d $selected_branch"
					if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
						git branch -d "$selected_branch"
					fi
				fi
				;;
			"D" )
				delete_remote=true
				echo -e "Which branch do you want do delete ${GL_BOLD}REMOTELY${GL_NO_COLOR}?"
				if _choose_branch selected_branch ; then
					if _yes_no "Are you sure you want to delete remote branch "$selected_branch"? This action cannot be undone."; then
						_log debug "git push origin --delete $selected_branch"
						if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
							git push origin --delete "$selected_branch"
						fi
					else
						_log warn "Remote branch deletion aborted."
					fi
				fi
				;;
			"?" ) _log warn "Unknown option \"$OPTARG\"" ;;
			":" ) _log err "Arguments not specified for option \"$OPTARG\"" ;;
		esac
	done

	if [ "$delete_local" = false ] && [ "$delete_remote" = false ]; then
		_log debug "git branch --list --all"
		git branch --list --all
	fi
}

# Undo all local commits and changes (stagged and unstagged). 
greset() {
	continue_msg="(y/n)"
	echo "Are you sure you want to discard all local stagged and unstagged changes? This action cannot be undone. $continue_msg"

	while true; do
		read -p "> " response

		if [[ $response =~ ^[YySs]$ ]]; then
			_log debug "git checkout ."
			_log debug "git reset ."
			_log debug "git reset --hard HEAD"

			if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
				git checkout . 
				git reset .
				git reset --hard HEAD
			fi
			break

		elif [[ $response =~ ^[Nn]$ ]]; then
			_log warn "Reset aborted"
			return "1"
		fi

		echo $continue_msg
	done
}

# - Configurations
# --------------------

gconfig() {
	 case $1 in
		loglevel )
            case $2 in
                err* )   let "GL_LOGLEVEL = 0" ;;
                war* )   let "GL_LOGLEVEL = 1" ;;
                inf* )   let "GL_LOGLEVEL = 2" ;;
                debug* ) let "GL_LOGLEVEL = 3" ;;
                *) _log err "Log level must be: error/err, warn/war, info/inf or debug."
            esac
            ;;

        debug-mode )
            if [[ "$2" = false ]] || [[ "$2" = true ]]; then
                GL_DEBUG_MODE_ENABLED=$2
            fi
            ;;
            
		*) _log err "Configuration \"$1\" not found" ;;
	esac
}
