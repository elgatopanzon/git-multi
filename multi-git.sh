#!/usr/bin/env sh

######################################################################
# @author      : ElGatoPanzon
# @file        : multi-git
# @created     : Tuesday Sep 05, 2023 12:25:25 CST
#
# @description : Manage multiple git repos in the same directory using .gitignore
######################################################################

# all state is stored in .gitignore using comments to identify that it's managed by multi-git
# example line in .gitignore:
# path/to/sub/repo # Managed by multi-git

GITIGNORE_MANAGED_STRING="Managed by multi-git"

get_root_repo_path() {
	git rev-parse --show-toplevel
}

# root repo git ignore path
GITIGNORE_PATH="$(get_root_repo_path)/.gitignore"
CURRENT_DIR="$(pwd)"


gitignore_search() {
	grep "$1" "$GITIGNORE_PATH"
}

gitignore_exists() {
	if [ ! -f "$GITIGNORE_PATH" ]; then
		return 1
	fi

	return 0
}

gitignore_create() {
	touch "$GITIGNORE_PATH"

	gitignore_commit "create .gitignore"
}

gitignore_commit() {
	perform_root_git_command add "$GITIGNORE_PATH"
	perform_root_git_command commit -m "multi-git: $1"
}

perform_root_git_command() {
	git --git-dir="$(get_root_repo_path)/.git" --work-tree="$(get_root_repo_path)" "$@"
}

perform_sub_repo_git_command() {
	SUB_REPO_PATH="$(get_root_repo_path)/$1"
	params=( $* )
    unset params[0]
    set -- "${params[@]}"
	git --git-dir="$SUB_REPO_PATH/.git" --work-tree="$SUB_REPO_PATH" "$@"
}

gitignore_get_repo_string() {
	echo "# $GITIGNORE_MANAGED_STRING (sub repo $1)"
}

gitignore_add_repo() {
	# add cloned repo to ignore file
	echo "$(gitignore_get_repo_string "$1" "$2") " >> "$GITIGNORE_PATH"
	echo "/$2 " >> "$GITIGNORE_PATH"

	# commit changes to ignore file
	gitignore_commit "add sub-repo $1 => $2"
}

gitignore_remove_repo() {
	# remove repo from ignore file
	grep -v "$1" "$GITIGNORE_PATH" > temp && mv temp "$GITIGNORE_PATH"
	grep -v "/${2} " "$GITIGNORE_PATH" > temp && mv temp "$GITIGNORE_PATH"

	# commit changes to ignore file
	gitignore_commit "remove sub-repo $1 => $2"
}

sub_repo_exists() {
	if [ -z "$(gitignore_search "$1")" ]; then
		return 0
	else
		echo "exists"
	fi
}


sub_repo_add() {
	REPO="$1"
	REPO_DIR="$2"

	echo "Cloning $REPO to $REPO_DIR"

	# change to repo root path
	cd "$(get_root_repo_path)"

	# clone the repo content to root relevant path
	git clone "$REPO" "$REPO_DIR"

	# return to previous dir
	cd "$CURRENT_DIR"

	# update gitignore
	gitignore_add_repo "$REPO" "$REPO_DIR"
}

sub_repo_remove() {
	REPO="$1"
	REPO_DIR="$2"

	echo "Removing sub repo at $REPO_DIR ($REPO)"

	# change to repo root path
	cd "$(get_root_repo_path)"

	# remove local content
	rm -rf "$REMOVE_REPO_DIR"

	# return to previous dir
	cd "$CURRENT_DIR"

	# update gitignore
	gitignore_remove_repo "$REPO" "$REPO_DIR"
}

sub_repo_get_repo_from_path() {
	grep "$1 " "$GITIGNORE_PATH" -B 1 | head -n 1 | awk '{print $7}' # get it from the comment line
}
sub_repo_get_repo_path_from_repo() {
	grep "$1" "$GITIGNORE_PATH" -A 1 | tail -n 1 | cut -c2- # get it from below the comment line
}

CMD="$1" # command to perform

# init the .gitignore file if exists
if ! gitignore_exists; then
	echo ".gitignore doesn't exist, creating"

	# create and commit .gitignore
	gitignore_create
fi

if [ "$CMD" == "add" ]; then
	ADD_REPO="$2"
	ADD_REPO_DIR="$3"

	if [ -z "$ADD_REPO" ] || [ -z "$ADD_REPO_DIR" ]; then
		echo "usage: add REPO PATH"
		exit
	fi
	
	if [ ! -z "$(sub_repo_get_repo_path_from_repo "$ADD_REPO")" ]; then
		echo "Repo exists"
		echo "REPO: $ADD_REPO"
		echo "PATH: $(sub_repo_get_repo_path_from_repo "$ADD_REPO")"
	else
		sub_repo_add "$ADD_REPO" "$ADD_REPO_DIR"
	fi
elif [ "$CMD" == "remove" ]; then
	REMOVE_REPO_DIR="$2"
	REMOVE_REPO="$(sub_repo_get_repo_from_path "$REMOVE_REPO_DIR")"

	if [ -d "$(get_root_repo_path)/$REMOVE_REPO_DIR" ]; then
		read -p "Are you sure [y/n]? " -n 1 -r
		echo    # (optional) move to a new line
		if [ "$REPLY" == "y" ]; then
			# remove the sub repo
			REMOVE_REPO_STATUS="$(perform_sub_repo_git_command "$REMOVE_REPO_DIR" "status --porcelain")"

			if [ ! -z "$REMOVE_REPO_STATUS" ]; then
				echo "Repo $REMOVE_REPO_DIR status:"
				echo $REMOVE_REPO_STATUS

				read -p "Confirm removal of directory and pending changes [y/n]? " -n 1 -r
				echo    # (optional) move to a new line
				if [ "$REPLY" == "y" ]; then
					sub_repo_remove "$REMOVE_REPO" "$REMOVE_REPO_DIR"
				fi
			fi
		fi
	else
		echo "No sub-repo at path $REMOVE_REPO_DIR"
	fi
elif [ "$CMD" == "list" ]; then
	while read -r line ; do
		LIST_REPO="$(echo $line | awk '{print $7}' | rev | cut -c2- | rev)"
		LIST_REPO_PATH="$(sub_repo_get_repo_path_from_repo "$LIST_REPO" | rev | cut -c2- | rev)"

		echo "/$LIST_REPO_PATH: $LIST_REPO"
		perform_sub_repo_git_command "$LIST_REPO_PATH" "status --porcelain"
	done < <(grep "$GITIGNORE_MANAGED_STRING" "$GITIGNORE_PATH")	
fi