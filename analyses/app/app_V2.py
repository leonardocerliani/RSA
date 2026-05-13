import streamlit as st
import streamlit.components.v1 as components
from nilearn import plotting

from setproctitle import setproctitle
setproctitle("app_models")

from create_dizio_images import dizio

# run with streamlit run app.py

# -------- Aux fns and defs ------------

bd = '/data00/leonardo/RSA/analyses'
sub_list_path = '/data00/leonardo/RSA/sub_list.txt'

models = ['allMovies', 'arousal', 'valence', 'emotion', 'one_ev_per_movie']

# Pretty print dict
import json
def pprint(dict):
  print(json.dumps(dict, indent=4))

sub_list = []
with open(sub_list_path,'r') as file:
    for line in file:
        numba = line.strip()
        sub_list.append(numba.zfill(2))

# ---------------------------------------

st.set_page_config(layout="wide")



# Streamlit app
st.title("Model Results Viewer")

main_col, right_col = st.columns([9, 3])

with main_col:

    # Dropdown for selecting a model
    selected_model = st.selectbox("Choose a model:", models)

    # Determine available copes for the selected model
    if selected_model in dizio and 'grouplevel' in dizio[selected_model]:
        available_copes = list(dizio[selected_model]['grouplevel'].keys())
        selected_cope = st.selectbox("Choose a cope:", available_copes)

        # Display the image for the selected model and cope
        if selected_cope:
            # Nilearn interactive plot
            st.subheader(f"Grouplevel result for {selected_model}, {selected_cope}")
            nii_image_path = dizio[selected_model]['grouplevel'][selected_cope]['nii']
            view = plotting.view_img(nii_image_path, threshold=3, black_bg=False)
            html_view = view.get_iframe(width=700, height=300)  # extract the HTML
            components.html(html_view, height=310) # display in Streamlit


    # Select one sub to display the 1st_level images
    subs_allruns = list(dizio[selected_model]['1st_level'][selected_cope].keys())
    subs = list(set([item.split('_')[0] for item in subs_allruns]))
    subs.sort(key=lambda x: int(x[3:]))
    selected_sub = st.selectbox("Choose a subject: ", subs)
    
    # # Initial code to display all images in one column 
    # if selected_model and selected_cope and selected_sub:
    #     st.write(f"1st level results for {selected_sub} in {selected_model} {selected_cope}:")
    #     for run in subs_allruns:
    #         if run.startswith(selected_sub):
    #             png_image = dizio[selected_model]['1st_level'][selected_cope][run]['png']
    #             # st.write(f"{run}: {png_image}")  # file location
    #             st.image(png_image, caption=f'run {run}')

    # ChatGPT code to display 8 images in two rows of 4
    if selected_model and selected_cope and selected_sub:
        st.write(f"1st level results for {selected_sub} in {selected_model} {selected_cope}:")

        # Filter runs that start with the selected subject
        filtered_runs = [run for run in subs_allruns if run.startswith(selected_sub)]

        # Define the number of images per row
        images_per_row = 4

        # Iterate over the filtered runs in chunks
        for i in range(0, len(filtered_runs), images_per_row):
            # Create a row of columns
            cols = st.columns(images_per_row)
            for col, run in zip(cols, filtered_runs[i:i + images_per_row]):
                png_image = dizio[selected_model]['1st_level'][selected_cope][run]['png']
                col.image(png_image, caption=f'run {run}', width=150)  # Adjust width as needed




# Right-hand side content (in the right 4-column wide section)
with right_col:
    with st.container(height=1000):
        # Check if a model and cope have been selected
        if selected_model and selected_cope and '2nd_level' in dizio[selected_model]:
            st.write(f'2nd level results : {selected_model}')
            for sub in sub_list:
                # Retrieve the path for each subject's image
                if f'sub{sub}' in dizio[selected_model]['2nd_level'][selected_cope]:
                    sub_img_path = dizio[selected_model]['2nd_level'][selected_cope][f'sub{sub}']['png']
                    st.image(sub_img_path, caption=f"sub{sub}")







# pprint(dizio['arousal']['2nd_level']['cope1']['sub21']['png'])

# for sub in sub_list:
#     print(dizio['arousal']['2nd_level']['cope1'][f'sub{sub}']['png'])


#     pprint(dizio['arousal']['grouplevel']['cope1']['png'])
