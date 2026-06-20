# create_all_ip_3.tcl

# Directory structure:
# root/
#   build/
#   scripts/
#   ip_src/
#   constraints/
#   rtl_src/
#   coe/

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]
set coe_dir    [file join $root_dir "coe"]

puts "script_dir = $script_dir"
puts "root_dir   = $root_dir"
puts "coe_dir    = $coe_dir"

#set root_dir  "C:/fa_ll"
#set test_dir  "$root_dir/build"
#set proj_name "all_ip_test"
#set part_name "xczu7ev-ffvc1156-2-e"

#create_project $proj_name $test_dir -part $part_name -force


# ============================================================
# IP 1: add_counter_and_rom_for_rd_col_addr_LL
# ============================================================

create_ip -name c_addsub -vendor xilinx.com -library ip -version 12.0 -module_name add_cnt_rd

set_property -dict {
   CONFIG.AINIT_Value {0}
   CONFIG.A_Type {Unsigned}
   CONFIG.A_Width {16}
   CONFIG.Add_Mode {Add}
   CONFIG.B_Constant {false}
   CONFIG.B_Type {Unsigned}
   CONFIG.B_Value {0000000000000000}
   CONFIG.B_Width {16}
   CONFIG.Borrow_Sense {Active_Low}
   CONFIG.Bypass {false}
   CONFIG.Bypass_CE_Priority {CE_Overrides_Bypass}
   CONFIG.Bypass_Sense {Active_High}
   CONFIG.CE {true}
   CONFIG.CLK_INTF.FREQ_HZ {100000000}
   CONFIG.CLK_INTF.INSERT_VIP {0}
   CONFIG.C_In {false}
   CONFIG.C_Out {false}
   CONFIG.Implementation {DSP48}
   CONFIG.Latency {1}
   CONFIG.Latency_Configuration {Manual}
   CONFIG.Out_Width {16}
   CONFIG.SCLR {true}
   CONFIG.SCLR_INTF.INSERT_VIP {0}
   CONFIG.SINIT {false}
   CONFIG.SINIT_Value {0}
   CONFIG.SSET {false}
   CONFIG.Sync_CE_Priority {Sync_Overrides_CE}
   CONFIG.Sync_Ctrl_Priority {Reset_Overrides_Set}
} [get_ips add_cnt_rd]

# ============================================================
# IP 2:  blk_dual_mem_gen_no_reg_LL_0
# ============================================================

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_buf

