# GitLib

**GitLib** is a library of utility functions for daily/commonly used Git commands.
It provides methods to ease usage of some Git commands and to standardizing processes and commit messages.

GitLib is meant for anyone that uses Git from the terminal, making the daily work faster and preventing commons typos. Also it is a tool to encourage the usage of task-reference messages when commiting changes by standardizing them, allowing, that way, the integration of Git with issue tracking systems (i.e.: systems that scan issue IDs in messages).

## Install

**NOTE**: First of all, you need to have Git available on your computer, you can check if it is installed by typing `git` in your terminal. If it is not, you can download and install from the [Git download page](https://git-scm.com/download).

1. Check out a clone of this repository to a location of your choice;
2. Include the installation file within your ~/.bash_profile or ~/.bashrc file:

   `source <path_to_gitlib>/setup.sh`

3. You can also add configuration commands, such as:

   `gconfig loglevel`
   
   `gconfig refs-string`

Further configurations are not necessary.

## Usage

The commands are simple and self explanatory.

### `gpull [<branch_name>]`

Arguments:
* \<branch_name\>: [Optional] the branch which changes will be pulled, if none is specified, the current branch will be used.

Description:

Incorporates remote changes into the current branch.

Examples:
* Name of current branch: master
  * `gpull`
  * Will result in the following commands:
    * `git pull origin master`

  * `gpull other_branch`
  * Will result in the following commands:
    * `git pull origin other_branch`

### `gpush [<branch_name>]`

Arguments:
* \<branch_name\>: [Optional] the branch which changes will be pushed, if none is specified, the current branch will be used.

Description:

Updates remote branch sending local commits.

Examples:
* Name of current branch: master
  * `gpush`
  * Will result in the following commands:
    * `git gush origin master`

  * `gpush other_branch`
  * Will result in the following commands:
    * `git gush origin other_branch`

### `gcommit [-p] <message>`

Arguments:
* \<message\>: The commit message.

Options:
* -p: Push the commit.

Description:

Prepare the content staged for the next commit and then commit changes. While executing this command, the commit message is analyzed to ckeck if it contains the task-reference string, if it does not, a message will be prompted to confirm the action. The possible answers are:
* 'y' or 's': Do the commit with the actual message;
* 'n': Aborts the commit;
* \<number\>: The task number (e.g.: 1234). When this option is selected, the commit message will be appended with the task-reference string with the given number, and then, confirm the commit.

**IMPORTANT**: The commit message passed as argument is customized based on the **current branch name**. If the branch name match the pattern:
* name: The message will be formatted as: "name [message]"
* b_name: The message will be formatted as: "name [message]"
* b_task_1234: The message will be formatted using the task-reference string: "refs #1234 [message]"

That way, all the commits are standardized and offers more agility by automatically customizing the message.

Examples:
* Name of current branch: master
  * `gcommit -p "Added the save button click event"`
  * Will result in the following commands:
    * `git add .`
    * `git commit -m "master [Added the save button click event]"`
    * `git push origin master`
  * The confirm message *will* be prompted

* Name of current branch: b_task_1234
  * `gcommit "Added the save button click event"`
  * Will result in the following commands:
    * `git add .`
    * `git commit -m "refs #1234 [Added the save button click event]"`
  * The confirm message *will not* be prompted

### `gout [-b] <branch_name>`

Options:
* -b: Create and checkout a new branch
  * ~~Actually, it will accept any of `git branch` standard options.~~

Arguments:
* \<branch_name\>: The branch which will be switched to.

Description:

Prepare the local project for working on a specifc branch, switching the actual branch for the new one.

Examples:
* Name of current branch: master
  * `gout -b b_task_1234`
  * Will result in the following commands:
    * `git checkout -b b_task_1234`

### `gmerge <branch_name>`

Arguments:
* \<branch_name\>: The branch which commits will be merged

Description:

Incorporates changes from the named commits of the specified branch into the current branch.

**IMPORTANT**: Before merging, the `gpull` command will be executed. It will not cause any harmful effect, if there is any remote commit not yet fetched into the local repository, the `git merge` will fail and you will need to execute `git pull` anyway.

Examples:
* Name of current branch: master
  * `gmerge b_task_1234`
  * Will result in the following commands:
    * `gpull`
    * `git merge b_task_1234`

### `gstatus`

Description:

Displays paths that have differences between the index file and the current HEAD commit. Simplifying: it is just a contraction of `git stauts` command, the standard options and arguments will work.

Examples:
* Name of current branch: master
  * `gstatus`
  * Will result in the following commands:
    * `git status`
	
## Configuration

There are some options that can be configured. All the configurations can be changed using the `gconfig` command while passing the configuration name as arguments. The following items are the currently available options:

### `refs-string <new_refs_string> <new_refs_regex>`

Arguments:
* Reference string: The new task-reference string
* Reference REGEX: The new reference Unix Regular Expression. The reference string *must* match this pattern.

Description:

Changes the actual task-reference string that is used within the `gcommit` command to check if the commit message refers ~~or not~~ to a task. The pattern specified by the REGEX will be used to do the comparison.

Defaults:
* Reference string: refs #0000
* Reference REGEX: refs[[:space:]]+#[[:digit:]]*[^[:alpha:]]

### `loglevel <new_log_level>`

Arguments:
* Log level: The new log level of the tool

Description:

Changes the actual log level of GitLib commands. The currently available levels are:
* err: Error
* war: Warning
* info: Information
* debug: Debug

Defaults:
* Log level: info

## Author and contact

Luiz Felipe Nazari

luiz.nazari.42@gmail.com
