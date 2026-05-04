import os
import json
import random
import shutil
from flask import Flask, request, jsonify
from flask_cors import CORS

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.document_loaders import PyPDFLoader, WebBaseLoader
from langchain_community.vectorstores import Chrom
from langchain_community.embeddings import OllamaEmbeddings
from langchain.docstore.document import Document

from langchain_community.chat_models import ChatOllama
from langchain.prompts import PromptTemplate
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from typing import List

LLM_MODEL = 'llama3:8b-instruct-q4_K_M'
EMBEDDING_MODEL = 'nomic-embed-text'

print("--- Initializing AI Models ---")
llm = ChatOllama(model=LLM_MODEL)
embeddings = OllamaEmbeddings(model=EMBEDDING_MODEL)
print(f"LLM: {LLM_MODEL} | Embeddings: {EMBEDDING_MODEL}")
print("--- Models Initialized Successfully ---")
class QuizQuestion(BaseModel):
    question: str = Field(description="The quiz question.")
    options: List[str] = Field(description="A list of 4 possible answers.")
    correctAnswer: str = Field(description="The correct answer, which must be one of the items in the options list.")

class Quiz(BaseModel):
    questions: List[QuizQuestion] = Field(description="A list of quiz questions.")

class ConcentrationPair(BaseModel):
    question: str = Field(description="The term or question for one card.")
    answer: str = Field(description="The corresponding definition or answer for the matching card.")

class ConcentrationGame(BaseModel):
    pairs: List[ConcentrationPair] = Field(description="A list of term-definition pairs.")

class QuickAnswer(BaseModel):
    answer: str = Field(description="A concise and direct answer to the user's question.")

class GambleQuizQuestion(BaseModel):
    question: str = Field(description="The trivia question based on the database.")
    options: List[str] = Field(description="A list of exactly 4 possible answers.")
    correctAnswerIndex: int = Field(description="The index (0-3) of the correct answer in the options list.")


# --- Basic Flask App Setup ---
app = Flask(__name__)
CORS(app)

# --- In-memory Data Store ---
LEAVES_FILE = 'leaves_data.json'

def load_leaves():
    if os.path.exists(LEAVES_FILE):
        with open(LEAVES_FILE, 'r') as f:
            data = json.load(f)
            return data.get('leaves', 10)
    return 10

def save_leaves(count):
    with open(LEAVES_FILE, 'w') as f:
        json.dump({'leaves': count}, f)

leaf_balance = load_leaves()

# --- RAG Helper Function ---
def get_rag_context(notebook_title, query):
    """Loads the vector store for a notebook and retrieves context."""
    if not notebook_title:
        return ""

    notebook_path = os.path.join('notebooks', notebook_title)
    vectordb_path = os.path.join(notebook_path, "chroma_db")

    if not os.path.exists(vectordb_path):
        print(f"No vector store found for notebook: {notebook_title}")
        return "No source documents found for this notebook."

    try:
        vectorstore = Chroma(
            persist_directory=vectordb_path,
            embedding_function=embeddings
        )
        
        retriever = vectorstore.as_retriever(search_kwargs={'k': 5})
        docs = retriever.get_relevant_documents(query)

        context = "\n\n".join([doc.page_content for doc in docs])
        return context
    except Exception as e:
        print(f"Error loading vector store or retrieving context for '{notebook_title}': {e}")
        return "Error retrieving documents."

# --- API Endpoints ---

@app.route('/get/leaves', methods=['GET'])
def get_leaves():
    return jsonify({'leaves': leaf_balance})

@app.route('/count/leaves', methods=['POST'])
def count_leaves():
    global leaf_balance
    data = request.get_json()
    leaf_balance = data.get('leavesno', leaf_balance)
    save_leaves(leaf_balance)
    return jsonify({'status': 'success', 'new_balance': leaf_balance})

