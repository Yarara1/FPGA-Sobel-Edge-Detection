# FPGA-Based Sobel Edge Detection Accelerator

Hardware implementation of a **Sobel edge detection accelerator** using Verilog, MicroBlaze, BRAM, Vitis, XSDB, and Python.

The system processes a **102×102 8-bit grayscale image** on the FPGA using a custom Sobel filter implemented in programmable logic. The resulting **100×100 edge-detected image** is stored in output BRAM and reconstructed in Python for verification.

The design was developed as part of the **EEE351 Intelligent System Design and Application** image-filtering project.

---

## Project Overview

The accelerator performs 2D Sobel filtering in hardware.

```text
102×102 Grayscale Image
        │
        ▼
Python Preprocessing
        │
        ▼
32-bit Word-Spaced Binary
        │
        ▼
      XSDB
        │
        ▼
     BRAM1
  10,404 pixels
        │
        ▼
  Sobel Accelerator
     3×3 Window
        │
        ▼
     BRAM2
  10,000 pixels
        │
        ▼
   XSDB Memory Dump
        │
        ▼
Python Reconstruction
        │
        ▼
100×100 Edge Image
```

The input image contains:

```text
102 × 102 = 10,404 pixels
```

Since the Sobel operation uses a 3×3 neighborhood without padding, the valid output region is:

```text
100 × 100 = 10,000 pixels
```

---

## Key Features

- Custom Sobel edge detector written in Verilog
- 3×3 image convolution
- 102×102 grayscale input
- 100×100 filtered output
- 8-bit grayscale pixel data
- Separate input and output BRAM memories
- MicroBlaze processor for accelerator control
- AXI BRAM Controllers for memory access
- CSR-based `start` / `done` handshaking
- XSDB-based image loading and result extraction
- Python preprocessing and output reconstruction
- Pixel-by-pixel hardware/reference verification
- Integrated Logic Analyzer (ILA) debugging

---

## System Architecture

The complete system contains:

- **MicroBlaze processor**
- **AXI Interconnect**
- **Control/Status Register (CSR)**
- **BRAM1** — input image memory
- **BRAM2** — filtered output memory
- **Custom Sobel accelerator**
- **Integrated Logic Analyzer (ILA)**

The MicroBlaze controls the accelerator through the AXI-connected control/status registers. The input image is stored in BRAM1, the Sobel computation is performed in programmable logic, and the result is written into BRAM2.

### Processing Sequence

```text
MicroBlaze / XSDB
       │
       ▼
     BRAM1
  102×102 image
       │
       ▼
 image_cntrl
       │
   3×3 window
       ▼
  sobel_core
       │
       ▼
     BRAM2
  100×100 image
```

---

## Sobel Edge Detection

The Sobel operator detects edges by calculating horizontal and vertical image gradients using two 3×3 kernels.

### Horizontal Gradient — Gx

```text
-1   0   1
-2   0   2
-1   0   1
```

### Vertical Gradient — Gy

```text
-1  -2  -1
 0   0   0
 1   2   1
```

For every valid image position, the accelerator processes a 3×3 pixel window and computes:

```text
Sx = horizontal gradient
Sy = vertical gradient
```

Instead of calculating:

```text
sqrt(Sx² + Sy²)
```

the hardware uses:

```text
|Sx| + |Sy|
```

This avoids implementing a hardware square-root operation.

The final value is saturated to 8 bits:

```text
if result > 255:
    output = 255
else:
    output = result
```

---

## RTL Architecture

The custom accelerator consists of three main Verilog modules:

```text
rtl/
├── image_top.v
├── image_cntrl.v
├── sobel_core.v
└── ip/
    ├── BRAM1.xci
    └── BRAM2.xci
```

### `image_top.v`

`image_top` is the top-level image-processing module.

It connects:

```text
image_cntrl
     │
     ├── BRAM1
     ├── BRAM2
     └── sobel_core
```

For each output pixel, nine 8-bit neighboring pixels are combined into a:

```text
9 × 8 bits = 72-bit pixel window
```

This window is passed to `sobel_core`, and the resulting 8-bit Sobel value is written into BRAM2.

### `image_cntrl.v`

The controller is implemented as a finite state machine.

For each output position, it:

