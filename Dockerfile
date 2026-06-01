FROM node:22-bookworm-slim

ARG USER_UID=1000
ARG USER_GID=1000
ARG OPENCODE_NPM_SPEC=opencode-ai@latest
ARG BEADS_NPM_SPEC=@beads/bd@latest
ARG WHISPER_CPP_REF=master

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        ffmpeg \
        gh \
        git \
        jq \
        less \
        libgomp1 \
        libpulse0 \
        openssh-client \
        pkg-config \
        procps \
        ripgrep \
        xauth \
        xdotool \
        xinput \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "$OPENCODE_NPM_SPEC" "$BEADS_NPM_SPEC" \
    && mv /usr/local/bin/opencode /usr/local/bin/opencode-real

RUN git clone --depth 1 --branch "$WHISPER_CPP_REF" https://github.com/ggerganov/whisper.cpp.git /tmp/whisper.cpp \
    && cmake -S /tmp/whisper.cpp -B /tmp/whisper.cpp/build -DWHISPER_BUILD_EXAMPLES=ON -DWHISPER_BUILD_TESTS=OFF \
    && cmake --build /tmp/whisper.cpp/build --config Release -j"$(nproc)" \
    && cmake --install /tmp/whisper.cpp/build --prefix /usr/local \
    && ldconfig \
    && mkdir -p /opt/whisper/models \
    && rm -rf /tmp/whisper.cpp

RUN existing_group="$(getent group "$USER_GID" | cut -d: -f1 || true)" \
    && if [ -z "$existing_group" ]; then groupadd --gid "$USER_GID" dev; elif [ "$existing_group" != "dev" ]; then groupmod --new-name dev "$existing_group"; fi \
    && existing_user="$(getent passwd "$USER_UID" | cut -d: -f1 || true)" \
    && if [ -z "$existing_user" ]; then useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/bash dev; elif [ "$existing_user" != "dev" ]; then usermod --login dev "$existing_user"; fi \
    && usermod --home /home/dev --move-home --gid "$USER_GID" --shell /bin/bash dev \
    && mkdir -p /home/dev/.config /home/dev/.local/share /workspace \
    && chown -R "$USER_UID":"$USER_GID" /home/dev /workspace /opt/whisper

RUN git config --system pull.rebase true \
    && git config --system rebase.autoStash true \
    && git config --system fetch.prune true \
    && git config --system --add safe.directory /workspace

COPY scripts/workbench-entrypoint.sh /usr/local/bin/workbench-entrypoint.sh
COPY scripts/install-whisper-model.sh /usr/local/bin/install-whisper-model.sh
COPY scripts/opencode-wrapper.sh /usr/local/bin/opencode
COPY scripts/voice-linux-daemon.sh /usr/local/bin/voice-linux-daemon.sh
COPY scripts/whisper-transcribe.sh /usr/local/bin/whisper-transcribe

RUN chmod +x /usr/local/bin/workbench-entrypoint.sh /usr/local/bin/install-whisper-model.sh /usr/local/bin/opencode /usr/local/bin/voice-linux-daemon.sh /usr/local/bin/whisper-transcribe

USER dev
WORKDIR /workspace
