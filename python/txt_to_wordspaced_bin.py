from pathlib import Path

txt_path = Path("data/input/input_image.txt")
out_path = Path("data/binary/input_image_wordspaced.bin")

with open(txt_path, "r") as f:
    vals = [int(line.strip()) for line in f if line.strip()]

print("Pixels:", len(vals))
print("Min:", min(vals), "Max:", max(vals))

with open(out_path, "wb") as f:
    for v in vals:
        if not (0 <= v <= 255):
            raise ValueError(f"Pixel value out of range: {v}")

        # Store one 8-bit pixel in the LSB of a 32-bit word
        f.write(bytes([v, 0x00, 0x00, 0x00]))

print("Saved:", out_path)
print("Output bytes:", len(vals) * 4)
