# Fetch steamcmd tarball on the native build platform (avoids apt-get under QEMU in steamcmd image).
FROM --platform=$BUILDPLATFORM alpine:3.19 AS steam-bundle
RUN apk add --no-cache curl tar
WORKDIR /bundle
RUN curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - \
    && mkdir -p bin \
    && cp steamcmd.sh bin/ \
    && cp linux32/steamcmd bin/linux32_steamcmd \
    && cp linux32/libstdc++.so.6 .

FROM mcr.microsoft.com/dotnet/sdk:8.0

ARG BUILDPLATFORM
ARG TARGETARCH
ARG TML_VERSION

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=steam-bundle /bundle /tmp/steamcmd-bundle
COPY install-steamcmd.sh /tmp/install-steamcmd.sh
RUN chmod +x /tmp/install-steamcmd.sh \
    && BUILDPLATFORM=$BUILDPLATFORM TARGETARCH=$TARGETARCH /tmp/install-steamcmd.sh \
    && rm -rf /tmp/steamcmd-bundle /tmp/install-steamcmd.sh

RUN wget https://github.com/tModLoader/tModLoader/releases/download/${TML_VERSION}/tModLoader.zip \
    && unzip tModLoader.zip \
    && rm tModLoader.zip \
    && chmod +x *.sh

COPY entrypoint.sh sync-mods.sh /app/
RUN chmod +x /app/entrypoint.sh /app/sync-mods.sh

RUN chown -R 1001:1001 /app

EXPOSE 7777

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["./start-tModLoaderServer.sh", "-savedirectory", "/app/data"]
