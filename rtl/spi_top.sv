module spi_top(
    input  logic clk, rst, 
    input  logic i_wr, 
    input  logic [7:0] i_addr, i_din,
    output logic o_done, o_err,
    output logic [7:0] o_dout
);

logic ready, op_done, miso, mosi, cs; 

spi_master spi_m (clk, rst, i_wr, i_din, i_addr, ready, op_done, miso, cs, mosi, o_done, o_err, o_dout);
spi_slave spi_s (clk, rst, cs, mosi, ready, op_done, miso);

endmodule
