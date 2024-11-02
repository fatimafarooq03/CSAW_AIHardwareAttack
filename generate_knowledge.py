import fitz
import openai
import re

openai.api_key = ''

def extract_text_from_pdf(pdf_path):
    text = ""
    with fitz.open(pdf_path) as pdf:
        for page_num in range(pdf.page_count):
            page = pdf[page_num]
            text += page.get_text()
    return text

def chunk_text(text, max_tokens=2000):
    sentences = re.split(r'(?<=[.!?]) +', text)
    chunks = []
    current_chunk = ""
    current_tokens = 0
    
    for sentence in sentences:
        sentence_tokens = len(sentence.split()) / 4  # Approximate tokens per word
        
        if current_tokens + sentence_tokens > max_tokens:
            chunks.append(current_chunk.strip())
            current_chunk = sentence
            current_tokens = sentence_tokens
        else:
            current_chunk += " " + sentence
            current_tokens += sentence_tokens
    
    if current_chunk:
        chunks.append(current_chunk.strip())
        
    return chunks

def summarize_chunk(chunk, query):
    response = openai.ChatCompletion.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are a hardware security expert helping with creating a knowledge base"
             "from a large document. You are given a small chunk of that document and a particular user query. Produce"
              "the knowledge base out of the chunk that will be the most useful to answer that particular query."},
            {"role": "user", "content": f"Summarize the following text:\n\n{chunk} for this query:\n\n{query}"}
        ],
        max_tokens=400  # Adjust for concise summaries
    )
    return response.choices[0].message['content'].strip()

def generate_knowledge(file_path='knowledge_base.pdf', query=''):
    text = extract_text_from_pdf(file_path)
    chunks = chunk_text(text)
    consolidated_summary = ""
    output_file="generated_knowledge.txt"

    for chunk in chunks:
        summary = summarize_chunk(chunk, query)
        consolidated_summary += summary + " "  # Concatenate each summary with a space
    
    with open(output_file, "w") as file:
        file.write(consolidated_summary.strip())
    return consolidated_summary.strip()

