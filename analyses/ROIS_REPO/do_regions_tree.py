
# %%
import sys
print(sys.executable)

# %%
import nibabel as nib
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

atlases = [
  "Yeo7.nii.gz",
  "Yeo17.nii.gz",
  "HO_cort.nii.gz",
  "anatomy_toolbox.nii.gz"
]

n_atlases = len(atlases)

nii_vec_length = np.prod(nib.load(atlases[0]).get_fdata().shape)
nii = np.zeros( (n_atlases, nii_vec_length, ) )

for i in np.arange(n_atlases):
  print(f'importing {atlases[i]}')
  nii[i,] = nib.load(atlases[i]).get_fdata().ravel()
  


# %%

# 1. remove columns that contain any zero
nonzero_cols = np.all(nii != 0, axis=0)
nii = nii[:, nonzero_cols]

# 2. retain unique columns
_, unique_cols_indices = np.unique(nii, axis=1, return_index=True)
nii = nii[:, np.sort(unique_cols_indices)]

# 3. keep only columns where first row == 5
mask = nii[0, :] == 5
nii = nii[:, mask]

# 4. convert to integers to avoid decimal points
nii = nii.astype(int)

# 5. visualize
sns.heatmap(nii)

# 6. check unique values in second row
print(np.unique(nii[1, :]))

print(nii.shape)

# %%

lines = ["graph TD"]
n_rows, n_cols = nii.shape

created_nodes = set()
created_edges = set()

for r in range(n_rows - 1):
    for c in range(n_cols):
        parent = f"{r}_{nii[r, c]}"
        child = f"{r+1}_{nii[r+1, c]}"
        
        # add nodes only once
        if parent not in created_nodes:
            lines.append(f"{parent}[{nii[r, c]}]")
            created_nodes.add(parent)
        if child not in created_nodes:
            lines.append(f"{child}[{nii[r+1, c]}]")
            created_nodes.add(child)
        
        # add edge only once
        edge = (parent, child)
        if edge not in created_edges:
            lines.append(f"{parent} --> {child}")
            created_edges.add(edge)

mermaid_code = "\n".join(lines)
print(mermaid_code)
# %%

# transpose so each row = one path
paths = nii.T  # shape becomes (n_columns, n_levels)

# convert to DataFrame, naming columns Level1, Level2, ...
df = pd.DataFrame(paths, columns=[f"Level{i+1}" for i in range(paths.shape[1])])

# save to CSV
df.to_csv("nii_for_collapsibleTree.csv", index=False)

# %%
