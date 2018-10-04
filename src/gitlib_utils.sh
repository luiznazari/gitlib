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
# - Utility
# ------------------------------

# - Constants
# --------------------

GL_NO_COLOR="\033[0m"
GL_RED="\033[0;31m"
GL_GREEN="\033[0;32m"
GL_CYAN="\033[0;36m"
GL_YELLOW="\033[1;33m"

GL_LOGLEVEL=2

# - Configurations
# --------------------

gconfig() {
	 case $1 in
        refs-string )
            if [ -z "$2" ]; then
                _log err "\"$2\" is not a valid task-reference string"

			elif [ -z "$3" ]; then
                _log err "\"$3\" is not a valid regex"
				
            elif ! [[ "$2" =~ $3 ]]; then
                _log err "\"$3\" does not match with the task-reference string \"$2\""

			else
				GL_REFS_STRING="$2"
                GL_REFS_REGEX="$3"
            fi
        	;;
			
		loglevel )
            case $2 in
                err* )   let "GL_LOGLEVEL = 0" ;;
                war* )   let "GL_LOGLEVEL = 1" ;;
                inf* )   let "GL_LOGLEVEL = 2" ;;
                debug* ) let "GL_LOGLEVEL = 3" ;;
                *) _log err "Log level must be: error, warn, info or debug."
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

# - Functions
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
_get_curr_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

_hasUnpushedCommitsFor() {
    [[ -n "$(git diff origin/HEAD..$1)" ]] && return 0 || return 1
}

_hasUnpushedCommits() {
    branch="$(_get_curr_branch)"
    return $(_hasUnpushedCommitsFor $branch)
}

# defazer commit local
# git reset --soft head~1; git reset .;git checkout . 
