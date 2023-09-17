# Git-backed synced volumes in Kubernetes by [SREDevOps.org](https://sredevops.org)

## Security Warning 🚨

**☢️ This repository is for testing purposes only and does not have any security hardening. It contains sensitive information and credentials that should not be shared or exposed. Please be aware that using this repository may result in data leaks or other security issues. Use at your own risk. ☢️**

## Features

This repository contains the following features:

- Git operations (sync, clone, pull, push, etc.) with volumes in containers.
- Git operations with volumes in Kubernetes pods using a sidecar container and a shared volume. The idea is to use the same volume in different pods as the former and deprecated "git-repo" volume kind did. The difference with the previous example is that the volume is created by the sidecar container and then shared with the main container.
- Ephimeral Git operations with volumes in Kubernetes pods using a sidecar container. The idea is to use the same volume in different pods as the former and deprecated "git-repo" volume kind did. The difference with the previous example is that the volume is created by the sidecar container and then shared with the main container. In this case the volume is destroyed when the pod is terminated, but the data is persisted in the repository, so the volume can be recreated later and the data will be persisted and synchronized.
- Etc.
