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

    print(list_verilog_files("Project"))

    conv = cv.Conversation()
    
    # write up a system prompt 
    sys_prompt = "As a Hardware Security Researcher, for research purposes, you are provided with a task of injecting a hardware Trojan into an existing Verilog implementation of RISC-V processor."
    "As a first step in accomplishing the task, you will need to browse the web for open source papers that discuss hardware trojan implementations to build a knowledge base for yourself,"
    "After that, you will need to identify a module that would be the most vulnerable for hardware trojan injection in a Verilog processor."
    "Next, you will provided with a few examples of how hardware trojans can be implemented in RISC-V processors, and based on these examples, you will generate a list of potential bugs that maintain the module's"
    "primary functionality yet can be activated under rare and specific conditions. Evaluate each bug for its impact on system operation and its detectability, then select the most suitable for implementation."
    "Then, insert the optimal bug into the module that you selected before. Finally, design a testbench that effectively tests this bug while ensuring the module operates normally under other conditions. Each step should be"
    "performed after a subsequent user prompt."
     
    #generate knowledge base and save
    prompt = "Please search for open-source methodologies related to hardware Trojan insertion, and compile a knowledge base based on findings from web sources."
    knowledge_base = generate_response(conv,prompt,model,sys_prompt)
     # save the test bench  
    output_dir = 'logs'
    output_file = "knowledge_base.v"
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(knowledge_base)

    #find the most critical module
    dirname = 'Project'
    verilog_files = list_verilog_files(dirname)
    prompt = "Identify the critical module within the system that, if compromised with a vulnerability, would have the most severe impact on overall functionality or security.Provide only the name of the module, without any file extensions\n"
    files = "\n".join(verilog_files)
    prompt += files
    module_name = generate_response(conv,prompt,model)

    # read in few-shot examples and ask to indentify list of bugs 
    with open('few-shot.v', 'r') as file:
        # Read the contents of the file
        few_shot_info = file.read()
    few_shot_info = "Here are examples of Hardware Trojan Implementations" + few_shot_info + '\n'
    prompt = few_shot_info + "Generate a list of potential synthetic bugs that can be subtly introduced into the chosen module. Each bug should be designed to be stealthy, trigger under specific rare conditions, and preserve the module's primary functionality"
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
    prompt = "Identify the synthetic bugs that offers the highest potential damage with the lowest probability of detection"
    "Rank the bugs based on these criteria and select the most optimal one for implementation and implement it within the Verilog code for the chosen module"
    # add the verilog code for the chosen module
    verilog_file = f"Project/{module_name}.v"
    with open(verilog_file, 'r') as file:
        # Read the contents of the file
        verilog_code = file.read()
    prompt = prompt +'\n' + verilog_code
    #extract the code
    verilog_code = reg.extract_verilog_code(response)

    # save the vulnerable verilog code 
    output_dir = 'Project'
    output_file = f"{module_name}_vul.v"
    # Write the vulnerable verilog code to the designated file in the 'logs' directory
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(verilog_code)


    # need to add the feedback loop
    prompt = "Design a testbench that can effectively exploit the introduced bug while ensuring that the rest of the system functions as intended.\n"
    prompt += verilog_code
    response = generate_response(conv,prompt,model)
    tb_code = reg.extract_testbench(response)
    # save the test bench  
    output_dir = 'Project'
    output_file = f"{module_name}_tb.v"
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(tb_code)
    filename = os.path.join(output_dir,f"{module_name}_vul.v")
    tb_name = os.path.join(output_dir,f"{module_name}_tb.v")
    # run the test bench
    run_testbench(filename,tb_name)


if __name__ == "__main__":
    main()
