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
# - Help and  Documentation.
# ------------------------------

# TODO alterar para outro arquivo
# TODO atualizar
# TODO traduzir
ghelp() {
	echo -e "Biblioteca de funções de comandos básicos do git.\n"
	echo "# gstatus"
	echo -e "  - Realiza o comando 'git status'\n"
	echo "# gpull"
	echo "  - Realiza o comando 'git pull origin' com a branch atual"
	echo "  - Parâmetros:"
	echo -e "      1. [Opcional] Nome da branch\tgpull nome_branch\n"
	echo "# gpush"
	echo "  - Realiza o comando 'git push origin' com a branch atual"
	echo "  - Parâmetros:"
	echo -e "      1. [Opcional] Nome da branch\tgpush nome_branch\n"
	echo "# gmerge"
	echo -e "  - Chama a função gpull para a branch atual e, então,\n    realiza o comando 'git merge' com a branch especificada"
	echo "  - Parâmetros:"
	echo -e "      1. Nome da branch\t\t\tgmerge nome_branch\n"
	echo "# gout"
	echo "  - Realiza o comando 'git checkout' com a branch especificada"
	echo "  - Parâmetros:"
	echo -e "      1. Nome da branch\t\t\tgout nome_branch"
	echo -e "      2. Comando + Nome da branch\tgout -b nova_branch\n"
	echo "# gcommit"
	echo -e "  - Realiza os comandos 'git add .' e 'git commit -m' com a mesagem especificada\n\t*O comentário do commit será formatado de acordo com o nome da branch"
	echo "  - Parâmetros:"
	echo -e "      1. Comentário do commit\t\tgcommit \"mensagem\""
	echo "  - Opções:"
	echo -e "      -i\t\tMostra os comandos realizados"
	echo -e "      -p\t\tRealiza 'push' logo após o 'commit'"
	echo -e "      -i -p ou -ip\tExecuta ambas funções acima"
	echo "  - Exemplos de formatação do comentário:"
	echo -e "      1. b_task_1234\t\t\t\"refs #1234 [mensagem]\""
	echo -e "      2. b_tarefa\t\t\t\"tarefa [mensagem]\""
	echo -e "      3. homologacao\t\t\t\"homologacao [mensagem]\"\n"
}
