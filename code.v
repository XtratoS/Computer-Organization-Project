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
    output reg TRDY,
    output reg DEVSEL
);
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    parameter device_address = 32'h0000010;
    //Shows whether or not the device address matches what's on the ADDRESS LINE
    wire TARGETED = (device_address == AD);
    wire TRANSACTION = ~Frame;
    wire LAST_DATA_READ = Frame && ~IRDY;
    reg NEG_CLOCK_COUNTER;
    reg DEVSEL_2 = 1'b1;
    reg TRDY_2 = 1'b1;
    reg [31:0] DATA_REG = 32'h1020304;
    assign AD = ((CBE == PCI_read) && ~IRDY) ? DATA_REG : 32'hzzzzzzz;
    // reg [1:0] INDEX = 0;
    
    //memory belongs to the target
    reg [31:0] MEMORY [0:3];
    
    // Reset(Frame, TRDY, IRDY, DEVSEL);
    
    // This device address imitates a device connected to the PCI, we check the provided address
    // against this one to determine if we will set DEV_SEL or not

    
    always @(negedge clk) begin
        DEVSEL <= DEVSEL_2;
        TRDY <= TRDY_2;
        // Increment the clock counter every negative edge of the clock in order to read it later in the positive edge of the clock
        NEG_CLOCK_COUNTER++;
        // DEVSEL and TRDY fast
        if (TRANSACTION || LAST_DATA_READ) begin
            DEVSEL_2 <= 0;
            TRDY_2 <= 0;
        end
        if (NEG_CLOCK_COUNTER == 2) begin
            // DATA_REG <= 32'h1000220;
        end
    end
    
    always @(posedge clk) begin
        // Read the address at the 1st positive edge of the clock after the start of the frame
        if (NEG_CLOCK_COUNTER == 1) begin
            //READ ADDRESS
            if (TARGETED) begin
                DEVSEL_2 <= 1;
                TRDY_2 <= 1;
            end
        // Turnaround in the 2nd positive edge of the clock after the start of the frame
        end else if (NEG_CLOCK_COUNTER == 2) begin
            //TURNAROUND
        end else begin
            //WE PUT THE DATA ON THE ADDRESS LINE ON THE NEGATIVE EDGE OF THE CLOCK
        end
    end
    
    // Set the READ_FLAG at the start of the frame
    // Reset the counter at the start of the frame
    // always @(negedge Frame) begin
    //     READ_FLAG <= 1;
    //     NEG_CLOCK_COUNTER = 1; //0
    // end
    
    // Reset the READ_FLAG at the positive edge of the frame.
    // always @(posedge Frame) begin
    // #5 READ_FLAG <= 0;
    // end
    
endmodule

module PCITest;
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    // Instantiating the clock
    Clock C(clk);
    // Instantiation the PCI Variables
    wire [31:0] AD = ((CBE == PCI_read) && ~IRDY) ? 32'hzzzzzzz : 32'h0000010;
    reg Frame = 1;
    reg IRDY = 1;
    reg [3:0] CBE = 4'b0010;
    wire intermediate = ((CBE == PCI_read) && ~IRDY);
    // PCI Instance
    PCI pci(clk, Frame, IRDY, CBE, AD, TRDY, DEVSEL);
    initial begin
        // Monitor the frame and clock
        $monitor(Frame, " ", DEVSEL, " ", intermediate, " ", TRDY, AD, $time);
        // Set the frame to low after 15 nanosecond
        #15 Frame <= 0;
        #10 IRDY <= 0;
    end
    // Always block at positive and negative edges of the clock
    always @(posedge clk, negedge clk)
    begin
        // Stop the program after 100 nanoseconds
        if ($time == 100) begin
            $finish;
        end
    end
endmodule

// module Reset(input Frame, input TRDY, input IRDY, input DEVSEL);
//     Frame <= 1;
//     #5 TRDY <= 1;
//     #5 IRDY <= 1;
//     #5 DEVSEL <= 1;
// endmodule