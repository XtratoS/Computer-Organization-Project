module PCI(
    input CLK,
    input FRAME,
    input IRDY,
    input [3:0] CBE,
    inout [31:0] AD,
    output DEVSEL_wire,
    output TRDY_wire,
    output [31:0] DEBUG,
    output [31:0] M1,
    output [31:0] M2,
    output [31:0] M3,
    output [31:0] M4
);
    // Constants
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    parameter DEVICE_ADDRESS = 32'h0000010;
    // wire Change_op = 0;
  
    // Read and write operation flags using the provided command
    reg [3:0] CONTROL_reg = 4'bz;
    wire READ_OP = (PCI_read == CONTROL_reg);
    wire WRITE_OP = (PCI_write == CONTROL_reg);
    
    // Memory belongs to the target
    reg [31:0] MEMORY [0:3];
    
    // Temporary Data Register to hold 4 bytes of data
    reg [31:0] DATA_reg = 32'h0;

    // DEBUGGING
    reg [31:0] TEMP = 4'bz;
    assign DEBUG = TEMP;
    assign M1 = MEMORY[0];
    assign M2 = MEMORY[1];
    assign M3 = MEMORY[2];
    assign M4 = MEMORY[3];
    
    // Signals for READ Operations
    wire TARGETED = (DEVICE_ADDRESS == AD);
    reg TARGETED_reg = 0;
    wire TRANSACTION = ~FRAME;
    wire LAST_DATA_TRANSFER = FRAME && ~IRDY;
    
    // RST Signal to reset flags after every transaction
    wire RST = FRAME && IRDY;
    
    // DEVSEL and TRDY signals
    reg DEVSEL = 1;
    reg DEVSEL_2 = 1;
    assign DEVSEL_wire = RST || DEVSEL;
    reg TRDY = 1;
    reg TRDY_2 = 1;
    assign TRDY_wire = RST || TRDY;
    
    // Counters
    reg [7:0] NEG_CLOCK_COUNTER = 0;
    reg [1:0] INDEX = 0;
    
    // ADDRESS LINE Multiplexing (To Recieve Address then Send or Recieve Data)
    wire ADDRESS_TURNAROUND = ~IRDY && DEVSEL;
    wire CONTROL_ADDRESS_LINE_DURING_READ = (READ_OP && ~IRDY && ~ADDRESS_TURNAROUND);
    wire WAITING_IRDY = TRANSACTION && IRDY && ~DEVSEL;
    assign AD = ((CONTROL_ADDRESS_LINE_DURING_READ || WAITING_IRDY) ? DATA_reg : 32'hz);
    
    always @(negedge CLK) begin
        // Handle the delay for DEVSEL and TRDY
        DEVSEL <= DEVSEL_2;
        TRDY <= TRDY_2;
        
        // RESET NEG_EDGE_COUNTER INDEX
        if (RST) begin
            NEG_CLOCK_COUNTER <= 0;
            CONTROL_reg <= 4'bz;
            TARGETED_reg <= 0;
            TRDY <= 1;
            TRDY_2 <= 1;
            DEVSEL <= 1;
            DEVSEL_2 <= 1;
        end
        
        // RESET MEMORY INDEX
        if (NEG_CLOCK_COUNTER == 0) begin
            INDEX <= 0;
        end
        
        // READ
        if (READ_OP) begin
            if (TRANSACTION || LAST_DATA_TRANSFER) begin
                // Increment the clock counter every negative edge
                NEG_CLOCK_COUNTER <= NEG_CLOCK_COUNTER + 1;
                DEVSEL_2 <= 0;
                TRDY_2 <= 0;
            end
            if (~IRDY) begin
                DATA_reg <= MEMORY[INDEX];
                INDEX <= INDEX + 1;
            end
        end
        // WRITE
        else if (WRITE_OP) begin
            if (LAST_DATA_TRANSFER) begin
                DEVSEL_2 <= 1;
                TRDY_2 <= 1;
            end
            if (TRANSACTION || LAST_DATA_TRANSFER) begin
                NEG_CLOCK_COUNTER <= NEG_CLOCK_COUNTER + 1;
            end
            if (TARGETED_reg) begin
                DEVSEL_2 <= 0;
                TRDY_2 <= 0;
            end
        end
    end
    
    always @(posedge CLK) begin
         
        // Store the control signal in the first positive edge
        if (NEG_CLOCK_COUNTER == 0) begin
            // Remember if the device was targeted by the operation
            TARGETED_reg <= TARGETED;
            CONTROL_reg <= CBE;
        end
        
        // WRITE OPERATION
        if (TARGETED_reg && WRITE_OP && ~TRDY) begin
            if (CBE == 4'b1111) begin
                MEMORY[INDEX] <= AD;
                TEMP <= AD;
            end else if (CBE == 4'b0000) begin
                MEMORY[INDEX] <= 0;
                TEMP <= 0;
            end
            INDEX <= INDEX + 1;
        end
    end
endmodule