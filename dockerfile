# Use an official Python runtime as a parent image
FROM python:slim-buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install build essentials, git and curl
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git curl && \
    rm -rf /var/lib/apt/lists/* 

# Set working directory
WORKDIR /app

# Clone the git repository
RUN git clone https://github.com/AutonomousResearchGroup/autocoder.git . && \
    rm -rf .git && \
    curl https://api.github.com/repos/AutonomousResearchGroup/autocoder/commits > commits.json

# Create .preferences file as blank json if it does not exist
RUN if [ ! -f .preferences ]; then echo "{}" > .preferences; fi

# Install python dependencies
RUN pip install --no-cache-dir .

# Create start.sh file.
RUN printf '#!/bin/bash\n\
if [[ -z "$OPENAI_API_KEY" ]]; then\n\
  echo "OPENAI_API_KEY not set, please run with --env.\nExiting..."\n\
  exit 1\n\
fi\n\
if [[ ! -d "./project_data" ]]; then\n\
  echo "Project data directory not found, please mount it in the container at /app/project_data.\nExiting..."\n\
  exit 1\n\
fi\n\
if [[ -z "$SKIP_UPDATES" ]]; then\n\
  echo "Checking for updates..."\n\
  curl https://api.github.com/repos/AutonomousResearchGroup/autocoder/commits > commits_new.json\n\
  if ! cmp -s commits.json commits_new.json; then\n\
    echo "New updates found. Continue? (Y/n)"\n\
    read user_input\n\
    if [[ "$user_input" =~ ^([nN][oO]|[nN])$ ]]; then\n\
      echo "Exiting..."\n\
      exit 0\n\
    fi\n\
  else\n\
    echo "No new updates found."\n\
  fi\n\
fi\n\
python start.py'\
> /app/start.sh && chmod +x /app/start.sh

# Revert back to user dialog for autocoder 
ENV DEBIAN_FRONTEND=dialog

# Define command to run
CMD ["/bin/bash", "/app/start.sh"]
