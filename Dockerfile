# syntax=docker/dockerfile:1.4
# 1.4: minimum version for heredoc support in RUN (used for nix config below)

#╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
#║ Supabase PostgreSQL image with Nix extensions — parameterised by major version.                                   ║
#║                                                                                                                   ║
#║ Build (defaults to PostgreSQL 17):                                                                                ║
#║   docker build --target=postgres -t supabase-postgres:17 .                                                        ║
#║                                                                                                                   ║
#║ Build for a different PostgreSQL version:                                                                         ║
#║   docker build --build-arg=PG_VERSION=15 --target=postgres -t supabase-postgres:15 .                              ║
#║                                                                                                                   ║
#║ Build for OrioleDB:                                                                                               ║
#║   docker build --build-arg=PG_VERSION=17 --build-arg=VARIANT=orioledb --target=postgres -t supabase-orioledb:17 . ║
#║                                                                                                                   ║
#║ Build for Multigres:                                                                                              ║
#║   docker build --build-arg=PG_VERSION=17 --target=multigres -t supabase-multigres:17 .                            ║
#╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

# Put all ARGs up top for better discoverability
# Use non-versioned `ARG THE_ARG` in the layer that uses it to get the ref to this one
ARG ALPINE_VERSION=3.23
ARG GOSU_VERSION=1.19
ARG PGCTLD_REV=1e3bad798972600778ee27eb08ab7d34cc8be8e9 # Pinned to the commit that introduced --pg-initdb-sql-dirs (MUL-484)
ARG PG_VERSION=17
ARG VARIANT

#╔════════════════════════════════╗
#║        Postgres + Exts         ║
#╚════════════════════════════════╝
FROM alpine:${ALPINE_VERSION} AS pg
ARG PG_VERSION
ARG VARIANT

RUN <<EOF
case $PG_VERSION:$VARIANT in
 15: | 17: | 17:orioledb) ;;
 15:orioledb) echo "OrioleDB not supported on PG17" >&2 && exit 1;;
 17:*) echo "Unknown VARIANT ($VARIANT) only orioledb supported" >&2 && exit 1;;
 *) echo "Unknown PG_VERSION ($PG_VERSION) only 15,17 supported" >&2 && exit 1;;
esac
EOF

# Install dependencies for nix installer (coreutils for GNU cp, sudo for installer)
RUN apk add --no-cache \
    bash \
    coreutils \
    curl \
    shadow \
    sudo \
    xz

# Create nix config
RUN cat >/tmp/extra-nix.conf <<EOF
extra-experimental-features = nix-command flakes
extra-substituters = https://nix-postgres-artifacts.s3.amazonaws.com
extra-trusted-public-keys = nix-postgres-artifacts:dGZlQOvKcNEjvT7QEAJbcV6b6uk7VF/hWMjhYleiaLI=
EOF
RUN curl -L https://releases.nixos.org/nix/nix-2.34.6/install | sh -s -- --daemon --no-channel-add --yes --nix-extra-conf-file /tmp/extra-nix.conf
ENV PATH="$PATH:/nix/var/nix/profiles/default/bin"
RUN nix --version

WORKDIR /nixpg
COPY flake.* .
COPY nix/ ./nix
COPY .git/ .git/

# Build PostgreSQL with extensions
RUN attr=psql_${VARIANT:+$VARIANT-}${PG_VERSION}_slim/bin && \
    echo Building $attr && \
    nix profile add path:.#$attr

# Build groonga and copy plugins
RUN nix profile add path:.#supabase-groonga && \
    mkdir -p /tmp/groonga-plugins && \
    cp -r /nix/var/nix/profiles/default/lib/groonga/plugins /tmp/groonga-plugins/

RUN nix store gc && nix store optimise

#╔═════════════════════════════════════════════╗
#║                     Gosu                    ║
#╚═════════════════════════════════════════════╝
FROM golang:1.26-alpine${ALPINE_VERSION} AS gosu
ARG GOSU_VERSION

RUN apk add --no-cache curl git
# Build gosu from source
RUN git clone --depth 1 --branch "${GOSU_VERSION}" https://github.com/tianon/gosu.git /gosu && \
    cd /gosu && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o /usr/local/bin/gosu . && \
    chmod +x /usr/local/bin/gosu && \
    /usr/local/bin/gosu --version

