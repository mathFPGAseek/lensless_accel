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

  // ---- Example sequence: START -> poll DONE -> CLEAR (edit offsets) ----
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
  
  integer poll_count;
  localparam integer DIV = 500;
  
  initial begin
    // init master signals
    s_awaddr=0; s_wdata=0; s_araddr=0; s_wstrb=0;
    s_awvalid=0; s_wvalid=0; s_bready=0; s_arvalid=0; s_rready=0;
    
    @(posedge aresetn); repeat (5) @(posedge aclk);
    
    // Set Stop for 1D FFT
    //axi_write32(SLV0,32'h00000010 & 32'h000000F0); // Stop[3..0] = 0001 Stop at 1D FFT
    axi_write32_masked(SLV0,32'h00000010,32'h00000010); // Stop[3..0] = 0001 Stop at 1D FFT
                                                        // WAVEFORM shows = x0000_0010
    

    //@(posedge aresetn);// 
    repeat (5) @(posedge aclk);
    
    // start FISTA
    //axi_write32(SLV0,32'h00000400 & 32'h00000F00); // start 2 = 1 start 1 = 0
    //axi_write32(SLV0,32'h00000200 & 32'h00000F00); // start 2 = 0 start 1 = 1
    axi_write32_masked(SLV0,32'h00000400,32'h00000600); // start 2 = 1 start 1 = 0
                                                        // WAVEFORM shows = x0000_0410
    axi_write32_masked(SLV0,32'h00000200,32'h00000600); // start 2 = 0 start 1 = 1
                                                        // WAVEFORM shows = x0000_0210
    
    poll_count = 0;
    // Poll Stop bit
    do begin
    
        if (poll_count % DIV == 0) begin        
        	$display("%0t: Starting AXI read: Polling Done bit for Completion of 1D FFT", $time);        	
        end
        
        axi_read32(SLV0,rd_reg_0);
        
        done = ((rd_reg_0 & 32'h00001000) != 1'b0);
        
        poll_count = poll_count + 1;
        
        if (( poll_count % DIV == 0) || (done == 1'b1)) begin
        		 $display("%0t: AXI returned rd_reg_0=%08h; bit12=%b; done=%b",
             $time, rd_reg_0, rd_reg_0[12], done);
        end
      
    end while ( done !== 1'b1); 
    
    $display("%0t: Stop detected: rd_reg_0=%08h",
         $time, rd_reg_0);   
    
    $display("-------------------------------------------------");
    $display(" Stop detected: Read out 1D FFT results %0t", $time); 
    $display("-------------------------------------------------");
    
    
    //----------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------
    // Read FFT 1D Test from simulation file
    // & then restart for FFT2-D processing
    //----------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------
    
    
    //@(posedge aresetn); 
    repeat (50) @(posedge aclk);
    
    // Set debug mode ON
    //axi_write32(SLV0,32'h00000100 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000100,32'h00000100);
                                                      // WAVEFORM shows = x0000_0310
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    // Set debug mode OFF
    //axi_write32(SLV0,32'h00000000 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000000,32'h00000100);
                                                      // WAVEFORM shows = x0000_0210
    
    //@(posedge aresetn); //
    repeat (10) @(posedge aclk);
    
    
    // Set Stop for 2D FFT
    axi_write32_masked(SLV0,32'h00000020,32'h00000020); // Stop[3..0] = 0002 Stop at 2D FFT
                                                        // WAVEFORM shows = x0000_0230
                                                        
    $display(" Set stop for 2D FFT @ %0t", $time);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
                                                        
   // Clear Stop for 1D FFT
    axi_write32_masked(SLV0,32'h00000000,32'h00000010); // Stop[3..0] = 0001 Clear Stop at 1D FFT
                                                        // WAVEFORM shows = x0000_0220
    $display(" Cleared Stop for 1d FFT @ %0t", $time);
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    //  Set Restart Engine
    axi_write32_masked(SLV0,32'h00000800,32'h00000800); 
                                                        // WAVEFORM shows = x0000_0A20
    $display("  Restarted Engine @ %0t", $time);
    
    
    // To try and flush bit out of read regsiter!
    // Toggle debug on and off
    
    // Set debug mode ON
    //axi_write32(SLV0,32'h00000100 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000100,32'h00000100);
                                                      // WAVEFORM shows = x0000_0310
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    // Set debug mode OFF
    //axi_write32(SLV0,32'h00000000 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000000,32'h00000100);
                                                      // WAVEFORM shows = x0000_0210
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Release Restart Engine
    axi_write32_masked(SLV0,32'h00000000,32'h00000800); 
                                                        // WAVEFORM shows = x0000_0220
    $display("Release Restart Engine @ %0t", $time);
    
    
    // delay ; after restart releases done.
    repeat (100) @(posedge aclk);
    
    poll_count = 0;
    // Poll Stop bit
    do begin
    
        if (poll_count % DIV == 0) begin
        	$display("%0t: Starting AXI read: Polling Done bit for Completion of 2D FFT", $time);
        end
        
        axi_read32(SLV0,rd_reg_0);
        
        done = ((rd_reg_0 & 32'h00001000) != 1'b0);
        
        poll_count = poll_count + 1;
        
        if ((poll_count % DIV == 0) || (done == 1'b1)) begin
        	   $display("%0t: AXI returned rd_reg_0=%08h; bit12=%b; done=%b",
             $time, rd_reg_0, rd_reg_0[12], done);
        end
      
    end while ( done !== 1'b1); 
    
    $display("%0t: Stop detected: rd_reg_0=%08h",
         $time, rd_reg_0); 
         
    $display("-------------------------------------------------");
    $display(" Stop detected: Read out 2D FFT results %0t", $time);
    $display("-------------------------------------------------");
    
    
    //----------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------
    // Read FFT 2D Test from simulation file
    // & then restart for H processing
    //----------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------
    
     
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Set debug mode ON
    //axi_write32(SLV0,32'h00000100 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000100,32'h00000100);
                                                      // WAVEFORM shows = x0000_0310
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    // Set debug mode OFF
    //axi_write32(SLV0,32'h00000000 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000000,32'h00000100);
                                                      // WAVEFORM shows = x0000_0210
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    // Set Stop for H Proc
    axi_write32_masked(SLV0,32'h00000040,32'h00000040); // Stop[3..0] = 0004 Stop at H Proc
                                                        // WAVEFORM shows = ????
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
                                                        
   // Clear Stop for 2D FFT
    axi_write32_masked(SLV0,32'h00000000,32'h00000020); // Stop[3..0] = 0002 Clear Stop at 1D FFT
                                                        // WAVEFORM shows = x0000_0220
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    
    
    
    // Restart Engine
    axi_write32_masked(SLV0,32'h00000800,32'h00000800); 
                                                   // WAVEFORM shows = x0000_0A20.
    // To try and flush bit out of read regsiter!
    // Toggle debug on and off
    
    // Set debug mode ON
    //axi_write32(SLV0,32'h00000100 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000100,32'h00000100);
                                                      // WAVEFORM shows = x0000_0310
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    
    // Set debug mode OFF
    //axi_write32(SLV0,32'h00000000 & 32'h00000F00);
    axi_write32_masked(SLV0,32'h00000000,32'h00000100);
                                                      // WAVEFORM shows = x0000_0210
    
    //@(posedge aresetn); 
    repeat (10) @(posedge aclk);
    
    // Release Restart Engine
    axi_write32_masked(SLV0,32'h00000000,32'h00000800); 
                                                        // WAVEFORM shows = x0000_0220
    $display("Release Restart Engine @ %0t", $time);
    
    
    
    
    
    
    // delay ; after restart releases done
    repeat (100) @(posedge aclk);
    
    poll_count = 0;
    // Poll Stop bit
    do begin
    
        if( poll_count % DIV == 0) begin
           $display("%0t: Starting AXI read", $time);
        end
        
        axi_read32(SLV0,rd_reg_0);
        
        done = ((rd_reg_0 & 32'h00001000) != 1'b0);
        
        poll_count = poll_count + 1;
        
        if((poll_count % DIV == 0) || (done = 1'b1) ) begin
             $display("%0t: AXI returned rd_reg_0=%08h; bit12=%b; done=%b",
             $time, rd_reg_0, rd_reg_0[12], done);
        end
      
    end while ( done !== 1'b1); 
    
    $display("%0t: Stop detected: rd_reg_0=%08h",
         $time, rd_reg_0);
    
    $display("-------------------------------------------------");
    $display(" Stop detected: Read out H results %0t", $time);
    $display("-------------------------------------------------"); 
    
  end

endmodule
