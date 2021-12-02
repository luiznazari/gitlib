# GitLib

**GitLib** is a library of utility functions for daily/commonly used Git commands.
It provides methods to ease usage of some Git commands and to standardizing processes and commit messages.

GitLib is meant for anyone that uses Git from the terminal, making the daily work faster and preventing commons typos. Also it is a tool to encourage the usage of task-reference messages when commiting changes by standardizing them, allowing, that way, the integration of Git with issue tracking systems (i.e.: systems that scan issue IDs in messages).

## Install

**NOTE**: First of all, you need to have Git available on your computer, you can check if it is installed by typing `git` in your terminal. If it is not, you can download and install from the [Git download page](https://git-scm.com/download).

1. Check out a clone of this repository to a location of your choice;
2. Include the installation file within your ~/.bash_profile or ~/.bashrc file:

   `source <path_to_gitlib>/setup.sh`

3. You can also add [configuration commands](#configuration)

Further configurations are not necessary.

## Usage

### `gcommit [-p] [-s] <message>`

#### Arguments:
* `<message>`: The commit message.

#### Options:
* `-p`: Push the commit.
* `-s`: Commits only already stagged files. 

#### Description:

Prepare the unstaged and new files for the next commit and then commit changes.<br>

When you do a `gcommit`, you'll be prompted to choose the prefix specifying the referred commit. The available options are: `FIX`, `FEAT`, `TEST`, `REFACTOR`, `DOC`, `REVERT`.

If the branch name contains a task number, it'll be used in the commit message, otherwise, a task number need to be prompted to confirm the action. The possible answers are:
* `y` or `s`: Assumes `0` as the task number;
* `n`: Aborts the commit;
* `<number>`: The task number (e.g.: 1234). Can be multivalued, comma separated values are valid (e.g.: 123, 456).

**IMPORTANT**: The commit message passed as argument is customized based on the **current branch name**. If the branch name match the pattern:
* b_task_1234: The message will be formatted using the task number 1234.
* b_PREFIX_1234: The message will be formatted using the task prefix PREFIX and task number 1234.

IF the commit prefix is `REVERT`, instead of asking for the task number, you'll be prompted to speficy the ID of the target commit (SHA1 hash).

#### Examples:
Current branch: **master**
> \> `gcommit -p "Added the save button click event"` <br>
> \> Answer 1: FEAT <br>
> \> Answer 2: 123, 456 <br>
> \# Will result in the following commands: <br>
> \> `git add .` <br>
> \> `git commit -m "[FEAT][#PREFIX-123, #PREFIX-456]: Added the save button click event"` <br>
> \> `git push origin master` <br>

Current branch: **master**
> \> `gcommit -s "Added tests to the save button click event"` <br>
> \> Answer 1: TEST <br>
> \> Answer 2: 123 <br>
> \# Will result in the following commands: <br>
> \> `git commit -m "[TEST][#PREFIX-123]: Added tests to the save button click event event"` <br>

Current branch: **b_task_1234**
> \> `gcommit "Added the save button click event"` <br>
> \> Answer 1: FIX <br>
> \# Will not ask the task number <br>
> \# Will result in the following commands: <br>
> \> `git add .` <br>
> \> `git commit -m "[FIX][#PREFIX-1234]: Fixed the save button click event"`

Current branch: **b_CUSTOMPREFIX_1234**
> \> `gcommit "Added the save button click event"` <br>
> \> Answer 1: FEAT <br>
> \# Will not ask the task number <br>
> \# Will result in the following commands: <br>
> \> `git add .` <br>
> \> `git commit -m "[FEAT][#CUSTOMPREFIX-1234]: Added the save button click event"`

----

### `gpull [<branch_name>]`

#### Arguments:
* `<branch_name>`: [Optional] the branch which changes will be pulled, if none is specified, the current branch will be used.

#### Description:

Incorporates remote changes into the current branch.

#### Examples:
Current branch: **master**

> \> `gpull` <br>
> \# Will result in the following commands: <br>
> \> `git pull origin master` 

> \> `gpull other_branch` <br>
> \# Will result in the following commands: <br>
> \> `git pull origin other_branch`

----

### `gpush [<branch_name>]`

#### Arguments:
* `<branch_name>`: [Optional] the branch which changes will be pushed, if none is specified, the current branch will be used.

#### Description:

Updates remote branch sending local commits.

#### Examples:
Current branch: **master**

> \> `gpush` <br>
> \# Will result in the following commands: <br>
> \> `git gush origin master`

> \> `gpush other_branch` <br>
> \# Will result in the following commands: <br>
> \> `git gush origin other_branch`

----

### `gout [-b] <branch_name>`

#### Options:
* `-b`: Creates and checks out to a new branch
  * ~~Actually, it will accept any of `git branch` standard options.~~

#### Arguments:
* `<branch_name>`: The branch which will be switched to.

#### Description:

Prepare the local project for working on a specifc branch, switching the actual branch for the new one.

#### Examples:
Current branch: **master**

> \> `gout -b b_task_1234` <br>
> \# Will result in the following commands: <br>
> \> `git checkout -b b_task_1234`

----

### `gmerge <branch_name>`

#### Arguments:
* \<branch_name\>: The branch which commits will be merged

#### Description:

Incorporates changes from the named commits of the specified branch into the current branch.

**IMPORTANT**: Before merging, the `gpull` command will be executed. It will not cause any harmful effect, if there is any remote commit not yet fetched into the local repository, the `git merge` will fail and you will need to execute `git pull` anyway.

#### Examples:
Current branch: **master**
> \> `gmerge b_task_1234`
> \# Will result in the following commands:
> \> `gpull`
> \> `git merge b_task_1234`

----

### `gstatus`

#### Description:

Displays paths that have differences between the index file and the current HEAD commit. Simplifying: it is just a contraction of `git stauts` command, the standard options and arguments will work.

#### Examples:
Current branch: **master**
> \> `gstatus`
> \# Will result in the following commands:
> \> `git status`

----

### `greset`

#### Description:

Discards all stagged and unstagged changes and local (unpushed) commits. Only use this if you are *really sure* of what you are doing. There is no comming back.

#### Examples:

> \> `greset` <br>
> \# Will result in the following commands: <br>
> \> `git checkout .` <br>
> \> `git reset .` <br>
> \> `git reset --soft HEAD`

<br>

## Configuration

There are some options that can be configured. All the configurations can be changed using the `gconfig` command while passing the configuration name as arguments. The following items are the currently available options:

### `gconfig default-task-prefix <new_prefix>`

#### Arguments:
* `<new_prefix>`: The prefix used before the task number

#### Description:

Changes the actual task-reference prefix that is used within the `gcommit` command. It's used to compose the Jira task ID.

----

### `gconfig loglevel <new_log_level>`

#### Arguments:
* `<new_log_level>`: The new log level of the tool

#### Description:

Changes the actual log level of GitLib commands. The currently available levels are:
* err: Error
* war: Warning
* info: Information
* debug: Debug

#### Defaults:
* Log level: info

----

### `gconfig debug-mode <boolean>`

#### Arguments:
* `<boolean>`: true or false.

#### Description:

When debug mode is `true`, all commands *will not* cause changes to the git project. Useful with debug logging.

#### Defaults:

False.

----

## Author and contact

Luiz Felipe Nazari &lt;luiz.nazari.42@gmail.com&gt;
