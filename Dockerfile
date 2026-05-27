FROM mcr.microsoft.com/dotnet/sdk:8.0

ARG TML_VERSION

WORKDIR /app

# steamcmd is 32-bit; install full i386 runtime on amd64 (do not overlay partial libc copies)
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip python3 \
        libc6:i386 libstdc++6:i386 libgcc-s1:i386 \
        locales \
    && sed -i '/en_US.UTF-8/s/# //g' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
# Avoid steam runtime shim issues inside minimal containers
ENV STEAM_RUNTIME=0

RUN wget https://github.com/tModLoader/tModLoader/releases/download/${TML_VERSION}/tModLoader.zip \
    && unzip tModLoader.zip \
    && rm tModLoader.zip \
    && chmod +x *.sh

RUN mkdir -p /app/steamcmd \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /app/steamcmd

COPY entrypoint.sh sync-mods.sh extract-mod-name.py /app/
RUN chmod +x /app/entrypoint.sh /app/sync-mods.sh /app/extract-mod-name.py

RUN chown -R 1001:1001 /app

EXPOSE 7777

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["./start-tModLoaderServer.sh", "-savedirectory", "/app/data"]
