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
    	                                   
    	  clk_i                  : in std_logic; --clk_i, --: in std_logic;
        rst_i               	 : in std_logic; --rst_i, --: in std_logic;
                               
        turnaround_i           : in std_logic;                                                                                        
                        
        master_mode_o          : out std_logic_vector( 4 downto 0)
                                        
    );                              

end master_st_machine_controller;                                          

architecture struct of master_st_machine_controller is  
	
-- signals
signal decoder_st_d  : std_logic_vector ( 3 downto 0 );
signal decoder_st_r  : std_logic_vector ( 3 downto 0 );
signal master_mode_d : std_logic_vector ( 4 downto 0 );
signal master_mode_r : std_logic_vector ( 4 downto 0 );
	

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
 
  
    -----------------------------------------.
    --  Assignments
    -----------------------------------------	
     master_mode_o <= master_mode_r;
  
            	
end  architecture struct; 
    