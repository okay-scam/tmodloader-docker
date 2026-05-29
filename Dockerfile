FROM mcr.microsoft.com/dotnet/sdk:8.0

ARG TML_VERSION
# Persisted at runtime so sync-mods.sh can pick the matching mod build.
ENV TML_VERSION=${TML_VERSION}
# Provided automatically by BuildKit (amd64 / arm64); selects the DepotDownloader build.
ARG TARGETARCH
ARG DEPOTDOWNLOADER_VERSION=3.4.0

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*

# tModLoader dedicated server
RUN wget -q https://github.com/tModLoader/tModLoader/releases/download/${TML_VERSION}/tModLoader.zip \
    && unzip -q tModLoader.zip \
    && rm tModLoader.zip \
    && chmod +x *.sh

# Pre-install the exact .NET runtime tModLoader pins (it launches with roll-forward
# disabled). Without this the launcher downloads it into /app/dotnet on every fresh
# container — a multi-minute stall on each boot. Installing it here bakes it into the
# image so the launcher finds it and starts immediately. dotnet-install.sh auto-detects
# the architecture, so this works on both amd64 and arm64.
RUN DOTNET_VERSION="$(sed -n 's/^.*"version": "\(.*\)"/\1/p' tModLoader.runtimeconfig.json | tr -d '\r')" \
    && wget -q -O /tmp/dotnet-install.sh https://dot.net/v1/dotnet-install.sh \
    && bash /tmp/dotnet-install.sh \
        --channel "$(echo "$DOTNET_VERSION" | cut -f1,2 -d'.')" \
        --runtime dotnet \
        --version "$DOTNET_VERSION" \
        --install-dir /app/dotnet \
    && rm /tmp/dotnet-install.sh

# DepotDownloader: a managed (.NET) Steam content downloader. The self-contained build
# runs natively on amd64 and arm64 with no emulation, so Workshop mods download anywhere.
RUN case "${TARGETARCH}" in \
        amd64) DD_ARCH=linux-x64 ;; \
        arm64) DD_ARCH=linux-arm64 ;; \
        *) echo "unsupported TARGETARCH='${TARGETARCH}'" >&2; exit 1 ;; \
    esac \
    && wget -q -O /tmp/dd.zip "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOTDOWNLOADER_VERSION}/DepotDownloader-${DD_ARCH}.zip" \
    && mkdir -p /opt/depotdownloader \
    && unzip -q /tmp/dd.zip -d /opt/depotdownloader \
    && chmod +x /opt/depotdownloader/DepotDownloader \
    && rm /tmp/dd.zip

COPY entrypoint.sh sync-mods.sh /app/
RUN chmod +x /app/entrypoint.sh /app/sync-mods.sh

RUN chown -R 1001:1001 /app

EXPOSE 7777

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["./start-tModLoaderServer.sh", "-nosteam", "-savedirectory", "/app/data"]