@app.route('/notebooks', methods=['GET'])
def get_notebooks():
    notebooks_dir = 'notebooks'
    if not os.path.exists(notebooks_dir):
        return jsonify([])

    notebook_data = []
    for notebook_title in os.listdir(notebooks_dir):
        notebook_path = os.path.join(notebooks_dir, notebook_title)
        if os.path.isdir(notebook_path):
            files = [f for f in os.listdir(notebook_path) if f.endswith('.pdf')]
            notebook_data.append({'title': notebook_title, 'files': files})

    return jsonify(notebook_data)


@app.route('/create/notebook', methods=['POST'])
def create_notebook():
    title = request.form.get('title')
    if not title:
        return jsonify({'status': 'error', 'message': 'Missing title'}), 400

    notebook_path = os.path.join('notebooks', title)
    os.makedirs(notebook_path, exist_ok=True)
    
    all_docs = []

    try:
        # 1. Process PDF files
        pdf_files = request.files.getlist('files')
        for file in pdf_files:
            file_path = os.path.join(notebook_path, file.filename)
            file.save(file_path)
            loader = PyPDFLoader(file_path)
            all_docs.extend(loader.load())

        # 2. Process Web URLs
        web_sources_str = request.form.get('web_sources', '')
        if web_sources_str:
            web_urls = web_sources_str.split(',')
            loader = WebBaseLoader(web_urls)
            loader.requests_per_second = 1
            web_docs = loader.load()
            all_docs.extend(web_docs)
        
        # 3. Process Pasted Texts
        text_sources_json = request.form.get('text_sources', '[]')
        text_sources = json.loads(text_sources_json)
        for i, text_content in enumerate(text_sources):
            doc = Document(page_content=text_content, metadata={"source": f"Pasted Text {i+1}"})
            all_docs.append(doc)
            
        if not all_docs:
            return jsonify({'status': 'error', 'message': 'No sources provided'}), 400
            
        # 4. Split documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=150)
        chunked_docs = text_splitter.split_documents(all_docs)

        # 5. UPDATED: Create and save ChromaDB vector store
        vectordb_path = os.path.join(notebook_path, "chroma_db")
        vectorstore = Chroma.from_documents(
            documents=chunked_docs,
            embedding=embeddings,
            persist_directory=vectordb_path # This tells Chroma to save to disk
        )

        print(f"Successfully created and saved ChromaDB vector store for notebook: {title}")

    except Exception as e:
        print(f"Error during RAG creation for notebook '{title}': {e}")
        return jsonify({'status': 'error', 'message': f'Failed to process documents: {e}'}), 500

    return jsonify({'status': 'success', 'message': f'Notebook "{title}" created.'})

@app.route('/delete/notebook/<notebook_title>', methods=['DELETE'])
def delete_notebook(notebook_title):
    if not notebook_title:
        return jsonify({'status': 'error', 'message': 'Missing notebook title'}), 400

    notebook_path = os.path.join('notebooks', notebook_title)

    if not os.path.exists(notebook_path) or not os.path.isdir(notebook_path):
        return jsonify({'status': 'error', 'message': 'Notebook not found'}), 404

    try:
        # This works for ChromaDB as well, as it deletes the entire directory.
        shutil.rmtree(notebook_path)
        print(f"Successfully deleted notebook: {notebook_title}")
        return jsonify({'status': 'success', 'message': f'Notebook "{notebook_title}" deleted.'})
    except Exception as e:
        print(f"Error deleting notebook '{notebook_title}': {e}")
        return jsonify({'status': 'error', 'message': f'Failed to delete notebook: {e}'}), 500

