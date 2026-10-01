"""
txt_to_wordspaced_bin.py

Convert a text file containing one grayscale pixel value per line
into a 32-bit word-spaced binary file.

Each 8-bit pixel is stored in the least-significant byte of a
32-bit little-endian word:

    Pixel 0x4E -> 4E 00 00 00

For the Sobel project:
    Input image: 102 x 102
    Number of pixels: 10,404
"""

from pathlib import Path
import argparse
import struct


def convert_txt_to_bin(txt_path: Path, output_path: Path):
    # Read integer pixel values
    with open(txt_path, "r") as f:
        pixels = [
            int(line.strip())
            for line in f
            if line.strip()
        ]

    print(f"Pixels: {len(pixels)}")

    if pixels:
        print(f"Min pixel: {min(pixels)}")
        print(f"Max pixel: {max(pixels)}")

    expected_pixels = 102 * 102

    if len(pixels) != expected_pixels:
        print(
            f"Warning: expected {expected_pixels} pixels "
            f"for a 102x102 image, but found {len(pixels)}."
        )

    # Validate pixel range
    for index, value in enumerate(pixels):
        if not 0 <= value <= 255:
            raise ValueError(
                f"Pixel {index} has value {value}, "
                "which is outside the valid 8-bit range 0-255."
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Store each pixel as one 32-bit little-endian word
    with open(output_path, "wb") as f:
        for value in pixels:
            f.write(struct.pack("<I", value))

    print(f"Saved: {output_path}")
    print(f"Output bytes: {len(pixels) * 4}")


def main():
    parser = argparse.ArgumentParser(
        description="Convert grayscale pixel TXT data to 32-bit word-spaced binary."
    )

    parser.add_argument(
        "input",
        type=Path,
        help="Input TXT file containing one grayscale pixel value per line."
    )

    parser.add_argument(
        "output",
        type=Path,
        help="Output binary file."
    )

    args = parser.parse_args()

    convert_txt_to_bin(args.input, args.output)


if __name__ == "__main__":
    main()
