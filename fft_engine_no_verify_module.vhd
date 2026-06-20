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
-- filename: fft_engine_module.vhd
-- Initial Date: 10/14/23
-- Descr: FFT engine
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;
LIBRARY xil_defaultlib;
USE xil_defaultlib.all;

entity fft_engine_module is
generic(
	     g_USE_DEBUG_i  : in natural := 1;
	     g_USE_DEBUG_MODE_i : in natural := 0

	    
);
    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    master_mode_i                  : in std_logic_vector(4 downto 0);
  	
    -- Input Data to front end module
    init_valid_data_i              : in std_logic;
    init_data_i                    : in std_logic_vector(79 downto 0);    
    stall_warning_o                : out std_logic;
  
    dual_port_wr_o                 : out std_logic;  
    dual_port_addr_o               : out std_logic_vector(16 downto 0);
    dual_port_data_o               : out std_logic_vector(79 downto 0);
    	
    fft_rdy_o                      : out std_logic

    );
    
end fft_engine_module;

architecture struct of fft_engine_module is  
	
-- signals                                         
signal s_axis_config_valid_int  : std_logic;  
signal s_axis_config_trdy_int   : std_logic := '1';  
signal s_axis_config_tdata_int  : std_logic_vector(15 downto 0);                   
signal s_axis_data_tvalid_int   : std_logic; 
signal s_axis_data_trdy_int     : std_logic := '1';  
signal s_axis_data_tlast_int    : std_logic;                   
signal stall_warning_int        : std_logic;

signal dual_port_data_int       : std_logic_vector(79 downto 0);
signal m_axis_data_tvalid_int   : std_logic;
signal m_axis_data_tlast_int    : std_logic;
signal m_axis_data_tlast_int_r  : std_logic;

signal fft_rdy_int              : std_logic;

signal delay_valid_1_r          : std_logic;
signal delay_valid_2_r          : std_logic;

signal delay_data_1_r           : std_logic_vector(79 downto 0);
signal delay_data_2_r           : std_logic_vector(79 downto 0);
signal delay_data_3_r           : std_logic_vector(79 downto 0);
signal delay_data_4_r           : std_logic_vector(79 downto 0);
signal delay_data_5_r           : std_logic_vector(79 downto 0);
signal delay_data_6_r           : std_logic_vector(79 downto 0);

signal fft_input_data           : std_logic_vector(79 downto 0);
	
signal delay_master_mode_reg    : std_logic;
signal rising_edge_master_mode_reg : std_logic;

-------------------------------------------------
-- For Float FFT
-------------------------------------------------
signal fft_input_data_float          : std_logic_vector(63 downto 0);
signal s_axis_config_trdy_int_float  : std_logic;
signal s_axis_data_trdy_int_float    : std_logic;
signal dual_port_data_int_float      : std_logic_vector(63 downto 0); 
signal m_axis_data_tvalid_int_float  : std_logic;
signal m_axis_data_tlast_int_float   : std_logic;
signal m_axis_data_tlast_int_float_r : std_logic; 
        

------------------------------------------------- 
-- For Synthesis and Verification                          
-------------------------------------------------

signal state_counter_1_r            : integer;

-------------------------------------------------
-- For Debug  Only
-------------------------------------------------
constant ADDR_WIDTH : integer := 8;

signal debug_dual_port_int      : std_logic_vector(79 downto 0);
signal debug_dual_port_wr_r     : std_logic;
signal debug_dual_port_addr_r   : std_logic_vector(16 downto 0);

-------------------------------------------------
-- For Verification Only
-------------------------------------------------

constant MAX_SAMPLES : integer := 2**8;  -- maximum number of samples in a frame
constant MAX_SAMPLES_MINUS_ONE : integer := MAX_SAMPLES -1;

