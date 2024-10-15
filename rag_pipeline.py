from langchain_community.document_loaders import PyPDFLoader
from langchain import PromptTemplate, LLMChain
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.llms import GPT4All
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain.callbacks.base import BaseCallbackManager
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler

documents = PyPDFLoader('./pdfs/os_book.pdf').load_and_split()
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1024,chunk_overlap=64)
texts = text_splitter.split_documents(documents)
embeddings = HuggingFaceEmbeddings(model_name='sentence-transformers/all-MiniLM-L6-v2')
faiss_index = FAISS.from_documents(texts, embeddings)
faiss_index.save_local("./index")

embeddings = HuggingFaceEmbeddings(model_name='sentence-transformers/all-MiniLM-L6-v2')

# load vector store
print("loading indexes")
faiss_index = FAISS.load_local("./index", embeddings, allow_dangerous_deserialization=True)
print("index loaded")
gpt4all_path = './models/alpaca1.gguf'

# # Set your query here manually
question = "What are the three states in which a process can exist"
matched_docs = faiss_index.similarity_search(question, 4)
context = "you are an operating systems developer with a deep knowledge in the field"
for doc in matched_docs:
    context = context + doc.page_content + " \n\n "

template = """
Please use the following context to answer questions.
Context: {context}
 - -
Question: {question}
Answer: Let's think step by step."""

callback_manager = BaseCallbackManager([StreamingStdOutCallbackHandler()])
llm = GPT4All(model=gpt4all_path, max_tokens=1000, callback_manager=callback_manager, verbose=True,repeat_last_n=0)
prompt = PromptTemplate(template=template, input_variables=["context", "question"]).partial(context=context)
chain = llm | prompt
response = chain.invoke("What are the three states in which a process can exist")
print(response)