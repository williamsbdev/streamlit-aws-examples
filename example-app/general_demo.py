import streamlit as st

st.write("Hello World!")

first_name = st.text_input('First name')
if st.checkbox('Add last name'):
    last_name = st.text_input('Last name')
else:
    last_name = ''
repetitions = st.slider('Repetitions')

st.write(' '.join([first_name, last_name] * repetitions))
