FROM alpine:3.23 AS build
WORKDIR /usr/local/src/ssh
COPY resources/openssh.patch .
RUN OPENSSH_VERSION='10.2p1' && \
    ARCHIVE_SHA_256='ccc42c0419937959263fa1dbd16dafc18c56b984c03562d2937ce56a60f798b2' && \
    apk add --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -S -L -O "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" && \
    CHECKSUM=$(sha256sum "openssh-${OPENSSH_VERSION}.tar.gz" | awk '{print $1;}') && \
    echo "Checksum is $CHECKSUM" && \
    [ "$CHECKSUM" = "$ARCHIVE_SHA_256" ] && \
    echo "Checksum is valid" && \
    tar xzf "openssh-${OPENSSH_VERSION}.tar.gz" && \
    cd "openssh-${OPENSSH_VERSION}" && \
    patch -p1 < ../openssh.patch && \
    ./configure && \
    make ssh && \
    mv ssh /usr/local/bin/
WORKDIR /usr/local/src/dh-groups
RUN curl -s -S -L -O 'https://raw.githubusercontent.com/cryptosense/diffie-hellman-groups/04610a10e13db3a69c740bebac9cb26d53c520d3/gen/common.json'
COPY --from=ghcr.io/astral-sh/uv:0.9 /uv /bin/
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_INSTALL_DIR=/python
ENV UV_PYTHON_PREFERENCE=only-managed
RUN uv python install 3.14
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=resources/uv.lock,target=uv.lock \
    --mount=type=bind,source=resources/pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

FROM alpine:3.23
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
RUN apk add --no-cache bash libressl4.2-libcrypto tini
ARG UID=65532
ARG GID=65532
RUN addgroup -g "$GID" -S app && adduser -u "$UID" -G app -S app
WORKDIR /app
COPY --from=build /python /python
COPY --from=build /usr/local/src/dh-groups/common.json .
COPY --from=build /usr/local/bin/ssh .
COPY --from=build --chown=app:app /app/.venv .venv
COPY --chown=app:app resources/ssh-weak-dh-analyze.py .
COPY --chown=app:app resources/ssh-weak-dh-test.sh .
COPY --chown=app:app resources/configs/ configs/
ENV PATH="/app/.venv/bin:$PATH"
USER app
VOLUME /logs
ENTRYPOINT ["/sbin/tini", "--", "./ssh-weak-dh-test.sh"]
