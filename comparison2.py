from PIL import Image
import numpy as np
import math

# Load your images (must be same size and grayscale)
orig = np.array(Image.open("fpga_output_resized_fil.png").convert("L"), dtype=np.float32)
filt = np.array(Image.open("fpga_output_resized_filfil.png").convert("L"), dtype=np.float32)

# Ensure both have the same shape
if orig.shape != filt.shape:
    print("Images must have the same size!")
    exit()

# ---- Compute MSE (Mean Squared Error) ----
mse = np.mean((orig - filt) ** 2)

# ---- Compute PSNR (Peak Signal-to-Noise Ratio) ----
if mse == 0:
    psnr = float('inf')
else:
    psnr = 20 * math.log10(255 / math.sqrt(mse))

# ---- Display results ----
print(f"Image Comparison Results:")
print(f"--------------------------")
print(f"MSE  : {mse:.3f}")
print(f"PSNR : {psnr:.3f} dB")

# Optional: show both images side-by-side for visual check
combined = Image.fromarray(np.hstack((orig, filt)).astype(np.uint8))
combined.show()
