FROM codercom/code-server:4.103.1

USER root

# 기본 패키지
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


# --- AWS CLI v2 ---
RUN curl -fsSLo /tmp/awscliv2.zip \
      https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    aws --version && \
    rm -rf /tmp/aws /tmp/awscliv2.zip


# --- Terraform ---
RUN wget -O - https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends terraform && \
    terraform --version && \
    terraform -install-autocomplete && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*


# --- Docker CLI ---
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    docker --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*


# --- Java ---
ARG JAVA_VERSION=17

# 일반 JDK 대신 GUI 의존성이 적은 headless JDK 사용
# Spring Boot / Gradle build / java -jar 실행에는 충분함
RUN apt-get update && \
    apt-get install -y --no-install-recommends "openjdk-${JAVA_VERSION}-jdk-headless" && \
    java -version && \
    javac -version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*


# --- Node.js ---
ARG NODE_MAJOR=24

# 불필요
# NodeSource의 nodejs 패키지에 npm이 이미 포함되어 있음
# ARG NPM_VERSION=11.16.0

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    node --version && \
    npm --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# 불필요
# npm 자체는 위 nodejs 설치 시 이미 설치됨
# RUN npm install -g "npm@${NPM_VERSION}"


# --- Helm ---
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    ./get_helm.sh && \
    helm version && \
    rm -f get_helm.sh

# 기존:
# VERIFY_CHECKSUM=false ./get_helm.sh
#
# checksum 검증을 일부러 끌 필요가 없으므로 제거


# --- Kubectl ---
ARG KUBECTL_VERSION="1.35.3"

RUN curl -fsSLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    kubectl version --client


# --- Bash completion / Alias ---
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


# --- VS Code Extensions ---
USER coder

RUN code-server --install-extension hashicorp.terraform && \
    code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools && \
    code-server --install-extension redhat.vscode-yaml

# 불필요 가능성이 높음
# Docker 명령어 실습에는 docker-ce-cli만 있으면 됨
# VS Code 좌측 GUI에서 Docker 컨테이너를 관리할 때만 필요
# RUN code-server --install-extension ms-azuretools.vscode-docker

# 무거운 Java Extension Pack
# Spring 프로젝트를 ./gradlew build / bootRun / java -jar 정도로 사용하는 경우 필요 없음
# RUN code-server --install-extension vscjava.vscode-java-pack

# Java 코드 자동완성까지 필요하다면 Java Pack 대신 이것만 추가 가능
# RUN code-server --install-extension redhat.java


# --- 최종 캐시 정리 ---
USER root

RUN rm -rf \
    /tmp/* \
    /var/tmp/* \
    /root/.cache \
    /root/.npm \
    /home/coder/.cache \
    /home/coder/.npm

USER coder

ENV SHELL=/bin/bash
