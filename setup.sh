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
# - Instalation
# ------------------------------

# Include the installation file within your ~/.bash_profile or ~/.bashrc file
# source <path_to_gitlib>/install.sh

# You can also add configuration commands, such as:
# gconfig loglevel debug

# - Sources
# --------------------

GL_DEBUG_MODE_ENABLED=false
GL_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$GL_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    GL_SOURCE="$(readlink "$GL_SOURCE")"
done
GL_SOURCE_DIR="$( dirname "$GL_SOURCE" )/src"

if [ -d "$GL_SOURCE_DIR" ]; then
	source $GL_SOURCE_DIR/vendors/select_options.sh
	source $GL_SOURCE_DIR/gitlib_utils.sh
	source $GL_SOURCE_DIR/gitlib.sh
else
	echo "[ERROR] GitLib could not be loaded. Unable to locate source directory: \"$GL_SOURCE_DIR\""
fi

# Further configurations are not necessary
# For more information see the README.md