constant IP_WIDTH    : integer := 34;
constant MEM_WIDTH   : integer := IP_WIDTH*2 -1;
type     MEM_ARRAY is array(0 to  MAX_SAMPLES-1,0 to MAX_SAMPLES-1) of std_logic_vector(MEM_WIDTH downto  0);

constant FLOAT_IP_WIDTH    : integer := 32;
constant FLOAT_MEM_WIDTH   : integer := FLOAT_IP_WIDTH*2 -1;
type     FLOAT_MEM_ARRAY is array(0 to  MAX_SAMPLES-1,0 to MAX_SAMPLES-1) of std_logic_vector(FLOAT_MEM_WIDTH downto  0);
	
type     bit_addr is array ( 0 to MAX_SAMPLES-1) of integer;
type     result_type is ( '0', '1');
signal   fft_raw_mem_1d       : MEM_ARRAY;
signal   fft_raw_mem_1d_float : FLOAT_MEM_ARRAY;
signal   fft_raw_mem_2d       : MEM_ARRAY;
file     write_file_1d        : text;
file     write_file_1d_float  : text;
file     write_file_2d        : text;
signal   dummy  : std_logic := '1';
signal   write_fft_1d_raw_done : result_type;
signal   write_fft_1d_raw_done_float : result_type;
signal   write_fft_2d_test_raw_done : result_type;


constant PAD_ZEROS       : std_logic_vector(5 downto 0) := (others=> '0');
constant PAD_EIGHT_ZEROS : std_logic_vector(7 downto 0) := (others=> '0');

signal state_counter_2_r            : integer;
signal clear_state_counter_2_d      : std_logic;
signal clear_state_counter_2_r      : std_logic;
signal clear_state_counter_2_rr     : std_logic; 


  
       
       

  



