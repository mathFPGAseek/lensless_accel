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
//  /   /         Filename           : example_tb.sv
// /___/   /\     Date Last Modified : $Date: 2014/09/03 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDRx SDRAM EXAMPLE TB
// Purpose          : This is an  example test-bench that shows how to interface
//                    to the Memory controller (MC) User Interface (UI). This example 
//                    works for DDR3/4 memory controller generated from MIG. 
//                    This module waits for the calibration complete 
//                    (init_calib_complete) to pass the traffic to the MC.
//
//                    This TB generates 100 write transactions 
//                    followed by 100 read transactions to the MC.
//                    Checks if the data that is read back from the 
//                    memory is correct. After 100 writes and reads, no other
//                    commands will be issued by this TG.
//
//                    All READ and WRITE transactions in this example TB are of 
//                    DDR3/4 BURST LENGTH (BL) 8. In a single clock cycle 1 BL8
//                    transaction will be generated.
//
//                    The fabric to DRAM clock ratio is 4:1. In each fabric 
//                    clock cycle 8 beats of data will be written during 
//                    WRITE transactions and 8 beats of data will be received 
//                    during READ transactions.
//
//                    The results of this example_tb is guaranteed only for  
//                    100 write and 100 read transactions.
//                    The results of this example_tb is not guaranteed beyond 
//                    100 write and 100 read transactions.
//                    For longer transactions use the HW TG.
//
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps / 1ps

