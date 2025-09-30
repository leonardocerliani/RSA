
# %%


import sys
print(sys.executable)



# %%

import nibabel as nib
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

atlases = [
  "Yeo7.nii.gz",
  "Yeo17.nii.gz",
  "HO_cort.nii.gz",
  "anatomy_toolbox_for_RSA.nii.gz"
]

n_atlases = len(atlases)

nii_vec_length = np.prod(nib.load(atlases[0]).get_fdata().shape)
nii = np.zeros( (n_atlases, nii_vec_length, ) )

for i in np.arange(n_atlases):
  print(f'importing {atlases[i]}')
  nii[i,] = nib.load(atlases[i]).get_fdata().ravel()
  

# %%
