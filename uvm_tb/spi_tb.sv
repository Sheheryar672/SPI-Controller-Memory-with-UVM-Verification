`include "uvm_macros.svh"
import uvm_pkg::*;

///////////////////////////////////////////////////////////////
class spi_config extends uvm_object;
    `uvm_object_utils(spi_config)

    function new (string inst = "spi_config");
        super.new(inst);
    endfunction

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
endclass : spi_config

////////////////////////////////////////////////////////////
typedef enum bit [1:0] {read, writed, rstdut} op_mode;

////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;

    rand  op_mode op;
          logic i_wr;
          logic rst;
    randc logic [7:0] i_addr;
    rand  logic [7:0] i_din;
          logic [7:0] o_dout;
          logic o_done;
          logic o_err;

    `uvm_object_utils_begin(transaction)
          `uvm_field_int(i_wr, UVM_ALL_ON);
          `uvm_field_int(i_addr, UVM_ALL_ON);
          `uvm_field_int(i_din, UVM_ALL_ON);
          `uvm_field_int(rst, UVM_ALL_ON);
          `uvm_field_int(o_dout, UVM_ALL_ON);
          `uvm_field_int(o_done, UVM_ALL_ON);
          `uvm_field_int(o_err, UVM_ALL_ON);
          `uvm_field_enum(op_mode, op, UVM_DEFAULT);
    `uvm_object_utils_end
    
    constraint addr_c { i_addr <= 10; }
    constraint addr_err_c { i_addr > 31; }

    function new (string inst = "transaction");
        super.new(inst);
    endfunction

endclass : transaction