begin
  
  
    -----------------------------------------
    -- FFT St mach contoller
    -----------------------------------------	 
    
    U0 : entity xil_defaultlib.fft_inbound_st_machine_controller

    GENERIC MAP (
    
    g_USE_DEBUG_MODE_i  => g_USE_DEBUG_MODE_i
	  
    )           
    PORT MAP(                                
    	                                   
    	  clk_i                  => clk_i,        -- : in std_logic; --clk_i,
        rst_i                  => rst_i,        -- : in std_logic; --rst_i,
                             
        master_mode_i          => master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
        
        valid_i                => delay_valid_2_r,  -- : in std_logic; --

        
        mode_change_i          => rising_edge_master_mode_reg,
                             
        s_axis_config_valid_o  => s_axis_config_valid_int,-- : out std_logic;
        s_axis_config_trdy_i   => s_axis_config_trdy_int,-- : in std_logic;
        s_axis_config_tdata_o  => s_axis_config_tdata_int,-- : out std_logic_vector(15 downto 0);
                            
        s_axis_data_tvalid_o   => s_axis_data_tvalid_int,-- : out std_logic;
        s_axis_data_trdy_i     => s_axis_data_trdy_int,-- : in std_logic;
        s_axis_data_tlast_o    => s_axis_data_tlast_int,-- : out std_logic;
        
        m_axis_data_tlast_i    => m_axis_data_tlast_int,
        
        fft_rdy_o              => fft_rdy_int, 
                            
        stall_warning_o        => stall_warning_int-- : out std_logic;                                   
    );
    
  -----------------------------------------.
  --  Delay input valid to align
  -----------------------------------------	
  delay_valid_i  : process(clk_i,rst_i) 
  	  begin
  	  	if( rst_i = '1') then
  	  		   delay_valid_1_r               <= '0';
  	  		   delay_valid_2_r               <= '0';
  	  		   
  	  	elsif(clk_i'event and clk_i = '1') then
  	  		   delay_valid_1_r               <= init_valid_data_i;
  	  		   delay_valid_2_r               <= delay_valid_1_r;
  	  		   
  	    end if;
  end process delay_valid_i;
  -----------------------------------------.
  --  Delay input data to align
  -----------------------------------------	
  
  delay_data_i : process( clk_i, rst_i )
         begin
            if( rst_i = '1') then
              
              delay_data_1_r                 <= (others=> '0');
              delay_data_2_r                 <= (others=> '0');
              delay_data_3_r                 <= (others=> '0');
              delay_data_4_r                 <= (others=> '0');
              delay_data_5_r                 <= (others=> '0');
              delay_data_6_r                 <= (others=> '0');
           
       
              
            elsif(clk_i'event and clk_i = '1') then	
            	
            	delay_data_1_r                 <= init_data_i;
              delay_data_2_r                 <= delay_data_1_r;
              delay_data_3_r                 <= delay_data_2_r;
              delay_data_4_r                 <= delay_data_3_r;
              delay_data_5_r                 <= delay_data_4_r;
              delay_data_6_r                 <= delay_data_5_r;
   
  
      	    	
      	    end if;
      	    	
      	   
  end process delay_data_i;                       

     
    -- data offset from <39:6> because data is native 34 bits(1.33) & data read from mem
    -- that was 40 bits in length, with most sig fig big endian;
        fft_input_data <= delay_data_6_r;
    -----------------------------------------
    --  FFT Core
    -----------------------------------------	
    --U1 : entity work.fix_fft_0 
  --PORT MAP ( 
    --aclk 													=>  clk_i, --: in STD_LOGIC;
    --aresetn 											=>  not(rst_i), --: in STD_LOGIC;
    --s_axis_config_tdata 					=>  s_axis_config_tdata_int, --: in STD_LOGIC_VECTOR ( 15 downto 0 );
    --s_axis_config_tvalid 					=>  s_axis_config_valid_int, --: in STD_LOGIC;
    --s_axis_config_tready 					=>  s_axis_config_trdy_int, --: out STD_LOGIC;
    --s_axis_data_tdata 						=>  fft_input_data, --: in STD_LOGIC_VECTOR ( 79 downto 0 ); ???? Need to delay
    --s_axis_data_tvalid 						=>  s_axis_data_tvalid_int, --: in STD_LOGIC;
    --s_axis_data_tready 						=>  s_axis_data_trdy_int, --: out STD_LOGIC;
    --s_axis_data_tlast 						=>  s_axis_data_tlast_int, --: in STD_LOGIC;
    --m_axis_data_tdata 						=>  dual_port_data_int, --: out STD_LOGIC_VECTOR ( 79 downto 0 );
    --m_axis_data_tvalid 						=>  m_axis_data_tvalid_int, --: out STD_LOGIC;
    --m_axis_data_tready 						=>  '1', --: in STD_LOGIC;
    --m_axis_data_tlast 						=>  m_axis_data_tlast_int, --: out STD_LOGIC;
    --event_frame_started 					=>  open, --: out STD_LOGIC;
    --event_tlast_unexpected 				=>  open, --: out STD_LOGIC;
    --event_tlast_missing 					=>  open, --: out STD_LOGIC;
    --event_status_channel_halt 		=>  open, --: out STD_LOGIC;
    --event_data_in_channel_halt 		=>  open, --: out STD_LOGIC;
    --event_data_out_channel_halt 	=>  open --: out STD_LOGIC
  --);
 
 -- split data for float input
 fft_input_data_float <= fft_input_data(71 downto 40) & fft_input_data(31 downto 0); 
  
    U2 : entity work.flt_fft_1 
  PORT MAP( 
   aclk 											=> clk_i, --aclk : in STD_LOGIC;
   aresetn 										=> not(rst_i),--aresetn : in STD_LOGIC;
   s_axis_config_tdata 				=> s_axis_config_tdata_int,--s_axis_config_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
   s_axis_config_tvalid 			=> s_axis_config_valid_int,--s_axis_config_tvalid : in STD_LOGIC;
   s_axis_config_tready 			=> s_axis_config_trdy_int_float,--s_axis_config_tready : out STD_LOGIC;
   s_axis_data_tdata 					=> fft_input_data_float,--s_axis_data_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
   s_axis_data_tvalid 				=> s_axis_data_tvalid_int,--s_axis_data_tvalid : in STD_LOGIC;
   s_axis_data_tready 				=> s_axis_data_trdy_int_float,--s_axis_data_tready : out STD_LOGIC;
   s_axis_data_tlast 					=> s_axis_data_tlast_int,--s_axis_data_tlast : in STD_LOGIC;
   m_axis_data_tdata 					=> dual_port_data_int_float,--m_axis_data_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
   m_axis_data_tvalid 				=> m_axis_data_tvalid_int_float,--m_axis_data_tvalid : out STD_LOGIC;
   m_axis_data_tready 				=> '1',--m_axis_data_tready : in STD_LOGIC;
   m_axis_data_tlast 					=> m_axis_data_tlast_int_float,--m_axis_data_tlast : out STD_LOGIC;
   event_frame_started 				=> open,--event_frame_started : out STD_LOGIC;
   event_tlast_unexpected 		=> open,--event_tlast_unexpected : out STD_LOGIC;
   event_tlast_missing 				=> open,--event_tlast_missing : out STD_LOGIC;
   event_status_channel_halt 	=> open,--event_status_channel_halt : out STD_LOGIC;
   event_data_in_channel_halt => open,--event_data_in_channel_halt : out STD_LOGIC;
   event_data_out_channel_halt => open--event_data_out_channel_halt : out STD_LOGIC
    );

-- TEMP DEBUG ONLY: WAs used when we took out our FFT float U2 module !!!!!!!!!! !!!!!!!!!!
--dual_port_data_int_float <= (others=> '0');--m_axis_data_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
--m_axis_data_tvalid_int_float <= '0';--m_axis_data_tvalid : out STD_LOGIC;
--m_axis_data_tlast_int_float  <=  '0';

--m_axis_data_tvalid_int <= '0';
--m_axis_data_tlast_int <= '0'; -- m_axis_data_tlast_int_r -> for state_counter_1 --> dual_port_addr_o

  
  ------------------------------------------
  -- KLudge need to reset fft controller
  ------------------------------------------
  reset_fft: process(clk_i,rst_i)
  	begin
  		if( rst_i = '1') then
  			delay_master_mode_reg <= '0';
  		elsif(clk_i'event and clk_i = '1') then
  			delay_master_mode_reg <= master_mode_i(0);
  	  end if;
  end process reset_fft;
  
  rising_edge_master_mode_reg <= not(delay_master_mode_reg) and master_mode_i(0);
  

--g_NO_U1_DEBUG : if g_USE_DEBUG_i = 0 generate -- default condition

  ----------------------------------------..
  -- Counters for Output Address and Verification KEEP
  ----------------------------------------
  -- counter for lower index
  --state_counter_1 : process( clk_i, rst_i,m_axis_data_tlast_int_r)
  --  begin
  --    if  ( rst_i = '1' )   then
  --        state_counter_1_r       <=  0 ;
  --    elsif(  m_axis_data_tlast_int_r = '1' ) then
  --        state_counter_1_r       <=  0 ;
  --    elsif( clk_i'event and clk_i = '1') then
  --      if ( m_axis_data_tvalid_int = '1') then
  --        state_counter_1_r       <=  state_counter_1_r + 1;
  --      end if;
  --    end if;
  --end process state_counter_1;
  
--end generate g_NO_U1_DEBUG;


g_USE_U1_FLOAT : if g_USE_DEBUG_i = 2 generate -- default condition

  ----------------------------------------..
  -- Counters for Output Address and Verification
  ----------------------------------------
  -- counter for lower index
  state_counter_1 : process( clk_i, rst_i,m_axis_data_tlast_int_float_r) -- changed from t_last_int
    begin
      if  ( rst_i = '1' )   then
          state_counter_1_r       <=  0 ;
      elsif(  m_axis_data_tlast_int_float_r = '1' ) then
          state_counter_1_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
        if ( m_axis_data_tvalid_int_float = '1') then
          state_counter_1_r       <=  state_counter_1_r + 1;
        end if;
      end if;
  end process state_counter_1;
  
end generate g_USE_U1_FLOAT;  

    
-----------------------------------------
--  Assignments
-----------------------------------------	
--g_NO_U0_DEBUG : if g_USE_DEBUG_i = 0 generate -- default condition
--    dual_port_wr_o       <=  m_axis_data_tvalid_int;     
--    dual_port_addr_o     <=  std_logic_vector(to_unsigned(state_counter_1_r,dual_port_addr_o'length));         
--    dual_port_data_o     <=  dual_port_data_int; 
--end generate g_NO_U0_DEBUG;

g_USE_U0_FLOAT : if g_USE_DEBUG_i = 2 generate 
    dual_port_wr_o       <=  m_axis_data_tvalid_int_float;     
    dual_port_addr_o     <=  std_logic_vector(to_unsigned(state_counter_1_r,dual_port_addr_o'length));         
    dual_port_data_o     <=  PAD_EIGHT_ZEROS & dual_port_data_int_float(63 downto 32) & PAD_EIGHT_ZEROS & dual_port_data_int_float(31 downto 0); 
end generate g_USE_U0_FLOAT;    
    
    
fft_rdy_o            <=  fft_rdy_int;     
stall_warning_o      <=  stall_warning_int;
    
-----------------------------------------------------------------
--Verification             ,....,                    Verification
--Verification           ,:::::::                    Verification
--Verification          ,::/^\"``.                   Verification
--Verification         ,::/, `   e`.                 Verification
--Verification        ,::; |        '.               Verification
--Verification        ,::|  \___,-.  c)              Verification
--Verification        ;::|     \   '-'               Verification
--Verification        ;::|      \                    Verification
--Verification        ;::|   _.=`\                   Verification
--Verification        `;:|.=` _.=`\                  Verification
--Verification          '|_.=`   __\                 Verification
--Verification          `\_..==`` /                  Verification
--Verification           .'.___.-'.                  Verification
--Verification          /          \                 Verification
--Verification         ('--......--')                Verification
--Verification         /'--......--'\                Verification
--Verification         `"--......--"`                Verification
--Verification                                       Verification
--Verification        Do not synthesize the code     Verification
--Verification               below                   Verification
--Verification        Only for verification!         Verification
--Verification                                       Verification
--Verification             Verify 1D FFT             Verification
--Verification                                       Verification
--Verification       Use in conjuntion with Matlab   Verification
--Verification          file: verify_1d_fft.m        Verification
-----------------------------------------------------------------


  
 ----------------------------------------
  -- register mlast tvalid float    KEEP !
  ----------------------------------------
 --   m_axis_data_tlast_reg : process(clk_i, rst_i)
 -- 	begin
 -- 		if ( rst_i = '1') then
 -- 			 m_axis_data_tlast_int_r  <=  '0';
 --
 -- 	  elsif(clk_i'event and clk_i  = '1') then
 --        m_axis_data_tlast_int_r  <=  m_axis_data_tlast_int;
 -- 	  end if;
 -- end process m_axis_data_tlast_reg;
   
  ----------------------------------------
  -- register mlast tvalid
  ----------------------------------------
    m_axis_data_tlast_float_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			 m_axis_data_tlast_int_float_r  <=  '0';

  	  elsif(clk_i'event and clk_i  = '1') then
         m_axis_data_tlast_int_float_r  <=  m_axis_data_tlast_int_float;
  	  end if;
  end process m_axis_data_tlast_float_reg;
  
 
  
 
                
    
    
  
  


          	
end  architecture struct; 
    