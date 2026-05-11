library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fista_accel_top_wrapper_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here.

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end fista_accel_top_wrapper_v1_0;

architecture arch_imp of  fista_accel_top_wrapper_v1_0 is

    component  fista_accel_top is
    --generic(
    --	    generic_i  : in natural);
    port (

	  clk_i               	         						  : in std_logic;
    rst_i               	         						  : in std_logic;                                           
    dbg_master_mode_i                  				  : in std_logic_vector(4 downto 0);                                            
    dbg_rdy_fr_init_and_inbound_i      				  : in std_logic; -- Equiv. to Almost full flag
    dbg_wait_fr_init_and_inbound_i     				  : in std_logic; -- Equiv. to Almost empty flag                                            
    --fft signals                               
    dbg_fft_flow_tlast_i              				  : in std_logic; -- This is a multiple clock pulse when 
                                                   -- done writing to mem buffer by FFT state mach    
    dbg_mem_init_start_o               				  : out std_logic;                                               
    -- AXI interface backend signals.           
    axi_intf_sram_addr_int_debug_i   			      : in std_logic_vector( 15 downto 0); 
    axi_intf_sram_t1_mem_en_int_debug_i         : in std_logic;                       -- t1 mem
    axi_intf_sram_t1_mem_wr_en_vec_int_debug_i  : in std_logic_vector( 0 downto 0);  	                                          
    axi_intf_stop_dec_debug_i     						  : in std_logic_vector(3 downto 0);    -- When to stop processing
    axi_intf_command_debug_i     							  : in std_logic;                        -- switch to debug for muxes.                                             
    axi_intf_start_1_debug_i      						  : in std_logic;
    axi_intf_start_2_debug_i     							  : in std_logic;                                              
    axi_intf_restart_debug_i      						  : in std_logic;                                             
    axi_intf_data_in_i            						  : in std_logic_vector(79 downto 0);
    axi_intf_data_out_o           						  : out std_logic_vector(79 downto 0);                                              
    axi_intf_stop_debug_o         						  : out std_logic;                                                  
    -- app interface to ddr controller          
    app_rdy_i           												: in std_logic;
    app_wdf_rdy_i       												: in std_logic;
    app_rd_data_valid_i   											: in std_logic_vector( 0 downto 0);
    add_rd_data_i         											: in std_logic_vector(511 downto 0);
    app_cmd_o             											: out std_logic_vector(2 downto 0);
    app_addr_o            											: out std_logic_vector(28 downto 0);
    app_en_o              											: out std_logic;
    app_wdf_mask_o        											: out std_logic_vector(63 downto 0);
    app_wdf_data_o        											: out std_logic_vector(511 downto 0);
    app_wdf_end_o         											: out std_logic;
    app_wdf_wren_o        											: out std_logic;  	                                             
    -- mux control to ddr memory controller.    
    dbg_ddr_intf_mux_wr_sel_o     							: out std_logic_vector(1 downto 0);
    dbg_ddr_intf_demux_rd_sel_o   							: out std_logic_vector(2 downto 0);
    dbg_mem_shared_in_enb_o      								: out std_logic;
    dbg_mem_shared_in_addb_o      							: out std_logic_vector(7 downto 0);                                               
    -- mux control to front and Backend modules 
    dbg_front_end_demux_fr_fista_o   						: out std_logic;
    dbg_front_end_mux_to_fft_o       						: out std_logic_vector(1 downto 0);
    dbg_back_end_demux_fr_fh_mem_o   						: out std_logic;
    dbg_back_end_demux_fr_fv_mem_o   						: out std_logic;
    dbg_back_end_mux_to_front_end_o  						: out std_logic;                                               
    -- rd,wr control to F*(H) F(H) FIFO         
    dbg_f_h_fifo_wr_en_o             						: out std_logic;
    dbg_f_h_fifo_rd_en_o             						: out std_logic;
    dbg_f_h_fifo_full_i              						: in std_logic;
    dbg_f_h_fifo_empty_i            						: in std_logic;                                              
    -- rd,wr control to F(V) FIFO               
    dbg_f_v_fifo_wr_en_o             						: out std_logic;
    dbg_f_v_fifo_rd_en_o             						: out std_logic;
    dbg_f_v_fifo_full_i             						: in std_logic;
    dbg_f_v_fifo_empty_i             						: in std_logic;                                              
    --  rd,wr control to Fdbk FIFO              
    dbg_fdbk_fifo_wr_en_o             					: out std_logic;
    dbg_fdbk_fifo_rd_en_o             					: out std_logic;
    dbg_fdbk_fifo_full_i              					: in std_logic;
    dbg_fdbk_fifo_empty_i             					: in std_logic;                                             
    -- output control                           
    fista_accel_valid_rd_o            					: out std_logic

    );
   end component fista_accel_top;

	-- component declaration
	component proto_mem_v3_0_S00_AXI is   -- Keep the old S00_AXI bus v3
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		ctrl_0_reg_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);        
    ctrl_1_reg_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    ctrl_2_reg_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    ctrl_3_reg_in  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    done_in        : in  std_logic;
        
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component proto_mem_v3_0_S00_AXI;
		
		
	signal ctrl_0_sig  : std_logic_vector(31 downto 0);
	signal ctrl_1_sig  : std_logic_vector(31 downto 0);
	signal ctrl_2_sig  : std_logic_vector(31 downto 0);
	signal ctrl_3_sig  : std_logic_vector(31 downto 0);
	signal done_sig    : std_logic;
		
		
  -- AXI interface backend signals.            
  signal 		axi_intf_sram_addr_int_debug_sig : std_logic_vector(15 downto 0);--: in std_logic_vector( 15 downto 0); 
  signal   	axi_intf_sram_t1_mem_en_int_debug_sig : std_logic;--: in std_logic;                       -- t1 mem
  signal   	axi_intf_sram_t1_mem_wr_en_vec_int_debug_sig : std_logic_vector( 0 downto 0);--: in std_logic_vector( 0 downto 0);       
  signal  	axi_intf_stop_dec_debug_sig  : std_logic_vector(3 downto 0);--: in std_logic_vector(3 downto 0);    -- When to stop processing
  signal  	axi_intf_command_debug_sig   : std_logic;--: in std_logic;                        -- switch to debug for muxes.      
  signal  	axi_intf_start_1_debug_sig   : std_logic;--: in std_logic;
  signal  	axi_intf_start_2_debug_sig   : std_logic;--: in std_logic;
  signal    axi_intf_restart_debug_sig   : std_logic;--: in std_logic;
  signal    axi_intf_data_in_sig         : std_logic_vector(79 downto 0);--: in std_logic_vector(79 downto 0);
  signal    axi_intf_data_out_sig        : std_logic_vector(79 downto 0);--: out std_logic_vector(79 downto 0);
  signal    axi_intf_stop_debug_sig      : std_logic;--: out std_logic := '0';
  
  
  signal    axi_intf_data_in_lower_sig   : std_logic_vector(31 downto 0);
  
  signal    s00_axi_areset               : std_logic;
  

