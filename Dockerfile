# steamcmd bundle is built on amd64 (x86-only); game server image is multi-arch like cubebuc.
FROM --platform=linux/amd64 steamcmd/steamcmd:ubuntu-22 AS steam-builder

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /bundle
RUN curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - \
    && mkdir -p i386-lib bin \
    && cp -a /lib/i386-linux-gnu/. i386-lib/ \
    && cp linux32/libstdc++.so.6 . \
    && cp steamcmd.sh bin/ \
    && cp linux32/steamcmd bin/linux32_steamcmd \
    && cp /usr/games/steamcmd bin/steamcmd_wrapper

FROM mcr.microsoft.com/dotnet/sdk:8.0

ARG TARGETARCH
ARG TML_VERSION

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=steam-builder /bundle /tmp/steamcmd-bundle
COPY install-steamcmd.sh /tmp/install-steamcmd.sh
RUN chmod +x /tmp/install-steamcmd.sh && TARGETARCH=$TARGETARCH /tmp/install-steamcmd.sh \
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
