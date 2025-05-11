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
-- filename: h_h_star_inbound_state_machine_controller.vhd
-- Initial Date: 10/5/24
-- Descr:  H H Start Inbound FFT state machine
-- Read continuously from memory and provide a seq addr
------------------------------------------------.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity h_hstar_inbound_state_machine_controller is
	  generic(
	  	g_USE_DEBUG_MODE_i : in natural:= 0
	  );            
    port(                                
    	                                   
    	  clk_i               : in std_logic;                      -- : in std_logic; --clk_i,
        rst_i               : in std_logic;                      -- : in std_logic; --rst_i,
                            
        master_mode_i       : in std_logic_vector(4 downto 0);   --=> master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
        valid_i             : in std_logic;                      --=> port_1_valid_in_i,  -- : in std_logic; --
                            
        s_axis_data_tlast_o : out std_logic;                     --=> s_axis_a_tlast_int,-- : out std_logic;
                            
        buffer_addr_o       : out std_logic_vector( 7 downto 0); --=> buffer_addr_o
                            
        h_h_star_done_o     : out std_logic                      --=> h_h_star_done_o, 
                            
    );
    
                             

end h_hstar_inbound_state_machine_controller;                                          

architecture struct of h_hstar_inbound_state_machine_controller is  
	
-- signals
signal decoder_st_d                 : std_logic_vector ( 3 downto 0 );
signal decoder_st_r                 : std_logic_vector ( 3 downto 0 );

signal s_axis_data_tlast_d          : std_logic;	
signal s_axis_data_tlast_r          : std_logic;
signal s_axis_data_tlast_rr         : std_logic;

signal s_axis_config_valid_r        : std_logic;      
signal s_axis_config_tdata_r        : std_logic_vector ( 15 downto 0) ;              
signal s_axis_data_tvalid_r         : std_logic;  

--signal buffer_addr_int              : std_logic_vector(7 downto 0);
--signal h_h_star_done_int            : std_logic;               

-- counters
signal state_counter_1_r            : integer;

signal clear_state_counter_1_d      : std_logic; 
signal clear_state_counter_1_r      : std_logic;

signal enable_state_counter_1_d     : std_logic; 
signal enable_state_counter_1_r     : std_logic;
       

--constant
constant FFTSIZE256 : integer := 253; -- Make two less for pipeline latency to be applied

--- States
  
  type st_controller_t is (
    state_init,
    state_gen_addr,
    state_reset_addr
  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;

BEGIN

  ----------------------------------------.
  -- Main State Machine (Comb)
  ----------------------------------------  	
   st_mach_controller : process(
   
   	      valid_i,
       	  master_mode_i,
       	  ps_controller
       ) begin
       	
          case ps_controller is
       	
            when state_init =>
            	
            	decoder_st_d <= "0001"; --INIT State
            	
            	if( (master_mode_i = "00011" ) and
            		  (valid_i = '1') 
            		) then
            		ns_controller <= state_gen_addr;
            	else
            		ns_controller <= state_init;          		
              end if;
              	
              	
            when state_gen_addr =>
            	
            	decoder_st_d <= "0010"; 
            	
            	
              if( valid_i = '1') then
                ns_controller <= state_gen_addr;
              else
              	ns_controller <= state_reset_addr;
              end if;

           
            when state_reset_addr =>
            	
            	decoder_st_d <= "0011"; 

              ns_controller <= state_init;
                          		              	
             when others => 
             	  	
            	decoder_st_d <= "0001";
            	
         end case;
         
        end process st_mach_controller;
        
     
  -----------------------------------------
  -- Main State Machine Mem & control Signals Decoder
  -----------------------------------------
        
  -----------------------------------------
  -- Main State Machine (Reg) Mem & Control Signals
  -----------------------------------------

    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
       decoder_st_r           <= "0001"; -- init state
       
        
        ps_controller         <= state_init;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r          <= decoder_st_d;
      
        ps_controller          <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;       	
  
  -----------------------------------------
  -- s_axis_data_tlast Decoder
  -----------------------------------------          	
  
  dec_s_axis_data_tlast : process(state_counter_1_r)	
  begin
  	if (state_counter_1_r = FFTSIZE256 ) then
  		 s_axis_data_tlast_d <= '1';
  	else
  		 s_axis_data_tlast_d <= '0';
  	end if;
  		
  end process dec_s_axis_data_tlast;
  		
  -----------------------------------------
  -- s_axis_data_tlast Decoder (Reg) Signals
  -----------------------------------------	
  
  s_axis_data_tlast_reg : process( clk_i, rst_i )	
  begin
  	if (rst_i = '1' ) then
  		 s_axis_data_tlast_r  <= '0';
  		 s_axis_data_tlast_rr <= '0';
  	elsif( clk_i'event and clk_i = '1') then
  		 s_axis_data_tlast_r  <=  s_axis_data_tlast_d;
  		 s_axis_data_tlast_rr <=  s_axis_data_tlast_r;
  	end if;
  		
  end process s_axis_data_tlast_reg;
  
  
  -----------------------------------------
  -- Main State Machine Counter Signals Decoder
  -----------------------------------------
  st_mach_controller_counters_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "0001" => -- INIT state
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  		
  		when "0010" => -- Gen Addr
  			
  			clear_state_counter_1_d   <= '0'; 
  			enable_state_counter_1_d  <= '1';
  
     when "0011" => -- Reset Addr
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  		
  	
     when others =>
       			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  				
  	end case;
  		
  		
  end process  st_mach_controller_counters_decoder;  	
  
  -----------------------------------------
  -- Main State Machine (Reg) Counter Signals
  -----------------------------------------

  st_mach_controller_counters_registers : process( clk_i, rst_i )
         begin
            if( rst_i = '1') then

              
              clear_state_counter_1_r         <= '1';
              enable_state_counter_1_r        <= '0';	
                 
            elsif(clk_i'event and clk_i = '1') then	
            	              
            	-- 
              clear_state_counter_1_r         <= clear_state_counter_1_d;
              enable_state_counter_1_r        <= enable_state_counter_1_d;
    	    	
      	    end if;
      	    	
      	   
  end process st_mach_controller_counters_registers; 
  ----------------------------------------
  -- Counters
  ----------------------------------------
  --
  state_counter_1 : process( clk_i, rst_i, clear_state_counter_1_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_1_r       <=  0 ;
      elsif( clear_state_counter_1_r = '1') then
              state_counter_1_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_1_r = '1') then
              state_counter_1_r       <=  state_counter_1_r + 1;
         end if;
      end if;
  end process state_counter_1;
   
  -----------------------------------------
  --  Assignments
  -----------------------------------------	
     
  s_axis_data_tlast_o    <=   s_axis_data_tlast_rr;
  
  buffer_addr_o        <=   std_logic_vector(to_unsigned(state_counter_1_r,buffer_addr_o'length)); 
     
  h_h_star_done_o      <=   s_axis_data_tlast_rr;
  
  --buffer_addr_int        <=   std_logic_vector(to_unsigned(state_counter_1_r,buffer_addr_int'length)); 	
     
  --h_h_star_done_int      <=   s_axis_data_tlast_rr;
  
  
  --buffer_addr_o          <=   buffer_addr_int; 
  	
  --h_h_star_done_o        <=   h_h_start_done_int;


            	
end  architecture struct; 
