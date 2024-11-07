# AI Hardware Attack Challenge
This project introduces a new approach to leveraging LLMs like GPT-4o for hardware security tasks. By focusing on teaching GPT-4o through constructing a knowledge base  and few-shot prompting, this method could extend beyond hardware Trojans to other types of security vulnerabilities in the hardware domain. This approach eliminates the need for fine-tuning since the two approaches we use (generated knowledge and few-shot examples) only require precisely constructed and tuned prompts. While we acknowledge the fact that it might be not as robust as the fine-tuning approach, the fact that our framework is less computationally expensive allows us to generate attack attempts more quickly, thus having a larger pool of hardware trojans to validate and choose from. Moreover, since our approach is based on tuning the prompts and providing few-shot examples, we can change the scope of the attacks more easily, making them more generalizable or narrowed depending on the task at hand. It also demonstrates the potential risks of AI-driven attack vectors and emphasizes the need for enhanced security measures in hardware verification. All our work is open source.

## Methodology
### Manual Chain of Thought prompting
We base our approach on widely accepted automated CoT prompting, where a model is explicitly prompted to generate a step-by-step explanation or reasoning process before arriving at a final answer. However, since the model needs to be provided with a source code of the digital system under attack and the size of the complete system implementation almost always exceeds the context limit of the  model, there is no feasible way to construct a single comprehensive prompt that would end with a "think step by step" style instruction. Thus, we turn our attention to manually constructing a series of prompts that will guide the model. To bypass the limitation of context size window, in our pipeline, we ask the model to pick onle one module that is the ost prone to vulnerability injection. It is only after the target module is picked that we feed it the source code of the corresponding module.
### Few-shot approach
The few-shot prompting approach mentioned in the third step of our pipeline flow above is a technique used to enhance the model's in-context learning capabilities by providing the examples of response format that the model should follow. Specifically, our model is provided with a list of hardware trojans right before it is asked to generate a list of potential bugs. The hardware trojans that we include cover a range of components of the target digital system (https://github.com/ultraembedded/riscv is used for the purpose of demonstration), including ALU, Branch Control, Instruction RAM, and Program Counter. The set of examples was constructed based on the Hardware Trojan Dataset of RISC-V (https://zenodo.org/records/11035341) by selecting code snippets from the files that contained trojans.
### Generated knowledge
The idea behind the Generate Knowledge prompting is to ask the language model to generate useful information pertaining to the task at hand that the model can further use to generate its final response. Considering the specificity of our task, to improve the pool of information that the model can use to generate its knowledge base, we decided to manually create a file that will be fed to the model by handpicking academic papers that we thought contained the most relevant data. The list of the references is included in Appendix B. The constructed file ended up containing 80 pages, which, considering the limited context window, was too long. To make use of the most of the collected data, we decided to condense the document using another model instance. We split the  original document into smaller chunks and fed them one by one into the new model instance asking it to build a knowledge block that will be most useful for answering a particular query that we provided. The addition of the query to the knowledge generation task allowed us to make the knowledge base more tailored to a specific step at which it was constructed. As it was mentioned in the pipeline flow description, we ended up placing the knowledge generation step right before the moedl selects and implements a hardware trojan. This was the result of us playing around with the knowledge generation function by placing it at different steps in the pipeline and feeding it the corresponding prompts. Once every chunk of the original document was processed, we concatenated the condensed chunks and fed the resulting string to the original model instance asking it to remember the provided text and use it as knowledge base while constructing responses for the next queries.
## Results
In this project, we utilized a Large Language Model (LLM) to introduce a vulnerability through the framework described earlier. However, the logic of the testbenches generated was frequently flawed, requiring significant manual adjustments and extensive debugging by analyzing signal waveforms. Due to time constraints, we successfully refined only one testbench to demonstrate the exploit. Specifically, we used the testbench generated in round 1, which underwent substantial manual tweaking after observing signal waveforms, leading to a significant revision of its logic.
## Future direction
Future directions for this research involve experimenting with the trojan insertion pipeline framework across a diverse range of Verilog projects to evaluate its adaptability and effectiveness. This includes exploring different types of hardware designs and utilizing varied few-shot examples to assess how well the framework generalizes to new scenarios. Additionally, efforts will focus on refining the automated testbench generation process to ensure that testbenches are capable of triggering and exploiting inserted vulnerabilities without requiring manual inspection. By automating this process end-to-end, the framework can achieve greater scalability and utility in real-world applications while minimizing human intervention.

## Replication
To replicate the pipeline, follow these steps:

* Set up a virtual environment (optional but recommended):
```bash
$ python3 -m venv venv
$ source venv/bin/activate
```
* Install the required python packages:
```bash
$ pip3 install -r requirements.txt
```

* set your API key
```bash
$ export OPENAI_API_KEY=<API key>
```

* run the python script
```bash
$ python response.py
```
