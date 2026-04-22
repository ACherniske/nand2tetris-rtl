module AddressMap (
    input  wire [14:0] addr,
    input  wire        we,
    
    // Select signals for each component
    output wire        sel_ram,
    output wire        sel_screen,
    output wire        sel_kbd
);

    // 0x0000 - 0x3FFF : RAM (16K)
    assign sel_ram    = (addr < 15'h4000);
    
    // 0x4000 - 0x5FFF : Screen (8K)
    assign sel_screen = (addr >= 15'h4000 && addr < 15'h6000);
    
    // 0x6000          : Keyboard
    assign sel_kbd    = (addr == 15'h6000);

endmodule
