# import numpy as np
# from PIL import Image

# def wiener3x3_fpga(img, sigma_n2=500):
#     """
#     Exact replication of the Verilog weiner3x3 module.
#     Uses integer arithmetic, Q16.16 fixed point, and FPGA clamping logic.
#     """

#     img = img.astype(np.int32)
#     H, W = img.shape
#     out = np.zeros_like(img)

#     # Pad borders to allow 3x3 window everywhere
#     padded = np.pad(img, 1, mode='edge')

#     for y in range(H):
#         for x in range(W):

#             # Extract 3×3 block
#             block = padded[y:y+3, x:x+3].astype(np.int64)
#             p = block.flatten()

#             # ----- sum and sum of squares -----
#             sum9   = np.sum(p)                   # 13 bits in FPGA
#             sumsq9 = np.sum(p * p)               # 20 bits

#             # ----- mean = sum9 / 9 -----
#             mean = sum9 // 9                     # integer division

#             # ----- Ex2 = sumsq9 / 9 -----
#             Ex2 = sumsq9 // 9

#             # ----- variance = Ex2 - mean^2 -----
#             mean_sq = mean * mean
#             var = Ex2 - mean_sq
#             if var < 0:
#                 var = 0

#             # ----- num_var = max(0, var - sigma) -----
#             num_var = var - sigma_n2
#             if num_var < 0:
#                 num_var = 0

#             # ----- num_shift = (num_var << 16) -----
#             # Verilog: {16'd0, num_var} << 16
#             num_shift = num_var << 16

#             # ----- gain_q16 = num_shift / var  (Q16.16) -----
#             if var != 0:
#                 gain_q16 = num_shift // var
#             else:
#                 gain_q16 = 0

#             # ----- delta = p4 - mean -----
#             p4 = img[y, x]                       # center pixel
#             delta = int(p4) - int(mean)

#             # ----- prod = gain_q16 * delta -----
#             prod = gain_q16 * delta

#             # ----- add_term = prod >>> 16 (signed) -----
#             add_term = prod >> 16

#             # ----- filt = mean + add_term -----
#             filt = mean + add_term

#             # ----- clamp to [0,255] -----
#             if filt < 0:
#                 filt = 0
#             elif filt > 255:
#                 filt = 255

#             out[y, x] = int(filt)

#     return out.astype(np.uint8)

# # Load original image
# img = Image.open("tiger.png").convert("L")
# img = img.resize((320, 240))
# img_np = np.array(img)

# # Apply FPGA-matching Wiener filter
# filtered = wiener3x3_fpga(img_np, sigma_n2=500)

# Image.fromarray(filtered).save("filtered_fpga_exact.png")
# Image.fromarray(filtered).show()

import numpy as np
from PIL import Image
import math

# ----------------------------------------------------------
# 1. FPGA-Equivalent Wiener Filter (same as your Verilog)
# ----------------------------------------------------------
def wiener3x3_fpga(img, sigma_n2=500):
    img = img.astype(np.int32)
    H, W = img.shape
    out = np.zeros_like(img)

    padded = np.pad(img, 1, mode='edge')

    for y in range(H):
        for x in range(W):
            block = padded[y:y+3, x:x+3].astype(np.int64)
            p = block.flatten()

            sum9   = np.sum(p)
            sumsq9 = np.sum(p * p)

            mean = sum9 // 9
            Ex2  = sumsq9 // 9

            mean_sq = mean * mean
            var = Ex2 - mean_sq
            if var < 0:
                var = 0

            num_var = var - sigma_n2
            if num_var < 0:
                num_var = 0

            num_shift = num_var << 16

            if var != 0:
                gain_q16 = num_shift // var
            else:
                gain_q16 = 0

            p4 = img[y, x]
            delta = int(p4) - int(mean)

            prod = gain_q16 * delta
            add_term = prod >> 16

            filt = mean + add_term

            if filt < 0:
                filt = 0
            elif filt > 255:
                filt = 255

            out[y, x] = int(filt)

    return out.astype(np.uint8)


# ----------------------------------------------------------
# 2. Load Image → Grayscale → Resize
# ----------------------------------------------------------
orig_img = Image.open("tiger.png").convert("L")
orig_img = orig_img.resize((320, 240))

orig_np = np.array(orig_img).astype(np.float32)

# ----------------------------------------------------------
# 3. Apply Wiener Filter
# ----------------------------------------------------------
filtered_np = wiener3x3_fpga(orig_np, sigma_n2=500).astype(np.float32)

Image.fromarray(filtered_np.astype(np.uint8)).save("filtered_py.png")

# ----------------------------------------------------------
# 4. Compute MSE and PSNR
# ----------------------------------------------------------
mse = np.mean((orig_np - filtered_np) ** 2)

if mse == 0:
    psnr = float('inf')
else:
    psnr = 20 * math.log10(255 / math.sqrt(mse))

print("\nOriginal vs Wiener Filter Comparison:")
print("--------------------------------------")
print(f"MSE  : {mse:.3f}")
print(f"PSNR : {psnr:.3f} dB")

# ----------------------------------------------------------
# 5. Side-by-side display
# ----------------------------------------------------------
combined = Image.fromarray(
    np.hstack((orig_np.astype(np.uint8), filtered_np.astype(np.uint8)))
)
combined.show()