1. Generates the required BRAM1 addresses
2. Reads nine neighboring pixels
3. Forms a 3×3 pixel window
4. Sends the pixel window to `sobel_core`
5. Writes the Sobel result into BRAM2
6. Advances to the next output pixel
7. Asserts `done` after the full image has been processed

The 3×3 neighborhood is represented as:

```text
p00 p01 p02
p10 p11 p12
p20 p21 p22
```

For the input image:

```text
input_address = row × 102 + column
```

For the output image:

```text
output_address = row × 100 + column
```

### `sobel_core.v`

`sobel_core` performs the Sobel computation.

The module receives:

```text
9 pixels × 8 bits = 72 bits
```

The unsigned image pixels are extended before signed arithmetic is performed.

The hardware computes:

```text
Sx
Sy
|Sx|
|Sy|
|Sx| + |Sy|
```

The final output is saturated to the unsigned 8-bit range.

---

## BRAM Architecture

Two separate BRAM memories are used.

| Memory | Purpose | Resolution | Data Width | Depth |
|---|---|---:|---:|---:|
| BRAM1 | Input image | 102×102 | 8-bit | 10,404 |
| BRAM2 | Sobel output | 100×100 | 8-bit | 10,000 |

Pixels are stored in row-major order.

### BRAM1

```text
address = row × 102 + column
```

### BRAM2

```text
address = row × 100 + column
```

Using separate input and output memories simplifies control and hardware debugging.

---

## 32-Bit Word-Spaced Data Format

The AXI BRAM interface operates with 32-bit data, while each grayscale image pixel is only 8 bits.

Therefore, each pixel is stored in the least-significant byte of a 32-bit word.

For example:

```text
Pixel value = 0x4E

Stored as:

4E 00 00 00
```

Conceptually:

```text
31                         8 7          0
+---------------------------+------------+
|          0x000000         |   Pixel    |
+---------------------------+------------+
```

Because each 8-bit pixel occupies one 32-bit word, the lower two AXI address bits are ignored when mapping addresses to the internal BRAM pixel address.

For the complete input image:

```text
10,404 pixels × 4 bytes = 41,616 bytes
```

---

## Hardware / Software Control

The MicroBlaze processor is mainly used to control the accelerator.

The actual image processing runs in programmable logic.

The control interface uses:

```text
start ──► FPGA accelerator
done  ◄── FPGA accelerator
```

The processor:

1. Clears the start signal
2. Generates a start pulse
3. Polls the done register
4. Waits until hardware processing is complete

---

## Vitis and XSDB Flow

The full image was not embedded directly into the Vitis application.

Instead, the image was converted into a word-spaced binary file and loaded into BRAM1 using XSDB.

This reduced MicroBlaze program-memory usage and made the build process more reliable.

The hardware testing flow was:

```text
1. Program FPGA
2. Connect to MicroBlaze through XSDB
3. Download the Vitis ELF
4. Load the binary image into BRAM1
5. Read back BRAM1 addresses for verification
6. Run the accelerator
7. Wait for the done signal
8. Check BRAM2 output values
9. Dump BRAM2 contents
10. Reconstruct the result using Python
```

---

## Python Utilities

The repository contains Python scripts for preparing the input image and verifying the FPGA output.

```text
python/
├── txt_to_wordspaced_bin.py
├── bram_hex_to_image.py
├── bram_bin_to_image.py
├── compare_hw_output.py
└── requirements.txt
```

### `txt_to_wordspaced_bin.py`

Converts grayscale pixel values stored in text format into 32-bit word-spaced binary data.

```text
input_image.txt
       │
       ▼
8-bit grayscale pixels
       │
       ▼
32-bit little-endian words
       │
       ▼
input_image_wordspaced.bin
```

### `bram_bin_to_image.py`

Reads the dumped BRAM2 binary file.

Each 32-bit word is decoded and the lowest 8 bits are extracted:

```python
pixel = word & 0xFF
```

The first 10,000 pixels are reshaped into:

```text
100 × 100
```

### `bram_hex_to_image.py`

Provides the same reconstruction process when the BRAM output is available in hexadecimal format.

### `compare_hw_output.py`

Compares the FPGA output against the expected Sobel result pixel-by-pixel.

The script calculates:

- Number of mismatched pixels
- Maximum absolute difference
- Mean absolute difference

---

## Verification Results