begin

-- Instantiation of Axi Bus Interface S00_AXI
proto_mem_v3_0_S00_AXI_inst : proto_mem_v3_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	  ctrl_0_reg_out => ctrl_0_sig,       
    ctrl_1_reg_out => ctrl_1_sig,
    ctrl_2_reg_out => ctrl_2_sig,
    ctrl_3_reg_in  => ctrl_3_sig,
    done_in        => done_sig,
        
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
	
	
	-- Memory Map
	-- A memory is input and are used to write in data from processor
	-- B memory is output and are used to read out data to processor
	-- 
	-- slv 0 bit 0 & 1 are ena and wea respectively
	-- slv 0 bit 2 & 3 are enb and web respectively
	-- slv 0 bit 4-31 are don't care
	-- slv 1 is Addr A(31 downto 16) Addr B (15 downto 0)
	-- slv 2 is Data A(31 downto 0) ; write data
	-- slv 3 is Data B(31 downto 0) ; read data
	
	-- Treat Memory as just a dual port memory and follow normal 
	-- operations for this memory
	
	
	done_sig <= '0';

  -- ctrl 0
	axi_intf_sram_t1_mem_en_int_debug_sig <= ctrl_0_sig(0);
	axi_intf_sram_t1_mem_wr_en_vec_int_debug_sig(0) <= ctrl_0_sig(1);
		
	axi_intf_stop_dec_debug_sig(3 downto 0)  <= ctrl_0_sig(7 downto 4);
	axi_intf_command_debug_sig <= ctrl_0_sig(8);
	axi_intf_start_1_debug_sig <= ctrl_0_sig(9);	
  axi_intf_start_2_debug_sig <= ctrl_0_sig(10);
  axi_intf_restart_debug_sig <= ctrl_0_sig(11);
  	
	-- ctrl 1
	axi_intf_sram_addr_int_debug_sig(15 downto 0)  <= ctrl_1_sig(31 downto 16);
		
	
	-- ctrl 2
	axi_intf_data_in_lower_sig(31 downto 0)  <= ctrl_2_sig(31 downto 0); -- Real part only ; No upper bits padded
	axi_intf_data_in_sig(79 downto 0) <=  x"000000000000" & axi_intf_data_in_lower_sig(31 downto 0);
	
	-- ctrl 3
	ctrl_3_sig(31 downto 0) <= axi_intf_data_out_sig(31 downto 0); -- Real part only ; No upper bits padded
	

  s00_axi_areset <= not(s00_axi_aresetn);
  
