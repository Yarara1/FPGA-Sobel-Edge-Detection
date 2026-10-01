"""
bram_hex_to_image.py

Read a BRAM output stored as hexadecimal values and reconstruct
the 100x100 grayscale Sobel output image.

The least-significant 8 bits of each BRAM word are interpreted
as one grayscale pixel.
"""

from pathlib import Path
import argparse
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image


OUTPUT_WIDTH = 100
OUTPUT_HEIGHT = 100
NUM_PIXELS = OUTPUT_WIDTH * OUTPUT_HEIGHT


def read_bram_hex(hex_path: Path):
    values = []

    with open(hex_path, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            value = int(line, 16)

            # Pixel is stored in lowest 8 bits
            pixel = value & 0xFF

            values.append(pixel)

    if len(values) < NUM_PIXELS:
        raise ValueError(
            f"Expected at least {NUM_PIXELS} values, "
            f"but only found {len(values)}."
        )

    pixels = np.array(
        values[:NUM_PIXELS],
        dtype=np.uint8
    )

    return pixels


def main():
    parser = argparse.ArgumentParser(
        description="Convert BRAM HEX output into a grayscale image."
    )

    parser.add_argument(
        "input",
        type=Path,
        help="BRAM output HEX file."
    )

    parser.add_argument(
        "--save",
        type=Path,
        default=None,
        help="Optional path to save reconstructed PNG image."
    )

    args = parser.parse_args()

    pixels = read_bram_hex(args.input)

    print(f"Pixels: {len(pixels)}")
    print(f"Min: {pixels.min()}")
    print(f"Max: {pixels.max()}")

    print(
        "First 20:",
        [f"{value:02X}" for value in pixels[:20]]
    )

    image = pixels.reshape(
        (OUTPUT_HEIGHT, OUTPUT_WIDTH)
    )

    if args.save:
        args.save.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(image, mode="L").save(args.save)
        print(f"Saved image: {args.save}")

    plt.figure(figsize=(6, 6))
    plt.imshow(
        image,
        cmap="gray",
        vmin=0,
        vmax=255
    )
    plt.title("FPGA Sobel Output - BRAM HEX")
    plt.axis("off")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
