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
-- filename: init_state_machine_controller.vhd
-- Initial Date: 10/6/23
-- Descr: Init state machine to read out init block
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

    
entity init_st_machine_controller is

    generic(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug
	      g_USE_DEBUG_MODE_i : in natural := 0
	         ); -- 0 = no debug , 1 = debug
           
    port(                                
    	                                   
    	  clk_i                  : in std_logic; --clk_i, --: in std_logic;
        rst_i               	 : in std_logic; --rst_i, --: in std_logic;
                               
        master_mode_i          : in std_logic_vector(4 downto 0); --master_mode_i, --: in std_logic_vector(4 downto 0);                                                                                        
        mem_init_start_i       : in std_logic; --mem_init_start_i ,--: in std_logic;
        
        fft_rdy_i              : in std_logic;
                               
        addr_o                 : out std_logic_vector( 16 downto 0); --addr_int, --: out std_logic;
        en_o                   : out std_logic --en_int --: out std_logic;
                                    
                                    
    );                              

end init_st_machine_controller;                                          

architecture struct of init_st_machine_controller is  
	
-- signals
signal decoder_st_d  : std_logic_vector ( 2 downto 0 );
signal decoder_st_r  : std_logic_vector ( 2 downto 0 );
	
signal en_d          : std_logic;
signal en_r          : std_logic;
signal en_rr         : std_logic;

-- counters
signal state_counter_1_r           : integer;
signal state_counter_2_r           : integer;
signal state_counter_3_r           : integer;

signal clear_state_counter_1_d     : std_logic; 
signal clear_state_counter_1_r     : std_logic;
signal clear_state_counter_2_d     : std_logic; 
signal clear_state_counter_2_r     : std_logic;
signal clear_state_counter_3_d     : std_logic; 
signal clear_state_counter_3_r     : std_logic;

signal enable_state_counter_1_d     : std_logic; 
signal enable_state_counter_1_r     : std_logic;
signal enable_state_counter_2_d     : std_logic; 
signal enable_state_counter_2_r     : std_logic;
signal enable_state_counter_3_d     : std_logic; 
signal enable_state_counter_3_r     : std_logic;

-- address
signal addr_d         : std_logic_vector ( 16 downto 0 );
signal addr_r         : std_logic_vector ( 16 downto 0 );        

--constant
constant DELAY32 : integer := 32;
constant FFTSIZE256 : integer := 252; 
constant IMAGE256X256 : integer := 65536;
constant IMAGE256X256MINUSONE : integer := 65535;
	
