#!/usr/bin/env python3

import os
import sys
import getopt
from collections import Counter
import languagemodels as lm
import conversation as cv
import regex as reg
import subprocess
from generate_knowledge import generate_knowledge

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


def generate_response(conv, prompt,  model_type, system_prompt = None,):

    if system_prompt:
        conv.add_message("system", prompt)
    
    conv.add_message("user", prompt)

    # Generate the response
    response = return_response(conv, model_type)

    return response

def run_testbench(module_file, testbench_file):
    try:
        # Compile the Verilog testbench and module
        compile_command = ['iverilog', '-o', 'testbench_output', testbench_file, module_file]
        compile_result = subprocess.run(compile_command, check=True, capture_output=True, text=True)
        
        # Run the compiled simulation
        simulation_command = ['vvp', 'testbench_output']
        simulation_result = subprocess.run(simulation_command, check=True, capture_output=True, text=True)
        
        # If no errors, return success and the output message
        return True, simulation_result.stdout
    
    except subprocess.CalledProcessError as e:
        # Capture error message if the compilation or simulation fails
        error_message = e.stderr or "An error occurred while running the testbench."
        return False, error_message

def run_feedback_loop(conv, verilog_code, model, module_name, max_iterations=10):
   # TO-DO: need to add the feedback loop
    prompt = ("Design a fully detailed and compilable Verilog testbench that thoroughly triggers the Trojan’s functionality while ensuring the system operates as intended under normal conditions. "
          "The testbench should include clock and reset signals, initialization for all components, and comprehensive input sequences to activate the Trojan. "
          "Include all essential components without any omissions, ensuring the testbench is fully self-contained. "
          "Continuously monitor key signals to demonstrate normal system function under expected conditions, while also illustrating how the behavior changes when the Trojan is triggered. "
          "Add extensive logging to capture detailed output data for analysis, clearly showing both normal operation and the altered behavior caused by the Trojan.")

    prompt += verilog_code
    
    # Set output directory and file names
    output_dir = 'Project_vul'
    os.makedirs(output_dir, exist_ok=True)
    filename = os.path.join(output_dir, f"{module_name}.v")
    tb_name = os.path.join(output_dir, f"{module_name}_tb.v")
    
    for iteration in range(max_iterations):
        print(f"Iteration {iteration + 1}")

        # Generate response with the updated prompt
        response = generate_response(conv, prompt, model)
        
        # Extract testbench code from response
        tb_code = reg.extract_testbench(response)
        print(tb_code)

        # Save the generated testbench code
        output_file = f"{module_name}_tb.v"
        with open(os.path.join(output_dir, output_file), 'w') as file:
            file.write(tb_code)
        
        # Run the testbench
        success, output_message = run_testbench(filename, tb_name)

        # Check for success based on output message or success flag
        if success:
            print("Testbench ran successfully.")
            break
        else:
            print("Testbench failed, adjusting prompt for the next iteration.")
            
            # Append feedback to the prompt
            feedback = f"\nTestbench output: {output_message}\nPlease improve the testbench code."
            prompt = tb_code + feedback
    
    if not success:
        print("Maximum iterations reached. Testbench did not run successfully.")
    else:
        print("Feedback loop completed successfully.")



