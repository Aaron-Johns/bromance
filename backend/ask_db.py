from tqdm import tqdm

from langchain_community.document_loaders import (
    PyPDFLoader,
    Docx2txtLoader,
    UnstructuredPowerPointLoader,
    TextLoader,
    CSVLoader
)
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_community.chat_models import ChatOllama
from langchain.chains import RetrievalQA
from langchain.callbacks.base import BaseCallbackHandler


def make_qa(db_path="dbs/study_db", model="llama2"):
    db = FAISS.load_local(db_path, embedding_model, allow_dangerous_deserialization=True)
    retriever = db.as_retriever(search_kwargs={"k": 3})

    llm = ChatOllama(model=model, callbacks=[StreamHandler()])
    qa = RetrievalQA.from_chain_type(llm=llm, retriever=retriever, chain_type="stuff")
    return qa


# ------------------ Example Usage ------------------

# First time: build DB from multiple formats
files = ["physics.pdf", "chemistry.docx", "math_notes.txt", "bio_slides.pptx", "data.csv"]
db = build_or_update_db(files, db_path="dbs/study_db")

# Later, if you get a new document, just call build_or_update_db(["newfile.pdf"], "dbs/study_db")

# Ask questions
qa = make_qa("dbs/study_db", model="llama2")

print("\n\nAnswer:\n")
qa.run("Explain the main differences between organic and inorganic chemistry.")