-- States
  
  type st_controller_t is (
    state_init,
    state_wait,
    state_read_in_init,
    state_read_done

  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;

BEGIN

  ----------------------------------------
  -- Main State Machine (Comb)
  ----------------------------------------  	
   st_mach_controller : process(
       	  mem_init_start_i,
       	  master_mode_i,
       	  fft_rdy_i,
       	  state_counter_1_r,
       	  state_counter_2_r,
       	  state_counter_3_r,      	  
       	  ps_controller
       ) begin
       	
          case ps_controller is
       	
            when state_init =>
            	
            	decoder_st_d <= "001"; --INIT State.
            	
            	if( (master_mode_i = "00000" ) and
            		  (mem_init_start_i = '1') 
            		) then
            		ns_controller <= state_read_in_init;
            	else
            		ns_controller <= state_init;
              end if;
              	
            when state_wait =>           	
            	            	
            	decoder_st_d <= "010"; 
            	
            	if ( (  fft_rdy_i = '1' ) and
            		   ( state_counter_1_r <= IMAGE256X256MINUSONE)
            		 ) then
            		 ns_controller <= state_read_in_init;
            	else
            		  ns_controller <= state_wait;
            	end if;
              	
              	
            when state_read_in_init =>
            	
            	decoder_st_d <= "011"; 
            	
            	if ( state_counter_1_r <= IMAGE256X256) then
            		
            		if ( state_counter_2_r <= FFTSIZE256) then
            		  ns_controller <= state_read_in_init;
            		else
            			ns_controller <= state_wait; 
            		end if;            			
            	else
            		  ns_controller <= state_read_done;
            	end if;
            		              	
              	
            when state_read_done =>
            	
            	decoder_st_d <= "100"; 
            	
            	if ( state_counter_3_r = DELAY32) then
            		 ns_controller <= state_init;
            	else
            		  ns_controller <= state_read_done;
            	end if;
            		
            when others =>
            	
            	decoder_st_d <= "001";
            	
         end case;
        end process st_mach_controller;
        
     
  -----------------------------------------
  -- Main State Machine Mem & control Signals Decoder
  -----------------------------------------
  st_mach_controller_mem_and_control_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "001" => -- INIT state
  			
  		 en_d   <= '0';
  			
  		when "010" =>
  			
  		 en_d   <= '0'; 			
  			
  		when "011" =>
  			
  		 en_d   <= '1';
  		 
  	  when "100" =>
  			
  		 en_d   <= '0';
  			
  			
  		when others => 
  			
   		 en_d   <= '0'; 			
  		 
  			  			
  	end case;
  		
  		
  end process  st_mach_controller_mem_and_control_decoder;  	
        
  -----------------------------------------
  -- Main State Machine (Reg) Mem & Control Signals
  -----------------------------------------
  g_use_u1_no_debug : if g_USE_DEBUG_MODE_i = 0 generate -- default condition

    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
        decoder_st_r                <= "001"; -- init state
        en_r                        <= '0';
        en_rr                       <= '0'; 
        
        ps_controller               <= state_init;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r                <= decoder_st_d;
        en_r                        <= en_d;
        en_rr                       <= en_r;
        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;       	
  
  end generate g_use_u1_no_debug;
  
 g_use_u1_h_init_debug : if g_USE_DEBUG_MODE_i = 1 generate -- default condition

    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
        decoder_st_r                <= "001"; -- init state
        en_r                        <= '0';
        en_rr                       <= '0'; 
        
        ps_controller               <= state_wait;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r                <= decoder_st_d;
        en_r                        <= en_d;
        en_rr                       <= en_r;
        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;       	
  
  end generate g_use_u1_h_init_debug;

  -----------------------------------------
  -- Address Decoder
  -----------------------------------------          	
  addr_d(16 downto 0)  <=	   std_logic_vector(to_unsigned(state_counter_1_r,addr_d'length)); --direct row addr; image counter
  	
  -----------------------------------------
  -- Address decoder (Reg) Signals
  -----------------------------------------	
  
  dec_registers : process( clk_i, rst_i )
  begin
            if( rst_i = '1') then
            	
            	addr_r(16 downto 0)    <=	   (others=> '0'); 

  	
      	    elsif(clk_i'event and clk_i = '1') then
      	    	
      	    	addr_r(16 downto 0)    <=	 addr_d;

  
      	    end if;
      	    	
      	   
  end process dec_registers;
   -----------------------------------------.
  -- Main State Machine Counter Signals Decoder
  -----------------------------------------
  st_mach_controller_counters_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "001" => -- INIT state
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';  			
  			  			
  			clear_state_counter_3_d   <= '1'; 
  			enable_state_counter_3_d  <= '0';
  			
  		when "010" => -- wait
  			
  			clear_state_counter_1_d   <= '0'; 
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';			
  			  			
  			clear_state_counter_3_d   <= '1'; 
  			enable_state_counter_3_d  <= '0'; 
   
   
     when "011" => -- read
  			
  			clear_state_counter_1_d   <= '0'; 
  			enable_state_counter_1_d  <= '1'; 
  			
  			clear_state_counter_2_d   <= '0'; 
  			enable_state_counter_2_d  <= '1';			
  			  			
  			clear_state_counter_3_d   <= '1'; 
  			enable_state_counter_3_d  <= '0';
  			
  	 when "100" => -- delay
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';			
  			  			
  			clear_state_counter_3_d   <= '0'; 
  			enable_state_counter_3_d  <= '1';
    
     when others =>
       			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';	
  						  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';
  			
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
              
                            
              clear_state_counter_2_r         <= '1';
              enable_state_counter_2_r        <= '0';	
                                   
                            
              clear_state_counter_3_r         <= '1';
              enable_state_counter_3_r        <= '0';	
              
            elsif(clk_i'event and clk_i = '1') then	
            	              
            	-- 
              clear_state_counter_1_r         <= clear_state_counter_1_d;
              enable_state_counter_1_r        <= enable_state_counter_1_d;
              
               -- 
              clear_state_counter_2_r         <= clear_state_counter_2_d;
              enable_state_counter_2_r        <= enable_state_counter_2_d;
                                        
               -- 
              clear_state_counter_3_r         <= clear_state_counter_3_d;
              enable_state_counter_3_r        <= enable_state_counter_3_d;
      	    	
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
  
    --
  state_counter_2 : process( clk_i, rst_i, clear_state_counter_2_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_2_r       <=  0 ;
      elsif( clear_state_counter_2_r = '1') then
              state_counter_2_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_2_r = '1') then
              state_counter_2_r       <=  state_counter_2_r + 1;
         end if;
      end if;
  end process state_counter_2;
  
    state_counter_3 : process( clk_i, rst_i, clear_state_counter_3_r)
    begin
      if ( rst_i = '1' ) then
         state_counter_3_r       <=  0 ;
      elsif( clear_state_counter_3_r = '1') then
              state_counter_3_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( enable_state_counter_3_r = '1') then
              state_counter_3_r       <=  state_counter_3_r + 1;
         end if;
      end if;
  end process state_counter_3;
  

    
    -----------------------------------------.
    --  Assignments
    -----------------------------------------	
     addr_o <= addr_r;
     en_o <= en_rr; 
            	
end  architecture struct; 
    