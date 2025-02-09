module spi_master(
    input  logic clk, rst,
    input  logic i_wr, 
    input  logic [7:0] i_din, i_addr,
    input  logic i_ready, i_op_done, i_miso,
    output logic o_cs, o_mosi, o_done, o_err,
    output logic [7:0] o_dout
);

typedef enum bit [2:0] {idle, load, check_op, send_data, send_addr, read_data, error, check_ready} state_ty;
state_ty state = idle;

logic [16:0] din_reg; /// data: 8 bits, addr: 8 bits, op : wr/rd
logic [7:0] dout_reg;

integer count = 0;

////////////////////////// state logic 
always@(posedge clk) begin
    
    if(rst) begin
        state <= idle;
        o_cs   <= 1'b1;
        o_mosi <= 1'b0;
        o_done <= 1'b0;
        o_err  <= 1'b0;
        count  <= 0;
    end else begin
        
        case(state)
            
            idle: begin
                o_cs   <= 1'b1;
                o_mosi <= 1'b0;
                o_done <= 1'b0;
                o_err  <= 1'b0;
                state <= load;
            end
            
            load:begin
                din_reg <= {i_din, i_addr, i_wr};
                state <= check_op;
            end

            check_op: begin

                if (i_wr == 1'b1 && i_addr < 32) begin
                    o_cs  <= 1'b0;
                    state <= send_data; 
                end else if (i_wr == 1'b0 && i_addr < 32) begin
                    o_cs  <= 1'b0;
                    state <= send_addr;
                end else begin
                    o_cs  <= 1'b0;
                    state <= error;
                end
            
            end

            send_data: begin
                if(count <= 16) begin
                    count  <= count + 1;
                    o_mosi <= din_reg[count]; 
                    state  <= send_data;
                end else begin
                    o_cs   <= 1'b1;
                    o_mosi <= 1'b0;

                    if(i_op_done) begin
                        count  <= 0;
                        o_done <= 1'b1;
                        state <= idle; 
                    end else begin
                        state <= send_data;
                    end

                end
            end

            send_addr: begin
                if(count <= 8) begin
                    count  <= count + 1;
                    o_mosi <= din_reg[count];
                    state  <= send_addr; 
                end else begin
                    count <= 0;
                    o_cs <= 1'b1;
                    state <= check_ready;
                end
            end

            check_ready: begin
                if(i_ready)
                    state <= read_data;
                else
                    state <= check_ready; 
            end

            read_data: begin
                if(count <= 7) begin
                    count <= count + 1;
                    dout_reg[count] <= i_miso;
                    state <= read_data;
                end else begin
                    count  <= 0;
                    o_done <= 1'b1;
                    state  <= idle;
                end
            end

            error: begin
                o_err  <= 1'b1;
                state  <= idle;
                o_done <= 1'b1;
            end

            default: begin
                state <= idle;
                count <= 0;
            end
        endcase
    end

end

assign o_dout = dout_reg;

endmodule