module PCIWRITEREADTest;

    // CONSTANTS
    parameter PCI_read = 4'b0010;
    parameter PCI_write = 4'b0011;
    parameter [31:0] DEVICE_ADDRESS = 32'h0000010;
    
    Clock C(CLK);

    // Instantiating the PCI Variables
    reg FRAME = 1;
    reg IRDY = 1;
    reg [3:0] CBE = 4'hz;
    reg [31:0] DATA = 32'hz;

    wire DEVSEL;
    wire TRDY;
    reg TRANSACTION = 0;

    // ADDRESS LINE Multiplexing
    wire SENDING_ADDRESS = ((~FRAME) && IRDY && DEVSEL);
    reg [3:0] OP = 4'hz;
    wire WRITE_OP = (OP == PCI_write);
    wire SENDING_DATA = (~IRDY && WRITE_OP);
    wire [31:0] AD = ( SENDING_ADDRESS ? DEVICE_ADDRESS : ( SENDING_DATA ? DATA : 32'bz ) );

    // DEBUGGING VARIABLES
    wire [31:0] DEBUG;
    wire [31:0] M1;
    wire [31:0] M2;
    wire [31:0] M3;
    wire [31:0] M4;

    // PCI Instance
    PCI pci(CLK, FRAME, IRDY, CBE, AD, DEVSEL, TRDY, DEBUG, M1, M2, M3, M4);
    initial begin
        $dumpfile("wavedump.vcd");
        $dumpvars(CLK, FRAME, AD, CBE, IRDY, DEVSEL, TRDY);
        $monitor("FRAME: ", FRAME, " DEVSEL: ", DEVSEL, " IRDY: ", IRDY, " TRDY: ", TRDY, " DEBUG: ", DEBUG[16:0], " MEMORY: ", M1[15:0], M2[15:0], M3[15:0], M4[15:0], " ", " CBE: ", CBE, " ADDRESS: ", AD[16:0], " Time: ", $time, " ", CLK);
        // WRITE OPERATION
        #100 FRAME <= 0;
        OP <= 4'b0011;
        CBE <= 4'b0011;
        TRANSACTION <= 1;
        #10 IRDY <= 0;
        DATA <= 32'd1001;
        CBE <= 4'b0000;
        #20 DATA <= 32'd1002;
        CBE <= 4'b1111;
        #10 DATA <= 32'd1003;
        CBE <= 4'b0000;
        #10 DATA <= 32'd1004;
        CBE <= 4'b1111;
        FRAME <= 1;
        #10 IRDY <= 1;
        CBE <= 4'hz;
        TRANSACTION <= 0;
        
        // READ OPERATION
        OP <= 4'b0010;
        #140 FRAME <= 0;
        CBE <= 4'b0010;
        #10 IRDY <= 0;
        #40 IRDY <= 1;
        #10 IRDY <= 0;
        #100 FRAME <= 1;
        #10 IRDY <= 1;
        CBE <= 4'hz;
    end
    
    always @(posedge CLK, negedge CLK) begin
        // Stop the program after 500 nanoseconds
        if ($time >= 500) begin
            $finish;
        end
    end
endmodule