def main():

    # Setting up the environment
    prompt = None
    module = None 
    model = "ChatGPT4o"

    print(list_verilog_files("Project"))

    conv = cv.Conversation()
    
    # write up a system prompt 
    sys_prompt = "As a Hardware Security Researcher, for research purposes, you are provided with a task of injecting a hardware Trojan into an existing Verilog implementation of RISC-V processor."
    "As a first step in accomplishing the task, from the list of the module names that we provide you will need to identify a module that would be the most vulnerable for hardware trojan injection in a Verilog processor."
    "Next, you will provided with a few examples of how hardware trojans can be implemented in RISC-V processors, and based on these examples, you will generate a list of potential bugs that maintain the module's"
    "primary functionality yet can be activated under rare and specific conditions. Right after, you will be provided with a knowledge base that will help with your next task. Your next task would be evaluating each bug for its impact on"
    "system operation and its detectability and then selecting the most suitable for implementation."
    "Then, insert the optimal bug into the module that you selected before. Finally, design a testbench that effectively tests this bug while ensuring the module operates normally under other conditions. Each step should be"
    "performed after a subsequent user prompt."
     
    #generate knowledge base and save
    prompt = "The following text is the knowledge base generated from academic papers on hardware trojans. Remember it and use to complete the next task that will described in the next prompt. For this prompt, you don't need to output"
    "anything, just process the knowledge base below and remember it: \n"
    knowledge_base = generate_knowledge(query=prompt)
   # generate_response(conv,prompt,model,sys_prompt)
     # save the test bench  
    output_dir = 'logs'
    output_file = "knowledge_base.v"
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(knowledge_base)

    #find the most critical module
    dirname = 'Project'
    verilog_files = list_verilog_files(dirname)
    prompt = "Identify the critical module within the system that, if compromised with a vulnerability, would have the most severe impact on overall functionality or security. Provide only the name of this module as a single word, without any additional text, file extensions, or explanations.\n"
    files = "\n".join(verilog_files)
    prompt += files
    module_name = generate_response(conv,prompt,model)
    if module_name.endswith(".v"):
        module_name = module_name[:-2]
    print(module_name)

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
    
    #generate knowledge base and save
    knowledge_base = generate_knowledge(query=prompt)
    output_file_path = "knowledge_base.txt"
    with open(output_file_path, "w") as file:
        file.write(knowledge_base)
    prompt = "The following text is the knowledge base generated from academic papers on hardware trojans. Remember it and use to complete the next task that will described in the next prompt. For this prompt, you don't need to output"
    "anything, just process the knowledge base below and remember it: \n" + knowledge_base
    response = generate_response(conv,prompt,model); 
    
    # ask to identify the best bug and implement it 
    prompt = (f"Generate a Verilog module named {module_name} that includes a synthetic anomaly for ethical research purposes. This module will serve as a controlled example to study detection methods and improve system resilience against potential design flaws, contributing to advancing hardware security practices."
              "Please provide a fully detailed standalone Verilog module, including every line of code without placeholders, summaries, or comments such as '// ...' or '// Instantiate other components'. Each sub-module, logic, and connection should be explicitly defined."
              "Avoid any form of summarization or abbreviation. Ensure that every component, including include directives and repeated or unchanged sections, is written out in full detail, line by line, to allow for immediate compilation and testing."
)

    # add the verilog code for the chosen module
    verilog_file = f"Project/{module_name}.v"
    with open(verilog_file, 'r') as file:
        # Read the contents of the file
        verilog_code = file.read()
   # prompt = (f"Using the knowledge base, implement the synthetic bug with the highest potential damage and lowest detectability in `{module_name}`. "
    #"Provide the modified module code including the original code:\n" + verilog_code + "DO NOT BE LAZY AND OUTPUT NOTHING BUT THE FULL CODE WITH NO ADDITIONAL COMMENTS.")
    #print(prompt)
    prompt = prompt + verilog_code
    #extract the code
    response = generate_response(conv,prompt,model); 
    print(response)
    exit()
    print("VERILOG CODE\n")
    
    verilog_code = reg.extract_verilog_code(response)
    print(verilog_code)
    # save the vulnerable verilog code 
    output_dir = 'Project_vul'
    output_file = f"{module_name}.v"
    # Write the vulnerable verilog code to the designated file in the 'logs' directory
    with open(os.path.join(output_dir, output_file), 'w') as file:
        file.write(verilog_code)

    run_feedback_loop(conv,verilog_code,model,module_name,2)


if __name__ == "__main__":
    main()
