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
-- filename: master_state_machine_controller.vhd
-- Initial Date: 2/16/24
-- Descr: masterstate machine
--
------------------------------------------------.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

    
entity master_st_machine_controller is
	generic (
		       g_USE_DEBUG_MODE_i : in natural := 0
	        );           
    port(                                
    	                                   
    	  clk_i                  				: in std_logic; --clk_i, --: in std_logic;
        rst_i               	 				: in std_logic; --rst_i, --: in std_logic;
        
        command_dbg_i          				: in std_logic;
        
        stop_dec_dbg_i                : in std_logic_vector( 3 downto 0);
                               
        turnaround_i           				: in std_logic;
        
        stop_fft1d_dbg_o      	  		: out std_logic;
        
        stop_fft2d_dbg_o       				: out std_logic;
        
        stop_h_dbg_o           				: out std_logic;
        
        stop_inv_fft1d_h_dbg_o 				: out std_logic;
        
        stop_inv_fft2d_h_dbg_o 				: out std_logic;
        
        stop_pad_crop_sub_b_dbg_o 		: out std_logic;
        
        stop_fft1d_pad_dbg_o      		: out std_logic; --
        
        stop_fft2d_pad_dbg_o      		: out std_logic;
        
        stop_h_adj_dbg_o          		: out std_logic;
        
        stop_inv_fft1d_h_adj_dbg_o		: out std_logic;
        
        stop_inv_fft2d_h_adj_dbg_o    : out std_logic;
        
        stop_grad_update_dbg_o        : out std_logic;
        
        mem_1_addr_mux_control_o      : out std_logic_vector( 1 downto 0);
        	
        mem_1_ctrl_mux_control_o      : out std_logic_vector( 1 downto 0);
        	
        mem_2_addr_mux_control_o      : out std_logic_vector( 1 downto 0);
        	
        mem_2_ctrl_mux_control_o      : out std_logic_vector( 1 downto 0);
                                                                                                                          
        master_mode_o          : out std_logic_vector( 4 downto 0)
                                        
    );                              

end master_st_machine_controller;                                          

architecture struct of master_st_machine_controller is  
	
-- signals
signal decoder_st_d  : std_logic_vector ( 3 downto 0 );
signal decoder_st_r  : std_logic_vector ( 3 downto 0 );
signal master_mode_d : std_logic_vector ( 4 downto 0 );
signal master_mode_r : std_logic_vector ( 4 downto 0 );
	
signal	stop_fft1d_dbg_r : std_logic;		 	
signal  stop_fft2d_dbg_r : std_logic;
signal  stop_h_dbg_r : std_logic;
signal  stop_inv_fft1d_h_dbg_r : std_logic;
signal  stop_inv_fft2d_h_dbg_r : std_logic;
signal  stop_pad_crop_sub_b_dbg_r : std_logic;
signal  stop_fft1d_pad_dbg_r : std_logic;
signal  stop_fft2d_pad_dbg_r : std_logic;
signal  stop_h_adj_dbg_r  : std_logic;
signal  stop_inv_fft1d_h_adj_dbg_r : std_logic;
signal  stop_inv_fft2d_h_adj_dbg_r : std_logic;
signal  stop_grad_update_dbg_r  : std_logic;

signal	stop_fft1d_dbg_d : std_logic;		 	
signal  stop_fft2d_dbg_d : std_logic;
signal  stop_h_dbg_d : std_logic;
signal  stop_inv_fft1d_h_dbg_d : std_logic;
signal  stop_inv_fft2d_h_dbg_d : std_logic;
signal  stop_pad_crop_sub_b_dbg_d : std_logic;
signal  stop_fft1d_pad_dbg_d : std_logic;
signal  stop_fft2d_pad_dbg_d : std_logic;
signal  stop_h_adj_dbg_d  : std_logic;
signal  stop_inv_fft1d_h_adj_dbg_d : std_logic;
signal  stop_inv_fft2d_h_adj_dbg_d : std_logic;
signal  stop_grad_update_dbg_d  : std_logic;

signal mem_1_addr_mux_control_r : std_logic_vector ( 1 downto 0 );
signal mem_1_ctrl_mux_control_r : std_logic_vector( 1 downto 0 );
signal mem_2_addr_mux_control_r : std_logic_vector ( 1 downto 0 );
signal mem_2_ctrl_mux_control_r : std_logic_vector( 1 downto 0 );
	
