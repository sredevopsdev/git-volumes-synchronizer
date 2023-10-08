#!/usr/bin/env bash
set -e
export GIT_USERNAME="$GIT_USERNAME"
export GIT_TOKEN="$GIT_TOKEN"
export GIT_SSH_PRIVATE_KEY_BASE64="$GIT_SSH_PRIVATE_KEY_BASE64"
export GIT_REPO_URL="$GIT_REPO_URL"
export GIT_BRANCH="$GIT_BRANCH"
export GIT_SYNC_INTERVAL="$GIT_SYNC_INTERVAL"
export GIT_USER_EMAIL="$GIT_USER_EMAIL"

# sleep 3600
# chmod -Rfv 777 /git || echo "Error: Failed to chmod /git" >&2 && true

# Set up Git credentials
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_PASSWORD" ]; then
  git config --global credential.helper "store --file=/git/.git-credentials"
  printf "https://%s:%s@github.com\n" "$GIT_USERNAME" "$GIT_PASSWORD" > /git/.git-credentials
elif [ -n "$GIT_TOKEN" ]; then
  git config --global credential.helper "store --file=/git/.git-credentials"
  printf "https://x-access-token:%s@github.com\n" "$GIT_TOKEN" > /git/.git-credentials || true
elif [ -n "$GIT_SSH_PRIVATE_KEY_BASE64" ]; then
  mkdir -p /git/.ssh || true
  echo "$GIT_SSH_PRIVATE_KEY_BASE64" | base64 -d > /git/.ssh/id_rsa
  chmod 600 /git/.ssh/id_rsa || true
  ssh-keyscan github.com >> /git/.ssh/known_hosts || true
  git config --global core.sshCommand "ssh -i /git/.ssh/id_rsa -o UserKnownHostsFile=/git/.ssh/known_hosts"
fi

# Set up Git user
if [ -n "$GIT_USERNAME" ]; then
  git config --global user.name "$GIT_USERNAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi


# Check if the subdir "content" is a git repository. For true: pull, add, commit, and push every $GIT_SYNC_INTERVAL to $GIT_REPO_URL with $GIT_BRANCH branch name. For false: clone $GIT_REPO_URL with $GIT_BRANCH branch name into "content", and push every $GIT_SYNC_INTERVAL to $GIT_REPO_URL with $GIT_BRANCH branch name.

if [ -d "/git/content/.git" ]; then
  #  Add git safe directory
  while true; do
    cd /git/content || echo "Error: Failed to cd /git/content" >&2 && true
    chmod -Rfv 777 /git/content || echo "Error: Failed to chmod /git/content" >&2 && true
    git config --global --add safe.directory /git/content || echo "Error: Failed to add safe.directory" >&2 && true
    if ! git pull; then
      echo "Couldn't pull changes from remote repository" >&2 || true
      # exit 1
    fi
    if ! git add .; then
      echo "Couldn't add changes from local repository" >&2 || true
      # exit 1
    fi
    if ! git commit -m "Update from git-volumes-synchronizer at $(date)"; then
      echo "Couldn't commit changes from local repository" >&2 || true
      # exit 1
    fi
    if ! git push; then
      echo "Couldn't push changes to remote repository" >&2 || true
      # exit 1
    fi
    echo "Changes synced successfully at $(date) with branch $GIT_BRANCH"
    sleep "$GIT_SYNC_INTERVAL"
  done
else
  if ! git clone --single-branch --branch "$GIT_BRANCH" "$GIT_REPO_URL" /git/content && chmod -Rfv 777 /git/content; then
    echo "Error: Failed to clone remote repository $GIT_REPO_URL with branch $GIT_BRANCH" >&2
    exit 1
  fi
  echo "Repository $GIT_REPO_URL cloned successfully with branch $GIT_BRANCH"
fi

exit 0
