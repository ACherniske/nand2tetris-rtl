import serial
import sys
import time

def upload_hack_file(port, filename):
    try:
        # Open serial port
        ser = serial.Serial(port, baudrate=115200, timeout=1)
        print(f"Connecting to {port}...")
        time.sleep(2) # Allow time for serial initialization
        
        with open(filename, 'r') as f:
            lines = [line.strip() for line in f if line.strip()]
            
        print(f"Uploading {len(lines)} instructions...")
        
        for i, line in enumerate(lines):
            # Convert binary string to 16-bit integer
            value = int(line, 2)
            # Send as 2 bytes (Big Endian)
            ser.write(value.to_bytes(2, byteorder='big'))
            
            # Optional: Progress indicator every 100 lines
            if i % 100 == 0:
                print(f"Progress: {i}/{len(lines)}", end='\r')
        
        ser.close()
        print("\nUpload complete successfully.")
        
    except Exception as e:
        print(f"\nError: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 flasher.py /dev/ttyUSB0 program.hack")
    else:
        upload_hack_file(sys.argv[1], sys.argv[2])
