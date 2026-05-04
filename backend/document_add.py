import os
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


# --- Streaming callback ---
class StreamHandler(BaseCallbackHandler):
    def on_llm_new_token(self, token: str, **kwargs):
        print(token, end="", flush=True)


# --- 1. Load documents from multiple formats ---
def load_documents(files):
    docs = []
    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext == ".pdf":
            docs.extend(PyPDFLoader(f).load())
        elif ext == ".docx":
            docs.extend(Docx2txtLoader(f).load())
        elif ext == ".pptx":
            docs.extend(UnstructuredPowerPointLoader(f).load())
        elif ext in [".txt", ".md"]:
            docs.extend(TextLoader(f).load())
        elif ext == ".csv":
            docs.extend(CSVLoader(f).load())
        else:
            print(f"⚠️ Unsupported format: {f}")
    return docs


# --- 2. Split into chunks ---
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)


# --- 3. Embedding model (local HuggingFace) ---
embedding_model = HuggingFaceEmbeddings(model_name="./models/all-MiniLM-L6-v2")


# --- 4. Build or extend FAISS database ---
def build_or_update_db(files, db_path="dbs/study_db"):
    print("📂 Loading documents...")
    raw_docs = load_documents(files)
    docs = splitter.split_documents(raw_docs)

    if os.path.exists(db_path):
        print("🔄 Updating existing DB...")
        db = FAISS.load_local(db_path, embedding_model, allow_dangerous_deserialization=True)
        db.add_documents(docs)
    else:
        print("🆕 Creating new DB...")
        db = FAISS.from_documents(docs, embedding_model)

    db.save_local(db_path)
    return db