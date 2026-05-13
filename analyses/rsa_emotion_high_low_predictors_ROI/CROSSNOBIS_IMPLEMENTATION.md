# Crossnobis RSA Implementation Guide

**Version**: V15_CROSSNOBIS  
**Date**: 2026-02-01  
**Based on**: V15 (Euclidean distance)

## Overview

Crossnobis is a leave-one-run-out Mahalanobis distance metric that removes run-specific noise from fMRI RDMs. Instead of computing distances within aggregated 2nd-level copes (V15), it uses run-wise 1st-level copes.

### Key Differences from V15

| Aspect | V15 (Euclidean) | V15_CROSSNOBIS |
|--------|----------------|----------------|
| Data level | 2nd-level (aggregated) | 1st-level (run-wise) |
| Files per subject | 14 copes | 8 runs × 14 copes = 112<br/>**After neutral removal: 96** |
| Data structure | 2D (voxels × copes) | 3D (voxels × runs × copes) |
| Distance metric | Euclidean | Mahalanobis (leave-one-run-out) |
| Results code | EER | EXR |

**IMPORTANT**: Neutrals (copes 9 & 10) are **always removed** before analysis, reducing data to 12 copes per run.

---

## Files Created

### 1. `funs_V15_CROSSNOBIS_ROIs.R`

Complete functions library with:

**Data Import:**
- `import_df_path_copes_crossnobis()` - Direct path construction (no recursive scan)
- `load_sub_copes_crossnobis()` - Loads 3D array (voxels × runs × copes)

**Distance Calculation:**
- `DDOS_crossnobis(cov_method)` - Leave-one-run-out Mahalanobis
  - **cov_method options:**
    - `"shrinkage"` (default) - Ledoit-Wolf shrinkage (rsatoolbox approach)
    - `"pseudoinverse"` - Moore-Penrose pseudoinverse (most robust)

**Orchestration:**
- `do_RDM_fmri_crossnobis()` - Processes all ROIs for one subject

**Utilities:**
- `create_filename_results()` - Updated with "X" code for crossnobis
- General V15 functions for behavioral RDMs (`DDOS_vec`, `plot_tril`, etc.)

### 2. `do_RSA_v15_CROSSNOBIS_ROIs_EHLP.Rmd`

Complete analysis notebook following V15 structure:

**Parameters:**
```yaml
params:
  atlas_filename: test_ROI.nii.gz
  remove_neutrals: "YES"
  minus_neutral: "NO"
  subs_set: "N26"
  RSA_on_residuals: FALSE
  filter_RDMs: FALSE
  crossnobis_cov_method: "shrinkage"  # shrinkage or pseudoinverse
```

**Sections:**
1. df_path_copes creation (run-level)
2. Crossnobis fMRI RDM calculation
3. Noise ceiling/floor
4. Behavioral RDMs (same as V15)
5. RM-ANOVA filtering (same as V15)
6. RSA calculation (same as V15)
7. Mean calculations and visualization
8. Results save

### 3. `do_RSA_ROI_V3_CROSSNOBIS.sh`

Bash launcher script:
```bash
./do_RSA_ROI_V3_CROSSNOBIS.sh <atlas.nii.gz>
```

---

## Algorithm: Crossnobis Distance

### Mathematical Definition

For each fold *i* (leave-one-run-out):

1. **Test data**: Held-out run *i*
2. **Training data**: Remaining runs (average across runs)
3. **Residuals**: Each training run minus training average
4. **Covariance**: Estimated from training residuals
5. **Distance**: Mahalanobis distance between test copes

$$ d_{ij}^{(fold)} = \sqrt{(x_i - x_j)^T \Sigma^{-1} (x_i - x_j)} $$

6. **Final RDM**: Average distances across all folds

### Covariance Estimation

**Problem**: Standard covariance often singular with high-dimensional data.

**Solutions implemented:**

#### Shrinkage (Default)
```R
Sigma_shrink <- corpcor::cov.shrink(residuals_flat, verbose = FALSE)
Sigma_inv <- solve(Sigma_shrink)
```
- Ledoit-Wolf optimal shrinkage
- Same approach as rsatoolbox
- Statistically principled

#### Pseudoinverse (Fallback)
```R
Sigma <- cov(residuals_flat)
Sigma_inv <- MASS::ginv(Sigma)
```
- Always works (no singularity issues)
- Moore-Penrose pseudoinverse
- Most robust option

---

## Data Flow

