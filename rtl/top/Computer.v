module Computer (
    input wire clk_12mhz,
    input wire btn_n,       // Active low: hold to load, release to run
    input wire uart_rx_pin,
    output wire [4:0] ledn
);
    // --- System Signals ---
    wire reset = ~btn_n;    
    
    // --- Bus Signals (Muxed) ---
    wire [14:0] mem_addr;
    wire [15:0] mem_data_in;
    wire        mem_we;
    wire [15:0] mem_data_out;

    // --- Component Signals ---
    wire uart_byte_ready;
    wire [7:0] uart_byte;
    
    wire loading_active;
    wire [14:0] loader_addr;
    wire [15:0] loader_data;
    wire        loader_we;
    
    wire [14:0] cpu_pc;
    wire [15:0] cpu_data_out;
    wire        cpu_we;
    
    wire sel_ram, sel_screen, sel_kbd;
    wire [15:0] ram_out, screen_out, kbd_out;

    // 1. UART Receiver
    uart_rx u_uart (
        .clk(clk_12mhz), .reset(reset), .rx(uart_rx_pin),
        .data(uart_byte), .data_ready(uart_byte_ready)
    );

    // 2. Bootloader Controller
    Loader u_loader (
        .clk(clk_12mhz), .reset(reset),
        .rx_data(uart_byte), .rx_ready(uart_byte_ready),
        .mem_data(loader_data), .mem_addr(loader_addr),
        .mem_write_en(loader_we), .loading_active(loading_active)
    );

    // 3. Address Mapper
    AddressMap u_map (
        .addr(mem_addr), .we(mem_we),
        .sel_ram(sel_ram), .sel_screen(sel_screen), .sel_kbd(sel_kbd)
    );

    // 4. Memory/IO Modules
    RAM16K u_ram (.clk(clk_12mhz), .addr(mem_addr), .data_in(mem_data_in), .we(mem_we && sel_ram), .data_out(ram_out));
    Screen u_scr (.clk(clk_12mhz), .addr(mem_addr), .data_in(mem_data_in), .we(mem_we && sel_screen), .data_out(screen_out));
    Keyboard u_kbd (.addr(mem_addr), .data_out(kbd_out));

    // 5. CPU Core
    CPU u_cpu (
        .clk(clk_12mhz), .reset(loading_active),
        .instruction(mem_data_out), .pc(cpu_pc),
        .data_out(cpu_data_out), .writeM(cpu_we)
    );

    // --- Muxing Logic ---
    assign mem_addr    = loading_active ? loader_addr : cpu_pc;
    assign mem_data_in = loading_active ? loader_data : cpu_data_out;
    assign mem_we      = loading_active ? loader_we   : cpu_we;
    
    assign mem_data_out = sel_screen ? screen_out : 
                          sel_kbd    ? kbd_out    : ram_out;

    // --- Status ---
    assign ledn[0] = ~loading_active; // Green: Running
    assign ledn[1] = ~uart_byte_ready; 

endmodule
