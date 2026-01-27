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
  	                                          
  signal turnaround_int                        : std_logic;
                                              
  signal master_mode_int                       : std_logic_vector(4 downto 0);
  signal master_mode_upper_bits_int            : std_logic_vector(4 downto 1); 
                                              
  signal dummy_input_1                         : std_logic := '1';
  signal dummy_input_2                         : std_logic := '1';
  signal dummy_input_3                         : std_logic_vector(0 downto 0) := (others=> '0');
  		                                        
  signal sram_wr_en_vec_int                    : std_logic_vector(0 downto 0);
  signal sram_wr_en_int                        : std_logic;
  signal sram_en_int                           : std_logic;
  signal sram_addr_int                         : std_logic_vector(15 downto 0);
  signal data_fr_mem_intf_to_sys               : std_logic_vector(79 downto 0);
  signal valid_fr_mem_intf_to_sys              : std_logic;
  signal data_fr_mem_intf_to_gen_proc          : std_logic_vector(79 downto 0);
  signal valid_fr_mem_intf_to_gen_proc         : std_logic;
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
begin
  
  
    -----------------------------------------.
    -- Memory Controller 
    -----------------------------------------	
    
    u0 : entity work.mem_controller
    GENERIC MAP (
    	           g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
    )
    PORT MAP(
    	
    	  clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                      => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => master_mode_int, --: in std_logic_vector(4 downto 0);
                                                 
        rdy_fr_init_and_inbound_i                   => dbg_rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost full flag
        wait_fr_init_and_inbound_i                  => dbg_wait_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost empty flag
                                                    
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
                                         
        mem_shared_in_enb_o                         => dbg_mem_shared_in_enb_int, --: out std_logic;
        mem_shared_in_addb_o                        => dbg_mem_shared_in_addb_int, --: out std_logic_vector(7 downto 0);
                                                  
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
                                                
        -- output control                      
        fista_accel_valid_rd_o                      => fista_accel_valid_rd_o,--: out std_logic
        
        -- turnaround signal
        turnaround_o                                => turnaround_int
    	                                              
    );
    
 --app_wdf_data_o <= (others=>'0');       --: out std_logic_vector(511 downto 0);.
   app_wdf_data_o <= DATA_512_MINUS_80 & data_to_mem_intf_fr_mem_in_buffer;
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
    	                                   
    	  clk_i                  => clk_i,--: in std_logic; --clk_i, --: in std_logic;
        rst_i               	 => rst_i,--: in std_logic; --rst_i, --: in std_logic;
                                
        turnaround_i           => turnaround_int,--: in std_logic_vector(4 downto 0);                                                                                        
                               
        master_mode_o          => master_mode_int--: out std_logic_vector( 4 downto 0)
                                       
    ); 
    
     
    -----------------------------------------
    -- Transpose mem_intf
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
  ena   => sram_en_int,                                  --ena : in STD_LOGIC;
  wea   => sram_wr_en_vec_int,                           --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => sram_addr_int,                                --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => data_to_mem_intf_fr_mem_in_buffer,            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_fr_mem_intf_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  vouta => valid_fr_mem_intf_to_gen_proc,
  dbg_qualify_state_i => dbg_qualify_state_verify_rd(0)
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
    from_trans_mem_valid_i          =>       valid_fr_mem_intf_to_gen_proc, --: in std_logic;
    from_trans_mem_data_i           =>       data_fr_mem_intf_to_gen_proc, --: in std_logic_vector(79 downto 0); 
                                  
    from_h_mem_valid_i              =>       valid_fr_big_h_mem_to_gen_proc, --: in std_logic;
    from_h_mem_data_i               =>       data_fr_big_h_mem_to_gen_proc, --: in std_logic_vector(79 downto 0);
    	                             
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
  	  	
  u9 : entity work.mem_h_psf_module
  GENERIC MAP(
	    	debug_capture_file_i => ONE_INTEGER,           -- capture file
	      debug_state_i  =>  ZERO_INTEGER,               -- no writeback to transpose memory
	      g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i       -- debug state
	) 
 
  PORT MAP ( 
  clk_i => clk_i,
  rst_i => rst_i,                                        --clka : in STD_LOGIC;
  master_mode_i =>   master_mode_int,                    --: in std_logic_vector(4 downto 0);
  ena   => sram_en_int,                                  --ena : in STD_LOGIC;
  wea   => sram_wr_en_vec_int,                           --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => sram_addr_int,                                --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => data_to_mem_intf_fr_mem_in_buffer,            --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_fr_big_h_mem_to_gen_proc,                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  vouta => valid_fr_big_h_mem_to_gen_proc,
  dbg_qualify_state_i => dbg_qualify_state_verify_rd(0) -- for verfication
  );
  
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
    