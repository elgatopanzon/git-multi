# git-multi - Git Submodules done better?!

This project is a little git plugin I decided to put together because I keep running into this same problem: how can I effectively manage multiple nested git repos in a single repo without running into something messy? Personally not a fan of the native `git submodule` so I decided to have a crack at my own implementation with a few bells and whistles.

Introducing git-multi!

# Features
* Manage sub repos with easy commands like `clone`, `ls`, `mv` and `rm`
* Nest multiple repos in an existing repo
* Automatically inits any existing git submodules upon clone, update and init
* Doesn't require configuration or state, only uses `.gitignore`
* Full functionality of those sub repos from anywhere in your main repo! (not limited like git submodules)
* Run batch git commands or batch shell commands on all your git-multi sub repos
* Recursively manage trees of nested git repos!

# How to use it
Multi-git is a git plugin, and once the script `git-multi` is in your path it can be used as a native git subcommand with `git multi`.

The first thing you'll want to do is get a main repo where you want to clone your nested git repos.

## To clone, use the `clone` command:
## `git multi clone https://some-repo.git libs/some-repo`

This will automate the following actions for you with a single command:

* Init a blank `.gitignore` file if none exists, and commit to your repo
* Ignore the destination path `libs/some-repo`, and commit this to your repo
* Clone the `https://some-repo.git` repo to the local folder `libs/some-repo`, relative to your git project root
* Update and init any native git submodules the repo might be using (can't control if others choose to rely on sub modules!)
* Recursively run `git multi init-all` on the repo at `libs/some-repo` (more about recursion later)

With that you have successfully cloned and nested a git repo in your existing repo without any complaints, and have full functionality over that repo. You can push, pull, commit, branch, etc. just you would a normal repo, and your main repo is not going to complain.

## To init an existing repo with git-multi sub repos, use the `init-all` command:
## `git multi init-all`

When you clone your repo again to another machine, someone else clones your repo, the contents of `libs/some-repo` won't exist. That's because the operations of git-multi are transparent to the operations of git.

The `init-all` command scans the `.gitignore` file for repos managed by git-multi and re-clones and re-updates them in the newly cloned work tree. The sames steps which were performed with the `clone` command are performed again with the `init-all` command, except that it prepares ALL git-multi sub repos in a single command.

## Listing all sub-repos with `ls`
## `git multi ls`

The `ls` command will list all sub repos found in the current repo, including any unstaged changes.

```
$ git multi ls
libs/some-repo: https://some-repo.git
libs/some-other-repo: https://some-other-repo.git
```

## Jump between sub repos with the `cd` command
Let's say we are the maintainer of `some-repo`, and we are working on both our main repo and this library at the same time.
## `git multi cd libs/some-repo` to change to the directory of the git-multi sub repo

**Note: Why not just use regular `cd libs/some-repo`?**
You can, but `git multi cd` is available anywhere in your main project including deep sub directories, so you don't have to think about finding where it is!

## `git multi cd` to return to the previous directory
Once we made our changes in `libs/some-repo`, we can back out to the **previous directory in the main project** with `git multi cd` and no sub repo path, which saves us losing our previous position in the main project!

Running `git multi ls` again now shows an unstaged change that we forgot about in the `some-repo` repo.
```
$ git multi ls
libs/some-repo: https://some-repo.git
 M README.md
libs/some-other-repo: https://some-other-repo.git
```

Changes are simply listed below your sub repo's path in the list. It's easy to run the `git multi ls` command to get a quick status of every sub repo when you forgot to commit something on a sub repo.

## Executing git commands on your sub repos from anywhere, with the `exec` command
The `exec` command is a powerful way to run **any** git command from any sub-directory in your main project, on one of your sub repos. For example in the above we had unstaged changes to `README.md` in the `libs/some-repo` sub repo. We could just `cd` over there and commit the changes, but that's *slow*!

## `git multi exec libs/some-repo commit -a` to run git commands on your sub repos, from anywhere
With this quick command we don't even need to hop over there, we can just commit the changes and enter our commit message like normal, and we are done!

## Executing shell commands on your sub repos, also from anywhere
## `git multi exec-sh libs/some-repo ls -lah`

Similar to the `exec` command, `exec-sh` works in the same way but with raw shell commands.

## Moving a sub repo directory to another with the `mv` command
## `git multi mv libs/some-repo libs/some-old-repo`

Moving sub repos to another directory is easy. You don't have to manually move the contents and update the state file, you just issue an `mv` command.

Behind the scenes the sub repo is removed and re-cloned and updated in the new location.

## Removing all traces of a sub repo from your main repo with `rm`
## `git multi rm libs/some-old-repo` delete the contents and stop tracking `libs/some-old-repo`

Similar to unix `rm` command, deletes are not to be taken lightly. While you can restore your `.gitignore` if you accidently remove a sub repo you want, you won't be able to restore the contents of the repo which you delete.

When you delete a sub repo, you will asked if to confirm the deletion, and if there's any unstaged changes you will be asked to confirm the deletion a second time to prevent accidently losing work.

## Cleanup and remove all traces of git-multi on your repo, with `rm-all`
## `git multi rm-all` delete all sub repos

Like the `git multi rm` command, this cannot be undone, and you will be first shown a list of all repos and their unstaged changes with a single confirmation before proceeding.

After running this command all your sub-repos will be removed and any traces from your `.gitignore` will also be removed. It will be like you never used git-multi in the first place... except for the git history containing the git-multi state in the `.gitignore`, so you can always restore that.

## Keeping your sub repos up to date, recursively
## `git multi update-all` update all sub repos and git submodules

This command executes a `pull`, updates all native git submodules, and recursively performs the same action with `git multi update-all` on all managed sub repos. This allows you to keep everything in sync with a single command from the main project repo.

## Batch commands, running on all your repos at the same time!
## `git multi exec-all status` run the git command `git status` on all your sub repos
## `git multi exec-sh-all ls -lah` run the shell command `ls -lah` on all your sub repos

## For the full help text, run `git multi help`.
