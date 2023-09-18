# Git-backed synced volumes in Kubernetes by [SREDevOps.org](https://sredevops.org)

## Security Warning 🚨

**WARNING** This repository is for testing purposes only and is not secure. It contains sensitive information and credentials that should not be shared or exposed. Using this repository may result in data leaks or other security issues. Use with caution and at your own risk.

### PULL REQUESTS ARE WELCOME!

## Features

This repository contains the following features:

- Git operations (sync, clone, pull, push, etc.) with volumes in containers.
- Git operations with volumes in Kubernetes pods using a sidecar container and a shared volume. The idea is to use the same volume in different pods as the former and deprecated "git-repo" volume kind did. The difference with the previous example is that the volume is created by the sidecar container and then shared with the main container.
- Ephememeral volumes in Kubernetes pods using a sidecar container and a shared volume. The idea is to use the same volume in different pods as the former and deprecated "git-repo" volume kind did. The difference with the previous example is that the volume is created by the init container and then shared with the main container. In this case the volume is destroyed when the pod is terminated, but the data is persisted in the repository, so the volume can be recreated later and the data will be persisted and synchronized.
- Etc.

## Entrypoint (According to Github Copilot)

> This is a shell script called entrypoint.sh that sets up Git credentials and user information, and then checks if the content directory is a Git repository. If it is, the script pulls, adds, commits, and pushes changes to the remote repository every $GIT_SYNC_INTERVAL (an environment variable that specifies the time interval in seconds between each sync). If the content directory is not a Git repository, the script clones the remote repository specified by $GIT_REPO_URL with the branch $GIT_BRANCH into the content directory, and then pushes changes to the remote repository every $GIT_SYNC_INTERVAL.
>
> The script first sets environment variables for Git credentials and user information. If $GIT_USERNAME and $GIT_PASSWORD are both set, the script sets up Git credentials using the store helper and writes them to a file called .git-credentials in the /git directory. If $GIT_TOKEN is set, the script sets up Git credentials using the store helper and writes them to the .git-credentials file. If $GIT_SSH_PRIVATE_KEY_BASE64 is set, the script creates a .ssh directory in the /git directory, decodes the base64-encoded private key, writes it to a file called id_rsa in the .ssh directory, sets the file permissions to 600, adds the GitHub host key to the known_hosts file in the .ssh directory, and sets the core.sshCommand Git configuration to use the private key.
>
> The script then sets up Git user information by setting the user.name and user.email Git configurations to $GIT_USERNAME and $GIT_USER_EMAIL, respectively.
>
> The script then checks if the content directory is a Git repository by checking if the .git directory exists in the content directory. If it does, the script changes the working directory to the content directory and sets the safe.directory Git configuration to /git/content. The script then enters an infinite loop that pulls changes from the remote repository, adds changes to the local repository, commits changes to the local repository with a commit message that includes the current date and time, and pushes changes to the remote repository with the branch $GIT_BRANCH. If any of these steps fail, the script prints an error message to stderr and exits with a non-zero status code. The script then sleeps for $GIT_SYNC_INTERVAL seconds before starting the loop again.
> 
> If the content directory is not a Git repository, the script clones the remote repository specified by $GIT_REPO_URL with the branch $GIT_BRANCH into the content directory using the clone command with the --single-branch and --branch options. The script then sets the file permissions of the content directory to 777 (read, write, and execute permissions for all users). If the clone command fails, the script prints an error message to stderr and exits with a non-zero status code. The script then prints a success message to stdout and exits with a zero status code.

# Variables (As secrets in Kubernetes)

- [deploy/01-secrets.sample.yaml](deploy/01-secrets.sample.yaml)

```yaml
# deploy/01-secrets.sample.yaml
apiVersion: v1
data:
  GIT_USERNAME: ""
  GIT_PASSWORD: ""
  GIT_TOKEN: ""
  GIT_SSH_PRIVATE_KEY_BASE64: ""
  GIT_REPO_URL: ""
  GIT_SYNC_INTERVAL: 3600 # 1 hour, in milliseconds. The synchronization interval is used to configure the synchronization process.
  GIT_BRANCH: ""
  GIT_USER_EMAIL: ""

kind: Secret
metadata:
  name: git-credentials-repo
  namespace: gitsync
```

## Example usage

- [deploy/04-mysql-statefulset.yaml](deploy/04-mysql-statefulset.yaml)

```yaml
# deploy/04-mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-gitsync
  namespace: gitsync
spec:
  serviceName: mysql-gitsync
  replicas: 1
  selector:
    matchLabels:
      app: mysql-gitsync
  template:
    metadata:
      labels:
        app: mysql-gitsync
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      securityContext:
        # Set this to any valid GID, and two things happen:
        #   1) The volume "mysql-from-git" is group-owned by this GID.
        #   2) This GID is added to each container.
        fsGroup: 27 # "27" is the GID for mysql docker.io/mysql/mysql-server:8.0.32-1.2.11-server
      volumes:
      - name: mysql-from-git
        emptyDir:
          sizeLimit: "2Gi"
          medium: ""

      initContainers:
      - name: git-sync-init
        image: ghcr.io/sredevopsdev/git-volumes-synchronizer:latest
        imagePullPolicy: Always
        envFrom:
        - secretRef:
            name: git-sync-credentials # git-credentials-repo is the name of the secret containing the git credentials GITSYNC_PASSWORD and GITSYNC_USERNAME
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: mysql-from-git
          mountPath: /git # this is the path where the git-sync container will store the mysql data
          readOnly: false
          mountPropagation: HostToContainer

      containers:
      - name: mysql-gitsync
        envFrom:
        - secretRef:
            name: gitsync-mysql-credentials # gitsync-mysql-credentials is the name of the secret containing the mysql credentials MYSQL_DATABASE, MYSQL_PASSWORD, MYSQL_ROOT_HOST, MYSQL_ROOT_PASSWORD, MYSQL_USER, MYSQL_USER_HOST
        image: docker.io/mysql/mysql-server:8.0.32-1.2.11-server
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
          protocol: TCP
          name: mysql-gitsync

        volumeMounts:
        - name: mysql-from-git
          mountPath: /var/lib/mysql # this is the path where mysql stores its data
          subPath: content/mysql # subpath relative to the volume defined in the container image and in this case a subfolder in the repo itself
          readOnly: false
          mountPropagation: HostToContainer


        securityContext:
          readOnlyRootFilesystem: false # mysql needs to write to its data directory
          runAsGroup: 27 # "27" is the GID for mysql docker.io/mysql/mysql-server:8.0.32-1.2.11-server
          runAsNonRoot: false # mysql needs to run as root


        resources:
          limits:
            cpu: "1"
            memory: 1Gi
          requests:
            cpu: "0"
            memory: "0"

      # sidecarContainers:
      - name: git-sync-sidecar
        image: ghcr.io/sredevopsdev/git-volumes-synchronizer:latest
        imagePullPolicy: Always
        envFrom:
        - secretRef:
            name: git-sync-credentials # 
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: mysql-from-git
          mountPath: /git # this is the path where the git-sync container will store the mysql data
          readOnly: false
          mountPropagation: HostToContainer
```
