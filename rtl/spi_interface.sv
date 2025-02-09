interface spi_i;

    logic clk, rst;
    logic i_wr;
    logic [7:0] i_addr, i_din;
    logic o_done, o_err;
    logic [7:0] o_dout;

endinterface