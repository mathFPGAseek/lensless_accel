# readme.txt
# rbd 
# 6/21/26

#------------------------------------------------------------------------------
# SYNTHESIS & IMPLEMENTATION 64x64 image ( ONLY Tranpose memory image) AND w/o AXI
#------------------------------------------------------------------------------

Step #1.
# Create a root path;
# Example:
C:\design\<your_root_name>

Step #2.
# At your root create the following structure
/build
/coe
/constraints
/rtl_syn_wo_axi
/script


Step #3.

Copy from git the following files ( and only the following files) to /rtl
     av_minus_b_eng.vhd
     fft_engine_no_verify_module.vhd
     fft_inbound_state_machine_controller.vhd
     fista_accel_top.vhd
     fista_accel_top_wrapper_v1_0.vhd
     front_end_module.vhd
     gen_proc_module.vhd
     h_h_start_mult_eng.vhd
     h_hstat_inbound_state_machine_controller.vhd
     inbound_flow_module.vhd
     init_state_machine_controller.vhd
     master_machine_controller.vhd
     mem_controller_FOR_SYNTH.vhd
     mem_in_buffer_module.vhd
     mem_st_machine_controller.vhd
     mem_transpose_module_ONLY_FOR_BD_SYNTH.vhd
     proto_mem_v3_0_S00_AXI.vhd
     update_eng.vhd

Step #4. 
     Copy from git the following files ( and only the following files) to /coe
     point_source_vectors.coe
     read_addr_vectors.coe
     wr_addr_vectors.coe
     
Step #5.
     Copy from git the following files ( and only the following files) to /script

     build_project.tcl
     create_ip.tcl
     synth.tcl 
     
Step #6. 
     Execute the command from a Windows file: 
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_syn_64_by_64_mem_img_project.tcl  
      
      
Step #7.
     Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     
Step #8.
     Launch Synthesis ( from \script)
     source synth.tcl
     
Step #9.
     Launch Implementation ( from radial button or prompt after synthesis)


#------------------------------------------------------------------------------
# SIMULATION 64x64 image w/o AXI Interface
#------------------------------------------------------------------------------

Step #1.
# Create a root path;
# Example:
C:\design\<your_root_name>

Step #2.
# At your root create the following structure
/build
/coe
/constraints
/rtl_sim_wo_axi
/script
/waveforms
/verification

Step #3.

#Copy from git the following files ( and only the following files) to /rtl_sim_wo_axi

     av_minus_b_eng.vhd
     fft_engine_module_64_by_64.vhd
     fft_inbound_state_machine_controller_64_by_64.vhd
     fista_accel_top.vhd
     fista_accel_top_wrapper_v1_0.vhd
     front_end_module.vhd
     gen_proc_module.vhd
     h_h_start_mult_eng.vhd
     h_hstat_inbound_state_machine_controller.vhd
     inbound_flow_module_64_by_64.vhd
     init_state_machine_controller_64_by_64.vhd
     master_machine_controller.vhd
     mem_controller_64_by_64.vhd
     mem_in_buffer_module_64_by_64.vhd
     mem_st_machine_controller_64_by_64.vhd
     mem_transpose_module_64_by_64.vhd
     proto_mem_v3_0_S00_AXI.vhd
     update_eng.vhd
     tb_old_school_top.sv
     
Step #3A
     # Edit fista_accel_top.vhd
     # Here in code: Make this line : debug_capture_file_i => ONE_INTEGER
     u6 : entity work.mem_transpose_module
     GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	        debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	        g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	)
	
Step #4. 
     #Copy from git the following files ( and only the following files) to /coe
     point_source_vectors_64_by_64.coe
     read_addr_vectors_64_by_64.coe
     wr_addr_vectors_64_by_64.coe

Step #5.
     #Copy from git the following files ( and only the following files) to /script

     build_sim_64_by_64_wo_axi_mem_img_project.tcl
     create_sim_64_by_64_wo_axi_mem_img_ip.tcl
     
Step #6. 
     #Execute the command from a Windows file: 
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_sim_64_by_64_wo_axi_mem_img_project.tcl 
      
      
Step #7.
     #Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     
Step #8.
     Launch Simulation ( from radial button on GUI)    
 
 
Step #9. 
     Copy  fft_1d_256_by_256_memory.wcfg to /waveforms 
     Using radial buttons, File->Simulation Wavefoem-> Open Configuration( wavefrom above) 
     
Step #10.
     ( At tcl prompt) > restart
     > run all ( run to about 7 us)   
     

Step #11.
# Verification with MATLAB 
Copy folder fft_1d_64_by_64 to /verification
Open MATLAB 2024b(Could be earlier version)

Step #12
# Edit file convert_vectors_to_single_col_read.m
fft1dmemvectors  = importfile("C:\design\<your_root_name>\build\fa_ll_ip_test\fa_ll_ip_test.sim\sim_1\behav\xsim\MEM_TRANSPOSE_col_rd_mem_raw_fft_1d_float_vectors.txt",[1,Inf]);

Step #13A
Add new folder under /fft_1d_256_256; New folder /data

Step #13B 
Run: verify_1d_fft_float_col_read

Step #14.
Verify that figures are < 10E-7 error       
#------------------------------------------------------------------------------
# SIMULATION 256x256 image
#------------------------------------------------------------------------------