U1 : fista_accel_top 
--generic(
--	    generic_i  : in natural);
   Port map (

	  clk_i               	         						  => s00_axi_aclk,--: in std_logic;
    rst_i               	         						  => s00_axi_areset,--: in std_logic;
                                                
    dbg_master_mode_i                  				  => (others => '0'),--: in std_logic_vector(4 downto 0);
                                                 
    dbg_rdy_fr_init_and_inbound_i      				  => '0',--: in std_logic; -- Equiv. to Almost full flag
    dbg_wait_fr_init_and_inbound_i     				  => '0',--: in std_logic; -- Equiv. to Almost empty flag
                                                
    --fft signals                               
    dbg_fft_flow_tlast_i              				  => '0',--: in std_logic; -- This is a multiple clock pulse when 
                                                 -- done writing to mem buffer by FFT state mach    
    dbg_mem_init_start_o               				  => open,--: out std_logic;
                                                 
    -- AXI interface backend signals.           
    axi_intf_sram_addr_int_debug_i   			      => axi_intf_sram_addr_int_debug_sig(15 downto 0),--: in std_logic_vector( 15 downto 0); 
    axi_intf_sram_t1_mem_en_int_debug_i         => axi_intf_sram_t1_mem_en_int_debug_sig,--: in std_logic;                       -- t1 mem
    axi_intf_sram_t1_mem_wr_en_vec_int_debug_i  => axi_intf_sram_t1_mem_wr_en_vec_int_debug_sig( 0 downto 0),--: in std_logic_vector( 0 downto 0);
    	                                          
    axi_intf_stop_dec_debug_i     						  => axi_intf_stop_dec_debug_sig(3 downto 0),--: in std_logic_vector(3 downto 0);    -- When to stop processing
    axi_intf_command_debug_i     							  => axi_intf_command_debug_sig,--: in std_logic;                        -- switch to debug for muxes.
                                                
    axi_intf_start_1_debug_i      						  => axi_intf_start_1_debug_sig,--: in std_logic;
    axi_intf_start_2_debug_i     							  => axi_intf_start_2_debug_sig,--: in std_logic;
                                                
    axi_intf_restart_debug_i      						  => axi_intf_restart_debug_sig,--: in std_logic;
                                                
    axi_intf_data_in_i            						  => axi_intf_data_in_sig(79 downto 0),--: in std_logic_vector(79 downto 0);
    axi_intf_data_out_o           						  => axi_intf_data_out_sig(79 downto 0),--: out std_logic_vector(79 downto 0);
                                                
    axi_intf_stop_debug_o         						  => axi_intf_stop_debug_sig,--: out std_logic := '0';
                                                  
                                                  
                                                  
    -- app interface to ddr controller            
    app_rdy_i           												=> '0',--: in std_logic;
    app_wdf_rdy_i       												=> '0',--: in std_logic;
    app_rd_data_valid_i   											=> (others => '0'),--: in std_logic_vector( 0 downto 0);
    add_rd_data_i         											=> (others => '0'),--: in std_logic_vector(511 downto 0);
    app_cmd_o             											=> open,--: out std_logic_vector(2 downto 0);
    app_addr_o            											=> open,--: out std_logic_vector(28 downto 0);
    app_en_o              											=> open,--: out std_logic;
    app_wdf_mask_o        											=> open,--: out std_logic_vector(63 downto 0);
    app_wdf_data_o        											=> open,--: out std_logic_vector(511 downto 0);
    app_wdf_end_o         											=> open,--: out std_logic;
    app_wdf_wren_o        											=> open,--: out std_logic;
   	                                             
    -- mux control to ddr memory controller.     
    dbg_ddr_intf_mux_wr_sel_o     							=> open,--: out std_logic_vector(1 downto 0);
    dbg_ddr_intf_demux_rd_sel_o   							=> open,--: out std_logic_vector(2 downto 0);
    dbg_mem_shared_in_enb_o      								=> open,--: out std_logic;
    dbg_mem_shared_in_addb_o      							=> open,--: out std_logic_vector(7 downto 0);
                                                 
    -- mux control to front and Backend modules  
    dbg_front_end_demux_fr_fista_o   						=> open,--: out std_logic;
    dbg_front_end_mux_to_fft_o       						=> open,--: out std_logic_vector(1 downto 0);
    dbg_back_end_demux_fr_fh_mem_o   						=> open,--: out std_logic;
    dbg_back_end_demux_fr_fv_mem_o   						=> open,--: out std_logic;
    dbg_back_end_mux_to_front_end_o  						=> open,--: out std_logic;
                                                 
    -- rd,wr control to F*(H) F(H) FIFO          
    dbg_f_h_fifo_wr_en_o             						=> open,--: out std_logic;
    dbg_f_h_fifo_rd_en_o             						=> open,--: out std_logic;
    dbg_f_h_fifo_full_i              						=> '0',--: in std_logic;
    dbg_f_h_fifo_empty_i            						=> '0',--: in std_logic;
                                                
    -- rd,wr control to F(V) FIFO                
    dbg_f_v_fifo_wr_en_o             						=> open,--: out std_logic;
    dbg_f_v_fifo_rd_en_o             						=> open,--: out std_logic;
    dbg_f_v_fifo_full_i             						=> '0',--: in std_logic;
    dbg_f_v_fifo_empty_i             						=> '0',--: in std_logic;
                                                 
    --  rd,wr control to Fdbk FIFO               
    dbg_fdbk_fifo_wr_en_o             					=> open,--: out std_logic;
    dbg_fdbk_fifo_rd_en_o             					=> open,--: out std_logic;
    dbg_fdbk_fifo_full_i              					=> '0',--: in std_logic;
    dbg_fdbk_fifo_empty_i             					=> '0',--: in std_logic;
                                                
    -- output control                           
    fista_accel_valid_rd_o            					=> open--: out std_logic

    );
    
	-- User logic ends

end arch_imp;