@app.route('/add-sources/<notebook_title>', methods=['POST'])
def add_sources(notebook_title):
    if not notebook_title:
        return jsonify({'status': 'error', 'message': 'Missing notebook title'}), 400

    notebook_path = os.path.join('notebooks', notebook_title)
    # UPDATED: Path for ChromaDB
    vectordb_path = os.path.join(notebook_path, "chroma_db")

    if not os.path.exists(vectordb_path):
        return jsonify({'status': 'error', 'message': 'Notebook vector store not found'}), 404

    all_docs = []
    try:
        # 1. Process PDF files
        pdf_files = request.files.getlist('files')
        for file in pdf_files:
            file_path = os.path.join(notebook_path, file.filename)
            file.save(file_path)
            loader = PyPDFLoader(file_path)
            all_docs.extend(loader.load())

        # 2. Process Web URLs
        web_sources_str = request.form.get('web_sources', '')
        if web_sources_str:
            web_urls = web_sources_str.split(',')
            loader = WebBaseLoader(web_urls)
            loader.requests_per_second = 1
            web_docs = loader.load()
            all_docs.extend(web_docs)

        # 3. Process Pasted Texts
        text_sources_json = request.form.get('text_sources', '[]')
        text_sources = json.loads(text_sources_json)
        for i, text_content in enumerate(text_sources):
            doc = Document(page_content=text_content, metadata={"source": f"Pasted Text {i+1}"})
            all_docs.append(doc)

        if not all_docs:
            return jsonify({'status': 'error', 'message': 'No new sources provided'}), 400

        # 4. Split new documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=150)
        chunked_docs = text_splitter.split_documents(all_docs)

        # 5. UPDATED: Load existing ChromaDB and add new documents
        vectorstore = Chroma(
            persist_directory=vectordb_path,
            embedding_function=embeddings
        )
        vectorstore.add_documents(chunked_docs)
        # NOTE: No explicit 'save' is needed. Chroma persists changes automatically.

        print(f"Successfully added {len(chunked_docs)} new chunks to notebook: {notebook_title}")

    except Exception as e:
        print(f"Error adding sources to notebook '{notebook_title}': {e}")
        return jsonify({'status': 'error', 'message': f'Failed to process new documents: {e}'}), 500

    return jsonify({'status': 'success', 'message': f'Sources added to notebook "{notebook_title}".'})


