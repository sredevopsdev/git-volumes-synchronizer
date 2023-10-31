FROM ubuntu:mantic-20231011

LABEL org.opencontainers.image.source="https://github.com/sredevopsdev/git-volumes-synchronizer"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install --no-install-recommends -y git openssh-client ca-certificates nano && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/cache/apt/archives/* && \
  git --version && \
  which git


# Create a non-root user and group gid=1001 uid=1001 with home=/git and shell=/bin/bash.
RUN mkdir /git && \
    groupadd -g 1001 gituser && \
    useradd -d /git -u 1001 -g 1001 -m -s /bin/bash gituser && \
    chown -R 1001:1001 /git && \
    chmod -R 777 /git

# Copy the entrypoint script
COPY --chown=1001:1001  entrypoint.sh /entrypoint.sh

# Set the entrypoint script as executable
RUN chmod +x /entrypoint.sh

# Create a volume
VOLUME /git
# VOLUME /home/gituser

# Switch to the non-root user
USER 1001:1001
# Set the working directory
WORKDIR /git

# Set up Git credentials
ENV GIT_USERNAME ""
ENV GIT_PASSWORD ""
ENV GIT_TOKEN ""
ENV GIT_SSH_PRIVATE_KEY_BASE64 ""
ENV GIT_REPO_URL ""
ENV GIT_BRANCH ""
ENV GIT_SYNC_INTERVAL ""
ENV GIT_USER_EMAIL ""


# Set the entrypoint command
ENTRYPOINT ["/entrypoint.sh"]


