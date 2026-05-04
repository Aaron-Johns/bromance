# pip install tqdm

from tqdm import tqdm
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_ollama import ChatOllama
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA
from langchain.callbacks.base import BaseCallbackHandler

class StreamHandler(BaseCallbackHandler):
    def on_llm_new_token(self, token: str, **kwargs) -> None:
        print(token, end="", flush=True)

print("📄 Loading PDF...")
loader = PyPDFLoader("/home/ajohns/Downloads/bitcoin.pdf")
documents = loader.load()

print("✂️ Splitting into chunks...")
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
docs = splitter.split_documents(documents)

print("🔢 Loading embedding model...")
embedding_model = HuggingFaceEmbeddings(model_name="./models/all-MiniLM-L6-v2")

print("🧠 Generating embeddings and building FAISS index...")
embeddings = []
texts = []

for doc in tqdm(docs, desc="Embedding docs"):
    texts.append(doc.page_content)
    embeddings.append(embedding_model.embed_query(doc.page_content))

vectorstore = FAISS.from_texts(texts, embedding_model)

retriever = vectorstore.as_retriever(search_kwargs={"k": 3})

print("🤖 Starting Ollama model...")

llm = ChatOllama(model="gemma3:12b-it-qat", callbacks=[StreamHandler()])

qa = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=retriever,
    chain_type="stuff"
)

types = {'quiz': """
You are a quiz generator for a study app.  
Generate exactly {n} multiple-choice questions on the topic: "{topic}".  

Follow this strict JSON format (do not add explanations or commentary):  

{{
  "quiz": [
    {{
      "id": 1,
      "question": "Write the question here",
      "options": [
        "Option A",
        "Option B",
        "Option C",
        "Option D"
      ],
      "answer": "Correct Option Text",
      "explanation": "One or two sentence explanation of the answer."
    }},
    {{
      "id": 2,
      "question": "Next question here",
      "options": [
        "Option A",
        "Option B",
        "Option C",
        "Option D"
      ],
      "answer": "Correct Option Text",
      "explanation": "Brief explanation."
    }}
  ]
}}

Rules:
- Always output valid JSON.
- Each question must have exactly 4 options.
- The `answer` must be one of the options.
- Use `"id"` as an integer, starting from 1 and incrementing by 1.
- Keep explanations short and easy to understand.
- Output only the json file without any other extra sentences.
""",

'flashcards': """
You are tasked with generating data for a "Flashcard Pair Game" on the topic: {topic}.  
The game has cards that come in **pairs**:  
- A "Question Card" (front side)  
- A "Matching Answer Card" (back side)  

When a player selects the correct matching pair, both cards disappear.  

### Requirements:
1. Generate **N pairs of flashcards**.  
2. Each pair must have a **unique question and its correct answer**.  
3. Ensure answers are concise (max 10 words).  
4. Output should be in **JSON format** with the following schema:

{{
  "pairs": [
    {{
      "id": 1,
      "question": "What is the capital of France?",
      "answer": "Paris"
    }},
    {{
      "id": 2,
      "question": "Who developed the theory of relativity?",
      "answer": "Albert Einstein"
    }}
  ]
}}

### Notes:
- Make sure all questions are **clear and unambiguous**.  
- Avoid duplicate questions/answers.  
- Keep the tone educational but engaging.  

Now generate N = {n} flashcard pairs.
Output only the json file without any other extra sentences.
""", 

'pair':"""
You are an assistant that generates study materials for a matching card game. 
The game rules are:
- Each "Question Card" must have exactly one corresponding "Answer Card."
- A pair is considered correct if the answer matches the question.
- Format must be JSON for easy parsing.

Generate {n} pairs of cards for the topic: "{topic}".

Output in the following JSON format:
{{
  "pairs": [
    {{
      "id": 1,
      "question_card": "What is the capital of France?",
      "answer_card": "Paris"
    }},
    {{
      "id": 2,
      "question_card": "Who developed the theory of relativity?",
      "answer_card": "Albert Einstein"
    }}
  ]
}}
Output only the json file without any other extra sentences.
"""}


query = input("What would you like to learn about? ")
type = input("How would you like it generated? ")
type = type.strip().strip('"')  # removes whitespace and surrounding quotes

num = input("How many of those? ")
prompt = types[type].format(n=num, topic=query)
result = qa.invoke(prompt)