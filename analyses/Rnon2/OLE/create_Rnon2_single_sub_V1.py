import numpy as np
import nibabel as nib
from nilearn import image, masking
import time
from nilearn.input_data import NiftiMasker

# Load the 4D images
img1 = image.load_img('Y.nii.gz')
img2 = image.load_img('Yhat.nii.gz')
mask_img = image.load_img('mask.nii.gz')

# Use NiftiMasker to extract the time series
masker = NiftiMasker(mask_img=mask_img)

print("Reading images...")
time_series1 = masker.fit_transform(img1)
time_series2 = masker.fit_transform(img2)


# Calculate correlation for each voxel
n_voxels = time_series1.shape[1]
correlation_coefficients = np.empty(n_voxels)

print("Calculating CCs...")
for voxel in range(n_voxels):
    correlation_coefficients[voxel] = np.corrcoef(time_series1[:, voxel], time_series2[:, voxel])[0, 1]


# Reshape the correlation coefficients back to the mask shape
correlation_3d = np.zeros(mask_img.shape)  # Start with zeros
mask_data = mask_img.get_fdata().astype(bool)

# Fill the correlation values into the mask locations
correlation_3d[mask_data] = correlation_coefficients

print("Creating CC nifti image...")
# Create a new NIfTI image
correlation_img = image.new_img_like(mask_img, correlation_3d)

# Save the resulting correlation image
correlation_img.to_filename('correlation_map.nii.gz')

print("All done")

# # ------------ TEST ----------

# from sklearn.linear_model import LinearRegression

# np.random.seed(124)  # For reproducibility
# x = np.random.randn(1000).reshape(-1, 1)  # Reshape for sklearn
# y = 0.7 * x.flatten() + 0.6 * np.random.randn(1000)  # Flatten to get 1D array


# # Fit the linear regression model
# model = LinearRegression()
# model.fit(x, y)

# # Get the coefficients
# coefficients = model.coef_
# intercept = model.intercept_

# # Predict the values
# y_pred = model.predict(x)

# # Calculate the residuals
# residuals = y - y_pred

# np.corrcoef(y, y_pred)

# yhat = y - residuals

# # ----------------
# array_ones = np.ones((2, 3, 4, 5))

# # Create a 4D array of tens with the same shape
# array_tens = np.full((2, 3, 4, 5), 10)
