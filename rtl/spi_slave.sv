module spi_slave(
    input  logic clk, rst,
    input  logic i_cs, i_mosi,
    output logic o_ready, o_op_done, o_miso
);

typedef enum bit [2:0] {idle, check_op, write_to_mem, read_addr, send_data} state_ty;
state_ty state = idle;

logic [7:0] mem [32] = '{default:0};
integer count = 0;
logic [15:0] din;
logic [7:0] dout;

always@(posedge clk) begin
    
    if(rst) begin
        count     <= 0;
        o_ready   <= 1'b0;
        o_op_done <= 1'b0;
        o_miso    <= 1'b0;
        state     <= idle;       
    end else begin
        case(state)

            idle:begin
                count     <= 0;
                o_ready   <= 1'b0;
                o_op_done <= 1'b0;
                o_miso    <= 1'b0; 
                  
                if(!i_cs)
                    state <= check_op;
                else 
                    state <= idle;
            end

            check_op:begin

                if(i_mosi) 
                    state <= write_to_mem;
                else  
                    state <= read_addr;
            end

            write_to_mem: begin

                if (count <= 15) begin
                    din[count] <= i_mosi;
                    count      <= count + 1;
                    state      <= write_to_mem;
                end else begin
                    mem[din[7:0]] <= din[15:8];
                    state <= idle;
                    count <= 0;
                    o_op_done <= 1'b1;
                end
            end

            read_addr: begin

                if(count <= 7) begin
                    count <= count + 1;
                    din[count] <= i_mosi;
                    state <= read_addr;
                end else begin
                    o_ready <= 1'b1;
                    count   <= 0;
                    dout    <= mem[din[7:0]];
                    state   <= send_data;
                end
            end

            send_data: begin
                o_ready <= 1'b0;

                if (count <= 7) begin
                    count <= count + 1;
                    o_miso <= dout[count];
                    state <= send_data;
                end else begin
                    count <= 0;
                    o_op_done <= 1'b1;
                    state <= idle;
                end
            end

            default: state <= idle;
        endcase
    end

end

endmodule