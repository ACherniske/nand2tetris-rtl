def convert_hack_to_hex(input_filename, output_filename):
    """
    Converts a binary string file (.hack) to a hex file (.hex)
    suitable for $readmemh in Verilog synthesis.
    """
    try:
        with open(input_filename, 'r') as f_in:
            with open(output_filename, 'w') as f_out:
                for line in f_in:
                    binary_str = line.strip()
                    if not binary_str:
                        continue
                    
                    # Convert binary string to integer, then to hex
                    # 16-bit binary to 4-digit hex
                    hex_val = int(binary_str, 2)
                    f_out.write(f"{hex_val:04X}\n")
        
        print(f"Successfully converted '{input_filename}' to '{output_filename}'.")
    
    except ValueError as e:
        print(f"Error converting file: {e}. Ensure all lines are 16-bit binary strings.")

# Run the converter
if __name__ == "__main__":
    convert_hack_to_hex('program.hack', 'program.hex')
