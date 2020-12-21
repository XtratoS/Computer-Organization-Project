module clockGen(Clock);
    output Clock;
    reg Clock;
    initial
        Clock = 0;
    always
        #5 Clock = ~Clock;
endmodule

// module clockTestBench;
//     clockGen C(clk);
//     initial begin
//         $monitor(clk);
//     end
//     always @(posedge clk) begin
//         if ($time > 40) begin
//             $finish;
//         end
//     end
// endmodule

// module Target(Address, )

//     parameter device_address = 32'h0000010;

// endmodule

// The Main Module
module PCI(
    input clk,
    input Frame,
    input IRDY,
    input [3:0] CBE,
    inout [31:0] AD,
    output reg TRDY
);

    reg DEVSEL = 1'b1;
    reg READ_FLAG = 0;
    reg CLOCK_COUNTER;
    
    reg CHECK_ADDRESS = 0;
    
    // Reset(Frame, TRDY, IRDY, DEVSEL);
    
    // This device address imitates a device connected to the PCI, we check the provided address
    // against this one to determine if we will set DEV_SEL or not
    parameter device_address = 32'h0000010;
    
    always @(negedge clk) begin
        // Increment the clock counter every negative edge of the clock in order to read it later in the positive edge of the clock
        CLOCK_COUNTER <= CLOCK_COUNTER + 1;
        if (READ_FLAG == 1) begin
            if (AD == device_address) begin
                #5 DEVSEL <= 0;
                #5 TRDY <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        // Read the address at the 1st positive edge of the clock after the start of the frame
        if (CLOCK_COUNTER == 1) begin
            //READ ADDRESS
        // Turnaround in the 2nd positive edge of the clock after the start of the frame
        end else if (CLOCK_COUNTER == 2) begin
            //TURNAROUND
        end
    end
    
    // Set the READ_FLAG at the start of the frame
    // Reset the counter at the start of the frame
    always @(negedge Frame) begin
        READ_FLAG <= 1;
        CHECK_ADDRESS <= 1;
        CLOCK_COUNTER <= 1;
    end
    
    // Reset the READ_FLAG at the positive edge of the frame.
    always @(posedge Frame) begin
        #5 READ_FLAG <= 0;
    end
    
endmodule

module PCITest;
    // Instantiating the clock
    clockGen C(clk);
    // Instantiation the PCI Variables
    wire [31:0] AD = 32'h0000010;
    reg Frame = 1;
    reg IRDY = 0;
    wire TRDY = 0;
    reg [3:0]CBE = 4'b1111;
    // PCI Instance
    PCI pci(clk, Frame, IRDY, CBE, AD, TRDY);
    initial begin
        // Monitor the frame and clock
        $monitor(Frame, clk);
        // Set the frame to low after 15 nanosecond
        #15 Frame <= 0;
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