# readme.txt
# rbd 
# 6/21/26

#------------------------------------------------------------------------------
# SYNTHESIS & IMPLEMENTATION 64x64 image
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
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\build_project.tcl  
      
      
Step #7.
     Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     
Step #8.
     Launch Synthesis ( from \script)
     source synth.tcl
     
Step #9.
     Launch Implementation ( from radial button or prompt after synthesis)


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

Step #5.
     #Copy from git the following files ( and only the following files) to /script

     build_sim_256_by_256_mem_img_project.tcl
     create_sim_256_by_256_mem_img_ip.tcl

Step #6. 
     #Execute the command from a Windows file: 
     C:\Xilinx_2022_2\Vivado\2022.2\bin\vivado.bat -mode batch -source C:\design\<your_root_name>\script\ build_sim_256_by_256_mem_img_project.tcl 
      
      
Step #7.
     #Open the vivado Project
     C:\design\<your_root_name>\build\fa_ip_test\fa_ll_ip_test.xpr
     
Step #8.
     Launch Simulation ( from radial button on GUI)
 
Step #9. 
     Copy  fft_1d_256_by_256_memory.wcfg to /waveforms  
     
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

Step #13 
Run: verify_1d_fft_float_col_read

Step #12.
Verify that figures are < 10E-7 error


     