### V15 (Euclidean)
```
2nd-level copes (14 files/sub)
    ↓
Load into 2D array (voxels × copes)
    ↓
Euclidean distance
    ↓
RDM (66 elements: 12×11/2)
```

### V15_CROSSNOBIS
```
1st-level run copes (112 files/sub = 8 runs × 14 copes)
    ↓
Remove neutrals (copes 9 & 10) → 96 files/sub (8 runs × 12 copes)
    ↓
Load into 3D array (voxels × runs × copes)
    ↓
For each run (fold):
  - Hold out one run
  - Estimate covariance from other runs
  - Compute Mahalanobis distance
    ↓
Average across folds
    ↓
RDM (66 elements: 12×11/2)
```

**Note**: Neutrals are filtered immediately after path construction, before any data loading.

---

## Usage

### Basic Run
```bash
./do_RSA_ROI_V3_CROSSNOBIS.sh HO_cort.nii.gz
```

### With nohup (Long-Running)
```bash
nohup ./do_RSA_ROI_V3_CROSSNOBIS.sh HO_cort.nii.gz > HO_cort.log 2>&1 &
tail -f HO_cort.log
```

### Change Covariance Method

Edit `do_RSA_v15_CROSSNOBIS_ROIs_EHLP.Rmd` header:
```yaml
params:
  crossnobis_cov_method: "pseudoinverse"  # or "shrinkage"
```

---

## Output

### Results File

**Location**: `/data00/leonardo/RSA/analyses/RSA_ROI_APP/results_RSA_ROI/`

**Filename format**: `<atlas>_N26__EXR.RData`
- **E** = Euclidean (ratings RDM)
- **X** = Crossnobis (fMRI RDM)
- **R** = Pearson (RSA correlation)

**Contents**:
- `RSA` - Subject-level RSA correlations
- `RSA_mean` - ROI-level mean RSA
- `RDMs_fmri` - fMRI RDMs (crossnobis)
- `RDMs_rats` - Behavioral RDMs
- `mean_RDMs_fmri` - Average fMRI RDMs
- `mean_RDMs_rats` - Average behavioral RDMs
- `df_noise_summary` - Noise ceiling/floor per ROI
- `RSA_volumes_df` - For visualization app
- `df_path_copes` - File provenance

---

## Performance Considerations

### Threading
- **Sequential processing** (one subject at a time)
- **Reason**: BLAS libraries auto-use all cores for matrix operations
- **Benefit**: Avoids nested parallelization overhead

### Computation Time
Per subject (8 runs × 12 copes × N_ROIs):
- **Small atlas** (17 ROIs): ~2-5 minutes
- **Large atlas** (200+ ROIs): ~30-60 minutes

For 26 subjects:
- **Sequential**: ~1-2 hours (small atlas)
- **Memory**: ~5-10 GB RAM

---

## Validation Checklist

After running, verify:

1. **File count**: `df_path_copes` has 96 rows per subject (after neutral removal)
2. **RDM length**: Each RDM has 66 elements (12 copes × 11 / 2)
3. **ROI count**: Matches atlas regions
4. **No NAs**: Check `sum(is.na(RDMs_fmri$rdm_fmri[[1]]))`
5. **Noise ceiling**: Should be > noise floor for each ROI
6. **File saved**: Check results directory for `*_EXR.RData`

---

## Troubleshooting

### Singular Matrix Error
```
Error: system is computationally singular
```
**Solution**: Already fixed! Uses shrinkage or pseudoinverse.

### All Threads Still Used
- BLAS threading cannot be fully controlled from R
- Use `taskset` to limit cores: `taskset -c 0-39 R`
- Or accept brief thread spikes (computation still correct)

### Missing Files
```
WARNING: Some files do not exist!
```
**Check**:
1. First-level analysis completed for all runs?
2. File paths correct in `import_df_path_copes_crossnobis()`?
3. Subject list matches available data?

---

## References

- **rsatoolbox**: https://rsatoolbox.readthedocs.io/
- **Crossnobis**: Walther et al. (2016) - Reliability of dissimilarity measures
- **Ledoit-Wolf shrinkage**: Ledoit & Wolf (2004) - Improved estimation of covariance matrices

---

## Summary

✅ **Complete implementation** of crossnobis RSA based on V15  
✅ **Handles singular matrices** with shrinkage/pseudoinverse  
✅ **Compatible** with V15 downstream analysis (same output structure)  
✅ **Tested** and ready for production use

**Next steps**: Run with production atlas and compare with V15 results.
