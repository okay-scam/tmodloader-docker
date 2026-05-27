FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends libc6:i386 \
    && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:8.0

ARG TML_VERSION

WORKDIR /app

# steamcmd is 32-bit; copy i386 libc from builder (works on ARM hosts too)
COPY --from=builder \
    /lib/i386-linux-gnu/ld-linux.so.2 \
    /lib/i386-linux-gnu/libc.so.6 \
    /lib/i386-linux-gnu/libdl.so.2 \
    /lib/i386-linux-gnu/libm.so.6 \
    /lib/i386-linux-gnu/libpthread.so.0 \
    /lib/i386-linux-gnu/librt.so.1 \
    /lib/

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip python3 \
    && rm -rf /var/lib/apt/lists/*

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
