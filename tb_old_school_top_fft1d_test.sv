`timescale 1ns/1ps
module tb_top;

  // 100 MHz clock & reset
  logic aclk = 0; always #5 aclk = ~aclk;
  logic aresetn = 0;
  initial begin
    aresetn = 0;
    repeat (10) @(posedge aclk);
    aresetn = 1;
  end

  // ---- AXI4-Lite signals (32-bit) ----
  logic [3:0] s_awaddr, s_araddr;
  logic [31:0] s_wdata;
  logic  [3:0] s_wstrb;
  logic        s_awvalid, s_awready;
  logic        s_wvalid,  s_wready;
  logic  [1:0] s_bresp;   logic s_bvalid, s_bready;
  logic        s_arvalid, s_arready;
  logic [31:0] s_rdata;   logic [1:0] s_rresp; logic s_rvalid, s_rready;
  logic  [2:0] s_awprot = 3'b000, s_arprot = 3'b000;

  // ---- DUT (YOUR VHDL AXI-Lite slave) ----
  // Replace 'your_vhdl_axi_slave' with your entity/module name.
  // Adjust port names if they differ (e.g., s_axi_* vs S_AXI_*).
  fista_accel_top_wrapper_v1_0 dut (
    .s00_axi_aclk    (aclk),
    .s00_axi_aresetn (aresetn),

    .s00_axi_awaddr  (s_awaddr),
    .s00_axi_awprot  (s_awprot),
    .s00_axi_awvalid (s_awvalid),
    .s00_axi_awready (s_awready),

    .s00_axi_wdata   (s_wdata),
    .s00_axi_wstrb   (s_wstrb),
    .s00_axi_wvalid  (s_wvalid),
    .s00_axi_wready  (s_wready),

    .s00_axi_bresp   (s_bresp),
    .s00_axi_bvalid  (s_bvalid),
    .s00_axi_bready  (s_bready),

    .s00_axi_araddr  (s_araddr),
    .s00_axi_arprot  (s_arprot),
    .s00_axi_arvalid (s_arvalid),
    .s00_axi_arready (s_arready),

    .s00_axi_rdata   (s_rdata),
    .s00_axi_rresp   (s_rresp),
    .s00_axi_rvalid  (s_rvalid),
    .s00_axi_rready  (s_rready)
  );
  
  initial begin
  #1;
  $display("TB at 1 ns: aclk=%b aresetn=%b", aclk, aresetn);
  $display("DUT at 1 ns: clk=%b resetn=%b",
           dut.s00_axi_aclk,
           dut.s00_axi_aresetn);
end

  // ---- Minimal AXI4-Lite master tasks (no VIP) ----
  //task automatic axi_write32(input [31:0] addr, input [31:0] data);
  //  s_awaddr  <= addr;  s_awvalid <= 1'b1;
  //  s_wdata   <= data;  s_wstrb   <= 4'hF; s_wvalid <= 1'b1;
  //  s_bready  <= 1'b1;
  //  // address & data handshake (can complete in same cycle)
  //  do @(posedge aclk); while (!(s_awready && s_wready));
  //  s_awvalid <= 1'b0; s_wvalid <= 1'b0;
  //  // wait for write response
  //  do @(posedge aclk); while (!s_bvalid);
  //  s_bready  <= 1'b0;
  //endtask

  //task automatic axi_read32(input [31:0] addr, output [31:0] data);
  //  s_araddr  <= addr; s_arvalid <= 1'b1; s_rready <= 1'b1;
  //  // address handshake
  //  do @(posedge aclk); while (!s_arready);
  //  s_arvalid <= 1'b0;
  //  // wait for read data
  //  do @(posedge aclk); while (!s_rvalid);
  //  data = s_rdata;
  //  s_rready <= 1'b0;
  // endtask
 
   task automatic axi_write32_masked(  
      input [3:0]  addr,
      input [31:0] data,
      input [31:0] mask
      );
      reg [31:0] old_data;
      reg [31:0] new_data;
  
      axi_read32(addr, old_data);
  
      new_data = (old_data & ~mask) |
                 (data     &  mask);
  
      axi_write32(addr, new_data);
  endtask
  
  
  task automatic axi_write32(input [3:0] addr, input [31:0] data);
    s_awaddr  <= addr;  s_awvalid <= 1'b1;
    s_wdata   <= data;  s_wstrb   <= 4'hF; s_wvalid <= 1'b1;
    s_bready  <= 1'b1;
    // address & data handshake (can complete in same cycle)
    do @(posedge aclk); while (!(s_awready && s_wready));
    s_awvalid <= 1'b0; s_wvalid <= 1'b0;
    // wait for write response
    do @(posedge aclk); while (!s_bvalid);
    s_bready  <= 1'b0;
  endtask

  task automatic axi_read32(input [3:0] addr, output [31:0] data);
    s_araddr  <= addr; s_arvalid <= 1'b1; s_rready <= 1'b1;
    // address handshake
    do @(posedge aclk); while (!s_arready);
    s_arvalid <= 1'b0;
    // wait for read data
    do @(posedge aclk); while (!s_rvalid);
    data = s_rdata;
    s_rready <= 1'b0;
  endtask

  // ---- Example sequence: START -> poll DONE -> CLEAR (edit offsets). ----
  //localparam CTRL   = 32'h0000_0000; // bit0 START
  //localparam STATUS = 32'h0000_0004; // bit0 DONE, bit1 BUSY
  //localparam CLEAR  = 32'h0000_0008; // W1C DONE
  //localparam SLV0 = 4'b0000;
  //localparam SLV1 = 4'b0001;
  //localparam SLV2 = 4'b0010;
  //localparam SLV3 = 4'b0011;
  
  localparam SLV0 = 4'h0;
  localparam SLV1 = 4'h4;
  localparam SLV2 = 4'h8;
  localparam SLV3 = 4'hC;

  int polls;
  bit [31:0] rd; 
  bit done;
  
  bit [31:0] rd_mem_re_0;
  bit [31:0] rd_reg_0;
  
  initial begin
    // init master signals
    s_awaddr=0; s_wdata=0; s_araddr=0; s_wstrb=0;
    s_awvalid=0; s_wvalid=0; s_bready=0; s_arvalid=0; s_rready=0;
    
    @(posedge aresetn); repeat (5) @(posedge aclk);
    
    // Set Stop for 1D FFT
    //axi_write32(SLV0,32'h00000010 & 32'h000000F0); // Stop[3..0] = 0001 Stop at 1D FFT
    axi_write32_masked(SLV0,32'h00000010,32'h00000010); // Stop[3..0] = 0001 Stop at 1D FFT
    

    //@(posedge aresetn); 
    repeat (5) @(posedge aclk);
    
    // start FISTA
    //axi_write32(SLV0,32'h00000400 & 32'h00000F00); // start 2 = 1 start 1 = 0
    //axi_write32(SLV0,32'h00000200 & 32'h00000F00); // start 2 = 0 start 1 = 1
    axi_write32_masked(SLV0,32'h00000400,32'h00000600); // start 2 = 1 start 1 = 0
    axi_write32_masked(SLV0,32'h00000200,32'h00000600); // start 2 = 0 start 1 = 1
    
    
    // Poll Stop bit  
    while ( done !== 1'b1) begin
    		axi_read32(SLV0,rd_reg_0);
        //done = ((rd_reg_0 & 32'h00000200 & 32'h00000F00) != 1'b0);
        done = ((rd_reg_0 & 32'h00000200) != 1'b0);
    end
    
    $display(" Stop detected: Read out 1D FFT results %0t", $time);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Set debug mode ON
    //axi_write32(SLV0,32'h00000100 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000100,32'h00000100);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Read FFT 1D Test
    
    // 1st read
    	//axi_write32(SLV0,32'h00000004 & 32'h0000000F); // Read enable
    	//axi_write32(SLV1,32'h07000000 & 32'hFFFF0000); // Addr 1792 First NZ line FFT-1D
    	axi_write32_masked(SLV0,32'h00000001,32'h00000001); // Read enable
    	axi_write32_masked(SLV1,32'h07000000,32'hFFFF0000); // Addr 1792 First NZ line FFT-1D
    
      fork
        begin      
          repeat(10) @(posedge aclk);        
          axi_read32(SLV3, rd_mem_re_0);
        end
      join_any
      disable fork;
      $display("[%0t] Read =  %h ", $time, rd_mem_re_0);
     
     //@(posedge aresetn); 
     repeat (10) @(posedge aclk); 
    
    // 2nd read
    	//axi_write32(SLV0,32'h00000004 & 32'h0000000F); // Read enable
    	//axi_write32(SLV1,32'h07010000 & 32'hFFFF0000); // Addr 1793 First NZ line FFT-1D
    	axi_write32_masked(SLV0,32'h00000001,32'h00000001); // Read enable
    	axi_write32_masked(SLV1,32'h07010000,32'hFFFF0000); // Addr 1793 First NZ line FFT-1D
    
      fork
        begin      
          repeat(10) @(posedge aclk);        
          axi_read32(SLV3, rd_mem_re_0);
        end
      join_any
      disable fork;
      $display("[%0t] Read =  %h ", $time, rd_mem_re_0);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);  
      
    // 3rd read
    	//axi_write32(SLV0,32'h00000004 & 32'h0000000F); // Read enable
    	//axi_write32(SLV1,32'h07020000 & 32'hFFFF0000); // Addr 1794 First NZ line FFT-1D
    	axi_write32_masked(SLV0,32'h00000001,32'h00000001); // Read enable
    	axi_write32_masked(SLV1,32'h07020000,32'hFFFF0000); // Addr 1794 First NZ line FFT-1D
    
      fork
        begin      
          repeat(10) @(posedge aclk);        
          axi_read32(SLV3, rd_mem_re_0);
        end
      join_any
      disable fork;
      $display("[%0t] Read =  %h ", $time, rd_mem_re_0);
      
     //@(posedge aresetn); 
     repeat (10) @(posedge aclk); 
        
    // 4th read
    	//axi_write32(SLV0,32'h00000004 & 32'h0000000F); // Read enable
    	//axi_write32(SLV1,32'h07030000 & 32'hFFFF0000); // Addr 1795 First NZ line FFT-1D
    	axi_write32_masked(SLV0,32'h00000001,32'h00000001); // Read enable
    	axi_write32_masked(SLV1,32'h07030000,32'hFFFF0000); // Addr 1795 First NZ line FFT-1D
    
      fork
        begin      
          repeat(10) @(posedge aclk);        
          axi_read32(SLV3, rd_mem_re_0);
        end
      join_any
      disable fork;
      $display("[%0t] Read =  %h ", $time, rd_mem_re_0);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Set debug mode OFF
    //axi_write32(SLV0,32'h00000000 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000000,32'h00000100);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Restart Engine
    //axi_write32(SLV0,32'h00000800 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000800,32'h00000800);
    
    
    
    
    
    
    //  Previous simple commands

    // start
    //axi_write32(CTRL, 32'h1);
    //axi_write32(SLV0,32'h3); // enable , write mem A
    //axi_write32(SLV1,32'h00000000); // upper 16 bits are addr for Mem A(input-write)
                                    // lower 16 bits are addr for MemB(output-read)
    //axi_write32(SLV2,32'hDEADBEEF); // data for A memory ( write data)
    
    // TB simplified 
      
     
    
    //#1000 $finish;
    
    
    
    
    
    
    
    
  end

endmodule
