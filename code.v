module Clock(clock);
    output clock;
    reg clock;
    initial
        clock = 0;
    always
        #5 clock = ~clock;
endmodule

// The Main Module
module PCI(
    input clk,
    input Frame,
    input IRDY,
    input [3:0] CBE,
    inout [31:0] AD,
    output DEVSEL_wire,
    output TRDY_wire,
    output reg [31:0] DEBUG,
    input FORCE_DEVSEL_AND_TRDY_HIGH
);
    // Constants
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    parameter device_address = 32'h0000010;
    
    // Read and write operation flags using the provided command
    wire READ_OP = PCI_read == CBE;
    wire WRITE_OP = PCI_write == CBE;
    
    // Signals for READ Operations
    wire TARGETED = (device_address == AD);
    reg TARGETED_REG = 0;
    wire TRANSACTION = ~Frame;
    wire LAST_DATA_READ = Frame && ~IRDY;
    
    // DEVSEL and TRDY signals
    reg DEVSEL = 1'b1;
    reg DEVSEL_2 = 1'b1;
    assign DEVSEL_wire = FORCE_DEVSEL_AND_TRDY_HIGH ? 1 : DEVSEL;
    reg TRDY = 1'b1;
    reg TRDY_2 = 1'b1;
    assign TRDY_wire = FORCE_DEVSEL_AND_TRDY_HIGH ? 1 : TRDY;
    
    // Counters
    reg [3:0] NEG_CLOCK_COUNTER = 0;
    reg [1:0] INDEX = 0;
    
    // Memory belongs to the target
    reg [31:0] MEMORY [0:3];
    reg [31:0] DATA_REG = 32'h0;
    
    // ADDRESS LINE Multiplexing (To Recieve Address then Send or Recieve Data)
    assign AD = (READ_OP && ~IRDY) ? DATA_REG : 32'hz;
    
    always @(negedge clk) begin
    
        DEVSEL <= DEVSEL_2;
        TRDY <= TRDY_2;
        
        if (READ_OP) begin
            if ((TRANSACTION || LAST_DATA_READ)) begin
                // Increment the clock counter every negative edge
                NEG_CLOCK_COUNTER <= NEG_CLOCK_COUNTER + 1;
                if (NEG_CLOCK_COUNTER == 0) begin
                    MEMORY[0] <= 32'd101;
                    MEMORY[1] <= 32'd102;
                    MEMORY[2] <= 32'd103;
                    MEMORY[3] <= 32'd104;
                end
                DEVSEL_2 <= 0;
                TRDY_2 <= 0;
            end
            if (NEG_CLOCK_COUNTER >= 1) begin
                DATA_REG <= MEMORY[INDEX];
                INDEX <= INDEX + 1;
            end
        end 
        else if (WRITE_OP) begin
            if (LAST_DATA_READ) begin
                DEVSEL_2 <= 1;
                TRDY_2 <= 1;
            end
            if (TRANSACTION || LAST_DATA_READ) begin
                NEG_CLOCK_COUNTER <= NEG_CLOCK_COUNTER + 1;
            end
            if (TARGETED_REG) begin
                DEVSEL_2 <= 0;
                TRDY_2 <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        TARGETED_REG <= TARGETED;
        if (WRITE_OP) begin
            DEBUG <= AD;
        end
    end
endmodule

module PCIWRITETest;
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    // Instantiating the clock
    Clock C(clk);
    // Instantiation the PCI Variables
    reg Frame = 1;
    reg IRDY = 1;
    reg [3:0] CBE = 4'b0011;
    reg [31:0] DATA;
    // ADDRESS LINE Multiplexing
    wire SENDING_DATA = ~IRDY;
    reg TRANSACTION = 0;
    wire [31:0] AD = SENDING_DATA ? DATA : (TRANSACTION ? 32'h0000010 : 32'h1);
    reg FORCE_DEVSEL_AND_TRDY_HIGH_REG = 0;
    wire FORCE_DEVSEL_AND_TRDY_HIGH = FORCE_DEVSEL_AND_TRDY_HIGH_REG;
    // PCI Instance
    PCI pci(clk, Frame, IRDY, CBE, AD, DEVSEL, TRDY, DEBUG, FORCE_DEVSEL_AND_TRDY_HIGH);
    initial begin
        // Monitor the frame and clock
        // $monitor("Frame: ", Frame, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, AD, $time);
        // Set the frame to low after 15 nanosecond
        #100 Frame <= 0;
        TRANSACTION <= 1;
        #10 IRDY <= 0;
        DATA <= 32'd1001;
        #15 DATA <= 32'd1002;
        #5 DATA <= 32'd1003;
        Frame <= 1;
        #5 DATA <= 32'd1004;
        #5 IRDY <= 1;
        TRANSACTION <= 0;
        FORCE_DEVSEL_AND_TRDY_HIGH_REG <= 1;
        #20 FORCE_DEVSEL_AND_TRDY_HIGH_REG <= 0;
    end
    // Always block at positive and negative edges of the clock
    always @(posedge clk) begin
        $display("Frame: ", Frame, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, AD, $time);
    end
    always @(posedge clk, negedge clk) begin
        // Stop the program after 100 nanoseconds
        if ($time == 200) begin
            $finish;
        end
    end
endmodule

// module PCIREADTest;
//     parameter PCI_read = 4'b0010;
//     parameter PCI_write = 4'b0011;
//     // Instantiating the clock
//     Clock C(clk);
//     // Instantiation the PCI Variables
//     reg Frame = 1;
//     reg IRDY = 1;
//     reg [3:0] CBE = 4'b0010;
//     // ADDRESS LINE Multiplexing
//     wire [31:0] AD = ((CBE == PCI_read) && ~IRDY) ? 32'hz : 32'h0000010;
//     // PCI Instance
//     PCI pci(clk, Frame, IRDY, CBE, AD, DEVSEL, TRDY);
//     initial begin
//         // Monitor the frame and clock
//         $monitor("Frame: ", Frame, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, AD, $time);
//         // Set the frame to low after 15 nanosecond
//         #100 Frame <= 0;
//         #10 IRDY <= 0;
//         #100 Frame <= 1;
//         #10 IRDY <= 1;
//         #100 Frame <= 0;
//         #10 IRDY <= 0;
//     end
//     // Always block at positive and negative edges of the clock
//     always @(posedge clk) begin
//         $display("Frame: ", Frame, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, AD, $time);
//     end
//     always @(posedge clk, negedge clk) begin
//         // Stop the program after 100 nanoseconds
//         if ($time == 200) begin
//             $finish;
//         end
//     end
// endmodule

// module Reset(input Frame, input TRDY, input IRDY, input DEVSEL);
//     Frame <= 1;
//      TRDY <= 1;
//      IRDY <= 1;
//      DEVSEL <= 1;
// endmodule