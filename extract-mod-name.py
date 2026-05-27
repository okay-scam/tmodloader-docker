#!/usr/bin/env python3
"""Read the internal mod name from a .tmod file (tModLoader binary format)."""

import struct
import sys


def read7bit_int(data: bytes, offset: int) -> tuple[int, int]:
    result = 0
    shift = 0
    while offset < len(data):
        b = data[offset]
        offset += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, offset
        shift += 7
    raise ValueError("Invalid 7-bit encoded integer")


def read_dotnet_string(data: bytes, offset: int) -> tuple[str, int]:
    length, offset = read7bit_int(data, offset)
    end = offset + length
    return data[offset:end].decode("utf-8"), end


def mod_name_from_tmod(path: str) -> str:
    with open(path, "rb") as f:
        data = f.read()

    if data[:4] != b"TMOD":
        raise ValueError(f"Not a .tmod file: {path}")

    offset = 4
    _, offset = read_dotnet_string(data, offset)  # tML version
    offset += 20  # hash
    offset += 256  # signature
    offset += 4  # file data length
    name, _ = read_dotnet_string(data, offset)
    return name


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: extract-mod-name.py <path/to/mod.tmod>", file=sys.stderr)
        sys.exit(1)
    print(mod_name_from_tmod(sys.argv[1]))


if __name__ == "__main__":
    main()
