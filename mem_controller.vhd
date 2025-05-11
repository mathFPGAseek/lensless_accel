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
-- filename: mem_controller.vhd
-- Initial Date: 9/23/23
-- Descr: Memory Controller Top Level / Fista Accel.
-- Note:
-- For writes into DDR, the memory controller uses
-- counter 4 as a sequential coutner to write image
-- For reading( use counter 3) out of the shared buffer the data
-- that needs to be written into the DDR, the
-- addressing scheme, atleast for debug, needs
-- to take into account the shift and the bit
-- reversal from the fft. ( Note later this will
-- possibly change as the shift operation is not
-- done at this point in our Python system code).
--
-- For reads 
-- We will use counter 3 since it is a seq and
-- a ROM that will get us the column addr to 
-- build a line that will be used to complete
-- the 1D FFT to 2D FFT operation. However, note
-- that we cannout use counter 4 as it is a sequential
-- counter with respect to the state( meaning that
-- it will be enabled as long as we decode state).
-- Instead we need a counter, that will update everytime
-- we reach the post-write column state( This state
-- is after the FFT wait state and the Col write state,
-- that should access the same ROM for col addr and ADD
-- this to the next column addr that we need to write, with
-- of course the first column addr using a zero being added)
------------------------------------------------.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY xil_defaultlib;
USE xil_defaultlib.all;

entity mem_controller is
--generic(
--	    generic_i  : in natural);
    generic (
    	    g_USE_DEBUG_MODE_i : in natural := 0
    );
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    master_mode_i                  : in std_logic_vector(4 downto 0);
    
    rdy_fr_init_and_inbound_i      : in std_logic; -- Equiv. to Almost full flag
    wait_fr_init_and_inbound_i     : in std_logic; -- Equiv. to Almost empty flag
    
    --fft signals
    fft_flow_tlast_i               : in std_logic; -- This is a multiple clock pulse when 
                                                   -- done writing to mem buffer by FFT state mach
    
    mem_init_start_o               : out std_logic;
    
    -- input fifo control ??? Move to another state machine controller in mem controller
    --inbound_flow_fifo_wr_en_o      : out std_logic;
    --inbound_flow_fifo_rd_en_o      : out std_logic;
    --inbound_flow_fifo_full_i       : in std_logic;
    --inbound_flow_fifo_empty_i      : in std_logic;
    
    -- rd control to init memory ??? Move to init st and mem module
    ----------inbound_flow_mem_init_ena_o       : out std_logic;
    --inbound_flow_mem_init_wea_o       : out std_logic_vector(0 downto 0);
    ----------inbound_flow_mem_init_addra_o     : out std_logic_vector(15 downto 0);
    --inbound_flow_mem_init_enb_o       : out std_logic;
    --inbound_flow_mem_init_addb_o      : out std_logic_vector(7 downto 0);
    	
    -- rd control to external memory "B"  ??? Move to another state machine controller in mem controller
    ----------inbound_flow_mem_ext_ena_o       : out std_logic;
    --inbound_flow_mem_ext_wea_o       : out std_logic_vector(0 downto 0);
    ----------inbound_flow_mem_ext_addra_o     : out std_logic_vector(7 downto 0);
    --inbound_flow_mem_ext_enb_o       : out std_logic;
    --inbound_flow_mem_ext_addb_o      : out std_logic_vector(7 downto 0);
    
    -- app interface to ddr controller.
    app_rdy_i           	: in std_logic;
    app_wdf_rdy_i       	: in std_logic;
    app_rd_data_valid_i   : in std_logic_vector( 0 downto 0);
    --add_rd_data_i         : in std_logic_vector(511 downto 0);
    app_cmd_o             : out std_logic_vector(2 downto 0);
    --app_addr_o            : out std_logic_vector(28 downto 0);
    app_addr_o            : out std_logic_vector(15 downto 0);

    app_en_o              : out std_logic;
    app_wdf_mask_o        : out std_logic_vector(63 downto 0);
    --app_wdf_data_o        : out std_logic_vector(511 downto 0);
    app_wdf_end_o         : out std_logic;
    app_wdf_wren_o        : out std_logic;
    --app_wdf_en_o          : out std_logic;
    --app_wdf_addr_o        : out std_logic_vector(28 downto 0);
    --app_wdf_cmd_o         : out std_logic_vector(2 downto 0);
    	
    -- mux control to ddr memory controller.
    ddr_intf_mux_wr_sel_o     : out std_logic_vector(1 downto 0);
    ddr_intf_demux_rd_sel_o   : out std_logic_vector(2 downto 0);
     
    -- rd,wr control to shared input memory ??? Move to FFT st mach
    --mem_shared_in_ena_o       : out std_logic;
    --mem_shared_in_wea_o       : out std_logic_vector(0 downto 0);
    --mem_shared_in_addra_o     : out std_logic_vector(7 downto 0);
    mem_shared_in_ch_state_i  : in std_logic;
    mem_shared_in_enb_o       : out std_logic;
    mem_shared_in_addb_o      : out std_logic_vector(7 downto 0);
    	
    
    -- mux control to front and Backend modules  
    front_end_demux_fr_fista_o   : out std_logic;
    front_end_mux_to_fft_o       : out std_logic_vector(1 downto 0);
    back_end_demux_fr_fh_mem_o   : out std_logic;
    back_end_demux_fr_fv_mem_o   : out std_logic;
    back_end_mux_to_front_end_o  : out std_logic;
    
    -- rd,wr control to F*(H) F(H) FIFO 
    f_h_fifo_wr_en_o             : out std_logic;
    f_h_fifo_rd_en_o             : out std_logic;
    f_h_fifo_full_i              : in std_logic;
    f_h_fifo_empty_i             : in std_logic;
    
    -- rd,wr control to F(V) FIFO
    f_v_fifo_wr_en_o             : out std_logic;
    f_v_fifo_rd_en_o             : out std_logic;
    f_v_fifo_full_i              : in std_logic;
    f_v_fifo_empty_i             : in std_logic;
    
    --  rd,wr control to Fdbk FIFO
    fdbk_fifo_wr_en_o             : out std_logic;
    fdbk_fifo_rd_en_o             : out std_logic;
    fdbk_fifo_full_i              : in std_logic;
    fdbk_fifo_empty_i             : in std_logic;
    
    ---  rd,wr control to Fista xk FIFO ??? Move to fista st mach
    --fista_fifo_xk_wr_en_o         : out std_logic;
    --fista_fifo_xk_en_o            : out std_logic;
    --fista_fifo_xk_full_i          : in std_logic;
    --fista_fifo_xk_empty_i         : in std_logic;
    
    --  rd,wr control to Fista xk FIFO ??? Move to fista st mach
    --fista_fifo_vk_wr_en_o         : out std_logic;
    --fista_fifo_vk_en_o            : out std_logic;
    --fista_fifo_vk_full_i          : in std_logic;
    --fista_fifo_vk_empty_i         : in std_logic;
     
    -- output control
    fista_accel_valid_rd_o       : out std_logic;
    
    turnaround_o                 : out std_logic
    

    );
    
