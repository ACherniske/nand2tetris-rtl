module Computer (
    input wire clk_12mhz,
    input wire btn_n,           // Physical Reset Button (Active Low)
    input wire uart_rx_pin,
    output wire [4:0] ledn      // LEDs for status
);
    // --- System Signals ---
    wire reset = ~btn_n;        // True when button is held
    
    // --- Muxed Memory Bus ---
    wire [14:0] mem_addr;
    wire [15:0] mem_data_in;
    wire        mem_we;
    wire [15:0] mem_data_out;   // Data from Mapped Devices to CPU/Loader

    // --- Component Signals ---
    wire uart_byte_ready;
    wire [7:0] uart_byte;
    
    // Loader signals
    wire loading_active = reset; // Hold reset button to stay in Load Mode
    wire [14:0] loader_addr;
    wire [15:0] loader_data;
    wire        loader_we;
    
    // CPU signals
    wire [15:0] cpu_outM;
    wire [15:0] cpu_addressM;
    wire        cpu_we;
    wire [15:0] cpu_pc;
    
    // Address Map wires
    wire sel_ram, sel_screen, sel_kbd;
    wire [15:0] ram_out, screen_out, kbd_out;

    // 1. UART Receiver
    uart_rx u_uart (
        .clk(clk_12mhz), 
        .reset(reset), 
        .rx(uart_rx_pin),
        .data(uart_byte), 
        .data_ready(uart_byte_ready)
    );

    // 2. Bootloader Controller
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

    // 3. Address Mapper
    AddressMap u_map (
        .addr(mem_addr), 
        .we(mem_we),
        .sel_ram(sel_ram), 
        .sel_screen(sel_screen), 
        .sel_kbd(sel_kbd)
    );

    // 4. Memory/IO Modules
    RAM16K u_ram (
        .clk(clk_12mhz),
        .address(mem_addr[13:0]),    // Map 14-bit address
        .in(mem_data_in),            // Matches 'in'
        .writeM(mem_we && sel_ram),  // Matches 'writeM'
        .out(ram_out)                // Matches 'out'
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

    // 5. CPU Core
    CPU u_cpu (
        .clk(clk_12mhz), 
        .reset(loading_active),      // CPU is held in reset during Load Mode
        .instruction(mem_data_out), 
        .inM(mem_data_out),          // Memory data input to CPU
        .outM(cpu_outM),             // Data output from CPU
        .writeM(cpu_we),             // CPU write signal
        .addressM(cpu_addressM),     // CPU memory address
        .pc(cpu_pc)                  // CPU Program Counter
    );

    // 6. Muxing Logic
    assign mem_addr    = loading_active ? loader_addr   : cpu_addressM;
    assign mem_data_in = loading_active ? loader_data   : cpu_outM;
    assign mem_we      = loading_active ? loader_we     : cpu_we;
    
    assign mem_data_out = sel_screen ? screen_out : 
                          sel_kbd    ? kbd_out    : ram_out;

    // 7. Status LEDs
    assign ledn[0] = ~loading_active;  // ON when Running, OFF when Loading
    assign ledn[1] = ~uart_byte_ready; // Blinks when receiving UART data
    assign ledn[2] = ~sel_ram;         // LED ON when RAM is selected
    assign ledn[3] = ~sel_screen;      // LED ON when Screen is selected
    assign ledn[4] = ~sel_kbd;         // LED ON when Keyboard is selected

endmodule
