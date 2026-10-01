"""
bram_bin_to_image.py

Decode FPGA BRAM binary output stored as 32-bit little-endian words.

Each FPGA BRAM word contains one 8-bit grayscale Sobel output pixel
in bits [7:0].

Example:

    Binary bytes:
        4E 00 00 00

    32-bit word:
        0x0000004E

    Pixel:
        0x4E = 78
"""

from pathlib import Path
import argparse
import struct
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image


OUTPUT_WIDTH = 100
OUTPUT_HEIGHT = 100
NUM_PIXELS = OUTPUT_WIDTH * OUTPUT_HEIGHT
BYTES_PER_WORD = 4


def read_wordspaced_binary(bin_path: Path):
    with open(bin_path, "rb") as f:
        raw = f.read()

    print(f"Raw bytes: {len(raw)}")

    if len(raw) % BYTES_PER_WORD != 0:
        raise ValueError(
            "Binary file size is not divisible by 4 bytes. "
            "Expected 32-bit word-spaced data."
        )

    num_words = len(raw) // BYTES_PER_WORD

    words = struct.unpack(
        "<" + "I" * num_words,
        raw
    )

    if len(words) < NUM_PIXELS:
        raise ValueError(
            f"Expected at least {NUM_PIXELS} words, "
            f"but found {len(words)}."
        )

    # Keep only the lowest byte of every 32-bit word
    pixels = np.array(
        [word & 0xFF for word in words[:NUM_PIXELS]],
        dtype=np.uint8
    )

    return pixels


def main():
    parser = argparse.ArgumentParser(
        description="Convert 32-bit word-spaced BRAM binary output to image."
    )

    parser.add_argument(
        "input",
        type=Path,
        help="BRAM binary output file."
    )

    parser.add_argument(
        "--save",
        type=Path,
        default=None,
        help="Optional output PNG path."
    )

    args = parser.parse_args()

    pixels = read_wordspaced_binary(args.input)

    print(f"Pixels: {len(pixels)}")
    print(f"Min: {pixels.min()}")
    print(f"Max: {pixels.max()}")

    print(
        "First 20:",
        [f"{pixel:02X}" for pixel in pixels[:20]]
    )

    image = pixels.reshape(
        (OUTPUT_HEIGHT, OUTPUT_WIDTH)
    )

    print(f"Image shape: {image.shape}")

    if args.save:
        args.save.parent.mkdir(parents=True, exist_ok=True)

        Image.fromarray(
            image,
            mode="L"
        ).save(args.save)

        print(f"Saved image: {args.save}")

    plt.figure(figsize=(6, 6))
    plt.imshow(
        image,
        cmap="gray",
        vmin=0,
        vmax=255
    )
    plt.title("FPGA Sobel Output - BRAM Binary")
    plt.axis("off")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