The reconstructed FPGA result was compared directly with the reference Sobel output.

```text
BRAM raw bytes: 160000
HW image shape: (100, 100)
Answer image shape: (100, 100)

Mismatched pixels: 0 / 10000
Max difference: 0
Mean difference: 0.0

PASS: HW output matches answer PNG exactly.
```

The FPGA-generated output therefore matched the expected result for all **10,000 output pixels**.

---

## Hardware Debugging

Vivado's **Integrated Logic Analyzer (ILA)** was used to observe internal FPGA signals during operation.

Signals monitored included:

- `start`
- `done`
- BRAM1 enable
- BRAM1 address
- BRAM1 read data
- BRAM2 enable
- BRAM2 address
- BRAM2 write data

This was used to verify that:

- BRAM1 was read correctly
- Pixel addresses were generated correctly
- The Sobel core produced output data
- BRAM2 writes occurred correctly
- Start/done handshaking worked correctly

---

## Implementation Challenges

### AXI / BRAM Address Mapping

One major issue was the difference between:

```text
AXI interface: 32-bit words
Image pixels: 8-bit values
```

Since every pixel occupied one 32-bit word, the lower two AXI address bits had to be ignored.

Correcting the address slicing fixed the BRAM data alignment.

### MicroBlaze Program Memory

Initially, storing the complete image array inside the Vitis program increased the ELF size and caused memory-related build issues.

The final solution was:

```text
Python
   │
   ▼
Word-Spaced Binary
   │
   ▼
XSDB
   │
   ▼
BRAM1
```

This reduced the memory requirements of the MicroBlaze application.

### Vitis Linker Script

The Vitis linker script also required adjustment so that program sections were mapped to the correct MicroBlaze local memory.

Correcting the linker configuration allowed the ELF to execute correctly on the processor.

---

## Repository Structure

```text
FPGA-Sobel-Edge-Detection/
│
├── README.md
├── .gitignore
├── LICENSE
│
├── rtl/
│   ├── image_top.v
│   ├── image_cntrl.v
│   ├── sobel_core.v
│   └── ip/
│       ├── BRAM1.xci
│       └── BRAM2.xci
│
├── software/
│   └── vitis/
│       └── main.c
│
├── python/
│   ├── txt_to_wordspaced_bin.py
│   ├── bram_hex_to_image.py
│   ├── bram_bin_to_image.py
│   ├── compare_hw_output.py
│   └── requirements.txt
│
├── constraints/
│   └── Arty-A7-100-Master.xdc
│
├── data/
│   ├── input/
│   ├── binary/
│   ├── reference/
│   └── output/
│
└── results/
    ├── timing_summary.txt
    ├── utilization_summary.txt
    └── power_summary.txt
```

---

## Running the Python Utilities

Install the required Python libraries:

```bash
pip install -r python/requirements.txt
```

Convert the input pixel file into word-spaced binary:

```bash
python python/txt_to_wordspaced_bin.py \
    data/input/input_image.txt \
    data/binary/input_image_wordspaced.bin
```

Reconstruct the FPGA output:

```bash
python python/bram_bin_to_image.py \
    data/output/bram2_output.bin \
    --save data/output/fpga_sobel_output.png
```

Compare the FPGA result against the reference:

```bash
python python/compare_hw_output.py \
    data/output/bram2_output.bin \
    data/reference/answer_image.png
```

---

## Tools & Technologies

- Verilog
- Xilinx Vivado
- Xilinx Vitis
- MicroBlaze
- AXI Interconnect
- AXI BRAM Controller
- Block RAM
- XSDB
- Integrated Logic Analyzer
- Python
- NumPy
- Matplotlib
- Pillow

---

## What This Project Demonstrates

This project demonstrates:

- FPGA-based image processing
- 2D convolution hardware
- Sobel edge detection
- Signed fixed-width arithmetic
- FSM-based control
- BRAM addressing and memory mapping
- AXI / 8-bit data-width adaptation
- MicroBlaze hardware/software integration
- Vitis embedded software
- XSDB memory access
- ILA-based debugging
- Python-based hardware verification

The main challenge was not only implementing the Sobel algorithm itself, but also integrating the custom hardware accelerator with the processor, BRAM architecture, AXI interface, Vitis software, and FPGA debugging flow.