end mem_controller;

architecture struct of mem_controller is  
  -- signals
signal mem_shared_in_enb_int    : std_logic;
signal mem_shared_in_addb_int   : std_logic_vector( 7 downto 0); 
signal mem_shared_out_addb_int  : std_logic_vector( 7 downto 0); 
signal mem_shared_in_enb_int_r  : std_logic;

signal rd_addr_from_rd_rom      			 : std_logic_vector(15 downto 0);
signal rd_addr_incr_from_mem_cont      : std_logic_vector(15 downto 0); 
signal rd_col_addr_int                 : std_logic_vector(15 downto 0);
signal select_wr_rom_en         : std_logic;
signal select_rd_rom_en         : std_logic;

--signal app_en_int               : std_logic;  

signal enable_for_rom_int       : std_logic;  

component blk_wr_addr_mem_gen_no_reg_LL_0 
    port( 
    clka   : in STD_LOGIC;
    ena    : in STD_LOGIC;
    addra  : in STD_LOGIC_VECTOR ( 7 downto 0 );
    douta  : out STD_LOGIC_VECTOR ( 7 downto 0 )
    );
end component; 
	
begin
  
  
    -----------------------------------------
    -- Memory State Machine Controller 
    -----------------------------------------	
    
    u0 : entity work.mem_st_machine_controller
    GENERIC MAP(
    	         g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
    )
    PORT MAP(
    	
    	  clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                      => rst_i, --: in std_logic;
                                                    
        master_mode_i                               => master_mode_i, --: in std_logic_vector(4 downto 0);
                                                
        rdy_fr_init_and_inbound_i                   => rdy_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost full flag
        wait_fr_init_and_inbound_i                 =>  wait_fr_init_and_inbound_i, --: in std_logic; -- Equiv. to Almost empty flag
                                                 
        --fft signals                            
        fft_flow_tlast_i                            => fft_flow_tlast_i,--: in std_logic; -- This is a multiple clock pulse when 
                                                                   -- done writing to mem buffer by FFT state mach
                                                   
        mem_init_start_o                            => mem_init_start_o,--: out std_logic;
                                                       
        -- app interface to ddr controller             
        app_rdy_i           	                      => app_rdy_i,     --: in std_logic;
        app_wdf_rdy_i       	                      => app_wdf_rdy_i, --: in std_logic;
        app_rd_data_valid_i                         => app_rd_data_valid_i, --: in std_logic_vector( 0 downto 0);
        app_cmd_o                                   => app_cmd_o, --: out std_logic_vector(2 downto 0);
        app_addr_o                                  => app_addr_o, --: out std_logic_vector(28 downto 0);
        app_en_o                                    => app_en_o, --: out std_logic;
        app_wdf_mask_o                              => app_wdf_mask_o, --: out std_logic_vector(63 downto 0);
                                             
        app_wdf_end_o                               => app_wdf_end_o, --: out std_logic;
        app_wdf_wren_o                              => app_wdf_wren_o, --: out std_logic;
                                             
        	                                  
        -- mux control to ddr memory controller.      
        ddr_intf_mux_wr_sel_o                       => ddr_intf_mux_wr_sel_o, --: out std_logic_vector(1 downto 0);
        ddr_intf_demux_rd_sel_o                     => ddr_intf_demux_rd_sel_o, --: out std_logic_vector(2 downto 0);
        
        mem_shared_in_ch_state_i                    => mem_shared_in_ch_state_i,                                          
        mem_shared_in_enb_o                         => mem_shared_in_enb_int, --: out std_logic;
        mem_shared_in_addb_o                        => mem_shared_in_addb_int, --: out std_logic_vector(7 downto 0);
        
        -- For read col addr
        rd_col_addr_int_i                           => rd_col_addr_int,
                                               
        -- mux control to front and Backend modules 
        front_end_demux_fr_fista_o                  => front_end_demux_fr_fista_o, --: out std_logic;
        front_end_mux_to_fft_o                      => front_end_mux_to_fft_o, --: out std_logic_vector(1 downto 0);
        back_end_demux_fr_fh_mem_o                  => back_end_demux_fr_fh_mem_o , --: out std_logic;
        back_end_demux_fr_fv_mem_o                  => back_end_demux_fr_fv_mem_o, --: out std_logic;
        back_end_mux_to_front_end_o                 => back_end_mux_to_front_end_o, --: out std_logic;
                                                 
        -- rd,wr control to F*(H) F(H) FIFO       
        f_h_fifo_wr_en_o                            => f_h_fifo_wr_en_o, --: out std_logic;
        f_h_fifo_rd_en_o                            => f_h_fifo_rd_en_o, --: out std_logic;
        f_h_fifo_full_i                             => f_h_fifo_full_i, --: in std_logic;
        f_h_fifo_empty_i                            => f_h_fifo_empty_i, --: in std_logic;
                                                   
        -- rd,wr control to F(V) FIFO              
        f_v_fifo_wr_en_o                            => f_v_fifo_wr_en_o, --: out std_logic;
        f_v_fifo_rd_en_o                            => f_v_fifo_rd_en_o, --: out std_logic;
        f_v_fifo_full_i                             => f_v_fifo_full_i, --: in std_logic;
        f_v_fifo_empty_i                            => f_v_fifo_empty_i, --: in std_logic;
                                                 
        --  rd,wr control to Fdbk FIFO           
        fdbk_fifo_wr_en_o                           => fdbk_fifo_wr_en_o, --: out std_logic;
        fdbk_fifo_rd_en_o                           => fdbk_fifo_rd_en_o, --: out std_logic;
        fdbk_fifo_full_i                            => fdbk_fifo_full_i, --: in std_logic;
        fdbk_fifo_empty_i                           => fdbk_fifo_empty_i, --: in std_logic;
                                                
        -- output control                      
        fista_accel_valid_rd_o                      => fista_accel_valid_rd_o,--: out std_logic
        
        -- turnaround states
        turnaround_o                                => turnaround_o,

        
        -- rd counter to form read addr for col
        rd_addr_incr_from_mem_cont_o                => rd_addr_incr_from_mem_cont,
        
        -- enble for rom
    	  enable_for_rom_o                            => enable_for_rom_int                                            
    );
    
    -- Master mode will choose which ROM to decode
    -- For column reads we choose the blk_rd_addr
    -- FOr Row writes we choose the blk wr addr
    
    -----------------------------------------
    -- Address Generation for shared memory : To write to DDR
    -----------------------------------------.
    --U1 : entity work.blk_wr_addr_mem_gen_0 
    --PORT MAP( 
    --clka              =>   clk_i,--: in STD_LOGIC;
    --ena               =>   mem_shared_in_enb_int,--: in STD_LOGIC;
    --addra             =>   mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    --douta             =>   mem_shared_out_addb_int--: out STD_LOGIC_VECTOR ( 7 downto 0 )
    --);
    
    select_wr_rom_en <= not(master_mode_i(0)) and mem_shared_in_enb_int;
  
    
    U1 : entity xil_defaultlib.blk_wr_addr_mem_gen_no_reg_REGEN_LL_0 
    PORT MAP( 
    clka              =>   clk_i,--: in STD_LOGIC;
    ena               =>   select_wr_rom_en,--: in STD_LOGIC;
    addra             =>   mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    douta             =>   mem_shared_out_addb_int--: out STD_LOGIC_VECTOR ( 7 downto 0 )
    );
    
    --select_rd_rom_en <= master_mode_i(0) and app_en_int;
    select_rd_rom_en <= master_mode_i(0) and enable_for_rom_int;

            
    U2 : entity xil_defaultlib.blk_rd_addr_mem_gen_no_reg_REGEN_LL_0 
    PORT MAP( 
    clka              =>   clk_i,--: in STD_LOGIC;
    ena               =>   select_rd_rom_en,--: in STD_LOGIC;
    addra             =>   mem_shared_in_addb_int,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
    douta             =>   rd_addr_from_rd_rom--: out STD_LOGIC_VECTOR ( 15 downto 0 )
    );
    
    
    U3 : entity xil_defaultlib.add_counter_and_rom_for_rd_col_addr_LL 
    PORT MAP ( 
    A 							=> rd_addr_from_rd_rom,--: in STD_LOGIC_VECTOR ( 15 downto 0 );
    B 							=> rd_addr_incr_from_mem_cont,--: in STD_LOGIC_VECTOR ( 15 downto 0 );
    CLK 						=> clk_i,--: in STD_LOGIC;
    CE 							=> '1',--: in STD_LOGIC;
    SCLR 						=> rst_i,--: in STD_LOGIC;
    S 							=> rd_col_addr_int--: out STD_LOGIC_VECTOR ( 15 downto 0 )
  );                

    
    -----------------------------------------
    -- Address Generation for shared memory : To write to DDR
    -----------------------------------------	 
    --U2: entity work.blk_rd_addr_mem_gen_no_reg_0
    --PORT MAP ( 
    --clka    =>     clk_i, --: in STD_LOGIC;
    --ena     =>            --: in STD_LOGIC;
    --addra   =>            --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    --douta   =>            --: out STD_LOGIC_VECTOR ( 15 downto 0 )
  --);
    -----------------------------------------
    -- Delay Memory Controller enable output
    -----------------------------------------	
    enable_delay_reg : process(clk_i, rst_i)
    		begin
    			if( rst_i = '1') then
    				mem_shared_in_enb_int_r <= '0';
    				
    			elsif(clk_i'event and clk_i = '1') then
    				mem_shared_in_enb_int_r <= mem_shared_in_enb_int;
    			end if;
    				
    end process enable_delay_reg;	
    -----------------------------------------
    -- FISTA State Machine Controller 
    -----------------------------------------	
   
    -----------------------------------------
    -- Assignments
    -----------------------------------------.	 
    mem_shared_in_enb_o   <= mem_shared_in_enb_int_r;
    mem_shared_in_addb_o  <= mem_shared_out_addb_int; 
    --app_en_o              <= app_en_int; 
            	
end  architecture struct; 
    