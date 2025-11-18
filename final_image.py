# import serial
# import numpy as np
# from PIL import Image

# W, H = 320, 240
# PORT = "COM12"
# BAUD = 115200

# ser = serial.Serial(PORT, BAUD, timeout=1)

# print("Reading pixels...")

# data = []
# while len(data) < W * H:
#     b = ser.read(1)
#     if b:
#         data.append(b[0])
#         if len(data) % 1000 == 0:
#             print(f"{len(data)} / 76800")

# print("Done!")

# img = np.array(data, dtype=np.uint8).reshape(H, W)
# Image.fromarray(img).save("fpga_output.png")

# ser.close()

# # img = Image.open("woman_hat.png")
# # img.show()

import serial
import numpy as np
from PIL import Image

W, H = 320, 240
PORT = "COM12"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=1)

print("Reading pixels...")

data = []
while len(data) < W * H:
    b = ser.read(1)
    if b:
        data.append(b[0])
        if len(data) % 1000 == 0:
            print(f"{len(data)} / {W*H}")

print("Done!")

# Build grayscale image
img = np.array(data, dtype=np.uint8).reshape(H, W)
full_img = Image.fromarray(img)

# ---- CROP TOP-LEFT IMAGE (160×120) ----
crop_box = (0, 0, W//2, H//2)
cropped = full_img.crop(crop_box)

# ---- RESIZE CROPPED IMAGE TO 320×240 ----
resized = cropped.resize((W, H), Image.NEAREST)  # or Image.BILINEAR / Image.LANCZOS

# Save images
full_img.save("fpga_output_full.png")
cropped.save("fpga_output_cropped.png")
resized.save("fpga_output_resized_filfil.png")

# Display final 320×240 image
resized.show()

ser.close()
