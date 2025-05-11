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
-- filename: fft_inbound_state_machine_controller.vhd
-- Initial Date: 10/10/23
-- Descr: Inbound FFT state machine
-- Read continuously from memory or issue stall
------------------------------------------------.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

    
entity fft_inbound_st_machine_controller is
	  generic(
	  	      g_USE_DEBUG_MODE_i : in natural := 0
	  );           
    port(                                
    	                                   
    	  clk_i                  : in std_logic; --clk_i, --: in std_logic;.
        rst_i               	 : in std_logic; --rst_i, --: in std_logic;
                               
        master_mode_i          : in std_logic_vector(4 downto 0); --master_mode_i, --: in std_logic_vector(4 downto 0);                                                                                        
        valid_i                : in std_logic; --
        mode_change_i          : in std_logic;
        
        s_axis_config_valid_o  : out std_logic;
        s_axis_config_trdy_i   : in std_logic;
        s_axis_config_tdata_o  : out std_logic_vector(15 downto 0);
        
        s_axis_data_tvalid_o   : out std_logic;
        s_axis_data_trdy_i     : in std_logic;
        s_axis_data_tlast_o    : out std_logic;
        
        m_axis_data_tlast_i    : in std_logic;
        
        fft_rdy_o              : out std_logic;
        
        stall_warning_o        : out std_logic                                   
    );                              

end fft_inbound_st_machine_controller;                                          

architecture struct of fft_inbound_st_machine_controller is  
	
-- signals
signal decoder_st_d                 : std_logic_vector ( 3 downto 0 );
signal decoder_st_r                 : std_logic_vector ( 3 downto 0 );

signal s_axis_data_tlast_d          : std_logic;	
signal s_axis_data_tlast_r          : std_logic;
signal s_axis_data_tlast_rr         : std_logic;

signal s_axis_config_valid_d        : std_logic;      
signal s_axis_config_tdata_d        : std_logic_vector ( 15 downto 0) ;              
signal s_axis_data_tvalid_d         : std_logic;                 
signal stall_warning_d              : std_logic;   

signal s_axis_config_valid_r        : std_logic;      
signal s_axis_config_tdata_r        : std_logic_vector ( 15 downto 0) ;              
signal s_axis_data_tvalid_r         : std_logic;                 
signal stall_warning_r              : std_logic; 

signal fft_rdy_d                    : std_logic;
signal fft_rdy_r                    : std_logic;  

-- counters
signal state_counter_1_r            : integer;
signal state_counter_2_r            : integer;

signal clear_state_counter_1_d      : std_logic; 
signal clear_state_counter_1_r      : std_logic;
signal clear_state_counter_2_d      : std_logic; 
signal clear_state_counter_2_r      : std_logic;

signal enable_state_counter_1_d     : std_logic; 
signal enable_state_counter_1_r     : std_logic;
signal enable_state_counter_2_d     : std_logic; 
signal enable_state_counter_2_r     : std_logic;

--signal delay_valid_1_r              : std_logic;
--signal delay_valid_2_r              : std_logic;
--signal delay_valid_3_r              : std_logic;
--signal delay_valid_4_r              : std_logic;
--signal delay_valid_5_r              : std_logic;
--signal delay_valid_6_r              : std_logic;
--signal delay_valid_7_r              : std_logic;
       

--constant
constant FFTSIZE256 : integer := 253; -- Make two less for pipeline latency to be applied
constant DELAY8     : integer := 8;
constant DELAY128   : integer := 128;
constant DELAY256   : integer := 256;
constant DELAY512   : integer := 512;

