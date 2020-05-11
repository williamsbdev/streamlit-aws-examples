FROM python:3.7
EXPOSE 8501
COPY . /demo
WORKDIR /demo
RUN pip install -r requirements.txt
CMD streamlit run general_demo.py
