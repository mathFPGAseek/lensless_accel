------------------------------------------------
--        ,....,
--      ,:::::::
--     ,::/^\"``.
--    ,::/, `   e`.    
--   ,::; |        '.
--   ,::|  \___,-.  c)
--   ;::|     \   '-'
--   ;::|      \
--   ;::|   _.=`\     
--   `;:|.=` _.=`\
--     '|_.=`   __\
--     `\_..==`` /
--      .'.___.-'.
--     /          \
--    ('--......--')
--    /'--......--'\
--    `"--......--"`
--
-- Created By: RBD
-- filename: fista_accel_top.vhd
-- Initial Date: 9/23/23
-- Descr: Fista accel top 
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity fista_accel_top is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    dbg_master_mode_i                  : in std_logic_vector(4 downto 0);
  
    dbg_rdy_fr_init_and_inbound_i      : in std_logic; -- Equiv. to Almost full flag
    dbg_wait_fr_init_and_inbound_i     : in std_logic; -- Equiv. to Almost empty flag
  
    --fft signals
    dbg_fft_flow_tlast_i               : in std_logic; -- This is a multiple clock pulse when 
                                                 -- done writing to mem buffer by FFT state mach    
    dbg_mem_init_start_o               : out std_logic;
    
    -- AXI interface backend signals.
    axi_intf_sram_addr_int_debug_i   			     : in std_logic_vector( 15 downto 0); 
    axi_intf_sram_t1_mem_en_int_debug_i        : in std_logic;                       -- t1 mem
    axi_intf_sram_t1_mem_wr_en_vec_int_debug_i : in std_logic_vector( 0 downto 0);
    	
    axi_intf_stop_dec_debug_i     : in std_logic_vector(3 downto 0);    -- When to stop processing
    axi_intf_command_debug_i      : in std_logic;                        -- switch to debug for muxes.
    
    axi_intf_start_1_debug_i      : in std_logic;
    axi_intf_start_2_debug_i      : in std_logic;
    
    axi_intf_restart_debug_i      : in std_logic;
    
    axi_intf_data_in_i            : in std_logic_vector(79 downto 0);
    axi_intf_data_out_o           : out std_logic_vector(79 downto 0);
    
    axi_intf_stop_debug_o         : out std_logic := '0';
    
    
    
    -- app interface to ddr controller
    app_rdy_i           	: in std_logic;
    app_wdf_rdy_i       	: in std_logic;
    app_rd_data_valid_i   : in std_logic_vector( 0 downto 0);
    add_rd_data_i         : in std_logic_vector(511 downto 0);
    app_cmd_o             : out std_logic_vector(2 downto 0);
    app_addr_o            : out std_logic_vector(28 downto 0);
    app_en_o              : out std_logic;
    app_wdf_mask_o        : out std_logic_vector(63 downto 0);
    app_wdf_data_o        : out std_logic_vector(511 downto 0);
    app_wdf_end_o         : out std_logic;
    app_wdf_wren_o        : out std_logic;
   	
    -- mux control to ddr memory controller.
    dbg_ddr_intf_mux_wr_sel_o     : out std_logic_vector(1 downto 0);
    dbg_ddr_intf_demux_rd_sel_o   : out std_logic_vector(2 downto 0);
    dbg_mem_shared_in_enb_o       : out std_logic;
    dbg_mem_shared_in_addb_o      : out std_logic_vector(7 downto 0);

    -- mux control to front and Backend modules  
    dbg_front_end_demux_fr_fista_o   : out std_logic;
    dbg_front_end_mux_to_fft_o       : out std_logic_vector(1 downto 0);
    dbg_back_end_demux_fr_fh_mem_o   : out std_logic;
    dbg_back_end_demux_fr_fv_mem_o   : out std_logic;
    dbg_back_end_mux_to_front_end_o  : out std_logic;

    -- rd,wr control to F*(H) F(H) FIFO 
    dbg_f_h_fifo_wr_en_o             : out std_logic;
    dbg_f_h_fifo_rd_en_o             : out std_logic;
    dbg_f_h_fifo_full_i              : in std_logic;
    dbg_f_h_fifo_empty_i             : in std_logic;
 
    -- rd,wr control to F(V) FIFO
    dbg_f_v_fifo_wr_en_o             : out std_logic;
    dbg_f_v_fifo_rd_en_o             : out std_logic;
    dbg_f_v_fifo_full_i              : in std_logic;
    dbg_f_v_fifo_empty_i             : in std_logic;
 
    --  rd,wr control to Fdbk FIFO
    dbg_fdbk_fifo_wr_en_o             : out std_logic;
    dbg_fdbk_fifo_rd_en_o             : out std_logic;
    dbg_fdbk_fifo_full_i              : in std_logic;
    dbg_fdbk_fifo_empty_i             : in std_logic;
    
    -- output control
    fista_accel_valid_rd_o            : out std_logic

    );
    
end fista_accel_top;

