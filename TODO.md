# GitLib - TODO list

- [ ] gmessage change commit message for pushed or local commits
      local (last commit): "git commit --amend"
- [ ] "gcommit -d" undo last local commit "git reset --soft HEAD^"
- [ ] check if there are more modified/added/removed files not included in the commit before proceding

      ```sh
            _check_if_exists_stagged_files_besides_current_path() {
            # Ex.:
            # MM src/gitlib.sh
            # MM src/gitlib_utils.sh
            # ?? TODO.md
            changedFilePath=$(git status --untracked-files --short)
            #...
      }
      ```