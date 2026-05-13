import sys

if len(sys.argv) != 6:
    print("Usage: python script.py <source_bd> <dest_bd> <sub> <model> <run>")
    sys.exit(1)

import numpy as np
import nibabel as nib
from nilearn import image, masking
import time
from nilearn.input_data import NiftiMasker

source_bd = sys.argv[1]
dest_bd   = sys.argv[2]
model     = sys.argv[3]
sub       = sys.argv[4]
run       = sys.argv[5]


# Constructing the paths as Python strings
Y_nii_path = f"{source_bd}/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}_preproc_reg.feat/filtered_func_data.nii.gz"
res_nii_path = f"{source_bd}/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}_preproc_reg.feat/stats/res4d.nii.gz"
mask_nii_path = f"{source_bd}/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}_preproc_reg.feat/mask.nii.gz"
output_CC_path = f"{dest_bd}/{model}/sub-{sub}_run-{run}_CC_native_space.nii.gz"

print("Y path:", Y_nii_path)
print("res path:", res_nii_path)
print("mask path:", mask_nii_path)
print("output CC path:", output_CC_path)


print("Loading filtered_func_data, residuals and mask...")
# Load the 4D images
Y = image.load_img(Y_nii_path)
res = image.load_img(res_nii_path)
mask_img = image.load_img(mask_nii_path)

print("Calculating Yhat")
# Calculate Yhat = Y - res
Yhat = image.new_img_like(Y, Y.get_fdata() - res.get_fdata())

# Assign Y and Yhat to img1 and img2
img1=Y
img2=Yhat

# Use NiftiMasker to extract the time series
masker = NiftiMasker(mask_img=mask_img)

time_series1 = masker.fit_transform(img1)
time_series2 = masker.fit_transform(img2)


print("Calculating CCs for every mask voxel...")
n_voxels = time_series1.shape[1]
correlation_coefficients = np.empty(n_voxels)

for voxel in range(n_voxels):
    correlation_coefficients[voxel] = np.corrcoef(time_series1[:, voxel], time_series2[:, voxel])[0, 1]


# Reshape the correlation coefficients back to the mask shape
correlation_3d = np.zeros(mask_img.shape)  # Start with zeros
mask_data = mask_img.get_fdata().astype(bool)

# Fill the correlation values into the mask locations
correlation_3d[mask_data] = correlation_coefficients

print("Writing the output CC image in native space...")
# Create a new NIfTI image
correlation_img = image.new_img_like(mask_img, correlation_3d)

# Save the resulting correlation image
correlation_img.to_filename(output_CC_path)

print("All done")
