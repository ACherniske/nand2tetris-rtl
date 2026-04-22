def pad_hack_file(input_filename, output_filename, total_lines=32768):
    # Read the existing instructions from your program
    with open(input_filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    # Calculate how many lines of zeros we need to add
    padding_needed = total_lines - len(lines)

    if padding_needed < 0:
        print(f"Warning: Your program is longer than {total_lines} lines!")
        return

    # Write the new file
    with open(output_filename, 'w') as f:
        # Write the original program
        for line in lines:
            f.write(line + '\n')
        
        # Fill the rest with zeros
        for _ in range(padding_needed):
            f.write('0' * 16 + '\n')

    print(f"Successfully padded '{input_filename}' to {total_lines} lines in '{output_filename}'.")

# Run the script
pad_hack_file('program.hack', 'program_padded.hack')