#╔═══════════════════════════════════════════════╗
#║                     pgctld                    ║
#╚═══════════════════════════════════════════════╝
FROM golang:1.25-alpine${ALPINE_VERSION} AS pgctld
ARG PGCTLD_REV

RUN apk add --no-cache git

RUN git clone https://github.com/multigres/multigres.git /multigres && \
    cd /multigres && \
    git checkout ${PGCTLD_REV} && \
    # Copy pico CSS assets before build (mirrors pgctld.nix preBuild step)
    cp external/pico/pico.* go/common/web/templates/css/ 2>/dev/null || true && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o /usr/local/bin/pgctld ./go/cmd/pgctld

#╔══════════════════════════════════════╗
#║           Production Image           ║
#╚══════════════════════════════════════╝
FROM alpine:${ALPINE_VERSION} AS postgres
ARG ALPINE_VERSION
ARG PG_VERSION

# Install minimal runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    shadow \
    su-exec \
    tzdata \
    musl-locales \
    musl-locales-lang \
    && rm -rf /var/cache/apk/*

# Create postgres user/group
RUN addgroup -S postgres && \
    adduser -S -G postgres -h /var/lib/postgresql -s /bin/bash postgres && \
    addgroup -S wal-g && \
    adduser -S -G wal-g -s /bin/bash wal-g && \
    adduser postgres wal-g

# Copy Nix store and profiles from builder (profile already created by nix profile install)
COPY --from=pg /nix /nix

# Copy groonga plugins
COPY --from=pg /tmp/groonga-plugins/plugins /usr/lib/groonga/plugins

# Copy gosu
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu

# Setup PostgreSQL directories
RUN mkdir -p /usr/lib/postgresql/bin \
    /usr/lib/postgresql/share/postgresql \
    /usr/share/postgresql \
    /var/lib/postgresql/data \
    /var/run/postgresql \
    && chown -R postgres:postgres /usr/lib/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chown -R postgres:postgres /usr/share/postgresql \
    && chown -R postgres:postgres /var/run/postgresql

# Create symbolic links for binaries
RUN for f in /nix/var/nix/profiles/default/bin/*; do \
        ln -sf "$f" /usr/lib/postgresql/bin/ 2>/dev/null || true; \
        ln -sf "$f" /usr/bin/ 2>/dev/null || true; \
    done

# Create symbolic links for PostgreSQL shares
RUN ln -sf /nix/var/nix/profiles/default/share/postgresql/* /usr/lib/postgresql/share/postgresql/ 2>/dev/null || true && \
    ln -sf /nix/var/nix/profiles/default/share/postgresql/* /usr/share/postgresql/ 2>/dev/null || true && \
    ln -sf /usr/lib/postgresql/share/postgresql/timezonesets /usr/share/postgresql/timezonesets 2>/dev/null || true

# Set permissions
RUN chown -R postgres:postgres /usr/lib/postgresql && \
    chown -R postgres:postgres /usr/share/postgresql

# Setup configs
COPY --chown=postgres:postgres ansible/files/postgresql_config/postgresql.conf.j2 /etc/postgresql/postgresql.conf
COPY --chown=postgres:postgres ansible/files/postgresql_config/pg_hba.conf.j2 /etc/postgresql/pg_hba.conf
COPY --chown=postgres:postgres ansible/files/postgresql_config/pg_ident.conf.j2 /etc/postgresql/pg_ident.conf
COPY --chown=postgres:postgres ansible/files/postgresql_config/conf.d /etc/postgresql/postgresql.conf.d
COPY --chown=postgres:postgres ansible/files/postgresql_config/postgresql-stdout-log.conf /etc/postgresql/logging.conf
COPY --chown=postgres:postgres ansible/files/postgresql_config/supautils.conf.j2 /etc/postgresql-custom/supautils.conf
COPY --chown=postgres:postgres ansible/files/postgresql_extension_custom_scripts /etc/postgresql-custom/extension-custom-scripts
COPY --chown=postgres:postgres ansible/files/pgsodium_getkey_urandom.sh.j2 /usr/lib/postgresql/bin/pgsodium_getkey.sh
COPY --chown=postgres:postgres ansible/files/postgresql_config/custom_walg.conf /etc/postgresql-custom/wal-g.conf
COPY --chown=postgres:postgres ansible/files/postgresql_config/custom_read_replica.conf /etc/postgresql-custom/read-replica.conf
COPY --chown=postgres:postgres ansible/files/walg_helper_scripts/wal_fetch.sh /home/postgres/wal_fetch.sh
COPY ansible/files/walg_helper_scripts/wal_change_ownership.sh /root/wal_change_ownership.sh

# Configure PostgreSQL settings
RUN sed -i \
    -e "s|#unix_socket_directories = '/tmp'|unix_socket_directories = '/var/run/postgresql'|g" \
    -e "s|#session_preload_libraries = ''|session_preload_libraries = 'supautils'|g" \
    -e "s|#include = '/etc/postgresql-custom/supautils.conf'|include = '/etc/postgresql-custom/supautils.conf'|g" \
    -e "s|#include = '/etc/postgresql-custom/wal-g.conf'|include = '/etc/postgresql-custom/wal-g.conf'|g" /etc/postgresql/postgresql.conf && \
    echo "pgsodium.getkey_script= '/usr/lib/postgresql/bin/pgsodium_getkey.sh'" >> /etc/postgresql/postgresql.conf && \
    echo "vault.getkey_script= '/usr/lib/postgresql/bin/pgsodium_getkey.sh'" >> /etc/postgresql/postgresql.conf && \
    chown -R postgres:postgres /etc/postgresql-custom && \
    ln -s /etc/postgresql/postgresql.conf.d /etc/postgresql-custom/conf.d

# pg17+ does not ship timescaledb or plv8; db_user_namespace was removed in pg17.
# Applied conditionally so the same Dockerfile works for pg15 (where these are valid).
RUN if [ "$PG_VERSION" -ge 17 ]; then \
        sed -i 's/ timescaledb,//g; s/ plv8,//g' /etc/postgresql/postgresql.conf && \
        sed -i 's/db_user_namespace = off/#db_user_namespace = off/g' /etc/postgresql/postgresql.conf && \
        sed -i 's/ timescaledb,//g; s/ plv8,//g' /etc/postgresql-custom/supautils.conf; \
    fi

# Include schema migrations
COPY migrations/db /docker-entrypoint-initdb.d/
COPY ansible/files/pgbouncer_config/pgbouncer_auth_schema.sql /docker-entrypoint-initdb.d/init-scripts/00-schema.sql
COPY ansible/files/stat_extension.sql /docker-entrypoint-initdb.d/migrations/00-extension.sql

# OrioleDB stuff if building it
RUN [[ "$VARIANT" != orioledb ]] && exit 0; \
    sed -i 's/\(shared_preload_libraries.*\)'\''\(.*\)$/\1, orioledb'\''\2/' "/etc/postgresql/postgresql.conf" && \
    echo "default_table_access_method = 'orioledb'" >> "/etc/postgresql/postgresql.conf" && \
    sed -i 's/ postgis,//g; s/ pgrouting,//g' "/etc/postgresql-custom/supautils.conf" && \
    echo "CREATE EXTENSION orioledb;" > /docker-entrypoint-initdb.d/init-scripts/00-pre-init.sql && \
    chown postgres:postgres /docker-entrypoint-initdb.d/init-scripts/00-pre-init.sql && \
    true

ADD --chmod=0755 \
    https://raw.githubusercontent.com/docker-library/postgres/6edb0a8c4def40c371514b34aef9037ec82d9110/${PG_VERSION}/alpine${ALPINE_VERSION}/docker-entrypoint.sh \
    /usr/local/bin/docker-entrypoint.sh

# Setup pgsodium key script
RUN mkdir -p /usr/share/postgresql/extension/ && \
    ln -s /usr/lib/postgresql/bin/pgsodium_getkey.sh /usr/share/postgresql/extension/pgsodium_getkey && \
    chmod +x /usr/lib/postgresql/bin/pgsodium_getkey.sh

# Environment variables
ENV PATH="/nix/var/nix/profiles/default/bin:/usr/lib/postgresql/bin:${PATH}"
ENV PGDATA=/var/lib/postgresql/data
ENV POSTGRES_HOST=/var/run/postgresql
ENV POSTGRES_USER=supabase_admin
ENV POSTGRES_DB=postgres
ENV POSTGRES_INITDB_ARGS="--allow-group-access --locale-provider=icu --encoding=UTF-8 --icu-locale=en_US.UTF-8"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV GRN_PLUGINS_DIR=/usr/lib/groonga/plugins
# Point to minimal glibc locales included in slim Nix package for initdb locale support
ENV LOCALE_ARCHIVE=/nix/var/nix/profiles/default/lib/locale/locale-archive

# Marks the container unhealthy after 10 failed pg_isready probes, which blocks
# dependent services in Docker Compose (depends_on: condition: service_healthy).
# Kubernetes ignores Docker HEALTHCHECK entirely — use readinessProbe in the Pod spec.
HEALTHCHECK --interval=2s --timeout=2s --retries=10 CMD pg_isready -U postgres -h localhost

# SIGINT triggers PostgreSQL smart shutdown: waits for active sessions to finish
# before stopping. This avoids interrupting in-flight transactions but can delay
# pod termination if long-running queries are active.
# Consider SIGTERM (fast shutdown) to disconnect clients immediately, which
# respects Kubernetes terminationGracePeriodSeconds more predictably.
STOPSIGNAL SIGINT
EXPOSE 5432

# No USER directive: the entrypoint starts as root to fix volume ownership and
# set up permissions, then drops to the postgres user via gosu before exec'ing
# the postgres process. This follows the standard official PostgreSQL image pattern.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-D", "/etc/postgresql"]

#╔═══════════════════════╗
#║       Multigres       ║
#╚═══════════════════════╝
FROM postgres AS multigres

RUN if [ "$(postgres --version | awk -F. '{print $1}')" != 'postgres (PostgreSQL) 17' ]; then \
      echo "Multigres only supports PG17, got -->$(postgres --version)<--" >&2; \
      exit 1; \
    fi

# Install pgbackrest (available in Alpine community repo)
RUN apk add --no-cache pgbackrest

# Copy pgctld binary; keep it separate so the wrapper script can reference it cleanly
COPY --from=pgctld /usr/local/bin/pgctld /usr/local/bin/pgctld-bin

# pgctld config template — /etc/pgctld is a mount point in k8s so use a custom dir
COPY docker/pgctld/postgresql.conf.tmpl /etc/pgctld-custom/postgresql.conf.tmpl

# Wrapper: injects --postgres-config-template on every pgctld call so unmodified
# k8s manifests and local provisioner commands work without extra flags
COPY --chmod=0755 docker/pgctld/pgctld /usr/local/bin/pgctld

# /etc/postgresql/postgresql.conf is not modified here: pgctld renders its own
# config from postgresql.conf.tmpl and passes it directly to PostgreSQL, so the
# supabase base config (including wal-g and data_directory settings) is never loaded.

# wal-g is not used in Multigres (pgbackrest handles backups); remove inherited files.
RUN rm -f \
    /etc/postgresql-custom/wal-g.conf \
    /home/postgres/wal_fetch.sh \
    /root/wal_change_ownership.sh

# No HEALTHCHECK defined here: inherits the probe from the supabase base image.
# Kubernetes ignores Docker HEALTHCHECK entirely — use readinessProbe in the Pod spec.
# STOPSIGNAL inherited from supabase base image (SIGINT — smart shutdown).
USER postgres

# pgctld is the cluster lifecycle manager for Multigres: it handles initdb,
# config templating, replication setup, and coordinated restarts. Running it
# as PID 1 ensures it receives stop signals directly and can shut down
# PostgreSQL cleanly before the container exits.
ENTRYPOINT ["/usr/local/bin/pgctld"]

#╔═════════╗
#║ Useless ║
#╚═════════╝
FROM scratch
RUN echo "You have tried to build this image without specifying --target" >&2 && \
    echo "Either postgres or multigres is required" >&2 && \
    echo "P.S.: You can specify PG version with --build-arg=PG_VERSION=15|17" >&2 && \
    echo "P.P.S: You can build orioledb varian with --build-arg=VARIANT=orioledb" >&2 && \
    exit 1
