FROM myoung34/github-runner:latest

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        docker.io \
        git \
        jq \
        sudo \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nix /etc/nix/aws \
    && printf '%s\n' \
        'experimental-features = nix-command flakes' \
        'substituters = https://cache.nixos.org https://nix-postgres-artifacts.s3.amazonaws.com' \
        'trusted-public-keys = nix-postgres-artifacts:dGZlQOvKcNEjvT7QEAJbcV6b6uk7VF/hWMjhYleiaLI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
        > /etc/nix/nix.conf

RUN runner_name="$(getent passwd 1000 | cut -d: -f1 || true)" \
    && if [ -z "$runner_name" ]; then runner_name=runner; fi \
    && runner_home="$(getent passwd "$runner_name" | cut -d: -f6)" \
    && mkdir -p "$runner_home/.config/nix" \
    && chown -R "$runner_name":"$runner_name" "$runner_home/.config" \
    && su - "$runner_name" -c 'curl -L https://releases.nixos.org/nix/nix-2.34.6/install | sh -s -- --no-daemon' \
    && printf '%s\n' \
        'experimental-features = nix-command flakes' \
        'substituters = https://cache.nixos.org https://nix-postgres-artifacts.s3.amazonaws.com' \
        'trusted-public-keys = nix-postgres-artifacts:dGZlQOvKcNEjvT7QEAJbcV6b6uk7VF/hWMjhYleiaLI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
        > "$runner_home/.config/nix/nix.conf" \
    && chown "$runner_name":"$runner_name" "$runner_home/.config/nix/nix.conf"

ENV PATH="/home/runner/.nix-profile/bin:${PATH}"
ENV NIX_CONFIG="experimental-features = nix-command flakes"
ENV RUN_AS_ROOT=false