set_property -dict {
   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP {0}
   CONFIG.AXI_ID_Width {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP {0}
   CONFIG.AXI_Slave_Type {Memory_Slave}
   CONFIG.AXI_Type {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation {false}
   CONFIG.Algorithm {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk {false}
   CONFIG.Byte_Size {9}
   CONFIG.CLK.ACLK.INSERT_VIP {0}
   CONFIG.CTRL_ECC_ALGO {NONE}
   CONFIG.Collision_Warnings {ALL}
   CONFIG.Disable_Collision_Warnings {false}
   CONFIG.Disable_Out_of_Range_Warnings {false}
   CONFIG.ECC {false}
   CONFIG.EN_DEEPSLEEP_PIN {false}
   CONFIG.EN_ECC_PIPE {false}
   CONFIG.EN_SAFETY_CKT {false}
   CONFIG.EN_SHUTDOWN_PIN {false}
   CONFIG.EN_SLEEP_PIN {false}
   CONFIG.Enable_32bit_Address {false}
   CONFIG.Enable_A {Use_ENA_Pin}
   CONFIG.Enable_B {Use_ENB_Pin}
   CONFIG.Error_Injection_Type {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations {false}
   CONFIG.Interface_Type {Native}
   CONFIG.Load_Init_File {false}
   CONFIG.Memory_Type {Simple_Dual_Port_RAM}
   CONFIG.Operating_Mode_A {NO_CHANGE}
   CONFIG.Operating_Mode_B {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A {0}
   CONFIG.Output_Reset_Value_B {0}
   CONFIG.PRIM_type_to_Implement {BRAM}
   CONFIG.Pipeline_Stages {0}
   CONFIG.Port_A_Clock {100}
   CONFIG.Port_A_Enable_Rate {100}
   CONFIG.Port_A_Write_Rate {50}
   CONFIG.Port_B_Clock {100}
   CONFIG.Port_B_Enable_Rate {100}
   CONFIG.Port_B_Write_Rate {0}
   CONFIG.Primitive {8kx2}
   CONFIG.RD_ADDR_CHNG_A {false}
   CONFIG.RD_ADDR_CHNG_B {false}
   CONFIG.READ_LATENCY_A {1}
   CONFIG.READ_LATENCY_B {1}
   CONFIG.RST.ARESETN.INSERT_VIP {0}
   CONFIG.Read_Width_A {80}
   CONFIG.Read_Width_B {80}
   CONFIG.Register_PortA_Output_of_Memory_Core {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false}
   CONFIG.Register_PortB_Output_of_Memory_Core {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false}
   CONFIG.Remaining_Memory_Locations {0}
   CONFIG.Reset_Memory_Latch_A {false}
   CONFIG.Reset_Memory_Latch_B {false}
   CONFIG.Reset_Priority_A {CE}
   CONFIG.Reset_Priority_B {CE}
   CONFIG.Reset_Type {SYNC}
   CONFIG.Use_AXI_ID {false}
   CONFIG.Use_Byte_Write_Enable {false}
   CONFIG.Use_Error_Injection_Pins {false}
   CONFIG.Use_REGCEA_Pin {false}
   CONFIG.Use_REGCEB_Pin {false}
   CONFIG.Use_RSTA_Pin {false}
   CONFIG.Use_RSTB_Pin {false}
   CONFIG.Write_Depth_A {256}
   CONFIG.Write_Width_A {80}
   CONFIG.Write_Width_B {80}
   CONFIG.ecctype {No_ECC}
   CONFIG.register_porta_input_of_softecc {false}
   CONFIG.register_portb_output_of_softecc {false}
   CONFIG.softecc {false}
   CONFIG.use_bram_block {Stand_Alone}
} [get_ips mem_buf]

# ============================================================
# IP 3:  blk_mem_32bit_gen_REGEN_LL_0
# ============================================================
 
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_init

set_property -dict {
   
   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_ID_Width  {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_Slave_Type  {Memory_Slave}
   CONFIG.AXI_Type  {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation  {false}
   CONFIG.Algorithm  {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk  {false}
   CONFIG.Byte_Size  {9}
   CONFIG.CLK.ACLK.INSERT_VIP  {0}
   CONFIG.CTRL_ECC_ALGO  {NONE}
   CONFIG.Collision_Warnings  {ALL}
   CONFIG.Disable_Collision_Warnings  {false}
   CONFIG.Disable_Out_of_Range_Warnings  {false}
   CONFIG.ECC  {false}
   CONFIG.EN_DEEPSLEEP_PIN  {false}
   CONFIG.EN_ECC_PIPE  {false}
   CONFIG.EN_SAFETY_CKT  {false}
   CONFIG.EN_SHUTDOWN_PIN  {false}
   CONFIG.EN_SLEEP_PIN  {false}
   CONFIG.Enable_32bit_Address  {false}
   CONFIG.Enable_A  {Use_ENA_Pin}
   CONFIG.Enable_B  {Always_Enabled}
   CONFIG.Error_Injection_Type  {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations  {false}
   CONFIG.Interface_Type  {Native}
   CONFIG.Memory_Type  {Single_Port_ROM}
   CONFIG.Operating_Mode_A  {WRITE_FIRST}
   CONFIG.Operating_Mode_B  {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A  {0}
   CONFIG.Output_Reset_Value_B  {0}
   CONFIG.PRIM_type_to_Implement  {BRAM}
   CONFIG.Pipeline_Stages  {0}
   CONFIG.Port_A_Clock  {100}
   CONFIG.Port_A_Enable_Rate  {100}
   CONFIG.Port_A_Write_Rate  {0}
   CONFIG.Port_B_Clock  {0}
   CONFIG.Port_B_Enable_Rate  {0}
   CONFIG.Port_B_Write_Rate  {0}
   CONFIG.Primitive  {8kx2}
   CONFIG.RD_ADDR_CHNG_A  {false}
   CONFIG.RD_ADDR_CHNG_B  {false}
   CONFIG.READ_LATENCY_A  {1}
   CONFIG.READ_LATENCY_B  {1}
   CONFIG.RST.ARESETN.INSERT_VIP  {0}
   CONFIG.Read_Width_A  {32}
   CONFIG.Read_Width_B  {32}
   CONFIG.Register_PortA_Output_of_Memory_Core  {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives  {true}
   CONFIG.Register_PortB_Output_of_Memory_Core  {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives  {false}
   CONFIG.Remaining_Memory_Locations  {0}
   CONFIG.Reset_Memory_Latch_A  {false}
   CONFIG.Reset_Memory_Latch_B  {false}
   CONFIG.Reset_Priority_A  {CE}
   CONFIG.Reset_Priority_B  {CE}
   CONFIG.Reset_Type  {SYNC}
   CONFIG.Use_AXI_ID  {false}
   CONFIG.Use_Byte_Write_Enable  {false}
   CONFIG.Use_Error_Injection_Pins  {false}
   CONFIG.Use_REGCEA_Pin  {false}
   CONFIG.Use_REGCEB_Pin  {false}
   CONFIG.Use_RSTA_Pin  {false}
   CONFIG.Use_RSTB_Pin  {false}
   CONFIG.Write_Depth_A  {65536}
   CONFIG.Write_Width_A  {32}
   CONFIG.Write_Width_B  {32}
   CONFIG.ecctype  {No_ECC}
   CONFIG.register_porta_input_of_softecc  {false}
   CONFIG.register_portb_output_of_softecc  {false}
   CONFIG.softecc  {false}
   CONFIG.use_bram_block  {Stand_Alone}
} [get_ips mem_init]
   
# ============================================================
# IP 4:  blk_mem_gen_h_psf_mem_LL_0
# ============================================================

 
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_h

set_property -dict {

   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_ID_Width  {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_Slave_Type  {Memory_Slave}
   CONFIG.AXI_Type  {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation  {false}
   CONFIG.Algorithm  {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk  {false}
   CONFIG.Byte_Size  {9}
   CONFIG.CLK.ACLK.INSERT_VIP  {0}
   CONFIG.CTRL_ECC_ALGO  {NONE}
   CONFIG.Collision_Warnings  {ALL}
   CONFIG.Disable_Collision_Warnings  {false}
   CONFIG.Disable_Out_of_Range_Warnings  {false}
   CONFIG.ECC  {false}
   CONFIG.EN_DEEPSLEEP_PIN  {false}
   CONFIG.EN_ECC_PIPE  {false}
   CONFIG.EN_SAFETY_CKT  {false}
   CONFIG.EN_SHUTDOWN_PIN  {false}
   CONFIG.EN_SLEEP_PIN  {false}
   CONFIG.Enable_32bit_Address  {false}
   CONFIG.Enable_A  {Use_ENA_Pin}
   CONFIG.Enable_B  {Always_Enabled}
   CONFIG.Error_Injection_Type  {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations  {false}
   CONFIG.Interface_Type  {Native}
   CONFIG.Load_Init_File  {false}
   CONFIG.Memory_Type  {Single_Port_RAM}
   CONFIG.Operating_Mode_A  {WRITE_FIRST}
   CONFIG.Operating_Mode_B  {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A  {0}
   CONFIG.Output_Reset_Value_B  {0}
   CONFIG.PRIM_type_to_Implement  {BRAM}
   CONFIG.Pipeline_Stages  {0}
   CONFIG.Port_A_Clock  {100}
   CONFIG.Port_A_Enable_Rate  {100}
   CONFIG.Port_A_Write_Rate  {50}
   CONFIG.Port_B_Clock  {0}
   CONFIG.Port_B_Enable_Rate  {0}
   CONFIG.Port_B_Write_Rate  {0}
   CONFIG.Primitive  {8kx2}
   CONFIG.RD_ADDR_CHNG_A  {false}
   CONFIG.RD_ADDR_CHNG_B  {false}
   CONFIG.READ_LATENCY_A  {1}
   CONFIG.READ_LATENCY_B  {1}
   CONFIG.RST.ARESETN.INSERT_VIP  {0}
   CONFIG.Read_Width_A  {80}
   CONFIG.Read_Width_B  {80}
   CONFIG.Register_PortA_Output_of_Memory_Core  {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives  {true}
   CONFIG.Register_PortB_Output_of_Memory_Core  {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives  {false}
   CONFIG.Remaining_Memory_Locations  {0}
   CONFIG.Reset_Memory_Latch_A  {false}
   CONFIG.Reset_Memory_Latch_B  {false}
   CONFIG.Reset_Priority_A  {CE}
   CONFIG.Reset_Priority_B  {CE}
   CONFIG.Reset_Type  {SYNC}
   CONFIG.Use_AXI_ID  {false}
   CONFIG.Use_Byte_Write_Enable  {false}
   CONFIG.Use_Error_Injection_Pins  {false}
   CONFIG.Use_REGCEA_Pin  {false}
   CONFIG.Use_REGCEB_Pin  {false}
   CONFIG.Use_RSTA_Pin  {false}
   CONFIG.Use_RSTB_Pin  {false}
   CONFIG.Write_Depth_A  {65536}
   CONFIG.Write_Width_A  {80}
   CONFIG.Write_Width_B  {80}
   CONFIG.ecctype  {No_ECC}
   CONFIG.register_porta_input_of_softecc  {false}
   CONFIG.register_portb_output_of_softecc  {false}
   CONFIG.softecc  {false}
   CONFIG.use_bram_block  {Stand_Alone}
} [get_ips mem_h]


# ============================================================
# IP 5:  blk_mem_image_gen_LL_0
# ============================================================
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_img

set_property -dict {
   
   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_ID_Width  {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_Slave_Type  {Memory_Slave}
   CONFIG.AXI_Type  {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation  {false}
   CONFIG.Algorithm  {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk  {false}
   CONFIG.Byte_Size  {9}
   CONFIG.CLK.ACLK.INSERT_VIP  {0}
   CONFIG.CTRL_ECC_ALGO  {NONE}
   CONFIG.Collision_Warnings  {ALL}
   CONFIG.Disable_Collision_Warnings  {false}
   CONFIG.Disable_Out_of_Range_Warnings  {false}
   CONFIG.ECC  {false}
   CONFIG.EN_DEEPSLEEP_PIN  {false}
   CONFIG.EN_ECC_PIPE  {false}
   CONFIG.EN_SAFETY_CKT  {false}
   CONFIG.EN_SHUTDOWN_PIN  {false}
   CONFIG.EN_SLEEP_PIN  {false}
   CONFIG.Enable_32bit_Address  {false}
   CONFIG.Enable_A  {Use_ENA_Pin}
   CONFIG.Enable_B  {Always_Enabled}
   CONFIG.Error_Injection_Type  {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations  {false}
   CONFIG.Interface_Type  {Native}
   CONFIG.Load_Init_File  {false}
   CONFIG.Memory_Type  {Single_Port_RAM}
   CONFIG.Operating_Mode_A  {WRITE_FIRST}
   CONFIG.Operating_Mode_B  {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A  {0}
   CONFIG.Output_Reset_Value_B  {0}
   CONFIG.PRIM_type_to_Implement  {BRAM}
   CONFIG.Pipeline_Stages  {0}
   CONFIG.Port_A_Clock  {100}
   CONFIG.Port_A_Enable_Rate  {100}
   CONFIG.Port_A_Write_Rate  {50}
   CONFIG.Port_B_Clock  {0}
   CONFIG.Port_B_Enable_Rate  {0}
   CONFIG.Port_B_Write_Rate  {0}
   CONFIG.RD_ADDR_CHNG_A  {false}
   CONFIG.RD_ADDR_CHNG_B  {false}
   CONFIG.READ_LATENCY_A  {1}
   CONFIG.READ_LATENCY_B  {1}
   CONFIG.RST.ARESETN.INSERT_VIP  {0}
   CONFIG.Read_Width_A  {80}
   CONFIG.Read_Width_B  {80}
   CONFIG.Register_PortA_Output_of_Memory_Core  {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives  {true}
   CONFIG.Register_PortB_Output_of_Memory_Core  {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives  {false}
   CONFIG.Remaining_Memory_Locations  {0}
   CONFIG.Reset_Memory_Latch_A  {false}
   CONFIG.Reset_Memory_Latch_B  {false}
   CONFIG.Reset_Priority_A  {CE}
   CONFIG.Reset_Priority_B  {CE}
   CONFIG.Reset_Type  {SYNC}
   CONFIG.Use_AXI_ID  {false}
   CONFIG.Use_Byte_Write_Enable  {false}
   CONFIG.Use_Error_Injection_Pins  {false}
   CONFIG.Use_REGCEA_Pin  {false}
   CONFIG.Use_REGCEB_Pin  {false}
   CONFIG.Use_RSTA_Pin  {false}
   CONFIG.Use_RSTB_Pin  {false}
   CONFIG.Write_Depth_A  {4096}
   CONFIG.Write_Width_A  {80}
   CONFIG.Write_Width_B  {80}
   CONFIG.ecctype  {No_ECC}
   CONFIG.register_porta_input_of_softecc  {false}
   CONFIG.register_portb_output_of_softecc  {false}
   CONFIG.softecc  {false}
   CONFIG.use_bram_block  {Stand_Alone}
} [get_ips mem_img]

# ============================================================
# IP 6:  blk_rd_addr_mem_gen_no_reg_REGEN_LL_0
# ============================================================
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_rd_addr

set_property -dict {
   
   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_ID_Width  {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_Slave_Type  {Memory_Slave}
   CONFIG.AXI_Type  {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation  {false}
   CONFIG.Algorithm  {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk  {false}
   CONFIG.Byte_Size  {9}
   CONFIG.CLK.ACLK.INSERT_VIP  {0}
   CONFIG.CTRL_ECC_ALGO  {NONE}
   CONFIG.Collision_Warnings  {ALL}
   CONFIG.Disable_Collision_Warnings  {false}
   CONFIG.Disable_Out_of_Range_Warnings  {false}
   CONFIG.ECC  {false}
   CONFIG.EN_DEEPSLEEP_PIN  {false}
   CONFIG.EN_ECC_PIPE  {false}
   CONFIG.EN_SAFETY_CKT  {false}
   CONFIG.EN_SHUTDOWN_PIN  {false}
   CONFIG.EN_SLEEP_PIN  {false}
   CONFIG.Enable_32bit_Address  {false}
   CONFIG.Enable_A  {Use_ENA_Pin}
   CONFIG.Enable_B  {Always_Enabled}
   CONFIG.Error_Injection_Type  {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations  {false}
   CONFIG.Interface_Type  {Native}
   CONFIG.Memory_Type  {Single_Port_ROM}
   CONFIG.Operating_Mode_A  {WRITE_FIRST}
   CONFIG.Operating_Mode_B  {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A  {0}
   CONFIG.Output_Reset_Value_B  {0}
   CONFIG.PRIM_type_to_Implement  {BRAM}
   CONFIG.Pipeline_Stages  {0}
   CONFIG.Port_A_Clock  {100}
   CONFIG.Port_A_Enable_Rate  {100}
   CONFIG.Port_A_Write_Rate  {0}
   CONFIG.Port_B_Clock  {0}
   CONFIG.Port_B_Enable_Rate  {0}
   CONFIG.Port_B_Write_Rate  {0}
   CONFIG.Primitive  {8kx2}
   CONFIG.RD_ADDR_CHNG_A  {false}
   CONFIG.RD_ADDR_CHNG_B  {false}
   CONFIG.READ_LATENCY_A  {1}
   CONFIG.READ_LATENCY_B  {1}
   CONFIG.RST.ARESETN.INSERT_VIP  {0}
   CONFIG.Read_Width_A  {16}
   CONFIG.Read_Width_B  {16}
   CONFIG.Register_PortA_Output_of_Memory_Core  {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives  {false}
   CONFIG.Register_PortB_Output_of_Memory_Core  {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives  {false}
   CONFIG.Remaining_Memory_Locations  {0}
   CONFIG.Reset_Memory_Latch_A  {false}
   CONFIG.Reset_Memory_Latch_B  {false}
   CONFIG.Reset_Priority_A  {CE}
   CONFIG.Reset_Priority_B  {CE}
   CONFIG.Reset_Type  {SYNC}
   CONFIG.Use_AXI_ID  {false}
   CONFIG.Use_Byte_Write_Enable  {false}
   CONFIG.Use_Error_Injection_Pins  {false}
   CONFIG.Use_REGCEA_Pin  {false}
   CONFIG.Use_REGCEB_Pin  {false}
   CONFIG.Use_RSTA_Pin  {false}
   CONFIG.Use_RSTB_Pin  {false}
   CONFIG.Write_Depth_A  {256}
   CONFIG.Write_Width_A  {16}
   CONFIG.Write_Width_B  {16}
   CONFIG.ecctype  {No_ECC}
   CONFIG.register_porta_input_of_softecc  {false}
   CONFIG.register_portb_output_of_softecc  {false}
   CONFIG.softecc  {false}
   CONFIG.use_bram_block  {Stand_Alone}
} [get_ips mem_rd_addr]   

# ============================================================
# IP 7:  blk_wr_addr_mem_gen_no_reg_REGEN_LL_0
# ============================================================

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name mem_wr_addr

set_property -dict {

   CONFIG.AXILITE_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_ID_Width  {4}
   CONFIG.AXI_SLAVE_S_AXI.INSERT_VIP  {0}
   CONFIG.AXI_Slave_Type  {Memory_Slave}
   CONFIG.AXI_Type  {AXI4_Full}
   CONFIG.Additional_Inputs_for_Power_Estimation  {false}
   CONFIG.Algorithm  {Minimum_Area}
   CONFIG.Assume_Synchronous_Clk  {false}
   CONFIG.Byte_Size  {9}
   CONFIG.CLK.ACLK.INSERT_VIP  {0}
   CONFIG.CTRL_ECC_ALGO  {NONE}
   CONFIG.Collision_Warnings  {ALL}
   CONFIG.Disable_Collision_Warnings  {false}
   CONFIG.Disable_Out_of_Range_Warnings  {false}
   CONFIG.ECC  {false}
   CONFIG.EN_DEEPSLEEP_PIN  {false}
   CONFIG.EN_ECC_PIPE  {false}
   CONFIG.EN_SAFETY_CKT  {false}
   CONFIG.EN_SHUTDOWN_PIN  {false}
   CONFIG.EN_SLEEP_PIN  {false}
   CONFIG.Enable_32bit_Address  {false}
   CONFIG.Enable_A  {Use_ENA_Pin}
   CONFIG.Enable_B  {Always_Enabled}
   CONFIG.Error_Injection_Type  {Single_Bit_Error_Injection}
   CONFIG.Fill_Remaining_Memory_Locations  {false}
   CONFIG.Interface_Type  {Native}
   CONFIG.Memory_Type  {Single_Port_ROM}
   CONFIG.Operating_Mode_A  {WRITE_FIRST}
   CONFIG.Operating_Mode_B  {WRITE_FIRST}
   CONFIG.Output_Reset_Value_A  {0}
   CONFIG.Output_Reset_Value_B  {0}
   CONFIG.PRIM_type_to_Implement  {BRAM}
   CONFIG.Pipeline_Stages  {0}
   CONFIG.Port_A_Clock  {100}
   CONFIG.Port_A_Enable_Rate  {100}
   CONFIG.Port_A_Write_Rate  {0}
   CONFIG.Port_B_Clock  {0}
   CONFIG.Port_B_Enable_Rate  {0}
   CONFIG.Port_B_Write_Rate  {0}
   CONFIG.Primitive  {8kx2}
   CONFIG.RD_ADDR_CHNG_A  {false}
   CONFIG.RD_ADDR_CHNG_B  {false}
   CONFIG.READ_LATENCY_A  {1}
   CONFIG.READ_LATENCY_B  {1}
   CONFIG.RST.ARESETN.INSERT_VIP  {0}
   CONFIG.Read_Width_A  {8}
   CONFIG.Read_Width_B  {8}
   CONFIG.Register_PortA_Output_of_Memory_Core  {false}
   CONFIG.Register_PortA_Output_of_Memory_Primitives  {false}
   CONFIG.Register_PortB_Output_of_Memory_Core  {false}
   CONFIG.Register_PortB_Output_of_Memory_Primitives  {false}
   CONFIG.Remaining_Memory_Locations  {0}
   CONFIG.Reset_Memory_Latch_A  {false}
   CONFIG.Reset_Memory_Latch_B  {false}
   CONFIG.Reset_Priority_A  {CE}
   CONFIG.Reset_Priority_B  {CE}
   CONFIG.Reset_Type  {SYNC}
   CONFIG.Use_AXI_ID  {false}
   CONFIG.Use_Byte_Write_Enable  {false}
   CONFIG.Use_Error_Injection_Pins  {false}
   CONFIG.Use_REGCEA_Pin  {false}
   CONFIG.Use_REGCEB_Pin  {false}
   CONFIG.Use_RSTA_Pin  {false}
   CONFIG.Use_RSTB_Pin  {false}
   CONFIG.Write_Depth_A  {256}
   CONFIG.Write_Width_A  {8}
   CONFIG.Write_Width_B  {8}
   CONFIG.ecctype  {No_ECC}
   CONFIG.register_porta_input_of_softecc  {false}
   CONFIG.register_portb_output_of_softecc  {false}
   CONFIG.softecc  {false}
   CONFIG.use_bram_block  {Stand_Alone}
} [get_ips mem_wr_addr ]    


# ============================================================
# IP 8:  floating_point_add_LL_0  
# ============================================================


create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name fp_add

set_property -dict {
  
   CONFIG.ACLK_INTF.FREQ_HZ  {10000000}
   CONFIG.ACLK_INTF.INSERT_VIP  {0}
   CONFIG.ARESETN_INTF.INSERT_VIP  {0}
   CONFIG.A_Precision_Type  {Single}
   CONFIG.A_TUSER_Width  {1}
   CONFIG.Add_Sub_Value  {Add}
   CONFIG.Axi_Optimize_Goal  {Resources}
   CONFIG.B_TUSER_Width  {1}
   CONFIG.C_A_Exponent_Width  {8}
   CONFIG.C_A_Fraction_Width  {24}
   CONFIG.C_Accum_Input_Msb  {32}
   CONFIG.C_Accum_Lsb  {-31}
   CONFIG.C_Accum_Msb  {32}
   CONFIG.C_BRAM_Usage  {No_Usage}
   CONFIG.C_Compare_Operation  {Programmable}
   CONFIG.C_Has_ACCUM_INPUT_OVERFLOW  {false}
   CONFIG.C_Has_ACCUM_OVERFLOW  {false}
   CONFIG.C_Has_DIVIDE_BY_ZERO  {false}
   CONFIG.C_Has_INVALID_OP  {false}
   CONFIG.C_Has_OVERFLOW  {false}
   CONFIG.C_Has_UNDERFLOW  {false}
   CONFIG.C_Latency  {12}
   CONFIG.C_Mult_Usage  {Full_Usage}
   CONFIG.C_Optimization  {Speed_Optimized}
   CONFIG.C_Rate  {1}
   CONFIG.C_Result_Exponent_Width  {8}
   CONFIG.C_Result_Fraction_Width  {24}
   CONFIG.C_TUSER_Width  {1}
   CONFIG.Flow_Control  {Blocking}
   CONFIG.Has_ACLKEN  {false}
   CONFIG.Has_ARESETn  {false}
   CONFIG.Has_A_TLAST  {false}
   CONFIG.Has_A_TUSER  {false}
   CONFIG.Has_B_TLAST  {false}
   CONFIG.Has_B_TUSER  {false}
   CONFIG.Has_C_TLAST  {false}
   CONFIG.Has_C_TUSER  {false}
   CONFIG.Has_OPERATION_TLAST  {false}
   CONFIG.Has_OPERATION_TUSER  {false}
   CONFIG.Has_RESULT_TREADY  {true}
   CONFIG.M_AXIS_RESULT.INSERT_VIP  {0}
   CONFIG.Maximum_Latency  {true}
   CONFIG.OPERATION_TUSER_Width  {1}
   CONFIG.Operation_Type  {Add_Subtract}
   CONFIG.RESULT_TLAST_Behv  {Null}
   CONFIG.Result_Precision_Type  {Single}
   CONFIG.S_AXIS_A.INSERT_VIP  {0}
   CONFIG.S_AXIS_B.INSERT_VIP  {0}
   CONFIG.S_AXIS_C.INSERT_VIP  {0}
   CONFIG.S_AXIS_OPERATION.INSERT_VIP  {0}
 } [get_ips fp_add ]   
   
# ============================================================
# IP 9:  floating_point_mult_REGEN_LL_0  
# ============================================================

create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name fp_mult

set_property -dict {

   
   CONFIG.ACLK_INTF.FREQ_HZ  {10000000}
   CONFIG.ACLK_INTF.INSERT_VIP  {0}
   CONFIG.ARESETN_INTF.INSERT_VIP  {0}
   CONFIG.A_Precision_Type  {Single}
   CONFIG.A_TUSER_Width  {1}
   CONFIG.Add_Sub_Value  {Both}
   CONFIG.Axi_Optimize_Goal  {Resources}
   CONFIG.B_TUSER_Width  {1}
   CONFIG.C_A_Exponent_Width  {8}
   CONFIG.C_A_Fraction_Width  {24}
   CONFIG.C_Accum_Input_Msb  {32}
   CONFIG.C_Accum_Lsb  {-31}
   CONFIG.C_Accum_Msb  {32}
   CONFIG.C_BRAM_Usage  {No_Usage}
   CONFIG.C_Compare_Operation  {Programmable}
   CONFIG.C_Has_ACCUM_INPUT_OVERFLOW  {false}
   CONFIG.C_Has_ACCUM_OVERFLOW  {false}
   CONFIG.C_Has_DIVIDE_BY_ZERO  {false}
   CONFIG.C_Has_INVALID_OP  {false}
   CONFIG.C_Has_OVERFLOW  {false}
   CONFIG.C_Has_UNDERFLOW  {false}
   CONFIG.C_Latency  {9}
   CONFIG.C_Mult_Usage  {Full_Usage}
   CONFIG.C_Optimization  {Speed_Optimized}
   CONFIG.C_Rate  {1}
   CONFIG.C_Result_Exponent_Width  {8}
   CONFIG.C_Result_Fraction_Width  {24}
   CONFIG.C_TUSER_Width  {1}
   CONFIG.Flow_Control  {Blocking}
   CONFIG.Has_ACLKEN  {false}
   CONFIG.Has_ARESETn  {true}
   CONFIG.Has_A_TLAST  {false}
   CONFIG.Has_A_TUSER  {false}
   CONFIG.Has_B_TLAST  {false}
   CONFIG.Has_B_TUSER  {false}
   CONFIG.Has_C_TLAST  {false}
   CONFIG.Has_C_TUSER  {false}
   CONFIG.Has_OPERATION_TLAST  {false}
   CONFIG.Has_OPERATION_TUSER  {false}
   CONFIG.Has_RESULT_TREADY  {true}
   CONFIG.M_AXIS_RESULT.INSERT_VIP  {0}
   CONFIG.Maximum_Latency  {true}
   CONFIG.OPERATION_TUSER_Width  {1}
   CONFIG.Operation_Type  {Multiply}
   CONFIG.RESULT_TLAST_Behv  {Null}
   CONFIG.Result_Precision_Type  {Single}
   CONFIG.S_AXIS_A.INSERT_VIP  {0}
   CONFIG.S_AXIS_B.INSERT_VIP  {0}
   CONFIG.S_AXIS_C.INSERT_VIP  {0}
   CONFIG.S_AXIS_OPERATION.INSERT_VIP  {0}

} [get_ips fp_mult ]

# ============================================================
# IP 10: floating_point_sub_LL_0 
# ============================================================


create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name fp_sub

set_property -dict {
  
   CONFIG.ACLK_INTF.FREQ_HZ  {10000000}
   CONFIG.ACLK_INTF.INSERT_VIP  {0}
   CONFIG.ARESETN_INTF.INSERT_VIP  {0}
   CONFIG.A_Precision_Type  {Single}
   CONFIG.A_TUSER_Width  {1}
   CONFIG.Add_Sub_Value  {Subtract}
   CONFIG.Axi_Optimize_Goal  {Resources}
   CONFIG.B_TUSER_Width  {1}
   CONFIG.C_A_Exponent_Width  {8}
   CONFIG.C_A_Fraction_Width  {24}
   CONFIG.C_Accum_Input_Msb  {32}
   CONFIG.C_Accum_Lsb  {-31}
   CONFIG.C_Accum_Msb  {32}
   CONFIG.C_BRAM_Usage  {No_Usage}
   CONFIG.C_Compare_Operation  {Programmable}
   CONFIG.C_Has_ACCUM_INPUT_OVERFLOW  {false}
   CONFIG.C_Has_ACCUM_OVERFLOW  {false}
   CONFIG.C_Has_DIVIDE_BY_ZERO  {false}
   CONFIG.C_Has_INVALID_OP  {false}
   CONFIG.C_Has_OVERFLOW  {false}
   CONFIG.C_Has_UNDERFLOW  {false}
   CONFIG.C_Latency  {12}
   CONFIG.C_Mult_Usage  {Full_Usage}
   CONFIG.C_Optimization  {Speed_Optimized}
   CONFIG.C_Rate  {1}
   CONFIG.C_Result_Exponent_Width  {8}
   CONFIG.C_Result_Fraction_Width  {24}
   CONFIG.C_TUSER_Width  {1}
   CONFIG.Flow_Control  {Blocking}
   CONFIG.Has_ACLKEN  {false}
   CONFIG.Has_ARESETn  {false}
   CONFIG.Has_A_TLAST  {false}
   CONFIG.Has_A_TUSER  {false}
   CONFIG.Has_B_TLAST  {false}
   CONFIG.Has_B_TUSER  {false}
   CONFIG.Has_C_TLAST  {false}
   CONFIG.Has_C_TUSER  {false}
   CONFIG.Has_OPERATION_TLAST  {false}
   CONFIG.Has_OPERATION_TUSER  {false}
   CONFIG.Has_RESULT_TREADY  {true}
   CONFIG.M_AXIS_RESULT.INSERT_VIP  {0}
   CONFIG.Maximum_Latency  {true}
   CONFIG.OPERATION_TUSER_Width  {1}
   CONFIG.Operation_Type  {Add_Subtract}
   CONFIG.RESULT_TLAST_Behv  {Null}
   CONFIG.Result_Precision_Type  {Single}
   CONFIG.S_AXIS_A.INSERT_VIP  {0}
   CONFIG.S_AXIS_B.INSERT_VIP  {0}
   CONFIG.S_AXIS_C.INSERT_VIP  {0}
   CONFIG.S_AXIS_OPERATION.INSERT_VIP  {0}
} [get_ips fp_sub ]   

# ============================================================
# IP 11: xfft_LL_1
# ============================================================


create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name flt_fft_1

set_property -dict {
   
   CONFIG.aclken  {false}
   CONFIG.aresetn  {true}
   CONFIG.butterfly_type  {use_luts}
   CONFIG.channels  {1}
   CONFIG.complex_mult_type  {use_mults_resources}
   CONFIG.cyclic_prefix_insertion  {false}
   CONFIG.data_format  {floating_point}
   CONFIG.implementation_options  {pipelined_streaming_io}
   CONFIG.input_width  {32}
   CONFIG.memory_options_data  {block_ram}
   CONFIG.memory_options_hybrid  {false}
   CONFIG.memory_options_phase_factors  {block_ram}
   CONFIG.memory_options_reorder  {block_ram}
   CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors  {1}
   CONFIG.output_ordering  {bit_reversed_order}
   CONFIG.phase_factor_width  {24}
   CONFIG.run_time_configurable_transform_length  {false}
   CONFIG.target_clock_frequency  {300}
   CONFIG.target_data_throughput  {50}
   CONFIG.throttle_scheme  {nonrealtime}
   CONFIG.transform_length  {256}
   CONFIG.xk_index  {false}
 } [get_ips flt_fft_1 ]



puts "Project part:"
puts [get_property PART [current_project]]

# ============================================================
# COE FILES
# ============================================================
#
# IP 3:  blk_mem_32bit_gen_REGEN_LL_0:
# CONFIG.Coe_File {../../coe/point_source_vectors.coe}
#
# IP 6:  blk_rd_addr_mem_gen_no_reg_REGEN_LL_0
# CONFIG.Coe_File {../../coe/read_addr_vectors.coe}
#
# IP 7:  blk_wr_addr_mem_gen_no_reg_REGEN_LL_0
#

set ip_obj [get_ips mem_init]
set coe_file [file normalize [file join $coe_dir "point_source_vectors.coe"]]

puts "Setting COE file for IP : $ip_obj"
puts "Coe_file path: $coe_file"

if {![file exists $coe_file]} {
    error "COE file not found: $coe_file"
}

set_property -dict [list \
   CONFIG.Load_Init_File {true} \
   CONFIG.Coe_File $coe_file \
] $ip_obj



set ip_obj [get_ips mem_rd_addr]
set coe_file [file normalize [ file join $coe_dir "read_addr_vectors.coe"]]

puts "Setting COE file for IP :  $ip_obj"
puts "COE_file path : $coe_file"

if {![file exists $coe_file]} {
   error "COE file not found: $coe_file"
}

set_property -dict [list \
   CONFIG.Load_Init_File {true} \
   CONFIG.Coe_File $coe_file \
] $ip_obj


set ip_obj [get_ips mem_wr_addr]
set coe_file [file normalize [ file join $coe_dir "wr_addr_vectors.coe"]]

puts "Setting COE file for IP :  $ip_obj"
puts "COE_file path : $coe_file"

if {![file exists $coe_file]} {
   error "COE file not found: $coe_file"
}

set_property -dict [list \
   CONFIG.Load_Init_File {true} \
   CONFIG.Coe_File $coe_file \
] $ip_obj


foreach ip_name {mem_init mem_rd_addr mem_wr_addr } {
    set ip_obj [get_ips $ip_name]

    puts "--------------------------------"
    puts "IP: $ip_name"
    puts "Load_Init_File = [get_property CONFIG.Load_Init_File $ip_obj]"
    puts "Coe_File       = [get_property CONFIG.Coe_File $ip_obj]"
}

# ============================================================
# Generate IP
# ============================================================


generate_target all [get_ips]
export_ip_user_files -of_objects [get_ips] -no_script -sync -force
report_ip_status

puts "XCI paths:"
foreach ip [get_ips] {
    puts "$ip -> [get_files -quiet -of_objects $ip *.xci]"
}