///////////////////////////////////////////////////// writed seq
class write_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_seq)

    transaction tr;

    function new (string inst = "write_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);
            
            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask

endclass

///////////////////////////////////////////////////// writed with error seq
class write_w_err_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_w_err_seq)

    transaction tr;

    function new (string inst = "write_w_err_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat (15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(0);
            tr.addr_err_c.constraint_mode(1);
            
            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask

endclass : write_w_err_seq

///////////////////////////////////////////////////// read seq
class read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(read_seq)

    transaction tr;

    function new (string inst = "read_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);
            
            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask

endclass : read_seq

///////////////////////////////////////////////////// read with error seq
class read_w_err_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(read_w_err_seq)

    transaction tr;

    function new (string inst = "read_w_err_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(0);
            tr.addr_err_c.constraint_mode(1);
            
            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask

endclass : read_w_err_seq

/////////////////////////////////////////////////// reset dut seq
class rst_dut_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(rst_dut_seq)

    transaction tr;

    function new (string inst = "rst_dut_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = rstdut;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask

endclass : rst_dut_seq 

///////////////////////////////////////////////// bulk writed and read seq
class writeb_readb_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(writeb_readb_seq)

    transaction tr;

    function new (string inst = "writeb_readb_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(10) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);
        end

        repeat (10) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);
            
            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);
        end
        unlock(m_sequencer);
    endtask
endclass : writeb_readb_seq

///////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)

    transaction tr;
    virtual spi_i vif;

    function new (string inst = "driver", uvm_component parent = null);
        super.new(inst, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");

        if (!uvm_config_db #(virtual spi_i)::get(this,"","vif",vif)) 
            `uvm_error("drv","Unable to access the interface!!!");
    endfunction

    task reset_dut();

        repeat(5) begin
            vif.rst <= 1'b1;
            vif.i_addr <= 'h0;
            vif.i_din <= 'h0;
            vif.i_wr <= 1'b0;

            `uvm_info("drv", "System Reset: Start of Simulation", UVM_MEDIUM);
            @(posedge vif.clk);
        end
    endtask

    task driver();
        reset_dut();

        forever begin
            
            seq_item_port.get_next_item(tr);

                if(tr.op == rstdut) begin
                    vif.rst <= 1'b1;
                    @(posedge vif.clk);
                    `uvm_info("DRV", "System Reseted", UVM_NONE);
                end
                
                else if (tr.op == read) begin
                    vif.rst <= 1'b0;
                    vif.i_addr <= tr.i_addr;
                    vif.i_din <= tr.i_din;
                    vif.i_wr <= 1'b0;
                    @(posedge vif.clk);
                    
                    `uvm_info("DRV", $sformatf("Mode: Read, Addr: %0d, Datain: %0d", vif.i_addr, vif.i_din), UVM_NONE);
                    @(posedge vif.o_done);
                end

                else if (tr.op == writed) begin
                    vif.rst <= 1'b0;
                    vif.i_addr <= tr.i_addr;
                    vif.i_din <= tr.i_din;
                    vif.i_wr <= 1'b1;

                    @(posedge vif.clk);
                    `uvm_info("DRV", $sformatf("Mode: Write, Addr: %0d, Datain: %0d", vif.i_addr, vif.i_din), UVM_NONE);
                    @(posedge vif.o_done);
                end

            seq_item_port.item_done();
        end

    endtask    

    virtual task run_phase(uvm_phase phase);
        driver();
    endtask

endclass : driver

///////////////////////////////////////////////////////////////
class mon extends uvm_monitor;
    `uvm_component_utils(mon)

    transaction tr;
    uvm_analysis_port #(transaction) send;
    virtual spi_i vif;

    function new (string inst = "mon", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");
        send = new("send", this);

        if(!uvm_config_db #(virtual spi_i) :: get(this, "", "vif", vif))
            `uvm_error("MON", "Unable to access the interface!!!");
    endfunction

    virtual task run_phase (uvm_phase phase);
        forever begin
            @(posedge vif.clk);

            if (vif.rst) begin
                tr.op = rstdut;
                `uvm_info ("MON", "System Reset Detected", UVM_NONE);
                send.write(tr);
            end

            else if (!vif.rst & !vif.i_wr) begin    /// Read Mode
                @(posedge vif.o_done)
                tr.op = read;
                tr.i_addr = vif.i_addr;
                tr.o_dout = vif.o_dout;
                tr.o_err = vif.o_err;
                `uvm_info ("MON", $sformatf("DATA READ --> Addr: %0d, Data out: %0d, Error: %0d", tr.i_addr, tr.o_dout, tr.o_err), UVM_NONE);
                send.write(tr);
            end

            else if (!vif.rst && vif.i_wr) begin    /// Write Mode
                @(posedge vif.o_done);
                tr.op = writed;
                tr.i_addr = vif.i_addr;
                tr.i_din = vif.i_din;
                tr.o_err = vif.o_err;
                `uvm_info("MON", $sformatf("DATA WRITE --> Addr; %0d, Data in: %0d, Error: %0d", tr.i_addr, tr.i_din, tr.o_err), UVM_NONE);
                send.write(tr);
            end
        end
    endtask

endclass : mon

//////////////////////////////////////////////////////////////////////////////////
class sco extends uvm_scoreboard;
    `uvm_component_utils(sco);

    uvm_analysis_imp #(transaction, sco) recv;
    bit [7:0] mem [32] = '{default: 0};
    bit [7:0] addr;
    bit [7:0] data_recv;

    integer pass = 0, fail = 0, error = 0;

    function new (string inst = "sco", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        recv = new("recv", this);
    endfunction

    virtual function void write (transaction tr);
        if(tr.op == rstdut) begin
            `uvm_info("SCO", "System Reset Dectected", UVM_NONE);
        end

        else if (tr.op == writed) begin
            if (tr.o_err) begin
                `uvm_info ("SCO", "Error during WRITE operation!!!", UVM_NONE);
                error++;
            end

            else begin
                mem[tr.i_addr] = tr.i_din;
                `uvm_info("SCO", $sformatf("DATA WRITE --> addr: %0d, wdata: %0d, mem_wr: %0d", tr.i_addr, tr.i_din, mem[tr.i_addr]), UVM_NONE);
            end
        end

        else if (tr.op == read) begin
            if(tr.o_err) begin
                `uvm_info("SCO", "Error during Read mode!!!", UVM_NONE);            
                error++;
            end

            else begin
                data_recv = mem[tr.i_addr];

                if(data_recv == tr.o_dout) begin
                    `uvm_info("SCO", $sformatf("DATA MATCHED --> addr: %0d, rdata: %0d", tr.i_addr, tr.o_dout), UVM_NONE);
                    pass++;
                end else begin
                    `uvm_info("SCO", $sformatf("TEST FAILED --> addr: %0d, rdata: %0d, data_recv_mem: %0d", tr.i_addr, tr.o_dout, data_recv), UVM_NONE);
                    fail++;
                end
            end
        end
    
    $display ("---------------------------------------------------------------------------------------------------");
    endfunction

endclass : sco

///////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
    `uvm_component_utils (agent)

    spi_config cfg;
    uvm_sequencer #(transaction) seqr;
    driver d;
    mon m;

    function new (input string inst = "agent", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase (phase);
        cfg = spi_config::type_id::create("cfg");
        m = mon::type_id::create("m", this);

        if (cfg.is_active == UVM_ACTIVE) begin    
            seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
            d = driver::type_id::create("d", this);
        end

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        d.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass : agent

///////////////////////////////////////////////////////////////////////////////
class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    sco s;

    function new (string inst = "env", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        a = agent::type_id::create("a", this);
        s = sco::type_id::create("s", this);
    endfunction

    virtual function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        a.m.send.connect(s.recv);
    endfunction

endclass : env

////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
    `uvm_component_utils(test)

    env e;
    write_seq w;
    write_w_err_seq w_err;
    read_seq r;
    read_w_err_seq r_err;
    rst_dut_seq rst_dut;
    writeb_readb_seq wb_rb;

    function new (string inst = "test", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        e = env::type_id::create("e", this);
        w = write_seq::type_id::create("w");
        w_err = write_w_err_seq::type_id::create("w_err");
        r = read_seq::type_id::create("r");
        r_err = read_w_err_seq::type_id::create("r_err");
        rst_dut = rst_dut_seq::type_id::create("rst_dut");
        wb_rb = writeb_readb_seq::type_id::create("wb_rb");
    endfunction

    virtual task run_phase (uvm_phase phase);
        phase.raise_objection(this);
            
            w_err.start(e.a.seqr);
            r_err.start(e.a.seqr);
            w.start(e.a.seqr);
            r.start(e.a.seqr);
            wb_rb.start(e.a.seqr);
            
            $display("test passed: %0d", e.s.pass);
            $display("test failed: %0d", e.s.fail);
            $display("total errors due to addr > 32: %0d", e.s.error);

        phase.phase_done.set_drain_time(this, 20ns);
        phase.drop_objection(this);
    endtask
endclass : test

//////////////////////////////////////////////////////////////////////////////
module spi_tb();

    spi_i vif();
    spi_top dut (vif.clk, vif.rst, vif.i_wr, vif.i_addr, vif.i_din, vif.o_done, vif.o_err, vif.o_dout);

    initial begin
        vif.clk <= 0;
    end

    always #10 vif.clk <= ~vif.clk;

    initial begin
        uvm_config_db #(virtual spi_i) :: set (null, "*", "vif", vif);
        run_test("test");
    end

endmodule