signal mem_1_addr_mux_control_d : std_logic_vector ( 1 downto 0 );
signal mem_1_ctrl_mux_control_d : std_logic_vector( 1 downto 0 );
signal mem_2_addr_mux_control_d : std_logic_vector ( 1 downto 0 );
signal mem_2_ctrl_mux_control_d : std_logic_vector( 1 downto 0 );
	
signal mem_1_addr_mux_control_override_r : std_logic_vector( 1 downto 0 );
signal mem_1_ctrl_mux_control_override_r : std_logic_vector( 1 downto 0 );
signal mem_2_addr_mux_control_override_r : std_logic_vector( 1 downto 0 );
signal mem_2_ctrl_mux_control_override_r : std_logic_vector( 1 downto 0 );
	
	
signal mem_1_addr_mux_control_override_d : std_logic_vector( 1 downto 0 );
signal mem_1_ctrl_mux_control_override_d : std_logic_vector( 1 downto 0 );
signal mem_2_addr_mux_control_override_d : std_logic_vector( 1 downto 0 );
signal mem_2_ctrl_mux_control_override_d : std_logic_vector( 1 downto 0 );
	

--constant
	
-- States
  
  type st_controller_t is (
    state_wr_fwd_1d_A,
    state_rd_fwd_1d_A,
    state_wr_fwd_2d_A

  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;

BEGIN

  ----------------------------------------
  -- Main State Machine (Comb)
  ----------------------------------------  	
   st_mach_controller : process(
       	  turnaround_i,    	  
       	  ps_controller
       ) begin
       	
          case ps_controller is
       	
            when state_wr_fwd_1d_A =>
            	
            	decoder_st_d <= "0001"; 
            	
            	if( turnaround_i = '1' ) then 
            		 
            		ns_controller <= state_rd_fwd_1d_A;
            	else
            		ns_controller <= state_wr_fwd_1d_A;
              end if;
              	
            when state_rd_fwd_1d_A =>           	
            	            	
            	decoder_st_d <= "0010"; 
            	
            	if ( turnaround_i = '1' ) then
            		 ns_controller <= state_wr_fwd_2d_A;
            	else
            		  ns_controller <= state_rd_fwd_1d_A;
            	end if;
              	
              	
            when state_wr_fwd_2d_A =>
            	
            	decoder_st_d <= "0011"; 
            	
            	ns_controller <= state_wr_fwd_2d_A;
            
            		                       	
          		
            when others =>
            	
            	decoder_st_d <= "0001";
            	
         end case;
        end process st_mach_controller;
        
     
  -----------------------------------------
  -- Main State Machine Master Decoder
  -----------------------------------------
  st_mach_controller_master_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "0001" => 
  			
  		 master_mode_d   <= "00000";
  			
  		when "0010" =>
  			
  		 master_mode_d   <= "00001";
  			 			
  			
  		when "0011" =>
  		
  		 master_mode_d   <= "00011";	 	
 
  			
  		when others => 
  			
   		 master_mode_d   <= "00000";
 			 		 
  			  			
  	end case;
  		
  		
  end process  st_mach_controller_master_decoder;  	
        
  -----------------------------------------
  -- Main State Machine (Reg) Master
  -----------------------------------------
  g_use_u1_no_debug : if g_USE_DEBUG_MODE_i = 0 generate -- default condition

    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
        decoder_st_r                <= "0001"; -- init state
        master_mode_r               <= (others=>'0');
        
        ps_controller               <= state_wr_fwd_1d_A;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r                <= decoder_st_d;
        master_mode_r               <= master_mode_d;
        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;
  
 end generate g_use_u1_no_debug;
 
 g_use_u1_h_init_debug : if g_USE_DEBUG_MODE_i = 1 generate -- default condition

    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
        decoder_st_r                <= "0011"; -- init state
        master_mode_r               <= (others=>'0');
        
        ps_controller               <= state_wr_fwd_2d_A;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r                <= decoder_st_d;
        master_mode_r               <= master_mode_d;
        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;
  
          	
 end generate g_use_u1_h_init_debug;
 
 -----------------------------------------
  -- Decode stop Commands 
  -----------------------------------------.
  
  decode_stop_command_dbg : process(
  	stop_dec_dbg_i
  ) begin
  	
  	case stop_dec_dbg_i is
  		 
  		 when "0001" =>
  		 	
  		 	stop_fft1d_dbg_d <= '1';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	
  		 when "0010" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '1';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	 	
  		 when "0011" =>
  		 	
  		  stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '1';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	
  		 when "0100" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '1';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0'; 		 	
  		 	
  		 when "0101" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '1';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	
  		 when "0110" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '1';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	
  		 when "0111" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '1';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';	 	
  		 	
  		 when "1000" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '1';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';	 		 	
  		 	
  		 when "1001" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '1';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';
  		 	
  		 when "1010" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '1';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';	 	
  		 	
  		 when "1011" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '1';
  		 	stop_grad_update_dbg_d  <= '0';		
  		 	
  		 when "1100" =>
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '1';	
  		 	
  		 when others => 
  		 	
  		 	stop_fft1d_dbg_d <= '0';		 	
  		 	stop_fft2d_dbg_d <= '0';
  		 	stop_h_dbg_d  <= '0';
  		 	stop_inv_fft1d_h_dbg_d <= '0';
  		 	stop_inv_fft2d_h_dbg_d <= '0';
  		 	stop_pad_crop_sub_b_dbg_d <= '0';
  		 	stop_fft1d_pad_dbg_d  <= '0';
  		 	stop_fft2d_pad_dbg_d  <= '0';
  		 	stop_h_adj_dbg_d   <= '0';
  		 	stop_inv_fft1d_h_adj_dbg_d <= '0';
  		 	stop_inv_fft2d_h_adj_dbg_d  <= '0';
  		 	stop_grad_update_dbg_d  <= '0';	
       	
    end case;
   end process;
   
    -----------------------------------------.
    --  Reg Decode Stop Commands
    -----------------------------------------
    decode_stop_command_registers : process( clk_i, rst_i)
    	
    	begin
    		if ( rst_i = '1') then
   
           stop_fft1d_dbg_r <= '1';		 	
  		     stop_fft2d_dbg_r <= '0';
  		     stop_h_dbg_r <= '0';
  		     stop_inv_fft1d_h_dbg_r <= '0';
  		     stop_inv_fft2d_h_dbg_r <= '0';
  		     stop_pad_crop_sub_b_dbg_r <= '0';
  		     stop_fft1d_pad_dbg_r <= '0';
  		     stop_fft2d_pad_dbg_r <= '0';
  		     stop_h_adj_dbg_r  <= '0';
  		     stop_inv_fft1d_h_adj_dbg_r <= '0';
  		     stop_inv_fft2d_h_adj_dbg_r <= '0';
  		     stop_grad_update_dbg_r  <= '0';
  		     
  		   elsif(clk_i'event and clk_i = '1') then
  		   	
  		   	 stop_fft1d_dbg_r <= stop_fft1d_dbg_d;		 	
  		     stop_fft2d_dbg_r <= stop_fft2d_dbg_d;
  		     stop_h_dbg_r <= stop_h_dbg_d;
  		     stop_inv_fft1d_h_dbg_r <= stop_inv_fft1d_h_dbg_d;
  		     stop_inv_fft2d_h_dbg_r <= stop_inv_fft2d_h_dbg_d;
  		     stop_pad_crop_sub_b_dbg_r <= stop_pad_crop_sub_b_dbg_d;
  		     stop_fft1d_pad_dbg_r <= stop_fft1d_pad_dbg_d;
  		     stop_fft2d_pad_dbg_r <= stop_fft2d_pad_dbg_d;
  		     stop_h_adj_dbg_r  <= stop_h_adj_dbg_d;
  		     stop_inv_fft1d_h_adj_dbg_r <= stop_inv_fft1d_h_adj_dbg_d;
  		     stop_inv_fft2d_h_adj_dbg_r <= stop_inv_fft2d_h_adj_dbg_d;
  		     stop_grad_update_dbg_r  <= stop_grad_update_dbg_d;
  		   	
  		   end if;
  		 end process decode_stop_command_registers;
  		 
  		 
  	-----------------------------------------
    -- Mux Control for Transpose Memories
    -----------------------------------------
    mux_control_to_addr_trans_mem_1 : process(master_mode_r)
    
    begin 
    	
    	case master_mode_r is
    	
    		when "00000" => -- 1d fft
    			mem_1_addr_mux_control_d <= "00"; -- select memory controller
    		
    		when "00001" => -- 2d fft
    			mem_1_addr_mux_control_d <= "00";  --select memory controller
    		 		
    		
    		when others =>
    		  mem_1_addr_mux_control_d <= "11"; -- select GND
    			
      end case;
    end process mux_control_to_addr_trans_mem_1;
   
   
    
    mux_control_to_ctrl_trans_mem_1 : process(master_mode_r)
    
    begin 
    	
    	case master_mode_r is
    	
    		when "00000" => -- 1d fft
    			mem_1_ctrl_mux_control_d <= "00"; -- select memory controller
    		
    		when "00001" => -- 2d fft
    			mem_1_ctrl_mux_control_d <= "00";  --select memory controller
    		 		
    		
    		when others =>
    		  mem_1_ctrl_mux_control_d <= "11"; -- select GND
    			
      end case;
    end process mux_control_to_ctrl_trans_mem_1;
    
    
    
    
    
    
    mux_control_to_addr_trans_mem_2 : process(master_mode_r)
    
    begin 
    	
    	case master_mode_r is
    	
    		when "00000" => -- 1d fft
    			mem_2_addr_mux_control_d <= "11"; -- select memory controller
    		
    		when "00001" => -- 2d fft
    			mem_2_addr_mux_control_d <= "01";  --select memory controller
    		 		
    		
    		when others =>
    		  mem_2_addr_mux_control_d <= "11"; -- select GND
    			
      end case;
    end process mux_control_to_addr_trans_mem_2;
   
   
    
    mux_control_to_ctrl_trans_mem_2 : process(master_mode_r)
    
    begin 
    	
    	case master_mode_r is
    	
    		when "00000" => -- 1d fft
    			mem_2_ctrl_mux_control_d <= "11"; -- select memory controller
    		
    		when "00001" => -- 2d fft
    			mem_2_ctrl_mux_control_d <= "01";  --select memory controller
    		 		
    		
    		when others =>
    		  mem_2_ctrl_mux_control_d <= "11"; -- select GND
    			
      end case;
    end process mux_control_to_ctrl_trans_mem_2;
    
    -----------------------------------------.
    --  Reg Mux Control for Transpose Memories
    -----------------------------------------
    mux_control_to_registers : process( clk_i, rst_i)
    	
    	begin
    		if ( rst_i = '1') then
   
           mem_1_addr_mux_control_r <= "00";
           mem_1_ctrl_mux_control_r <= "00";
           
           mem_2_addr_mux_control_r <= "00";
           mem_2_ctrl_mux_control_r <= "00";
           
           mem_1_addr_mux_control_override_r <= "00";
           mem_1_ctrl_mux_control_override_r <= "00";
           
           mem_2_addr_mux_control_override_r <= "00";
           mem_2_ctrl_mux_control_override_r <= "00";
           
        elsif(clk_i'event and clk_i = '1') then
        	     	
           mem_1_addr_mux_control_r <= mem_1_addr_mux_control_d;
           mem_1_ctrl_mux_control_r <= mem_1_ctrl_mux_control_d;
           
           mem_2_addr_mux_control_r <= mem_2_addr_mux_control_d;
           mem_2_ctrl_mux_control_r <= mem_2_ctrl_mux_control_d;
           
           mem_1_addr_mux_control_override_r <= mem_1_addr_mux_control_override_d;
           mem_1_ctrl_mux_control_override_r <= mem_1_ctrl_mux_control_override_d;
           
           mem_2_addr_mux_control_override_r <= mem_2_addr_mux_control_override_d;
           mem_2_ctrl_mux_control_override_r <= mem_2_ctrl_mux_control_override_d;
         
        end if;
      end process mux_control_to_registers;
    
    -----------------------------------------.
    -- Mux Control for Transpose Memories Debug override
    -----------------------------------------    	
    mux_control_to_addr_trans_mem_1_dbg_override : process(command_dbg_i,mem_1_addr_mux_control_r)
    
    begin 
    	
    	case command_dbg_i is
    	
    		when '0' =>
    			mem_1_addr_mux_control_override_d <= mem_1_addr_mux_control_r; 
    		
    		when '1' => 
    		  mem_1_addr_mux_control_override_d <= "10"; -- debug mode
    		 		
    		
    		when others =>
    		  mem_1_addr_mux_control_override_d <= "11"; --GND
    			
      end case;
    end process mux_control_to_addr_trans_mem_1_dbg_override; 
    
    mux_control_to_ctrl_trans_mem_1_dbg_override : process(command_dbg_i,mem_1_ctrl_mux_control_r)
    
    begin 
    	
    	case command_dbg_i is
    	
    		when '0' =>
    			mem_1_ctrl_mux_control_override_d <= mem_1_ctrl_mux_control_r; 
    		
    		when '1' => 
    		  mem_1_ctrl_mux_control_override_d <= "10"; -- debug mode
    		 		
    		
    		when others =>
    		  mem_1_ctrl_mux_control_override_d <= "11"; --GND
    			
      end case;
    end process mux_control_to_ctrl_trans_mem_1_dbg_override;
    
    
    
    
    
    mux_control_to_addr_trans_mem_2_dbg_override : process(command_dbg_i,mem_2_addr_mux_control_r)
    
    begin 
    	
    	case command_dbg_i is
    	
    		when '0' =>
    			mem_2_addr_mux_control_override_d <= mem_2_addr_mux_control_r; 
    		
    		when '1' => 
    		  mem_2_addr_mux_control_override_d <= "10"; -- debug mode
    		 		
    		
    		when others =>
    		  mem_2_addr_mux_control_override_d <= "11"; --GND
    			
      end case;
    end process mux_control_to_addr_trans_mem_2_dbg_override; 
    
    mux_control_to_ctrl_trans_mem_2_dbg_override : process(command_dbg_i,mem_2_ctrl_mux_control_r)
    
    begin 
    	
    	case command_dbg_i is
    	
    		when '0' =>
    			mem_2_ctrl_mux_control_override_d <= mem_2_ctrl_mux_control_r; 
    		
    		when '1' => 
    		  mem_2_ctrl_mux_control_override_d <= "10"; -- debug mode
    		 		
    		
    		when others =>
    		  mem_2_ctrl_mux_control_override_d <= "11"; --GND
    			
      end case;
    end process mux_control_to_ctrl_trans_mem_2_dbg_override;
    
  		 
  
    -----------------------------------------
    --  Assignments
    -----------------------------------------	
   
  		   	 stop_fft1d_dbg_o <= stop_fft1d_dbg_r;		 	
  		     stop_fft2d_dbg_o <= stop_fft2d_dbg_r;
  		     stop_h_dbg_o <= stop_h_dbg_r;
  		     stop_inv_fft1d_h_dbg_o <= stop_inv_fft1d_h_dbg_r;
  		     stop_inv_fft2d_h_dbg_o <= stop_inv_fft2d_h_dbg_r;
  		     stop_pad_crop_sub_b_dbg_o <= stop_pad_crop_sub_b_dbg_r;
  		     stop_fft1d_pad_dbg_o <= stop_fft1d_pad_dbg_r;
  		     stop_fft2d_pad_dbg_o <= stop_fft2d_pad_dbg_r;
  		     stop_h_adj_dbg_o  <= stop_h_adj_dbg_r;
  		     stop_inv_fft1d_h_adj_dbg_o <= stop_inv_fft1d_h_adj_dbg_r;
  		     stop_inv_fft2d_h_adj_dbg_o <= stop_inv_fft2d_h_adj_dbg_r;
  		     stop_grad_update_dbg_o  <= stop_grad_update_dbg_r;
  		     	         	
           mem_1_addr_mux_control_o <= mem_1_addr_mux_control_override_r;
           mem_1_ctrl_mux_control_o <= mem_1_ctrl_mux_control_override_r;         
           mem_2_addr_mux_control_o <= mem_2_addr_mux_control_override_r;
           mem_2_ctrl_mux_control_o <= mem_2_ctrl_mux_control_override_r;
           
           master_mode_o <= master_mode_r;
  
            	
end  architecture struct; 
    