#!/usr/bin/env bash
# Set verbose mode 
set -x 
export GIT_USERNAME="$GIT_USERNAME"
export GIT_TOKEN="$GIT_TOKEN"
export GIT_SSH_PRIVATE_KEY_BASE64="$GIT_SSH_PRIVATE_KEY_BASE64"
export GIT_REPO_URL="$GIT_REPO_URL"
export GIT_BRANCH="$GIT_BRANCH"
export GIT_SYNC_INTERVAL="$GIT_SYNC_INTERVAL"
export GIT_USER_EMAIL="$GIT_USER_EMAIL"

# sleep 3600


# Set up Git credentials
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_PASSWORD" ]; then
  git config --global credential.helper "store --file=/home/gituser/.git-credentials"
  printf "https://%s:%s@github.com\n" "$GIT_USERNAME" "$GIT_PASSWORD" > /home/gituser/.git-credentials
elif [ -n "$GIT_TOKEN" ]; then
  git config --global credential.helper "store --file=/home/gituser/.git-credentials"
  printf "https://x-access-token:%s@github.com\n" "$GIT_TOKEN" > /home/gituser/.git-credentials
elif [ -n "$GIT_SSH_PRIVATE_KEY_BASE64" ]; then
  mkdir -p /home/gituser/.ssh || true
  echo "$GIT_SSH_PRIVATE_KEY_BASE64" | base64 -d > /home/gituser/.ssh/id_rsa
  chmod 600 /home/gituser/.ssh/id_rsa || true
  ssh-keyscan github.com >> /home/gituser/.ssh/known_hosts || true
  git config --global core.sshCommand "ssh -i /home/gituser/.ssh/id_rsa -o UserKnownHostsFile=/home/gituser/.ssh/known_hosts"
fi

# Set up Git user
if [ -n "$GIT_USERNAME" ]; then
  git config --global user.name "$GIT_USERNAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi
# Check if the subdir "content" is a git repository. For true: pull, add, commit, and push every $GIT_SYNC_INTERVAL to $GIT_REPO_URL with $GIT_BRANCH branch name. For false: clone $GIT_REPO_URL with $GIT_BRANCH branch name into "content", and push every $GIT_SYNC_INTERVAL to $GIT_REPO_URL with $GIT_BRANCH branch name.
if [ -d "/home/gituser/content/.git" ]; then
  cd /home/gituser/content || exit
  while true; do
    git pull
    git add .
    git commit -m "Update from gitsync at $(date)"
    git push
    sleep "$GIT_SYNC_INTERVAL"
  done
else
  # rm -rf /home/gituser/content || true
  git clone --single-branch --branch "$GIT_BRANCH" "$GIT_REPO_URL" /home/gituser/content || exit
  cd /home/gituser/content || exit
  while true; do
    git pull
    git add .
    git commit -m "Update from gitsync at $(date)"
    git push
    sleep "$GIT_SYNC_INTERVAL"
  done
fi

