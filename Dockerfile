FROM codercom/code-server:4.103.1

USER root

# Install necessary packages (wget, unzip for Terraform, prerequisites for Docker CLI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \
    terraform --version && \
    # Install Terraform autocomplete
    terraform -install-autocomplete && \
    # Clean up the apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# Install Docker CLI (using official Docker DEBIAN repository)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    docker --version && \
    rm -rf /var/lib/apt/lists/*

# --- Java (OpenJDK) ---
ARG JAVA_VERSION=17
RUN apt-get update && \
    apt-get install -y --no-install-recommends "openjdk-${JAVA_VERSION}-jdk" && \
    java -version && \
    rm -rf /var/lib/apt/lists/*

# --- Node.js ---
ARG NODE_MAJOR=20
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g npm@latest && \
    node --version && \
    npm --version && \
    rm -rf /var/lib/apt/lists/*

# --- Helm ---
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    VERIFY_CHECKSUM=false ./get_helm.sh && \
    helm version && \
    rm get_helm.sh

# --- Kubectl ---
ARG KUBECTL_VERSION="1.35.3"
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    kubectl version --client


# Add bash completion and source completion scripts
RUN echo 'source /usr/share/bash-completion/bash_completion' >> /etc/bash.bashrc && \
    echo 'source <(kubectl completion bash)' >> /etc/bash.bashrc && \
    echo 'source <(helm completion bash)' >> /etc/bash.bashrc && \
    echo 'alias ll="ls -alF"' >> /etc/bash.bashrc && \
    echo 'alias la="ls -A"' >> /etc/bash.bashrc && \
    echo 'alias l="ls -CF"' >> /etc/bash.bashrc && \
    echo 'alias cls="clear"' >> /etc/bash.bashrc && \
    echo 'alias k="kubectl"' >> /etc/bash.bashrc && \
    echo 'alias h="helm"' >> /etc/bash.bashrc && \
    echo 'alias tf="terraform"' >> /etc/bash.bashrc && \
    echo 'complete -o default -F __start_kubectl k' >> /etc/bash.bashrc

# Install VS Code extensions for autocompletion
USER coder

# Install all VS Code extensions in a single layer
RUN code-server --install-extension hashicorp.terraform && \
    code-server --install-extension ms-azuretools.vscode-docker && \
    code-server --install-extension vscjava.vscode-java-pack && \
    code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools && \
    code-server --install-extension redhat.vscode-yaml

# Set default shell to bash
ENV SHELL=/bin/bash