module example_tb #(
  parameter SIMULATION       = "FALSE",   // This parameter must be
                                          // TRUE for simulations and 
                                          // FALSE for implementation.
                                          //
  parameter APP_DATA_WIDTH   = 32,        // Application side data bus width.
                                          // It is 8 times the DQ_WIDTH.
                                          //
  parameter APP_ADDR_WIDTH   = 32,        // Application side Address bus width.
                                          // It is sum of COL, ROW and BANK address
                                          // for DDR3. It is sum of COL, ROW, 
                                          // Bank Group and BANK address for DDR4.
                                          //
  parameter nCK_PER_CLK      = 4,         // Fabric to PHY ratio
                                          //
  parameter MEM_ADDR_ORDER   = "ROW_COLUMN_BANK" // Application address order.
                                                 // "ROW_COLUMN_BANK" is the default
                                                 // address order. Refer to product guide
                                                 // for other address order options.
  )
  (
  // ********* ALL SIGNALS AT THIS INTERFACE ARE ACTIVE HIGH SIGNALS ********/
  input clk,                 // MC UI clock.
                             //
  input rst,                 // MC UI reset signal.
                             //
  input init_calib_complete, // MC calibration done signal coming from MC UI.
                             //
  input app_rdy,             // cmd fifo ready signal coming from MC UI.
                             //
  input app_wdf_rdy,         // write data fifo ready signal coming from MC UI.
                             //
  input app_rd_data_valid,   // read data valid signal coming from MC UI
                             //
  input [APP_DATA_WIDTH-1 : 0]  app_rd_data, // read data bus coming from MC UI
                                             //
  output [2 : 0]                app_cmd,     // command bus to the MC UI
                                             //
  output [APP_ADDR_WIDTH-1 : 0] app_addr,    // address bus to the MC UI
                                             //
  output                        app_en,      // command enable signal to MC UI.
                                             //
  output [(APP_DATA_WIDTH/8)-1 : 0] app_wdf_mask, // write data mask signal which
                                                  // is tied to 0 in this example
                                                  // 
  output [APP_DATA_WIDTH-1: 0]  app_wdf_data, // write data bus to MC UI.
                                              //
  output                        app_wdf_end,  // write burst end signal to MC UI
                                              //
  output                        app_wdf_wren, // write enable signal to MC UI
                                              //
  output                        compare_error,// Memory READ_DATA and example TB
                                              // WRITE_DATA compare error.
  output                        wr_rd_complete,
  
  //**** Signals for FISTA Acceleration*******
   
  input [4:0]                 dbg_master_mode_i,
               
  input                       dbg_rdy_fr_init_and_inbound_i,
   
  input                       dbg_wait_fr_init_and_inbound_i,
                   
  input                       dbg_fft_flow_tlast_i,
                                            
  output                      dbg_mem_init_start_o,
  
                        
                              //mux control to ddr memory controller          
  output [1:0]                dbg_ddr_intf_mux_wr_sel_o,
         
  output [2:0]                dbg_ddr_intf_demux_rd_sel_o,
       
  output                      dbg_mem_shared_in_enb_o,
           
  output [7:0]                dbg_mem_shared_in_addb_o,
          
                                                 
                              //mux control to front and Backend
  output                      dbg_front_end_demux_fr_fista_o,
    
  output [1:0]                dbg_front_end_mux_to_fft_o,
          
  output                      dbg_back_end_demux_fr_fh_mem_o,
    
  output                      dbg_back_end_demux_fr_fv_mem_o,
    
  output                      dbg_back_end_mux_to_front_end_o, 
                                                     
                              // rd,wr control to F*(H) F(H) FIFO
  output                      dbg_f_h_fifo_wr_en_o,
              
  output                      dbg_f_h_fifo_rd_en_o,
              
  input                       dbg_f_h_fifo_full_i, 
              
  input                       dbg_f_h_fifo_empty_i,            
                                                    
                              // rd,wr control to F(V) FIFO    
  output                      dbg_f_v_fifo_wr_en_o,
              
  output                      dbg_f_v_fifo_rd_en_o,
              
  input                       dbg_f_v_fifo_full_i,
               
  input                       dbg_f_v_fifo_empty_i,            
                                                         
                              //  rd,wr control to Fdbk FIFO   
  output                      dbg_fdbk_fifo_wr_en_o,
             
  output                      dbg_fdbk_fifo_rd_en_o,
             
  input                       dbg_fdbk_fifo_full_i,
              
  input                       dbg_fdbk_fifo_empty_i,           
                                                         
                              // output control                
  output                      fista_accel_valid_rd_o          
                                                                                           
  );



                                                                   
 
     //*******************************************************************************
     // SIMULATION of Fista Acceleration
     //*******************************************************************************
     
     fista_accel_top u1_fista_accel(

	  .clk_i               	            (clk), //: in std_logic;
    .rst_i               	            (rst), //: in std_logic;
                                      
    .dbg_master_mode_i                (dbg_master_mode_i), //: in std_logic_vector(4 downto 0);                                       
    .dbg_rdy_fr_init_and_inbound_i    (dbg_rdy_fr_init_and_inbound_i), //: in std_logic; -- Equiv. to Almost full flag
    .dbg_wait_fr_init_and_inbound_i   (dbg_wait_fr_init_and_inbound_i), //: in std_logic; -- Equiv. to Almost empty flag
                                       
    //fft signals                      
    .dbg_fft_flow_tlast_i             (dbg_fft_flow_tlast_i), //: in std_logic; -- This is a multiple clock pulse when 
                                         //         -- done writing to mem buffer by FFT state mach    
    .dbg_mem_init_start_o             (dbg_mem_init_start_o), //: out std_logic;
                                      
    // app interface to ddr controller
    .app_rdy_i           	            (app_rdy), //: in std_logic;
    .app_wdf_rdy_i       	            (app_wdf_rdy), //: in std_logic;
    .app_rd_data_valid_i              (app_rd_data_valid), //: in std_logic_vector( 0 downto 0);
    .add_rd_data_i                    (app_rd_data), //: in std_logic_vector(511 downto 0);
    .app_cmd_o                        (app_cmd), //: out std_logic_vector(2 downto 0);
    .app_addr_o                       (app_addr), //: out std_logic_vector(28 downto 0);
    .app_en_o                         (app_en), //: out std_logic;
    .app_wdf_mask_o                   (app_wdf_mask), //: out std_logic_vector(63 downto 0);
    .app_wdf_data_o                   (app_wdf_data), //: out std_logic_vector(511 downto 0);
    .app_wdf_end_o                    (app_wdf_end), //: out std_logic;
    .app_wdf_wren_o                   (app_wdf_wren), //: out std_logic;
   	
    //mux control to ddr memory controller.
    .dbg_ddr_intf_mux_wr_sel_o        (dbg_ddr_intf_mux_wr_sel_o), //: out std_logic_vector(1 downto 0);
    .dbg_ddr_intf_demux_rd_sel_o      (dbg_ddr_intf_demux_rd_sel_o), //: out std_logic_vector(2 downto 0);
    .dbg_mem_shared_in_enb_o          (dbg_mem_shared_in_enb_o), //: out std_logic;
    .dbg_mem_shared_in_addb_o         (dbg_mem_shared_in_addb_o), //: out std_logic_vector(7 downto 0);
                                      
    // mux control to front and Backend modules  
    .dbg_front_end_demux_fr_fista_o   (dbg_front_end_demux_fr_fista_o), //: out std_logic;
    .dbg_front_end_mux_to_fft_o       (dbg_front_end_mux_to_fft_o), //: out std_logic_vector(1 downto 0);
    .dbg_back_end_demux_fr_fh_mem_o   (dbg_back_end_demux_fr_fh_mem_o), //: out std_logic;
    .dbg_back_end_demux_fr_fv_mem_o   (dbg_back_end_demux_fr_fv_mem_o), //: out std_logic;
    .dbg_back_end_mux_to_front_end_o  (dbg_back_end_mux_to_front_end_o), //: out std_logic;
                                          
    // rd,wr control to F*(H) F(H) FIFO   
    .dbg_f_h_fifo_wr_en_o             (dbg_f_h_fifo_wr_en_o), // out std_logic;
    .dbg_f_h_fifo_rd_en_o             (dbg_f_h_fifo_rd_en_o), // out std_logic;
    .dbg_f_h_fifo_full_i              (dbg_f_h_fifo_full_i), // in std_logic;
    .dbg_f_h_fifo_empty_i             (dbg_f_h_fifo_empty_i), // in std_logic;
                                          
    // rd,wr control to F(V) FIFO         
    .dbg_f_v_fifo_wr_en_o             (dbg_f_v_fifo_wr_en_o ), // out std_logic;
    .dbg_f_v_fifo_rd_en_o             (dbg_f_v_fifo_rd_en_o), // out std_logic;
    .dbg_f_v_fifo_full_i              (dbg_f_v_fifo_full_i), // in std_logic;
    .dbg_f_v_fifo_empty_i             (dbg_f_v_fifo_empty_i), // in std_logic;
                                          
    //  rd,wr control to Fdbk FIFO        
    .dbg_fdbk_fifo_wr_en_o            (dbg_fdbk_fifo_wr_en_o), //: out std_logic;
    .dbg_fdbk_fifo_rd_en_o            (dbg_fdbk_fifo_rd_en_o), //: out std_logic;
    .dbg_fdbk_fifo_full_i             (dbg_fdbk_fifo_full_i), //: in std_logic;
    .dbg_fdbk_fifo_empty_i            (dbg_fdbk_fifo_empty_i), //: in std_logic;
                                          
    // output control                     
    .fista_accel_valid_rd_o           (fista_accel_valid_rd_o)  //: out std_logic
                                        
    );
  

endmodule
