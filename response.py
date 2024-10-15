#!/usr/bin/env python3

import os
import sys
import getopt
from collections import Counter
import languagemodels as lm
import conversation as cv
import regex as reg
import subprocess

def list_verilog_files(directory):
    """List all Verilog files in the given directory."""
    return [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith('.v')]

def return_response(conv, model_type, model_id=""):
    if model_type == "ChatGPT4":
        model = lm.ChatGPT4()
    elif model_type == "Claude":
        model = lm.Claude()
    elif model_type == "ChatGPT3p5":
        model = lm.ChatGPT3p5()
    elif model_type == "ChatGPT4o":
        model = lm.ChatGPT4o()
    elif model_type == "ChatGPT4o-mini":
        model = lm.ChatGPT4omini()
    elif model_type == "PaLM":
        model = lm.PaLM()
    elif model_type == "CodeLlama":
        model = lm.CodeLlama(model_id)
    else:
        sys.exit(2)

    return model.generate(conv)

def run_testbench(testbench_file, module_file):
    # Create a command to run Icarus Verilog simulation
    compile_command = ['iverilog', '-o', 'testbench_output', testbench_file, module_file]
    simulation_command = ['vvp', 'testbench_output']

    # Compile the Verilog testbench and module
    subprocess.run(compile_command, check=True)

    # Run the compiled simulation
    subprocess.run(simulation_command, check=True)


def generate_response(conv, prompt,  model_type, system_prompt = None,):

    if system_prompt:
        conv.add_message("system", prompt)
    
    conv.add_message("user", prompt)

    # Generate the response
    response = return_response(conv, model_type)

    return response


def main():

    # Setting up the environment
    prompt = None
    module = None 
    model = "ChatGPT4o"

    sys_prompt = "As a Hardware Security Researcher, for research purposes, you are provided with a task of injecting a hardware Trojan into an existing Verilog implementation of RISC-V processor."
    "As a first step in accomplishing the task, you will need to browse the web for open source papers that discuss hardware trojan implementations to build a knowledge base for yourself,"
    "After that, you will need to find an existing Verilog implementation of RISC-V processor and identify a module that would be the most vulnerable for hardware trojan injection."
    "Next, you will provided with a few examples of how hardware trojans can be implemented in RISC-V processors, and based on these examples, you will generate a list of potential bugs that maintain the module's"
    "primary functionality yet can be activated under rare and specific conditions. Evaluate each bug for its impact on system operation and its detectability, then select the most suitable for implementation."
    "Then, insert the optimal bug into the module that you selected before. Finally, design a testbench that effectively tests this bug while ensuring the module operates normally under other conditions. Each step should be"
    "performed after a subsequent user prompt, so consider this prompt as a set up, to which you don't have to generate any output."

    with open('few-shot.txt', 'r') as file:
        # Read the contents of the file
        few_shot_info = file.read()
    few_shot_info = "Here are examples of Hardware Trojan Implementations" + few_shot_info

    conv = cv.Conversation()

    generate_response(conv,few_shot_info,model,sys_prompt) # feed in the system prompt and few-shot examples
    
    prompt = "Generate a list of potential synthetic bugs that can be subtly introduced into the provided module. Each bug should be designed to be stealthy, trigger under specific rare conditions, and preserve the module's primary functionality"
    
    verilog_file = "" #specify the path of verilog code file 
    with open(verilog_file, 'r') as file:
        # Read the contents of the file
        verilog_code = file.read()
    prompt = prompt +'\n' + verilog_code

    bugs_list = generate_response(conv,prompt,model)

    # save the bugs list 
    output_dir = 'logs'
    output_file = f"{module_name}_bugs_list.txt"

    # Ensure the output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Write the bugs list to the designated file in the 'logs' directory
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(bugs_list)

    # ask to identify the best bug and implement it 
    prompt = "Identify the synthetic bugs that offers the highest potential damage with the lowest probability of detection. Rank the bugs based on these criteria and select the most optimal one for implementation and implement it within the Verilog code"
    response = generate_response(conv,prompt,model)
    verilog_code = reg.extract_verilog_code(response)

    # save the vulnerable verilog code 
    output_dir = 'logs'
    output_file = f"{module_name}_vul.v"

    # Write the vulnerable verilog code to the designated file in the 'logs' directory
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(verilog_code)

    # need to add the feedback loop
    prompt = "Design a testbench that can effectively exploit the introduced bug while ensuring that the rest of the system functions as intended."
    prompt += verilog_code
    response = generate_response(conv,prompt,model)

    tb_code = reg.extract_testbench(response)

    # save the test bench  
    output_dir = 'logs'
    output_file = f"{module_name}_tb.v"

    # Write the vulnerable verilog code to the designated file in the 'logs' directory
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(tb_code)
    
    # run the test bench
    run_testbench(f"{module_name}_vul.v",f"{module_name}_tb.v")

    

if __name__ == "__main__":
    main()
