module Clock(clock);
    output clock;
    reg clock;
    initial
        clock = 0;
    always
        #5 clock = ~clock;
endmodule