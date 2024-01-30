import numpy as np
import sys
print(sys.executable)

import nilearn
from nilearn import plotting
from nilearn import datasets
import json
import glob
import os

import warnings
warnings.filterwarnings('ignore')


# ------------- Main variables -------------------
bd = '/data00/leonardo/RSA/analyses'
prep_bd = '/data00/leonardo/RSA/prep_data' # for the 1st level images
sub_list_path = '/data00/leonardo/RSA/sub_list.txt'

nruns=8

models_name = ['allMovies', 'arousal', 'valence', 'emotion', 'one_ev_per_movie']


# ------- Auxiliary functions and files -----------
sub_list = []
with open(sub_list_path,'r') as file:
    for line in file:
        numba = line.strip()
        sub_list.append(numba.zfill(2))


# Pretty print dict
import json
def pprint(dict):
  print(json.dumps(dict, indent=4))


# Print all the keys recursively in the whole dictionary
# example usage with your dictionary 'dizio':
# print_dict_keys(dizio)
def print_dict_keys(d, indent=0):
    for key, value in d.items():
        print('    ' * indent + str(key))
        if isinstance(value, dict):
            print_dict_keys(value, indent + 1)

# Create glassbrain image
thr = 3
def create_glassbrain(path_nii, path_png):
    plotting.plot_glass_brain(path_nii, path_png, threshold=thr)

# -------------------------------------------------------

# dizio of ncopes : necessary because different models
# have different amount of ncopes
ncopes = {}
for mod in models_name:
    fsf_files = glob.glob(f'{bd}/{mod}/results/*.fsf')
    ncopes[mod] = len(fsf_files)
    print(f'{mod} has {len(fsf_files)} ncopes')


# Create a dictionary for the path to 2nd and grouplevel results
#
# E.g. structure
# pprint(dizio['arousal']['1st_level']['cope1']['sub02_run1']['png'])
# pprint(dizio['arousal']['2nd_level']['cope1']['sub30']['png'])
# pprint(dizio['arousal']['grouplevel']['cope1'])

# Initialize the dictionary
dizio = {}

# Insert grouplevel results
path_grouplevel_template = (
    '{bd}/{model}/results/grouplevel_{model}_cope{ncope}.gfeat/'
    'cope1.feat/thresh_zstat1.nii.gz'
)

for model in models_name:
    dizio[model] = {}    
    dizio[model]['grouplevel'] = {}
    for ncope in range(1, ncopes[model] + 1):
        path_grouplevel_nii = path_grouplevel_template.format(bd=bd, model=model, ncope=ncope)
        path_grouplevel_png = path_grouplevel_nii.replace('.nii.gz','_nilearn.png')
        dizio[model]['grouplevel'][f'cope{ncope}'] = {
            'nii' : path_grouplevel_nii,
            'png' : path_grouplevel_png
        }
        if not os.path.exists(path_grouplevel_png):
            create_glassbrain(path_grouplevel_nii, path_grouplevel_png)
            print(f'Writing image {path_grouplevel_png}')

# Insert second-level (within subject, across runs) results
path_2nd_level_template = (
    '{bd}/{model}/results/2nd_level/sub-{sub}_{model}.gfeat/'
    'cope{ncope}.feat/thresh_zstat1.nii.gz'
)

for model in models_name:
    # dizio[model] = {}
    dizio[model]['2nd_level'] = {}
    for ncope in range(1, ncopes[model] + 1):
        dizio[model]['2nd_level'][f'cope{ncope}'] = {}
        for sub in sub_list:
            path_2nd_level_nii = path_2nd_level_template.format(bd=bd, model=model, ncope=ncope, sub=sub)
            path_2nd_level_png = path_2nd_level_nii.replace('.nii.gz','_nilearn.png')
            dizio[model]['2nd_level'][f'cope{ncope}'][f'sub{sub}'] = {
                'nii' : path_2nd_level_nii,
                'png' : path_2nd_level_png
            }

# Insert first-level images (within subject, within run)
path_1st_level_template = (
    '{prep_bd}/sub-{sub}/fmri/{model}/sub-{sub}_run-{run}_preproc_reg.feat/'
    'thresh_zstat{ncope}.TYPE'
)

for model in models_name:
    # dizio[model] = {}
    dizio[model]['1st_level'] = {}
    for ncope in range(1, ncopes[model] + 1):
        dizio[model]['1st_level'][f'cope{ncope}'] = {}
        for sub in sub_list:
            for run in range(1, nruns+1):
                dizio[model]['1st_level'][f'cope{ncope}'][f'sub{sub}_run{run}'] = {
                    'nii' : path_1st_level_template.format(prep_bd=prep_bd, model=model, ncope=ncope, sub=sub, run=run).replace('.TYPE','.nii.gz'),
                    'png' : path_1st_level_template.format(prep_bd=prep_bd, model=model, ncope=ncope, sub=sub, run=run).replace('.TYPE','_nilearn.png')
                }

# pprint(dizio)



# Now png_paths_to_create contains the paths of PNG files that need to be created
png_to_create = []

for model in dizio:
    # Images in 2nd_level
    if '2nd_level' in dizio[model]:
        for ncope in dizio[model]['2nd_level']:
            for sub in dizio[model]['2nd_level'][ncope]:
                png_path = dizio[model]['2nd_level'][ncope][sub]['png']
                if not os.path.exists(png_path):
                    png_to_create.append(png_path)

    # Images in 1st_level
    if '1st_level' in dizio[model]:
        for ncope in dizio[model]['1st_level']:
            for subrun in dizio[model]['1st_level'][ncope]:
                png_path = dizio[model]['1st_level'][ncope][subrun]['png']
                if not os.path.exists(png_path):
                    png_to_create.append(png_path)

print(png_to_create)

# Create the images in parallel
import time
import concurrent.futures
n_workers = 40

# define the function to map
thr = 3
def create_glassbrain(path_png):
    path_nii = path_png.replace('_nilearn.png', '.nii.gz')
    print(f'{path_nii}')
    plotting.plot_glass_brain(path_nii, path_png, threshold=thr)

# Run it in parallel and time it
start_time = time.time()

with concurrent.futures.ProcessPoolExecutor(max_workers=n_workers) as executor:
    executor.map(create_glassbrain, png_to_create)

end_time = time.time()

elapsed_time = end_time - start_time
print(f"Execution took {elapsed_time} seconds.")


