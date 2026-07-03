# readme.txt
# rbd 
# 6/21/26


Step #1.
# Create a root path;
# Example:
C:\design\<your_root_name>

Step #2.
# At your root create the following structure
/build
/coe
/constraints
/ip_src
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
     mem_controller.vhd
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