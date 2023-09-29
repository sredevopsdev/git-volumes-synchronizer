FROM ubuntu:mantic

# Install Git

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install --no-install-recommends -y git openssh-client ca-certificates && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
  git --version && \
  which git

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Set the entrypoint script as executable
RUN chmod +x /entrypoint.sh



# Create a non-root user
RUN useradd -m -s /bin/bash gituser && \
  mkdir -p /git && \
  chmod 777 /git

# Create a volume
VOLUME /git
# VOLUME /home/gituser

# Switch to the non-root user
USER gituser
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
