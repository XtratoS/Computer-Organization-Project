module PCIREADTest;
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    // Instantiating the clock
    Clock C(clk);
    // Instantiation the PCI Variables
    reg Frame = 1;
    reg IRDY = 1;
    reg [3:0] CBE = 4'b0010;
    // ADDRESS LINE Multiplexing
    wire [31:0] AD = ((CBE == PCI_read) && ~IRDY) ? 32'hz : 32'h0000010;
    // PCI Instance
    PCI pci(clk, Frame, IRDY, CBE, AD, DEVSEL, TRDY, DEBUG);
    initial begin
        // Monitor the frame and clock
        $monitor("Frame: ", Frame, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, AD, $time);
        // Set the frame to low after 15 nanosecond
        #100 Frame <= 0;
        #10 IRDY <= 0;
        #100 Frame <= 1;
        #10 IRDY <= 1;
        #100 Frame <= 0;
        #10 IRDY <= 0;
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