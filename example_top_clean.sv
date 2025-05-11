

/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : example_top.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR4_SDRAM
// Purpose          :
//                    Top-level  module. This module serves both as an example,
//                    and allows the user to synthesize a self-contained
//                    design, which they can be used to test their hardware.
//                    In addition to the memory controller,
//                    the module instantiates:
//                      1. Synthesizable testbench - used to model
//                      user's backend logic and generate different
//                      traffic patterns
//
// Reference        :
// Revision History :
//*****************************************************************************
//LIBRARY xil_defaultlib;

`ifdef MODEL_TECH
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif INCA
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif VCS
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif XILINX_SIMULATOR
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif _VCP
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`endif
`ifdef MODEL_TECH
    `define SIMULATION_MODE
`elsif INCA
    `define SIMULATION_MODE
`elsif VCS
    `define SIMULATION_MODE
`elsif XILINX_SIMULATOR
    `define SIMULATION_MODE
`elsif _VCP
    `define SIMULATION_MODE
`endif


`timescale 1ps/1ps
module example_top #
  (
    parameter nCK_PER_CLK           = 4,   // This parameter is controllerwise
    parameter         APP_DATA_WIDTH          = 512, // This parameter is controllerwise
    parameter         APP_MASK_WIDTH          = 64,  // This parameter is controllerwise
  `ifdef SIMULATION_MODE
    parameter SIMULATION            = "TRUE" 
  `else
    parameter SIMULATION            = "FALSE"
  `endif

  )
   (
    input                   sys_rst, //Common port for all controllers
    input                   c0_sys_clk_p,
    input                   c0_sys_clk_n,
    
                
    //**** Signals for FISTA Acceleration*******
    input  [4:0]           dbg_master_mode_i,                      
    input                  dbg_rdy_fr_init_and_inbound_i,          
    input                  dbg_wait_fr_init_and_inbound_i,         
    input                  dbg_fft_flow_tlast_i,                   
    output                 dbg_mem_init_start_o,                   
    output [1:0]           dbg_ddr_intf_mux_wr_sel_o,              
    output [2:0]           dbg_ddr_intf_demux_rd_sel_o,            
    output                 dbg_mem_shared_in_enb_o,                
    output [7:0]           dbg_mem_shared_in_addb_o,                            
    output                 dbg_front_end_demux_fr_fista_o,         
    output [1:0]           dbg_front_end_mux_to_fft_o,             
    output                 dbg_back_end_demux_fr_fh_mem_o,         
    output                 dbg_back_end_demux_fr_fv_mem_o,         
    output                 dbg_back_end_mux_to_front_end_o,                                
    output                 dbg_f_h_fifo_wr_en_o,                   
    output                 dbg_f_h_fifo_rd_en_o,                   
    input                  dbg_f_h_fifo_full_i,                    
    input                  dbg_f_h_fifo_empty_i,                   
    output                 dbg_f_v_fifo_wr_en_o,                   
    output                 dbg_f_v_fifo_rd_en_o,                   
    input                  dbg_f_v_fifo_full_i,                    
    input                  dbg_f_v_fifo_empty_i,                                              
    output                 dbg_fdbk_fifo_wr_en_o,                  
    output                 dbg_fdbk_fifo_rd_en_o,                  
    input                  dbg_fdbk_fifo_full_i,                   
    input                  dbg_fdbk_fifo_empty_i,                                   
    output                 fista_accel_valid_rd_o                 
    );


  localparam  APP_ADDR_WIDTH = 29;
  localparam  MEM_ADDR_ORDER = "ROW_COLUMN_BANK";
  localparam DBG_WR_STS_WIDTH      = 32;
  localparam DBG_RD_STS_WIDTH      = 32;
  localparam ECC                   = "OFF";


      
  wire [APP_ADDR_WIDTH-1:0]            c0_ddr4_app_addr;
  wire [2:0]            c0_ddr4_app_cmd;
  wire                  c0_ddr4_app_en;
  wire [APP_DATA_WIDTH-1:0]            c0_ddr4_app_wdf_data;
  wire                  c0_ddr4_app_wdf_end;
  wire [APP_MASK_WIDTH-1:0]            c0_ddr4_app_wdf_mask;
  wire                  c0_ddr4_app_wdf_wren;
  wire [APP_DATA_WIDTH-1:0]            c0_ddr4_app_rd_data;
  wire                  c0_ddr4_app_rd_data_end;
  wire                  c0_ddr4_app_rd_data_valid;
  wire                  c0_ddr4_app_rdy;
  wire                  c0_ddr4_app_wdf_rdy;
  wire                  c0_ddr4_clk;
  wire                  c0_ddr4_rst;
  wire                  dbg_clk;
  wire                  c0_wr_rd_complete;


  wire                  c0_init_calib_complete;
  wire                  c0_data_compare_error;
 
assign c0_ddr4_app_rd_data = '0;
assign c0_ddr4_app_rd_data_valid = 1'b1;
assign c0_ddr4_app_wdf_rdy = 1'b1;
assign c0_ddr4_app_rdy = 1'b1;
                                    


    example_tb #
      (
       .SIMULATION     (SIMULATION),
       .APP_DATA_WIDTH (APP_DATA_WIDTH),
       .APP_ADDR_WIDTH (APP_ADDR_WIDTH),
       .MEM_ADDR_ORDER (MEM_ADDR_ORDER)
       )
      u_example_tb
        (
         .clk                                     (c0_sys_clk_p),
         .rst                                     (sys_rst),
         .app_rdy                                 (c0_ddr4_app_rdy),
         .init_calib_complete                     (c0_init_calib_complete),
         .app_rd_data_valid                       (c0_ddr4_app_rd_data_valid),
         .app_rd_data                             (c0_ddr4_app_rd_data),
         .app_wdf_rdy                             (c0_ddr4_app_wdf_rdy),
         .app_en                                  (c0_ddr4_app_en),
         .app_cmd                                 (c0_ddr4_app_cmd),
         .app_addr                                (c0_ddr4_app_addr),
         .app_wdf_wren                            (c0_ddr4_app_wdf_wren),
         .app_wdf_end                             (c0_ddr4_app_wdf_end),
         .app_wdf_mask                            (c0_ddr4_app_wdf_mask),
         .app_wdf_data                            (c0_ddr4_app_wdf_data),
         .compare_error                           (c0_data_compare_error),
         .wr_rd_complete                          (c0_wr_rd_complete),
        
          //**** Signals for FISTA Acceleration*******
         .dbg_master_mode_i                       (dbg_master_mode_i),
         .dbg_rdy_fr_init_and_inbound_i           (dbg_rdy_fr_init_and_inbound_i),
         .dbg_wait_fr_init_and_inbound_i          (dbg_wait_fr_init_and_inbound_i),
         .dbg_fft_flow_tlast_i                    (dbg_fft_flow_tlast_i),           
         .dbg_mem_init_start_o                    (dbg_mem_init_start_o),     
         .dbg_ddr_intf_mux_wr_sel_o               (dbg_ddr_intf_mux_wr_sel_o),
         .dbg_ddr_intf_demux_rd_sel_o             (dbg_ddr_intf_demux_rd_sel_o),
         .dbg_mem_shared_in_enb_o                 (dbg_mem_shared_in_enb_o), 
         .dbg_mem_shared_in_addb_o                (dbg_mem_shared_in_addb_o),                      
         .dbg_front_end_demux_fr_fista_o          (dbg_front_end_demux_fr_fista_o), 
         .dbg_front_end_mux_to_fft_o              (dbg_front_end_mux_to_fft_o),  
         .dbg_back_end_demux_fr_fh_mem_o          (dbg_back_end_demux_fr_fh_mem_o),  
         .dbg_back_end_demux_fr_fv_mem_o          (dbg_back_end_demux_fr_fv_mem_o),  
         .dbg_back_end_mux_to_front_end_o         (dbg_back_end_mux_to_front_end_o),                          
         .dbg_f_h_fifo_wr_en_o                    (dbg_f_h_fifo_wr_en_o),  
         .dbg_f_h_fifo_rd_en_o                    (dbg_f_h_fifo_rd_en_o),  
         .dbg_f_h_fifo_full_i                     (dbg_f_h_fifo_full_i),   
         .dbg_f_h_fifo_empty_i                    (dbg_f_h_fifo_empty_i),             
         .dbg_f_v_fifo_wr_en_o                    (dbg_f_v_fifo_wr_en_o),  
         .dbg_f_v_fifo_rd_en_o                    (dbg_f_v_fifo_rd_en_o),  
         .dbg_f_v_fifo_full_i                     (dbg_f_v_fifo_full_i), 
         .dbg_f_v_fifo_empty_i                    (dbg_f_v_fifo_empty_i),                                        
         .dbg_fdbk_fifo_wr_en_o                   (dbg_fdbk_fifo_wr_en_o),  
         .dbg_fdbk_fifo_rd_en_o                   (dbg_fdbk_fifo_rd_en_o), 
         .dbg_fdbk_fifo_full_i                    (dbg_fdbk_fifo_full_i), 
         .dbg_fdbk_fifo_empty_i                   (dbg_fdbk_fifo_empty_i),                 
                     
         .fista_accel_valid_rd_o                  (fista_accel_valid_rd_o) 
                                     
      );
   


endmodule




