--- States
  
  type st_controller_t is (
    state_init,
    state_config_fwd,
    state_config_col_rd,
    state_proc_fft,
    state_read_done1,
    state_read_done2,
    state_read_done3,
    state_stall

  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;

BEGIN

  ----------------------------------------.
  -- Main State Machine (Comb)
  ----------------------------------------  	
   st_mach_controller : process(
   	      valid_i,
       	  --delay_valid_7_r,
       	  master_mode_i,
       	  mode_change_i,
       	  s_axis_data_trdy_i,
       	  m_axis_data_tlast_i,
       	  state_counter_1_r,
       	  state_counter_2_r,
       	  ps_controller
       ) begin
       	
          case ps_controller is
       	
            when state_init =>
            	
            	decoder_st_d <= "0001"; --INIT State
            	
            	if( (master_mode_i = "00000" ) and
            		  (valid_i = '1') 
            		) then
            		ns_controller <= state_config_fwd;
            	elsif( (master_mode_i = "00001" ) and
            		  (valid_i = '1') 
            		) then 
            		ns_controller <= state_config_col_rd;
            	else
            		ns_controller <= state_init;          		
              end if;
              	
              	
            when state_config_fwd =>
            	
            	decoder_st_d <= "0010"; 

              --if ( state_counter_2_r < DELAY8) then
              --	ns_controller <= state_config_fwd;
              --else
                ns_controller <= state_proc_fft;
              --end if;

           
            when state_config_col_rd =>
            	
            	decoder_st_d <= "0011"; 

              ns_controller <= state_proc_fft;
                          		              	
              	
            when state_proc_fft =>
            	
            	decoder_st_d <= "0100"; 
            	
            	if  (s_axis_data_trdy_i = '1' ) then  -- This means ready ???
            		if ( state_counter_1_r < FFTSIZE256) then
            			 ns_controller <= state_proc_fft;  
            	  else
            		   ns_controller  <= state_read_done1;
            		end if;
              elsif  (s_axis_data_trdy_i = '0' ) then 
              	   ns_controller <= state_stall;
            	end if; 
   
            when state_read_done1 =>
            	
            	decoder_st_d <= "0101";
            	
            	if (m_axis_data_tlast_i = '1') then
            			 ns_controller <= state_read_done2;  
            	else
            		   ns_controller <= state_read_done1; 
            	end if;         
           		           
            		
            when state_read_done2 =>
            	
            	decoder_st_d <= "0110";
            	
            	if ( mode_change_i = '1') then
            		  ns_controller  <= state_read_done3;
            	--if ( state_counter_2_r < DELAY256) then
            	--elsif ( state_counter_2_r < DELAY512) then This works for row fft but not for col fft
            	elsif ( state_counter_2_r < DELAY128) then 

            			 ns_controller  <= state_read_done2;  
            	else
            		   ns_controller  <= state_read_done3;
            	end if;
   
            		                     		                      		
            when state_read_done3 =>
            	
            	decoder_st_d <= "0111";
            	
            	ns_controller  <= state_init;
     
            		
            when state_stall =>
            	
            	decoder_st_d <= "1000";
            	
            	ns_controller  <= state_init;
  
            		
            when others =>
            	
            	decoder_st_d <= "0001";
            	
         end case;
        end process st_mach_controller;
        
     
  -----------------------------------------
  -- Main State Machine Mem & control Signals Decoder
  -----------------------------------------
  st_mach_controller_mem_and_control_decoder : process( decoder_st_r)
  	begin
  		
  	case decoder_st_r is
  		
  		when "0001" => -- INIT state

  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';
   
       
  			
  		when "0010" => -- FWD Config
  			
  		 s_axis_config_valid_d  <= '1';            --: out std_logic;
       --s_axis_config_tdata_d  <=  x"0155"; --: out std_logic_vector(15 downto 0);
       s_axis_config_tdata_d  <=  x"0108"; --: out std_logic_vector(15 downto 0);

        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
  
       fft_rdy_d              <= '0'; 	
  			
  		when "0011" => -- Inv Config
  			  			
  		 s_axis_config_valid_d  <= '1';            --: out std_logic;
       --s_axis_config_tdata_d  <= x"0154";        --: out std_logic_vector(15 downto 0);
       s_axis_config_tdata_d  <=  x"0008"; --: out std_logic_vector(15 downto 0);
 
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';
   
       
             			
  		when "0100" => --Proc FFT
  			  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '1';            --: out std_logic;

       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';  
           
                           			
  		when "0101" => -- Read Done1
  			  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';
       
       
      when "0110" => -- Read Done2
  			  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';
       
       
      when "0111" => -- Read Done3
  			  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;..
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '1';
       
                                            			
  		when "1000" => -- Stall
  			  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '1';
       
       fft_rdy_d              <= '0';

  				
  			
  		when others => 
  			
  		 s_axis_config_valid_d  <= '0';            --: out std_logic;
       s_axis_config_tdata_d  <= (others=> '0'); --: out std_logic_vector(15 downto 0);
        
       s_axis_data_tvalid_d   <= '0';            --: out std_logic;
       
       stall_warning_d        <= '0';
       
       fft_rdy_d              <= '0';
	
  		 
  			  			
  	end case;
  		
  		
  end process  st_mach_controller_mem_and_control_decoder;  	
        
  -----------------------------------------
  -- Main State Machine (Reg) Mem & Control Signals
  -----------------------------------------.
  g_use_u0_no_debug : if g_USE_DEBUG_MODE_i = 0 generate
    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
       decoder_st_r           <= "0001"; -- init state
        
       s_axis_config_valid_r  <= '0';            --: out std_logic;
       s_axis_config_tdata_r  <= (others=> '0'); --: out std_logic_vector(15 downto 0);        
       s_axis_data_tvalid_r   <= '0';            --: out std_logic;       
       stall_warning_r        <= '0';
       
       fft_rdy_r              <= '0';

        
        ps_controller               <= state_init;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r          <= decoder_st_d;
                
        s_axis_config_valid_r  <= s_axis_config_valid_d;        
        s_axis_config_tdata_r  <= s_axis_config_tdata_d;           
        s_axis_data_tvalid_r   <= s_axis_data_tvalid_d;                 
        stall_warning_r        <= stall_warning_d;
       
        fft_rdy_r              <= fft_rdy_d;

        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;       	
  end generate g_use_u0_no_debug;
  
  g_use_u1_debug_h : if g_USE_DEBUG_MODE_i = 1 generate
    st_mach_controller_registers : process( clk_i, rst_i )
      begin
       if( rst_i = '1') then
       	
       	
        -- decoder 
       decoder_st_r           <= "0001"; -- init state
        
       s_axis_config_valid_r  <= '0';            --: out std_logic;
       s_axis_config_tdata_r  <= (others=> '0'); --: out std_logic_vector(15 downto 0);        
       s_axis_data_tvalid_r   <= '0';            --: out std_logic;       
       stall_warning_r        <= '0';
       
       fft_rdy_r              <= '0';

        
        ps_controller               <= state_init;
        			
       elsif(clk_i'event and clk_i = '1') then
         
        -- decoder
        decoder_st_r          <= decoder_st_d;
                
        s_axis_config_valid_r  <= s_axis_config_valid_d;        
        s_axis_config_tdata_r  <= s_axis_config_tdata_d;           
        s_axis_data_tvalid_r   <= s_axis_data_tvalid_d;                 
        stall_warning_r        <= stall_warning_d;
       
        fft_rdy_r              <= fft_rdy_d;

        
        ps_controller               <= ns_controller;       			           	
            	
       end if;
   end process st_mach_controller_registers;       	
  end generate g_use_u1_debug_h;
  
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
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';
  			
  		when "0010" => -- FWD Config
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  			
  			--clear_state_counter_2_d   <= '0'; 
  			--enable_state_counter_2_d  <= '1'; 
  			
  					
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0'; 
   
   
     when "0011" => -- Inv Config
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0'; 			
  	   
     when "0100" => -- Proc FFT
  			
  			clear_state_counter_1_d   <= '0'; 
  			enable_state_counter_1_d  <= '1'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0'; 			
  			  	   
     when "0101" => -- Read Done1
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';
  			
  	  			  	   
     when "0110" => -- Read Done2
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '0'; 
  			enable_state_counter_2_d  <= '1';
  			
  	  			  	   
     when "0111" => -- Read Done3
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';
  								
  			 			  			  	   
     when "1000" => -- Stall
  			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0'; 
  			
  			clear_state_counter_2_d   <= '1'; 
  			enable_state_counter_2_d  <= '0';
    
     when others =>
       			
  			clear_state_counter_1_d   <= '1'; 
  			enable_state_counter_1_d  <= '0';
  			
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
              
            elsif(clk_i'event and clk_i = '1') then	
            	              
            	-- 
              clear_state_counter_1_r         <= clear_state_counter_1_d;
              enable_state_counter_1_r        <= enable_state_counter_1_d;
              
               -- 
              clear_state_counter_2_r         <= clear_state_counter_2_d;
              enable_state_counter_2_r        <= enable_state_counter_2_d;
      	    	
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
  -----------------------------------------.
  --  Delay valid to align input data
  -----------------------------------------	
  
  --delay_valid_i : process( clk_i, rst_i )
  --       begin
  --          if( rst_i = '1') then
  --            
  --            delay_valid_1_r                 <= '0';
  --            delay_valid_2_r                 <= '0';
  --            delay_valid_3_r                 <= '0';
  --            delay_valid_4_r                 <= '0';
  --            delay_valid_5_r                 <= '0';
  --            delay_valid_6_r                 <= '0';
  --            delay_valid_7_r                 <= '0';
  --     
  --            
  --          elsif(clk_i'event and clk_i = '1') then	
  --          	
  --          	delay_valid_1_r                 <= valid_i;
  --            delay_valid_2_r                 <= delay_valid_1_r;
  --            delay_valid_3_r                 <= delay_valid_2_r;
  --            delay_valid_4_r                 <= delay_valid_3_r;
  --            delay_valid_5_r                 <= delay_valid_4_r;
  --            delay_valid_6_r                 <= delay_valid_5_r;
  --            delay_valid_7_r                 <= delay_valid_6_r;
  --
  --    	    	
  --    	    end if;
  --    	    	
  --    	   
  --end process delay_valid_i;   
    
  -----------------------------------------..
  --  Assignments
  -----------------------------------------	
     s_axis_config_valid_o  <=   s_axis_config_valid_r;
     s_axis_config_tdata_o  <=   s_axis_config_tdata_r;
     
     s_axis_data_tvalid_o   <=   s_axis_data_tvalid_r;
     s_axis_data_tlast_o    <=   s_axis_data_tlast_rr;
     
     stall_warning_o        <=   stall_warning_r;
     
     fft_rdy_o              <=   fft_rdy_r;
            	
end  architecture struct; 
