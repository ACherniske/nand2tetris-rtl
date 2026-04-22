module Computer (
    input wire clk_12mhz,
    input wire btn_n,           // Physical Reset Button (Active Low)
    input wire uart_rx_pin,
    output wire [4:0] ledn      // LEDs for status
);
    // System Signals
    wire reset = ~btn_n;        // True when button is held
    
    // Loader Control
    wire loading_active = reset; // Hold reset button to stay in Load Mode
    
    // UART Signals
    wire uart_byte_ready;
    wire [7:0] uart_byte;
    
    // Loader Signals
    wire [14:0] loader_addr;
    wire [15:0] loader_data;
    wire        loader_we;
    
    // CPU Signals
    wire [15:0] cpu_instruction;  // From ROM
    wire [15:0] cpu_inM;          // Data from memory/IO to CPU
    wire [15:0] cpu_outM;         // Data from CPU to memory/IO
    wire [15:0] cpu_addressM;     // CPU data memory address (16-bit)
    wire [14:0] cpu_addressM_15;  // Truncated to 15-bit
    wire        cpu_we;           // CPU write enable
    wire [15:0] cpu_pc;           // Program counter
    
    // Data Memory Bus (CPU/Loader Muxed)
    wire [14:0] mem_addr;
    wire [15:0] mem_data_in;
    wire        mem_we;
    wire [15:0] mem_data_out;
    
    // Address Map Signals
    wire sel_ram, sel_screen, sel_kbd;
    wire [15:0] ram_out, screen_out, kbd_out;

    // Truncate CPU data address to 15 bits
    assign cpu_addressM_15 = cpu_addressM[14:0];

    // UART Receiver
    uart_rx u_uart (
        .clk(clk_12mhz), 
        .reset(reset), 
        .rx(uart_rx_pin),
        .data(uart_byte), 
        .data_ready(uart_byte_ready)
    );

    // Bootloader Controller
    Loader u_loader (
        .clk(clk_12mhz), 
        .reset(reset),
        .rx_data(uart_byte), 
        .rx_ready(uart_byte_ready),
        .mem_data(loader_data), 
        .mem_addr(loader_addr),
        .mem_write_en(loader_we), 
        .loading_active(loading_active)
    );

    // Instruction ROM (Dual-Port: CPU reads, Loader writes)
    ROM32K u_rom (
        .clk(clk_12mhz),
        // CPU instruction fetch port
        .cpu_address(cpu_pc[14:0]),
        .cpu_instruction(cpu_instruction),
        // Loader write port (only active in load mode)
        .load_address(loader_addr),
        .load_data(loader_data),
        .load_we(loader_we && loading_active)
    );

    // Data Memory Mux (CPU/Loader share data bus)
    assign mem_addr    = loading_active ? loader_addr      : cpu_addressM_15;
    assign mem_data_in = loading_active ? loader_data      : cpu_outM;
    assign mem_we      = loading_active ? 1'b0             : cpu_we;  // Loader doesn't write to data memory

    // Address Mapper
    AddressMap u_map (
        .addr(mem_addr), 
        .we(mem_we),
        .sel_ram(sel_ram), 
        .sel_screen(sel_screen), 
        .sel_kbd(sel_kbd)
    );

    // Data Memory/IO Modules
    RAM16K u_ram (
        .clk(clk_12mhz),
        .address(mem_addr[13:0]),
        .in(mem_data_in),
        .writeM(mem_we && sel_ram),
        .out(ram_out)
    );

    Screen u_scr (
        .clk(clk_12mhz), 
        .addr(mem_addr), 
        .data_in(mem_data_in), 
        .we(mem_we && sel_screen), 
        .data_out(screen_out)
    );

    Keyboard u_kbd (
        .addr(mem_addr), 
        .data_out(kbd_out)
    );

    // Data memory output mux
    assign mem_data_out = sel_screen ? screen_out : 
                          sel_kbd    ? kbd_out    : ram_out;
    
    assign cpu_inM = mem_data_out;

    // CPU Core
    CPU u_cpu (
        .clk(clk_12mhz), 
        .reset(loading_active),         // CPU is held in reset during Load Mode
        .instruction(cpu_instruction),  // Instruction from ROM (separate bus)
        .inM(cpu_inM),                  // Data from memory/IO
        .outM(cpu_outM),                // Data to memory/IO
        .writeM(cpu_we),                // Write enable
        .addressM(cpu_addressM),        // Data memory address
        .pc(cpu_pc)                     // Program counter
    );

    // Status LEDs
    assign ledn[0] = ~loading_active;   // ON when Running, OFF when Loading
    assign ledn[1] = ~uart_byte_ready;  // Blinks when receiving UART data
    assign ledn[2] = ~sel_ram;          // LED ON when RAM is selected
    assign ledn[3] = ~sel_screen;       // LED ON when Screen is selected
    assign ledn[4] = ~sel_kbd;          // LED ON when Keyboard is selected

endmodule