Step #1.
# Create a root path;
# Example:
C:\design\<your_root_name>

Step #2.
# At your root create the following structure
/build
/coe
/constraints
/rtl
/script
/waveforms
/verification

Step #3.

#Copy from git the following files ( and only the following files) to /rtl
     av_minus_b_eng.vhd
     fft_engine_module.vhd
     fft_inbound_state_machine_controller.vhd
     fista_accel_top.vhd
     fista_accel_top_wrapper_v1_0.vhd
     front_end_module.vhd
     gen_proc_module.vhd
     h_h_start_mult_eng.vhd
     h_hstat_inbound_state_machine_controller.vhd
     inbound_flow_module.vhd
     init_state_machine_controller.vhd
     master_machine_controller.vhd
     mem_controller.vhd
     mem_in_buffer_module.vhd
     mem_st_machine_controller.vhd
     mem_transpose_module.vhd
     proto_mem_v3_0_S00_AXI.vhd
     update_eng.vhd
     tb_old_school_top.sv

Step #3A
     # Edit fista_accel_top.vhd
     # Here in code: Make this line : debug_capture_file_i => ONE_INTEGER
     u6 : entity work.mem_transpose_module
     GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	        debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	        g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	)


Step #4. 
     #Copy from git the following files ( and only the following files) to /coe
     point_source_vectors.coe
     read_addr_vectors.coe
     wr_addr_vectors.coe

Step #5..
     #Copy from git the following files ( and only the following files) to /script

     build_sim_256_by_256_mem_img_project.tcl
     create_sim_256_by_256_mem_img_ip.tcl
     
     #Copy from git the following folder contents:
     /verification
     /waveforms
     

Step #6. 
     #Execute the command from a Windows file: 
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_sim_256_by_256_mem_img_project.tcl 
      
      
Step #7.
     #Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     
Step #8.
     Launch Simulation ( from radial button on GUI)
 
Step #9. 
     Copy  fft_1d_256_by_256_memory.wcfg to /waveforms 
     Using radial buttons, File->Simulation Wavefoem-> Open Configuration( wavefrom above) 
     
Step #10.
     ( At tcl prompt) > restart
     > run all ( run to about 7 ms)


Step #11.
# Verification with MATLAB 
Copy folder fft_1d_256_by_256 to /verification
Open MATLAB 2024b(Could be earlier version)

Step #12
# Edit file convert_vectors_to_single_col_read.m
fft1dmemvectors  = importfile("C:\design\<your_root_name>\build\fa_ll_ip_test\fa_ll_ip_test.sim\sim_1\behav\xsim\MEM_TRANSPOSE_col_rd_mem_raw_fft_1d_float_vectors.txt",[1,Inf]);

Step #13A
Add new folder under /fft_1d_256_256; New folder /data

Step #13B 
Run: verify_1d_fft_float_col_read

Step #14.
Verify that figures are < 10E-7 error

#------------------------------------------------------------------------------
# SIMULATION 64x64 image with AXI Interface ( Really means no Matlab and no generation of usable Sim Text )
#------------------------------------------------------------------------------

Step #1: 
Follow instructions for : SIMULATION 64x64 image w/o AXI Interface,
but name directory for rtl_sim_wo_axi to rtl_sim up to #10 
w/ exception #5
copy:
build_sim_64_by_64_mem_img_project.tcl
create_sim_64_by_64_mem_img_ip.tcl

& w/ exception #6
use command: 
C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_sim_64_by_64_mem_img_project.tcl 
     

Step #2:
Except ignore instructions 11-14

Step #3:
Substitute file  : mem_transpose_module_64_by_64_no_verify_use_w_axi_sim
for file : mem_transpose_module_64_by_64.vhd

Substitute file : tb_old_school_top_fft1d_test.sv 
for file: tb_old_school_top.sv

Step #4:
Verify first three read tranactions match expected values in Matlab( do not run full matlab)


#------------------------------------------------------------------------------
# SYNTHESIS & IMPLEMENTATION 64x64 image w/ AXI Interface
#------------------------------------------------------------------------------

Step #1:
Follow instructions for : SIMULATION 64x64 image w/o AXI Interface,
but name directory for rtl_syn

Step #1A:
Except ignore instructions 5-14

Step #2: 
Copy from git the following file:

build_syn_64_by_64_mem_img_project.tcl
create_syn_64_by_64_mem_img_ip.tcl
synth.tcl

Step #3: 
Remove file:
tb_old_school_top.sv

Step #4:
Substitute file  : mem_transpose_module_64_by_64_no_verify_use_w_axi_sim
for file : mem_transpose_module_64_by_64.vhd

Step #5:
Substitute file  : fft_engine_module_64_by_64_no_verify.vhd
for file : fft_engine_module_64_by_64.vhd


Step #6
Change Top level of fista_accel_top.vhd 
line:

From : 
u6 : entity work.mem_transpose_module
  GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
	
To: 
u6 : entity work.mem_transpose_module
  GENERIC MAP(
	    	debug_capture_file_i => ZERO_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
	
Step #7. 
     #Execute the command from a Windows file: 
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_syn_64_by_64_mem_img_project.tcl 
      
      
Step #8.
     #Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     

	
Step #9.
     Launch Synthesis ( from \script)
     source synth.tcl
     
Step #10.
     Launch Implementation ( from radial button or prompt after synthesis)


     