architecture struct of fista_accel_top is  
  -- signals 
  
  signal dbg_mem_init_start_int                : std_logic; 
  signal init_data                             : std_logic_vector(79 downto 0);
  signal init_valid_data                       : std_logic;
                                              
  signal to_fft_data_int                       : std_logic_vector(79 downto 0);
  signal fista_accel_data_int                  : std_logic_vector(79 downto 0);
  	                                          
  signal to_fft_valid_int                      : std_logic;
  signal fista_accel_valid_int                 : std_logic;
                                              
  signal stall_warning_int                     : std_logic;--: out std_logic;
                                              
  signal dual_port_wr_int                      : std_logic_vector(0 downto 0);--: out std_logic;  
  signal dual_port_addr_int                    : std_logic_vector(16 downto 0);--: out std_logic_vector(16 downto 0);
  signal dual_port_data_int                    : std_logic_vector(79 downto 0);--: out std_logic_vector(79 downto 0)
                                              
  signal fft_rdy_int                           : std_logic;
                                              
  signal dbg_mem_shared_in_enb_int             : std_logic;
  signal dbg_mem_shared_in_addb_int            : std_logic_vector(7 downto 0);
  signal data_to_mem_intf_fr_mem_in_buffer     : std_logic_vector(79 downto 0);
  signal data_to_mem_intf_fr_mem_in_buffer_after_debug_mux : std_logic_vector(79 downto 0);
  	                                          
  signal turnaround_int                        : std_logic;
                                              
  signal master_mode_int                       : std_logic_vector(4 downto 0);
  signal master_mode_upper_bits_int            : std_logic_vector(4 downto 1); 
                                              
  signal dummy_input_1                         : std_logic := '1';
  signal dummy_input_2                         : std_logic := '1';
  signal dummy_input_3                         : std_logic_vector(0 downto 0) := (others=> '0');
  	
  --signal sram_t1_mem_addr_int_mux_select       : std_logic_vector(15 downto 0);
  --signal sram_t1_mem_wr_en_vec_int_mux_select  : std_logic_vector(0 downto 0);
  --signal sram_t1_mem_en_int_mux_select         : std_logic;
  		                                        
  signal sram_wr_en_vec_int                    : std_logic_vector(0 downto 0);
  signal sram_wr_en_int                        : std_logic;
  signal sram_en_int                           : std_logic;
  signal sram_addr_int                         : std_logic_vector(15 downto 0);
  signal data_fr_mem_intf_to_sys               : std_logic_vector(79 downto 0);
  signal valid_fr_mem_intf_to_sys              : std_logic;
  --signal data_fr_mem_intf_to_gen_proc          : std_logic_vector(79 downto 0);
  --signal valid_fr_mem_intf_to_gen_proc         : std_logic;
  signal data_fr_big_h_mem_to_gen_proc         : std_logic_vector(79 downto 0);
  signal valid_fr_big_h_mem_to_gen_proc        : std_logic;
  
  
  signal ena_to_buffer                         : std_logic;
  signal wea_to_buffer                         : std_logic_vector(0  downto 0);         
  signal addr_to_buffer                        : std_logic_vector(7  downto 0);
  signal data_to_buffer                        : std_logic_vector(79 downto 0);
  
  signal to_buffer_trans_mem_port_wr_int       : std_logic_vector(0  downto 0);
  signal to_buffer_trans_mem_port_addr_int     : std_logic_vector(16  downto 0);
  signal to_buffer_trans_mem_port_data_int     : std_logic_vector(79 downto 0);
  	
  signal done_signal_from_h_h_mult_int         : std_logic;
  
  signal stop_fft1d_dbg_int									   : std_logic;                                                               
  signal stop_fft2d_dbg_int									   : std_logic;                                                                
  signal stop_h_dbg_int					               : std_logic;                                                                      
  signal stop_inv_fft1d_h_dbg_int              : std_logic;                                                           
  signal stop_inv_fft2d_h_dbg_int              : std_logic;                                                           
  signal stop_pad_crop_sub_b_dbg_int           : std_logic;                                                        
  signal stop_fft1d_pad_dbg_int                : std_logic;                                                             
  signal stop_fft2d_pad_dbg_int                : std_logic;                                                             
  signal stop_h_adj_dbg_int                    : std_logic;                                                                 
  signal stop_inv_fft1d_h_adj_dbg_int          : std_logic;                                                       
  signal stop_inv_fft2d_h_adj_dbg_int          : std_logic;                                                       
  signal stop_grad_update_dbg_int              : std_logic;                                                           
  signal mem_1_addr_mux_control_int            : std_logic_vector( 1 downto 0);                                                    
  signal mem_1_ctrl_mux_control_int            : std_logic_vector( 1 downto 0);                                                   
  signal mem_2_addr_mux_control_int            : std_logic_vector( 1 downto 0);                                                  
  signal mem_2_ctrl_mux_control_int            : std_logic_vector( 1 downto 0);

  	
  -- debug signals : All signals go to mem,gen_proc, and master
                  -- DEBUG_STATE 
                  -- := 001 -> DEBUG H      -> {load H, Load F(v)}      : trans  & f_h memory
                  -- := 010 -> DEBUG Inv A  -> {Load (H x F(v))}        : trans memory  
                  -- := 011 -> DEBUG Av-B   -> {Load Av, Load B}        : trans & b memory
                  -- := 100 -> DEBUG AH     -> {Load crop&pad(AV-b)}    : trans memory
                  -- := 101 -> DEBUG H*     -> {Load H* , Load FH(v))}  : trans & f_adj memory
                  -- := 110 -> DEBUG InvAH  -> {Load (H* x FH(v))}      : trans memory
                  -- := 111 -> DEBUG update -> {Load Grad, Vk}          : trans & vk memory
 --
 -------------------------------------------------------------------------------------------------------------
 -- -- := 001 -> DEBUG H      -> {load H, Load F(v)}      : trans  & f_h memory
 -- debug scenario: Rd F(H) / No writes                               Settings
 -------------------------------------------------------------------------------------------------------------
 -- only verify Read col reads out of transpose memory after 2d FFT
 -- Also, we do not want to enable writes
 --                                                                   All modules :
 --                                                      							g_USE_DEBUG_H_INIT_i = 1
 --                 
 --                                                                   u6 : entity work.mem_transpose_module
 -- 	                                                                debug_state_i  =>  ZERO_INTEGER,
 --
 -------------------------------------------------------------------------------------------------------------
 --  Master mode decode:.
 --  "00000" => -- 1d fft
 --  "00001" => -- 2d fft
 --  "00010" => -- H*proc
 --  "00011" => -- H proc
 --  "00100" => -- 1d ifft
 --  "00101" => -- 2d ifft 
 --  "00110" => -- Av-b( pad and crop optional?)
 --  "00111" => -- update  
  	
  			                                                                                                                            
 
  signal   event_to_mem                    : std_logic;                
  constant DEBUG_STATE                     : std_logic_vector(2 downto 0) := "001"; -- DEBUG H
  	
  	
  signal dbg_rd_r                          : std_logic_vector(511 downto 0);             
  	
  constant DATA_512_MINUS_80               : std_logic_vector(431 downto 0) := (others => '0');
  constant DATA_512_ZEROS                  : std_logic_vector(511 downto 0) := (others => '0');
  
  constant ZERO                            : natural := 0;	
  constant ONE                             : natural := 1; -- for selecting  ONE = use debug
  constant TWO                             : natural := 2;
  
  constant ZERO_INTEGER                    : integer := 0;
  constant ONE_INTEGER                     : integer := 1;
  
  constant ZERO_VECTOR                     : std_logic_vector(0 downto 0) := (others => '0');
  
  constant g_USE_DEBUG_MODE_i              : natural := 0; 
                                           --: natural := 1; -- Changed this to try and synth on 9/1/25 back to zero
                                           -- otherwise 0.
  																		     -- set to 1 for H,H* sim debug; ( 2 RO Mems)
  																				 -- set to 2 for FFT/IFFT sim debug;( 1 RO Mem)
  																				 -- set to 3 for Av-b sim debug;(2 RO Mems)
  																				 -- set to 4 for Update sim debug;( 1R & 1W Mem))
  
  signal dbg_qualify_state_verify_rd       : std_logic_vector(2 downto 0);
  	
  attribute keep_hierarchy : string;
  attribute dont_touch     : string;

  attribute keep_hierarchy of u4 : label is "yes";
  attribute dont_touch     of u4 : label is "yes";
  
  -- Test Signals: p00a, p00b, p01
  signal enable_test_sram_t1_mem_en_int_mux_select        : std_logic;
  signal enable_test_sram_t1_mem_wr_en_vec_int_mux_select : std_logic_vector(0 downto 0);
  signal sram_t1_mem_en_int_mux_select                    : std_logic;
  signal sram_t1_mem_wr_en_vec_int_mux_select             : std_logic_vector(0 downto 0); 
  signal sram_t1_mem_en_int_mux_select_r                  : std_logic;
  signal sram_t1_mem_wr_en_vec_int_mux_select_r           : std_logic_vector(0 downto 0); 
  	
  	
  -- Support for PS bus and debugging
  
  
  -- Mux select data out to axi
  --in
  signal data_fr_mem_2_intf_to_gen_proc                   : std_logic_vector(79 downto 0);
  	
  -- Mux select data out to reg from  mem1 and mem(fft2d) : p02
  --select
  
  
  -- in
  signal data_fr_test_mem_intf_to_gen_proc                : std_logic_vector(79 downto 0);
  signal data_fr_mem_intf_to_gen_proc                     : std_logic_vector(79 downto 0);
  --
  -- out
  signal data_fr_mem_1                                    : std_logic_vector(79 downto 0);
  	
  -- register data and valids after mux selection from mem1 and mem(fft2d) : p02a
  -- in
  -- data_fr_mem_1 ,valid_fr_mem_1
  -- out
  -- data_fr_mem_1_r ,valid_fr_mem_1_r
  	
  	
  -- Mux select valid out to reg from mem1 and mem(fft2d) : p03
  -- select 
  -- stop_fft2d_dbg_int or valid_fr_test_mem_intf_to_gen_proc
  -- or valid_fr_mem_intf_to_gen_proc
  --
  -- in 
  signal valid_fr_mem_intf_to_gen_proc                    : std_logic;
  signal valid_fr_test_mem_intf_to_gen_proc               : std_logic;
  --
  -- out
  signal valid_fr_mem_1                                   : std_logic;
  
  
  
  -- Mux select data out to gen proc :p04
  -- select
  -- data_fr_mem_1_r or master_mode_int
  --
  -- in
  signal data_fr_mem_1_r                                  : std_logic_vector(79 downto 0);
  --
  -- out	
  signal data_fr_mem_intf_to_gen_proc_after_mux           : std_logic_vector(79 downto 0);
  	
  
  -- Mux select  valid out to gen proc : p05
  -- select
  -- valid_fr_mem_1_r or master_mode_int
  --
  -- in
  signal valid_fr_mem_1_r                                 : std_logic;
  --
  -- out
  signal valid_fr_mem_intf_to_gen_proc_after_mux          : std_logic;
  
  -- reg for sram t1 addr into memory 1 : p06
  --
  -- in //???? start here 
  signal sram_t1_mem_addr_int_mux_select                  : std_logic_vector( 15 downto 0);
  --
  -- out 
  signal sram_t1_mem_addr_int_mux_select_r                : std_logic_vector( 15 downto 0);
  
  -- Mux select what memory addr to PS FIFO : p07
  --
  -- select is master_mode_int
  --
  -- in sram_t1_mem_addr_int_mux_select_r
  -- is sram_t1_mem_addr_int_mux_select_r
  --
  -- out
  signal  sram_mem_addr_for_fifo                          : std_logic_vector( 15 downto 0);
  	
  -- reg for sram t1 addr into memory 1 : p08
  --
  -- in IS sram_mem_addr_for_fifo
  --
  -- out 
  signal sram_mem_addr_for_fifo_r                         : std_logic_vector( 15 downto 0);	
  	
  -- fifo for PS addr : p09
  -- signals  ARE : { sram_mem_addr_for_fifo_r,
  -- valid_fr_mem_intf_to_gen_proc_after_mux
  signal rd_en_fr_ps_controller                           : std_logic;
  signal addr_to_mem_1_and_2_fr_fifo                      : std_logic_vector( 15 downto 0);
  signal fifo_full                                        : std_logic;
  
  -- PS state machine : p10
  signal rd_addr_fr_ps_controller                         : std_logic_vector( 7 downto 0);
  
  -- Mux to buffer select PS control or Mem controller : p11
  -- signals specified in other locations
  -- select IS master_mode_int
  --in
  signal  dbg_mem_shared_in_enb_fr_mem_cont_int           : std_logic;
  signal 	dbg_mem_shared_in_addb_fr_mem_cont_int          : std_logic_vector( 7 downto 0);
  
  -- Mux into transpose memory #2 for addr : p12
  -- signals specified in other locations	
  -- out
  signal  sram_t2_mem_addr_int_mux_select                 : std_logic_vector( 15 downto 0);
  
  -- Mux into transpose memory #2 for ctrl : p13
  -- select  IS mem_2_ctrl_mux_control_int
  -- in specified in other locations except for. 
  signal sram_en_fr_ps_int                                : std_logic;
  signal sram_wr_en_vec_fr_ps_int                         : std_logic_vector( 0 downto 0);
  -- out specified in other locaions
  signal sram_t2_mem_en_int_mux_select                    : std_logic;
  signal sram_t2_mem_wr_en_vec_int_mux_select             : std_logic_vector( 0 downto 0);
  
  -- Mux into mem #2 Transpose
  -- select and in specified in other locaions
  --out
  signal data_to_mem_2_intf_fr_mem_in_buffer_after_debug_mux : std_logic_vector( 79 downto 0);
  	
  -- Mem transpose 2 :
  signal valid_fr_mem_2_intf_to_gen_proc                  : std_logic;
  signal dbg_qualify_state_verify_mem_2_rd                : std_logic_vector( 2 downto 0); 
 
  
begin
  
   
   
   
   
   
    
    -----------------------------------------
    -- Memory Controller 
    -----------------------------------------	.
    
    u0 : entity work.mem_controller
    GENERIC MAP (
    	           g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
    )
    PORT MAP(
    	
    	  clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                      => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => master_mode_int, --: in std_logic_vector(4 downto 0);
        
        -- start signals                                         
        --rdy_fr_init_and_inbound_i                   => dbg_rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost full flag
        --wait_fr_init_and_inbound_i                  => dbg_wait_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost empty flag
        
        rdy_fr_init_and_inbound_i                   => axi_intf_start_1_debug_i, --: in std_logic; -- Equiv. to Almost full flag  
        wait_fr_init_and_inbound_i                  => axi_intf_start_2_debug_i, --: in std_logic; -- Equiv. to Almost empty flag 
                                                   
        --fft signals                              
        fft_flow_tlast_i                            => dbg_fft_flow_tlast_i,--: in std_logic; -- This is a multiple clock pulse when 
                                                                  -- done writing to mem buffer by FFT state mach
                                                    
        mem_init_start_o                            => dbg_mem_init_start_int,--: out std_logic;
                                                    
        -- app interface to ddr controller.             
        app_rdy_i           	                      => dummy_input_1,     --: in std_logic;
        app_wdf_rdy_i       	                      => dummy_input_2, --: in std_logic;
        app_rd_data_valid_i                         => dummy_input_3, --: in std_logic_vector( 0 downto 0);
        app_cmd_o                                   => dbg_qualify_state_verify_rd, --: out std_logic_vector(2 downto 0);
        app_addr_o                                  => sram_addr_int, --: out std_logic_vector(28 downto 0);
        app_en_o                                    => sram_en_int, --: out std_logic;
        app_wdf_mask_o                              => OPEN, --: out std_logic_vector(63 downto 0);
                                             
        app_wdf_end_o                               => OPEN, --: out std_logic;
        app_wdf_wren_o                              => sram_wr_en_int, --: out std_logic;
                                             
        	                                  
        -- mux control to ddr memory controller.      
        ddr_intf_mux_wr_sel_o                       => dbg_ddr_intf_mux_wr_sel_o, --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o                     => dbg_ddr_intf_demux_rd_sel_o, --: out std_logic_vector(2 downto 0);
        
        --mem_shared_in_ch_state_i                    => dual_port_wr_int(0),
        mem_shared_in_ch_state_i                    => event_to_mem,                                         
                                         
        mem_shared_in_enb_o                         => dbg_mem_shared_in_enb_fr_mem_cont_int, --: out std_logic;
        mem_shared_in_addb_o                        => dbg_mem_shared_in_addb_fr_mem_cont_int, --: out std_logic_vector(7 downto 0);
                                                  
        -- mux control to front and Backend modules  
        front_end_demux_fr_fista_o                  => dbg_front_end_demux_fr_fista_o, --: out std_logic;
        front_end_mux_to_fft_o                      => dbg_front_end_mux_to_fft_o, --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o                  => dbg_back_end_demux_fr_fh_mem_o , --: out std_logic;
        back_end_demux_fr_fv_mem_o                  => dbg_back_end_demux_fr_fv_mem_o, --: out std_logic;
        back_end_mux_to_front_end_o                 => dbg_back_end_mux_to_front_end_o, --: out std_logic;
                                                    
        -- rd,wr control to F*(H) F(H) FIFO        
        f_h_fifo_wr_en_o                            => dbg_f_h_fifo_wr_en_o, --: out std_logic;
        f_h_fifo_rd_en_o                            => dbg_f_h_fifo_rd_en_o, --: out std_logic;
        f_h_fifo_full_i                             => dbg_f_h_fifo_full_i, --: in std_logic;
        f_h_fifo_empty_i                            => dbg_f_h_fifo_empty_i, --: in std_logic;
                                                 
        -- rd,wr control to F(V) FIFO             
        f_v_fifo_wr_en_o                            => dbg_f_v_fifo_wr_en_o, --: out std_logic;
        f_v_fifo_rd_en_o                            => dbg_f_v_fifo_rd_en_o, --: out std_logic;
        f_v_fifo_full_i                             => dbg_f_v_fifo_full_i, --: in std_logic;
        f_v_fifo_empty_i                            => dbg_f_v_fifo_empty_i, --: in std_logic;
                                                      
        --  rd,wr control to Fdbk FIFO           
        fdbk_fifo_wr_en_o                           => dbg_fdbk_fifo_wr_en_o, --: out std_logic;
        fdbk_fifo_rd_en_o                           => dbg_fdbk_fifo_rd_en_o, --: out std_logic;
        fdbk_fifo_full_i                            => dbg_fdbk_fifo_full_i, --: in std_logic;
        fdbk_fifo_empty_i                           => dbg_fdbk_fifo_empty_i, --: in std_logic;
        
        axi_intf_restart_debug_i                    => axi_intf_restart_debug_i,
        axi_intf_stop_debug_o                       => axi_intf_stop_debug_o,
        
        stop_fft1d_dbg_i                            => stop_fft1d_dbg_int,
        stop_fft2d_dbg_i                            => stop_fft2d_dbg_int,
                                                
        -- output control                      
        fista_accel_valid_rd_o                      => fista_accel_valid_rd_o,--: out std_logic
        
        -- turnaround signal
        turnaround_o                                => turnaround_int
    	                                              
    );
    
 --app_wdf_data_o <= (others=>'0');       --: out std_logic_vector(511 downto 0);.
   app_wdf_data_o <= DATA_512_MINUS_80 & data_to_mem_intf_fr_mem_in_buffer;
   app_wdf_data_o <= DATA_512_ZEROS;
    -----------------------------------------
    --  init_and_inbound flow
    -----------------------------------------	
    u1 :  entity  work.inbound_flow_module 
--generic(
--	    generic_i  : in natural);
    GENERIC MAP(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug
	      g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i
	  )-- 0 = no debug , 1 = debug

    PORT MAP (

        clk_i               	            =>   clk_i , --: in std_logic;
        rst_i               	            =>   rst_i , --: in std_logic;
                                    
        master_mode_i                     =>   dbg_master_mode_i, --: in std_logic_vector(4 downto 0);
        mem_init_start_i                  =>   dbg_mem_init_start_int, --: in std_logic; 
        
        fft_rdy_i                         =>   fft_rdy_int,
                                     
        -- Data to front end module      
        init_data_o                       =>   init_data,--: out std_logic_vector(79 downto 0)
        init_valid_data_o                 =>   init_valid_data
                                      
     );
    

    
    -----------------------------------------
    --  front_end
    -----------------------------------------	
    
    u2 : entity work.front_end_module 
--generic(
--	    generic_i  : in natural);
    PORT MAP (                    
                              
	  clk_i               	      =>   clk_i, --: in std_logic;
    rst_i               	      =>   rst_i, --: in std_logic;
                               
    --master_mode_i                 =>   dbg_master_mode_i, --: in std_logic_vector(4 downto 0);
    master_mode_i                 =>   master_mode_int, --: in std_logic_vector(4 downto 0);

                             
    fr_init_data_i                =>   init_data, --: in std_logic_vector(79 downto 0);
    fr_back_end_data_i            =>   (others=> '0'), --: in std_logic_vector(79 downto 0);
    fr_back_end_data2_i           =>   (others=> '0'), --: in std_logic_vector(79 downto 0);
    fr_fista_data_i               =>   (others=> '0'), --: in std_logic_vector(79 downto 0);
    fr_fd_back_fifo_data_i        =>   data_fr_mem_intf_to_sys, --: in std_logic_vector(79 downto 0);
                               
    fr_init_data_valid_i          =>   init_valid_data, --: in std_logic;	
    fr_back_end_valid_i           =>   '0', --: in std_logic;
    fr_back_end_valid2_i          =>   '0', --: in std_logic;
    fr_fista_valid_i              =>   '0', --: in std_logic;
    fr_fd_back_fifo_valid_i       =>   valid_fr_mem_intf_to_sys, --: in std_logic;
                                
  	                          
    -- Data to front end module  
    to_fft_data_o                 =>   to_fft_data_int, --: out std_logic_vector(79 downto 0);
    fista_accel_data_o            =>   fista_accel_data_int, --: out std_logic_vector(79 downto 0);
    	                          
    to_fft_valid_o                =>   to_fft_valid_int, --: out std_logic;
    fista_accel_valid_o           =>   fista_accel_valid_int --: out std_logic;
                                
    ); 
    
    -----------------------------------------
    --  fft engine
    -----------------------------------------
    u3 : entity work.fft_engine_module 
    GENERIC MAP(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug , 2 = float
	    --g_USE_DEBUG_i  =>  ZERO
	    	g_USE_DEBUG_i  =>  TWO, -- 2 = use float
	    	g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i 


	  ) -- 0 = no debug , 1 = debug
	  --    g_USE_DEBUG_H_INIT_i  =>  ZERO) -- 0 = no debug , 1 = debug

    PORT MAP (                      
                                    
	  clk_i               	     =>    clk_i,--: in std_logic;
    rst_i               	     =>    rst_i,--: in std_logic;
                                    
    --master_mode_i              =>    dbg_master_mode_i ,--: in std_logic_vector(4 downto 0);
  	master_mode_i              =>   master_mode_int, --: in std_logic_vector(4 downto 0);
                                
    -- Input Data to front end      
    init_valid_data_i          =>    to_fft_valid_int,--: in std_logic;
    init_data_i                =>    to_fft_data_int,--: in std_logic_vector(79 downto 0);    
    stall_warning_o            =>    stall_warning_int,--: out std_logic;
                                    
    dual_port_wr_o             =>    dual_port_wr_int(0),--: out std_logic;  
    dual_port_addr_o           =>    dual_port_addr_int,--: out std_logic_vector(16 downto 0);
    dual_port_data_o           =>    dual_port_data_int,--: out std_logic_vector(79 downto 0)
    
    fft_rdy_o                  =>    fft_rdy_int                                 
    );
                             
   
    
    -----------------------------------------
    --  mem_in_buffer
    -----------------------------------------.	
    u4 : entity work.mem_in_buffer_module
    GENERIC MAP(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug
	      --debug_state_i  =>  ZERO
	  g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i -- 0 = no debug , 1 = debug

	  ) -- 0 = no debug , 1 = debug 
    PORT MAP( 
    clk_i                     =>     clk_i,             --: in STD_LOGIC;
    rst_i               	    =>     rst_i,--: in std_logic;
    --ena                       =>     dual_port_wr_int(0),  --: in STD_LOGIC;
    --wea                       =>     dual_port_wr_int,--: in STD_LOGIC_VECTOR ( 0 to 0 );
    --addra                     =>     dual_port_addr_int(7 downto 0),--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    --dina                      =>     dual_port_data_int,--: in STD_LOGIC_VECTOR ( 79 downto 0 );
    
    ena                       =>     ena_to_buffer,  --: in STD_LOGIC;
    wea                       =>     wea_to_buffer,--: in STD_LOGIC_VECTOR ( 0 to 0 );
    addra                     =>     addr_to_buffer,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    dina                      =>     data_to_buffer,--: in STD_LOGIC_VECTOR ( 79 downto 0 );
   
    clkb                      =>     clk_i,--: in STD_LOGIC;
    enb                       =>     dbg_mem_shared_in_enb_int,--: in STD_LOGIC;
    addrb                     =>     dbg_mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    doutb                     =>     data_to_mem_intf_fr_mem_in_buffer--: out STD_LOGIC_VECTOR ( 79 downto 0 )
  );
                            
    -----------------------------------------
    --  master_controller
    -----------------------------------------	

    
    u5 : entity work.master_st_machine_controller  
    GENERIC MAP(
    	          g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i -- 0 = no debug , 1 = debug
	
    )       
    PORT MAP(                                
    	                                   
    	  clk_i                            => clk_i,--: in std_logic; --clk_i, --: in std_logic;
        rst_i               	           => rst_i,--: in std_logic; --rst_i, --: in std_logic;
                                           
        command_dbg_i          			     => axi_intf_command_debug_i,--: in std_logic;
                                        
        stop_dec_dbg_i                   => axi_intf_stop_dec_debug_i, --: in std_logic_vector( 3 downto 0);
                                        
        turnaround_i           			     => turnaround_int,--: in std_logic;
                                         
        stop_fft1d_dbg_o      	  	     => stop_fft1d_dbg_int,--: out std_logic;
                                        
        stop_fft2d_dbg_o       			     => stop_fft2d_dbg_int,--: out std_logic;
                                         
        stop_h_dbg_o           			     => stop_h_dbg_int,--: out std_logic;
                                         
        stop_inv_fft1d_h_dbg_o 			     => stop_inv_fft1d_h_dbg_int,--: out std_logic;
                                         
        stop_inv_fft2d_h_dbg_o 			     => stop_inv_fft2d_h_dbg_int,--: out std_logic;
                                        
        stop_pad_crop_sub_b_dbg_o 	     => stop_pad_crop_sub_b_dbg_int,--: out std_logic;
                                         
        stop_fft1d_pad_dbg_o      	     => stop_fft1d_pad_dbg_int,--: out std_logic;
                                        
        stop_fft2d_pad_dbg_o      	     => stop_fft2d_pad_dbg_int,--: out std_logic;
                                        
        stop_h_adj_dbg_o          	     => stop_h_adj_dbg_int,--: out std_logic;
                                        
        stop_inv_fft1d_h_adj_dbg_o	     => stop_inv_fft1d_h_adj_dbg_int,--: out std_logic;
                                        
        stop_inv_fft2d_h_adj_dbg_o       => stop_inv_fft2d_h_adj_dbg_int,--: out std_logic;
                                        
        stop_grad_update_dbg_o           => stop_grad_update_dbg_int,--: out std_logic;
                                         
        mem_1_addr_mux_control_o         => mem_1_addr_mux_control_int,--: out std_logic_vector( 1 downto 0);
                                        
        mem_1_ctrl_mux_control_o         => mem_1_ctrl_mux_control_int,--: out std_logic_vector( 1 downto 0);
                                        
        mem_2_addr_mux_control_o         => mem_2_addr_mux_control_int, --: out std_logic_vector( 1 downto 0);
                                        
        mem_2_ctrl_mux_control_o         => mem_2_ctrl_mux_control_int,--: out std_logic_vector( 1 downto 0);
       
        
                                                                                                
                               
        master_mode_o                    => master_mode_int--: out std_logic_vector( 4 downto 0)
                                       
    );
    
    -- ?? Need to add mux for debug select to
    -- either allow mc bus to go thru or the mc_state = "11110" mto 
    -- select the debug control over memories
    
    --?? Need to add a mux for data bus 
    
    -----------------------------------------
  -- Mux Data In  Memory #1
  -----------------------------------------	
  
  mux_data_in_from_axi_intf_mem_1 : process(    axi_intf_command_debug_i,
    	                                    axi_intf_data_in_i,
    	                                    data_to_mem_intf_fr_mem_in_buffer)
    
    begin 
    	
    	case axi_intf_command_debug_i is
    	
    		when '0' => -- Normal Data FLow
    			data_to_mem_intf_fr_mem_in_buffer_after_debug_mux 		<= data_to_mem_intf_fr_mem_in_buffer;
    			
    		when '1' => -- Debug Data In
    		  data_to_mem_intf_fr_mem_in_buffer_after_debug_mux			 <= axi_intf_data_in_i;		
    		
    		-- DEBUGGER THEORY of OPERATION: 
    		--when "11110" => -- debug mode THere is not a debug MASTER MODE , correct???
    		-- Master Mode just tells us where we are at in process; Then the debugger
    		-- will halt processing as we interrogate memory and then restart, that is the idea
    		-- behind debugging
           
    		
    		when others =>
    			data_to_mem_intf_fr_mem_in_buffer_after_debug_mux			 <= (others => '0');
    			
      end case;
    end process mux_data_in_from_axi_intf_mem_1;
   
    
    -----------------------------------------
    -- Muxes into Tranpose Memory #1
    -----------------------------------------
    mux_to_addr_trans_mem_1 : process(--master_mode_int,
    	                                mem_1_addr_mux_control_int,
    	                                sram_addr_int,
    	                                axi_intf_sram_addr_int_debug_i)
    
    begin 
    	
    	case mem_1_addr_mux_control_int is
    	
    		when "00" => -- From Mem Controller
    			sram_t1_mem_addr_int_mux_select <= sram_addr_int;
    		
    		when "01" => -- From Perp Controller ; Not designed yet ??
    			sram_t1_mem_addr_int_mux_select <= (others => '0');
    		
    		when "10" => -- debug mode
    			sram_t1_mem_addr_int_mux_select <= axi_intf_sram_addr_int_debug_i;
    			
    		when "11" => -- null mode
    			sram_t1_mem_addr_int_mux_select <= (others => '0');
    		
    		
    		when others =>
    			sram_t1_mem_addr_int_mux_select <= (others=> '0');
    			
      end case;
    end process mux_to_addr_trans_mem_1;
    
    
    
    mux_to_control_trans_mem_1 : process(--master_mode_int,
    	                                   mem_1_ctrl_mux_control_int,
    	                                   sram_en_int,
    	                                   sram_wr_en_vec_int,
    	                                   axi_intf_sram_t1_mem_en_int_debug_i,
    	                                   axi_intf_sram_t1_mem_wr_en_vec_int_debug_i)
    
    begin 
    	
    	case mem_1_ctrl_mux_control_int is
    	
    		when "00" => -- From Mem Controller
    			sram_t1_mem_en_int_mux_select 			 <= sram_en_int;        --Note: For Fwd 1-d 2-d fft
    			sram_t1_mem_wr_en_vec_int_mux_select <= sram_wr_en_vec_int;
    			
    		when "01" => -- From Perp Controller
    			sram_t1_mem_en_int_mux_select 			 <= '0';       
    			sram_t1_mem_wr_en_vec_int_mux_select <= (others => '0');  		
    		
    		when "10" => -- debug mode
    			sram_t1_mem_en_int_mux_select        <= axi_intf_sram_t1_mem_en_int_debug_i;
    		  sram_t1_mem_wr_en_vec_int_mux_select <= axi_intf_sram_t1_mem_wr_en_vec_int_debug_i;
    		  
    		when "11" => -- null mode
    			sram_t1_mem_en_int_mux_select        <= '0';
    		  sram_t1_mem_wr_en_vec_int_mux_select <= (others => '0');
    		
    		when others =>
    			sram_t1_mem_en_int_mux_select <= '0';
    			sram_t1_mem_wr_en_vec_int_mux_select <= (others=> '0');
    			
      end case;
    end process mux_to_control_trans_mem_1;
    		
    		
    		
    
     
    -----------------------------------------
    -- Transpose mem_intf Memory #1
    -----------------------------------------	
  sram_wr_en_vec_int(0) <= sram_wr_en_int;

  	  	
  u6 : entity work.mem_transpose_module
  GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
 
  PORT MAP ( 
  clk_i => clk_i,
  rst_i => rst_i,                                        --clka : in STD_LOGIC;
  master_mode_i =>   master_mode_int,                    --: in std_logic_vector(4 downto 0);
  ena   => sram_t1_mem_en_int_mux_select,                       --ena : in STD_LOGIC;
  wea   => sram_t1_mem_wr_en_vec_int_mux_select,                --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => sram_t1_mem_addr_int_mux_select,                     --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => data_to_mem_intf_fr_mem_in_buffer_after_debug_mux,            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_fr_mem_intf_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  vouta => valid_fr_mem_intf_to_gen_proc,
  dbg_qualify_state_i => dbg_qualify_state_verify_rd(0)
  );
  
    -----------------------------------------
    -- Test Transpose mem_intf with 1D FFT image
    -----------------------------------------.
  sram_wr_en_vec_int(0) <= sram_wr_en_int;

  u6_test_1dfft_p01 : entity work.mem1_test_module_fwd_fft2d_src_image
  GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
 
  PORT MAP ( 
  clk_i => clk_i,
  rst_i => rst_i,                                        --clka : in STD_LOGIC;
  master_mode_i =>   master_mode_int,                    --: in std_logic_vector(4 downto 0);
  ena   => enable_test_sram_t1_mem_en_int_mux_select,                       --ena : in STD_LOGIC;
  wea   => enable_test_sram_t1_mem_wr_en_vec_int_mux_select,                --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => sram_t1_mem_addr_int_mux_select,                     --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => (others => '0'),            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_fr_test_mem_intf_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  vouta => valid_fr_test_mem_intf_to_gen_proc,
  dbg_qualify_state_i => dbg_qualify_state_verify_rd(0)
  );
  
  -----------------------------------------
  -- Muxes to Test Transpose mem_intf with 1D FFT image
  -----------------------------------------	
  mux_data_to_test_transpose_mem_1d_fft_image_p00b : process(    master_mode_int,
    	                                   sram_t1_mem_en_int_mux_select_r,
    	                                   sram_t1_mem_wr_en_vec_int_mux_select_r)
    
    begin 
    	
    	case master_mode_int is
    		
    		when "00000" => -- 1d fft
    			enable_test_sram_t1_mem_en_int_mux_select 	<= '0';
    			enable_test_sram_t1_mem_wr_en_vec_int_mux_select <= (others => '0');
    	
    		when "00001" => -- 2d fft
    			enable_test_sram_t1_mem_en_int_mux_select 	<= sram_t1_mem_en_int_mux_select_r;
    			enable_test_sram_t1_mem_wr_en_vec_int_mux_select <= sram_t1_mem_wr_en_vec_int_mux_select_r; 
    		
    		when others =>
    			enable_test_sram_t1_mem_en_int_mux_select	<= '0';
    			enable_test_sram_t1_mem_wr_en_vec_int_mux_select  <= (others => '0');
    			
      end case;
    end process mux_data_to_test_transpose_mem_1d_fft_image_p00b;
  
  
  
  -----------------------------------------
  -- Mux Data Out
  -----------------------------------------	
  
  mux_data_out_to_axi_intf : process(    master_mode_int,
    	                                   data_fr_mem_intf_to_gen_proc,
    	                                   data_fr_mem_2_intf_to_gen_proc)
    
    begin 
    	
    	case master_mode_int is
    	
    		when "00000" => -- 1d fft
    			axi_intf_data_out_o 			 <= data_fr_mem_intf_to_gen_proc;
    			
    		when "00001" => -- 2d fft
    		  axi_intf_data_out_o			 <= data_fr_mem_2_intf_to_gen_proc;		
    		
    		-- DEBUGGER THEORY of OPERATION: 
    		--when "11110" => -- debug mode THere is not a debug MASTER MODE , correct???
    		-- Master Mode just tells us where we are at in process; Then the debugger
    		-- will halt processing as we interrogate memory and then restart, that is the idea
    		-- behind debugging
           
    		
    		when others =>
    			axi_intf_data_out_o			 <= (others => '0');
    			
      end case;
    end process mux_data_out_to_axi_intf;
                               
    -----------------------------------------
    -- Select Perp Signals Addr & Control to Test Mem 1
    -----------------------------------------.
    
    mux_perp_signals_to_test_mem_1_p00a : process( clk_i,rst_i)
    	
    	begin
    		if ( rst_i = '1') then
    			sram_t1_mem_en_int_mux_select_r         <= '0';
    			sram_t1_mem_wr_en_vec_int_mux_select_r  <= (others => '0');
    			--sram_t1_mem_addr_int_mux_select_r       <= '0';
    			
    			
    		elsif(clk_i'event and clk_i = '1') then
    			
    			sram_t1_mem_en_int_mux_select_r         <= sram_t1_mem_en_int_mux_select;
    			sram_t1_mem_wr_en_vec_int_mux_select_r  <= sram_t1_mem_wr_en_vec_int_mux_select;
    			--sram_t1_mem_addr_int_mux_select_r       <= sram_t1_mem_addr_int_mux_select;
    			
        end if;
     end process mux_perp_signals_to_test_mem_1_p00a;
     
    -----------------------------------------
    -- Select Data and valid from Test Mem 1 or Main Mem 1
    -----------------------------------------.
    
    mux_data_signals_fr_test_mem_1_p02 : process(stop_fft2d_dbg_int,
    	                                           data_fr_test_mem_intf_to_gen_proc,
    																						 data_fr_mem_intf_to_gen_proc
    																						 )
    	begin
    		
    		case stop_fft2d_dbg_int is
    			
    			when '0' =>
    				
    				data_fr_mem_1 <= data_fr_mem_intf_to_gen_proc;
    				
    			when '1' =>
    				
    				data_fr_mem_1 <= data_fr_test_mem_intf_to_gen_proc;
    				
    			when others =>
    				
    				data_fr_mem_1 <= (others => '0');
    					
    		end case;
    end process mux_data_signals_fr_test_mem_1_p02;
    
    
    
    
    mux_valid_signals_fr_test_mem_1_p03 : process(stop_fft2d_dbg_int,
    	                                           valid_fr_test_mem_intf_to_gen_proc,
    																						 valid_fr_mem_intf_to_gen_proc
    																						 )
    	begin
    		
    		case stop_fft2d_dbg_int is
    			
    			when '0' =>
    				
    				valid_fr_mem_1 <= valid_fr_mem_intf_to_gen_proc;
    				
    			when '1' =>
    				
    				valid_fr_mem_1 <= valid_fr_test_mem_intf_to_gen_proc;
    				
    			when others =>
    				
    				valid_fr_mem_1 <= '0';
    					
    		end case;
    end process mux_valid_signals_fr_test_mem_1_p03;
    
    reg_data_and_valid_fr_mem_1_p02a : process(clk_i,rst_i)
    	
    	begin
    		
    		if(rst_i = '1') then
    			
    			data_fr_mem_1_r    <= (others => '0');
    			valid_fr_mem_1_r   <= '0';
    			
    		elsif(clk_i'event and clk_i = '1') then
    			data_fr_mem_1_r    <= data_fr_mem_1;
    			valid_fr_mem_1_r   <= valid_fr_mem_1;
    			
    		end if;
    end process reg_data_and_valid_fr_mem_1_p02a;
    			
    			
    
    -----------------------------------------
    -- Select Data and valid from Mem 1 or Mem 2
    -----------------------------------------.
    
    mux_data_signals_fr_mem_1_or_mem_2_p04 : process(master_mode_int,
    	                                               data_fr_mem_1_r
    	                                               )
    	
    	begin
    		
    		case master_mode_int is
    			
    			when "00000" => -- 1d fft
    				
    				data_fr_mem_intf_to_gen_proc_after_mux <= data_fr_mem_1_r;
    				
    			when "00001" => -- 2d fft
    				
    				data_fr_mem_intf_to_gen_proc_after_mux <= data_fr_mem_1_r; -- Note: 2d FFT state 
    				                                                           -- also selects mem 1 as
    				                                                           -- data is being written into
    				                                                           -- mem 2
    			when others =>
    				
    					data_fr_mem_intf_to_gen_proc_after_mux <= (others => '0');
    						
    		end case;
    			
    end process mux_data_signals_fr_mem_1_or_mem_2_p04;
    
    
    mux_valid_signals_fr_mem_1_or_mem_2_p05 : process(master_mode_int, 
    	                                                valid_fr_mem_1_r)
    	
    	begin
    		
    		case master_mode_int is
    			
    			when "00000" => -- 1d fft
    				
    				valid_fr_mem_intf_to_gen_proc_after_mux <= valid_fr_mem_1_r;
    				
    			when "00001" => -- 2d fft
    				
    				valid_fr_mem_intf_to_gen_proc_after_mux <= valid_fr_mem_1_r; -- Note: 2d FFT state 
    				                                                             -- also selects mem 1 as
    				                                                             -- data is being written into
    				                                                             -- mem 2
    			when others =>
    				
    					valid_fr_mem_intf_to_gen_proc_after_mux <= '0';
    						
    		end case;
    			
    end process mux_valid_signals_fr_mem_1_or_mem_2_p05;
    
    -----------------------------------------
    -- PS FIFO Addr selection
    -----------------------------------------.
    reg_ps_fifo_addr_p06 : process(clk_i,rst_i)
    	begin
    		if(rst_i = '1') then
    			sram_t1_mem_addr_int_mux_select_r <= ( others=> '0');
    				
    		elsif( clk_i'event and clk_i = '1') then
    			sram_t1_mem_addr_int_mux_select_r <= sram_t1_mem_addr_int_mux_select;
    			
    		end if;
    			
    end process reg_ps_fifo_addr_p06;
    
    mux_ps_fifo_addr_p07 : process(master_mode_int,
    	                             sram_t1_mem_addr_int_mux_select_r)
    	begin
    		
    		case master_mode_int is
    			
    			when "00000" =>  -- 1d fft
    				sram_mem_addr_for_fifo <= sram_t1_mem_addr_int_mux_select_r;
    				
    			when "00001" => -- 2d fft
    				sram_mem_addr_for_fifo <= sram_t1_mem_addr_int_mux_select_r;
    				
    			when others =>
    				sram_mem_addr_for_fifo <= ( others => '0');
    					
    		end case;
    end process mux_ps_fifo_addr_p07;
    
    reg_srame_mem_addr_for_fifo_p08 : process(clk_i,rst_i)
    	begin
    		if( rst_i = '1') then
    			sram_mem_addr_for_fifo_r <= (others => '0');
    				
    		elsif(clk_i'event and clk_i = '1')then
    			sram_mem_addr_for_fifo_r <= sram_mem_addr_for_fifo;
    			
    		end if;
    			
    end process reg_srame_mem_addr_for_fifo_p08;
    			
    
    
   
    
  -----------------------------------------
  -- Mux Data In  Memory #2
  -----------------------------------------	
  
  mux_data_in_from_axi_intf_mem_2_p14 : process(    axi_intf_command_debug_i,
    	                                    axi_intf_data_in_i,
    	                                    data_to_mem_intf_fr_mem_in_buffer)
    
    begin 
    	
    	case axi_intf_command_debug_i is
    	
    		when '0' => -- Normal Data FLow
    			data_to_mem_2_intf_fr_mem_in_buffer_after_debug_mux 		<= data_to_mem_intf_fr_mem_in_buffer;
    			
    		when '1' => -- Debug Data In
    		  data_to_mem_2_intf_fr_mem_in_buffer_after_debug_mux			 <= axi_intf_data_in_i;		
    		
    		-- DEBUGGER THEORY of OPERATION: 
    		--when "11110" => -- debug mode THere is not a debug MASTER MODE , correct???
    		-- Master Mode just tells us where we are at in process; Then the debugger
    		-- will halt processing as we interrogate memory and then restart, that is the idea
    		-- behind debugging
           
    		
    		when others =>
    			data_to_mem_2_intf_fr_mem_in_buffer_after_debug_mux			 <= (others => '0');
    			
      end case;
    end process mux_data_in_from_axi_intf_mem_2_p14;
   
    
    -----------------------------------------
    -- Muxes into Tranpose Memory #2
    -----------------------------------------
    mux_to_addr_trans_mem_2_p12 : process(--master_mode_int,
    	                                mem_2_addr_mux_control_int,
    	                                sram_addr_int,
    	                                addr_to_mem_1_and_2_fr_fifo,
    	                                axi_intf_sram_addr_int_debug_i)
    
    begin 
    	
    	case mem_2_addr_mux_control_int is
    	
    		when "00" => -- From Mem Controller
    			sram_t2_mem_addr_int_mux_select <= sram_addr_int;
    		
    		when "01" => -- From PS Controller ;
    			sram_t2_mem_addr_int_mux_select <= addr_to_mem_1_and_2_fr_fifo;
    		
    		when "10" => -- debug mode
    			sram_t2_mem_addr_int_mux_select <= axi_intf_sram_addr_int_debug_i;
    			
    		when "11" => -- null mode
    			sram_t2_mem_addr_int_mux_select <= (others => '0');
    		
    		
    		when others =>
    			sram_t2_mem_addr_int_mux_select <= (others=> '0');
    			
      end case;
    end process mux_to_addr_trans_mem_2_p12;
    
    sram_en_fr_ps_int             <= rd_en_fr_ps_controller;
    sram_wr_en_vec_fr_ps_int(0)   <= rd_en_fr_ps_controller;
    
    
    mux_to_control_trans_mem_2_p13 : process(--master_mode_int,
    	                                   mem_2_ctrl_mux_control_int,
    	                                   sram_en_int,
    	                                   sram_wr_en_vec_int,
    	                                   sram_en_fr_ps_int,
    	                                   sram_wr_en_vec_fr_ps_int,
    	                                   axi_intf_sram_t1_mem_en_int_debug_i,
    	                                   axi_intf_sram_t1_mem_wr_en_vec_int_debug_i)
    
    begin 
    	
    	case mem_2_ctrl_mux_control_int is
    	
    		when "00" => -- From Mem Controller
    			sram_t2_mem_en_int_mux_select 			 <= sram_en_int;
    			sram_t2_mem_wr_en_vec_int_mux_select <= sram_wr_en_vec_int;
    			
    		when "01" => -- From Perp Controller
    			sram_t2_mem_en_int_mux_select 			 <= sram_en_fr_ps_int;
    			sram_t2_mem_wr_en_vec_int_mux_select <= sram_wr_en_vec_fr_ps_int;  		
    		
    		when "10" => -- debug mode
    			sram_t2_mem_en_int_mux_select        <= axi_intf_sram_t1_mem_en_int_debug_i;
    		  sram_t2_mem_wr_en_vec_int_mux_select <= axi_intf_sram_t1_mem_wr_en_vec_int_debug_i;
    		  
    		when "11" => -- null mode
    			sram_t2_mem_en_int_mux_select        <= '0';
    		  sram_t2_mem_wr_en_vec_int_mux_select <= (others => '0');
    		
    		when others =>
    			sram_t2_mem_en_int_mux_select <= '0';
    			sram_t2_mem_wr_en_vec_int_mux_select <= (others=> '0');
    			
      end case;
    end process mux_to_control_trans_mem_2_p13;
    		
    		
    		
    
     
    -----------------------------------------
    -- Transpose mem_intf Memory #2
    -----------------------------------------	
  sram_wr_en_vec_int(0) <= sram_wr_en_int;

  	  	
  u6_p15 : entity work.mem2_transpose_module_64_by_64
  GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
 
  PORT MAP ( 
  clk_i => clk_i,
  rst_i => rst_i,                                        --clka : in STD_LOGIC;
  master_mode_i =>   master_mode_int,                    --: in std_logic_vector(4 downto 0);
  ena   => sram_t2_mem_en_int_mux_select,                       --ena : in STD_LOGIC;
  wea   => sram_t2_mem_wr_en_vec_int_mux_select,                --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => sram_t2_mem_addr_int_mux_select,                     --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => data_to_mem_2_intf_fr_mem_in_buffer_after_debug_mux,            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_fr_mem_2_intf_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  vouta => valid_fr_mem_2_intf_to_gen_proc,
  dbg_qualify_state_i => dbg_qualify_state_verify_mem_2_rd(0)
  );
 
    
    
    
    
    
    
    
    
    
    
    
    				
    
    -----------------------------------------
    -- general procesor engine  (back_end)
    -----------------------------------------.
    
    u7 : entity work.gen_proc_module 
    GENERIC MAP(
	    	    	g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i 
    )
    
    PORT MAP(

	  clk_i               	         	=>      clk_i , --: in std_logic;
    rst_i               	         	=>      rst_i, --: in std_logic;
                                    
    master_mode_i                  	=>      (master_mode_int),--: in std_logic_vector(6 downto 0); -- Bits 5 & 6 describe engine mode
  	                             
      --inputs                      
    from_trans_mem_valid_i          =>       valid_fr_mem_intf_to_gen_proc_after_mux, --: in std_logic;
    from_trans_mem_data_i           =>       data_fr_mem_intf_to_gen_proc_after_mux, --: in std_logic_vector(79 downto 0); 
    
    -- Took out big H memory because Takes 144 RAMS /350 in device                              
    --from_h_mem_valid_i              =>       valid_fr_big_h_mem_to_gen_proc, --: in std_logic;
    --from_h_mem_data_i               =>       data_fr_big_h_mem_to_gen_proc, --: in std_logic_vector(79 downto 0);
    
    from_h_mem_valid_i              =>       '0', --: in std_logic;
    from_h_mem_data_i               =>       (others => '0'), --: in std_logic_vector(79 downto 0);
    	                             
    from_h_star_mem_valid_i         =>       '0', --: in std_logic;
    from_h_star_mem_data_i          =>       (others => '0'), --: in std_logic_vector(79 downto 0);    	
        	                          
    from_b_mem_valid_i              =>       '0', --: in std_logic;
    from_b_mem_data_i               =>       (others => '0'), --: in std_logic_vector(79 downto 0);   	
         	                         
    from_vk_mem_valid_i             =>       '0', --: in std_logic;
    from_vk_mem_data_i              =>       (others => '0'), --: in std_logic_vector(79 downto 0);      
  	                               
    -- outputs                      
    to_buffer_trans_mem_port_wr_o   =>       to_buffer_trans_mem_port_wr_int(0), --: out std_logic;  
    to_buffer_trans_mem_port_addr_o =>       to_buffer_trans_mem_port_addr_int, --: out std_logic_vector(16 downto 0);
    to_buffer_trans_mem_port_data_o =>       to_buffer_trans_mem_port_data_int, --: out std_logic_vector(79 downto 0);
                                   
    to_buffer_vk_mem_port_wr_o      =>       open, --: out std_logic;  
    to_buffer_vk_mem_port_addr_o    =>       open, --: out std_logic_vector(16 downto 0);
    to_buffer_vk_mem_port_data_o    =>       open, --: out std_logic_vector(79 downto 0); 	
   	                               
    to_front_end_port_wr_o          =>       valid_fr_mem_intf_to_sys, --: out std_logic;  
    to_front_end_port_data_o        =>       data_fr_mem_intf_to_sys, --: out std_logic_vector(79 downto 0);
                                    
    gen_proc_h_h_mult_rdy_o         =>       done_signal_from_h_h_mult_int, --: out std_logic;
    gen_proc_av_minus_b_rdy_o       =>       open, --: out std_logic;
    gen_proc_vk_mem_rdy_o           =>       open --: out std_logic
                                   
    );
    
 
   -----------------------------------------
    -- FIFO Address for PS Bus
    ---------------------------------------- 
                              --Note:
                              -- That signal : <valid_fr_mem_intf_to_gen_proc_after_mux>
                              -- comes from memory and registers and
                              -- does NOT come from gen proc.
                              -- The signal follows addresses from memory and
                              -- will be used to store addrs. in a FIFO
                              -- for use to ping-pong memory line.
u8_p09 : entity  work.fifo_256_module
  PORT  MAP(
    clk 											=>  clk_i, --: IN STD_LOGIC;
    srst 			                =>  rst_i, --: IN STD_LOGIC;
    din                       =>  sram_mem_addr_for_fifo_r, --: IN STD_LOGIC_VECTOR(79 DOWNTO 0);
    wr_en                     =>  valid_fr_mem_intf_to_gen_proc_after_mux, --: IN STD_LOGIC;
    rd_en                     =>  rd_en_fr_ps_controller, --: IN STD_LOGIC;
    dout                      =>  addr_to_mem_1_and_2_fr_fifo, --: OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
    full                      =>  fifo_full, --: OUT STD_LOGIC;
    empty                     =>  OPEN, --: OUT STD_LOGIC;
    wr_rst_busy               =>  OPEN,--: OUT STD_LOGIC;
    rd_rst_busy               =>  OPEN --: OUT STD_LOGIC
  );


u9_p10 : entity work.ps_state_machine_controller_64_by_64
    GENERIC MAP(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug.
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
	         ) -- 0 = no debug , 1 = debug
           
    PORT MAP(                                
    	                                   
    	  clk_i                  =>  clk_i,--: in std_logic; --clk_i, --: in std_logic;
        rst_i               	 =>  rst_i,--: in std_logic; --rst_i, --: in std_logic;
                               
        master_mode_i          =>  master_mode_int,--: in std_logic_vector(4 downto 0); --master_mode_i, --: in std_logic_vector(4 downto 0);                                                                                        
        done_i                 =>  event_to_mem,--: in std_logic; --mem_init_start_i ,--: in std_logic;
                               
        fifo_full_i            =>  fifo_full,--  : in std_logic;
                               
        addr_o                 =>  rd_addr_fr_ps_controller,--: out std_logic_vector( 16 downto 0); --addr_int, --: out std_logic;
        en_o                   =>  rd_en_fr_ps_controller--: out std_logic --en_int --: out std_logic;
                                                                    
    );                              
 
mux_to_buffer_control_and_read_p11 : process(master_mode_int,
	                                           dbg_mem_shared_in_enb_fr_mem_cont_int,
	                                           dbg_mem_shared_in_addb_fr_mem_cont_int,
	                                           rd_en_fr_ps_controller,
	                                           rd_addr_fr_ps_controller)
	begin
		case master_mode_int is
			
			when  "00000" => --1d fft
			
				dbg_mem_shared_in_enb_int   <= dbg_mem_shared_in_enb_fr_mem_cont_int;
				dbg_mem_shared_in_addb_int  <= dbg_mem_shared_in_addb_fr_mem_cont_int;
				    
			when  "00001" => -- 2d fft
				
				dbg_mem_shared_in_enb_int   <= rd_en_fr_ps_controller;
				dbg_mem_shared_in_addb_int  <= rd_addr_fr_ps_controller;
				
				
			when others =>
				
				dbg_mem_shared_in_enb_int   <=  '0';
				dbg_mem_shared_in_addb_int  <=  (others => '0');
				
		end case;
			
end process mux_to_buffer_control_and_read_p11;
    -----------------------------------------
    -- Muxes, ena,wea,addr, and data to buffer
    -----------------------------------------	
 
  
   mux_select_signals_to_buffer : process(master_mode_int,
  	                                      dual_port_wr_int,
  	                                      dual_port_addr_int,
  	                                      dual_port_data_int,
  	                                      to_buffer_trans_mem_port_wr_int,
  	                                      to_buffer_trans_mem_port_addr_int,
  	                                      to_buffer_trans_mem_port_data_int  
  	)
  	begin
  		
  		case master_mode_int is
  			
  			when "00000" => -- 1d fft
  					
  			ena_to_buffer	  <= dual_port_wr_int(0);
  			wea_to_buffer   <= dual_port_wr_int;
  			addr_to_buffer  <= dual_port_addr_int(7 downto 0);
  			data_to_buffer  <= dual_port_data_int;	
  			
  		  when "00001" => --2d fft		  		
  		  			
  			ena_to_buffer	  <= dual_port_wr_int(0);
  			wea_to_buffer   <= dual_port_wr_int;
  			addr_to_buffer  <= dual_port_addr_int(7 downto 0);
  			data_to_buffer  <= dual_port_data_int;	
  		
  		 
  			when "00011" => -- H proc				
  						
  			ena_to_buffer	  <= to_buffer_trans_mem_port_wr_int(0);
  			wea_to_buffer   <= to_buffer_trans_mem_port_wr_int;
  			addr_to_buffer  <= to_buffer_trans_mem_port_addr_int(7 downto 0);
  			data_to_buffer  <= to_buffer_trans_mem_port_data_int;			 
  			
  			when others =>  				
  						
  			ena_to_buffer	  <= '0';
  			wea_to_buffer   <= ZERO_VECTOR;
  			addr_to_buffer  <= (others=> '0');
  			data_to_buffer  <= (others=> '0');	
  		 
  				
  	 end case;
  end process	mux_select_signals_to_buffer; 
  
  -- THese are the DONE SIGNALS
  mux_select_event_to_mem : process(master_mode_int,
  	                                dual_port_wr_int,
  	                                done_signal_from_h_h_mult_int  
  	)
  	begin
  		
  		case master_mode_int is
  			
  			when "00000" => -- 1d fft
  				event_to_mem  <= dual_port_wr_int(0);
  					
  		  when "00001" => --2d fft
  		  	event_to_mem  <= dual_port_wr_int(0);
  			
  			when "00011" => -- H proc
  				--event_to_mem <= valid_fr_mem_intf_to_gen_proc;
  			  event_to_mem  <= done_signal_from_h_h_mult_int;
  			  
  			when others =>
  				event_to_mem <= '0';
  				
  	 end case;
  end process	mux_select_event_to_mem; 
  		
    -----------------------------------------
    --  f_h  memory
    -----------------------------------------	.
 -- TEMPORARY Need to add back H memory for complete design
 -- Taking out now for IP wrapper of BD design and synth  	  	
 -- u9 : entity work.mem_h_psf_module
 -- GENERIC MAP(
 --    	debug_capture_file_i => ONE_INTEGER,           -- capture file
 --	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
 --	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
 --	) 
 --
 -- PORT MAP ( 
 -- clk_i => clk_i,
 -- rst_i => rst_i,                                        --clka : in STD_LOGIC;
 -- master_mode_i =>   master_mode_int,                    --: in std_logic_vector(4 downto 0);
 -- ena   => sram_en_int,                                  --ena : in STD_LOGIC;
 -- wea   => sram_wr_en_vec_int,                           --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
 -- addra => sram_addr_int,                                --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
 -- dina  => data_to_mem_intf_fr_mem_in_buffer,            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
 -- douta => data_fr_big_h_mem_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
 -- vouta => valid_fr_big_h_mem_to_gen_proc,
--  dbg_qualify_state_i => dbg_qualify_state_verify_rd(0) -- for verfication
--  );
  
    -----------------------------------------
    --  f_h adj memory
    -----------------------------------------	
    
    -----------------------------------------
    --  b fdbk memory
    -----------------------------------------	
    
    
    -----------------------------------------
    --  v(k) memory
    -----------------------------------------	
    
    
    
    -----------------------------------------
    --  Misc.
    -----------------------------------------	
     debug_rd_data : process(clk_i, rst_i)
    	begin
    		if(rst_i = '1') then
    			dbg_rd_r   <= (others=> '0');
    		elsif(clk_i'event and clk_i = '1') then
    			dbg_rd_r <= add_rd_data_i;
    		end if;
    end process debug_rd_data;
    
    
    -----------------------------------------
    -- ???  Add a stub for mem_intf
    -----------------------------------------
    	
    app_cmd_o       <= (others=> '0');
    app_addr_o      <= (others=> '0');
    app_en_o        <= '0';
    app_wdf_mask_o  <= (others=> '0');
    app_wdf_data_o  <= (others=> '0');
    app_wdf_end_o   <= '0';  
    app_wdf_wren_o  <= '0';
      
    -----------------------------------------
    --  Assignments
    -----------------------------------------
     dbg_mem_init_start_o     <=  dbg_mem_init_start_int;
     
     dbg_mem_shared_in_enb_o  <= dbg_mem_shared_in_enb_int;
     dbg_mem_shared_in_addb_o <= dbg_mem_shared_in_addb_int;
            	
end  architecture struct; 
    