@app.route('/generate/quiz', methods=['POST'])
def generate_quiz():
    data = request.get_json()
    notebook = data.get('notebook')
    topic = data.get('topic', 'a general topic')
    n = data.get('n', 3)

    context = get_rag_context(notebook, topic)
    parser = PydanticOutputParser(pydantic_object=Quiz)

    prompt_template = """
    You are an expert quiz creator. Use the following context to generate a quiz with exactly {n} multiple-choice questions about the topic: {topic}.
    Base your questions ONLY on the provided context. If the context is insufficient, create questions on the general topic.
    For each question, provide 4 options. Ensure that one of the options is the correct answer.

    Context:
    {context}

    Return the quiz as a JSON object that follows this structure:
    {format_instructions}
    """
    prompt = PromptTemplate(
        template=prompt_template,
        input_variables=["topic", "n", "context"],
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    try:
        chain = prompt | llm | parser
        output = chain.invoke({"topic": topic, "n": n, "context": context})
        response_data = output.dict().get("questions", [])
        return jsonify(response_data)
    except Exception as e:
        print(f"Error generating quiz with Ollama: {e}")
        return jsonify({"error": "Failed to generate quiz from AI model."}), 500

@app.route('/generate/concentrate', methods=['POST'])
def generate_concentrate():
    data = request.get_json()
    notebook = data.get('notebook')
    topic = data.get('topic', 'a topic')
    n = data.get('n', 8)

    context = get_rag_context(notebook, topic)
    parser = PydanticOutputParser(pydantic_object=ConcentrationGame)

    prompt_template = """
    You are an expert at creating study materials. Use the following context to generate exactly {n} pairs of terms and definitions for a concentration game based on the topic: {topic}.
    Each pair should have a 'question' (the term) and an 'answer' (the definition). Base the terms and definitions ONLY on the provided context. Make the questions easy to understand and the answers short and sweet.

    Context:
    {context}

    Return the pairs as a JSON object that follows this structure:
    {format_instructions}
    """
    prompt = PromptTemplate(
        template=prompt_template,
        input_variables=["topic", "n", "context"],
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    try:
        chain = prompt | llm | parser
        output = chain.invoke({"topic": topic, "n": n, "context": context})
        response_data = output.dict().get("pairs", [])
        return jsonify(response_data)
    except Exception as e:
        print(f"Error generating concentration game with Ollama: {e}")
        return jsonify({"error": "Failed to generate concentration game from AI model."}), 500


@app.route('/generate/qq', methods=['POST'])
def generate_qq():
    data = request.get_json()
    notebook = data.get('notebook')
    topic = data.get('topic', 'your question')
    
    context = get_rag_context(notebook, topic)
    parser = PydanticOutputParser(pydantic_object=QuickAnswer)
    
    prompt_template = """
    You are a helpful assistant. Use the following context to provide a clear and concise answer to the question. If the answer is not in the context, say that you cannot find the answer in the provided documents.

    Context:
    {context}

    Question:
    {topic}

    Return the answer as a JSON object that follows this structure:
    {format_instructions}
    """
    prompt = PromptTemplate(
        template=prompt_template,
        input_variables=["topic", "context"],
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    try:
        chain = prompt | llm | parser
        output = chain.invoke({"topic": topic, "context": context})
        return jsonify(output.dict())
    except Exception as e:
        print(f"Error generating quick question with Ollama: {e}")
        return jsonify({"error": "Failed to generate answer from AI model."}), 500


@app.route('/generate/gamblequiz/', methods=['GET'])
def generate_gamble_quiz():
    context = ""
    notebooks_dir = 'notebooks'
    available_notebooks = []
    
    if os.path.exists(notebooks_dir):
        for name in os.listdir(notebooks_dir):
            notebook_path = os.path.join(notebooks_dir, name)
            if os.path.isdir(notebook_path) and os.path.exists(os.path.join(notebook_path, "chroma_db")):
                available_notebooks.append(name)

    if available_notebooks:
        random_notebook = random.choice(available_notebooks)
        print(f"Generating gamble quiz from notebook: {random_notebook}")
        context = get_rag_context(random_notebook, "any interesting fact or data point")
        prompt_template_str = """
        You are a trivia master. Use ONLY the following context to generate a single, interesting, and extremely hard multiple-choice trivia question.
        Provide exactly 4 possible options for the answer. One of them must be correct.
        Indicate the correct answer by its index in the options list (from 0 to 3).

        Context:
        {context}

        Return the question as a JSON object that follows this structure:
        {format_instructions}
        """
        input_variables = ["context"]
    else:
        print("No notebooks found for RAG-based gamble quiz. Falling back to general knowledge.")
        prompt_template_str = """
        You are a trivia master. Generate a single, random, multiple-choice and extremely hard trivia question on any general knowledge topic.
        Provide exactly 4 possible options for the answer.
        Indicate the correct answer by its index in the options list (from 0 to 3).

        Return the question as a JSON object that follows this structure:
        {format_instructions}
        """
        input_variables = []


    parser = PydanticOutputParser(pydantic_object=GambleQuizQuestion)
    
    prompt = PromptTemplate(
        template=prompt_template_str,
        input_variables=input_variables,
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    try:
        chain = prompt | llm | parser
        invoke_params = {"context": context} if context else {}
        output = chain.invoke(invoke_params)
        return jsonify(output.dict())
    except Exception as e:
        print(f"Error generating gamble quiz with Ollama: {e}")
        return jsonify({"error": "Failed to generate gamble quiz from AI model."}), 500


if __name__ == '__main__':
    if not os.path.exists('notebooks'):
        os.makedirs('notebooks')
    app.run(debug=True, port=5000)
