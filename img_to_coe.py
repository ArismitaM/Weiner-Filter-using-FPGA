from PIL import Image
import numpy as np

W_SRC, H_SRC = 320, 240

def save_coe_hex(byte_list, path):
    with open(path, "w", newline="\n") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for i, v in enumerate(byte_list):
            sep = "," if i != len(byte_list) - 1 else ";"
            f.write(f"{v:02X}{sep}\n")
    print(f"Wrote {path}: {len(byte_list)} words, 8-bit each")

def image_to_8bit_coe(img_path, out_coe="image_320x240_8bit.coe"):
    im = Image.open(img_path).convert("L").resize((W_SRC, H_SRC))
    arr = np.asarray(im, dtype=np.uint8).flatten().tolist()
    save_coe_hex(arr, out_coe)

# Example:
image_to_8bit_coe("tiger.png")

data = open("image_320x240_8bit.coe").read()
values = data.split("=")[1].replace(";", "").split(",")
print(len(values))

