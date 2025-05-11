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

	     --g_USE_DEBUG_H_INIT_i  : in natural := 0); -- 0 = no debug , 1 = debug
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
--signal delay_data_7_r           : std_logic_vector(79 downto 0);
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
        
 
--constant
--constant IMAG_ZEROS : std_logic_vector(39 downto 0) := (others=> '0');
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
	
-- counters
--signal state_counter_1_r            : integer;
--signal clear_state_counter_1_d      : std_logic;
--signal clear_state_counter_1_r      : std_logic;
--signal enable_state_counter_1_d     : std_logic; 
--signal enable_state_counter_1_r     : std_logic;
signal state_counter_2_r            : integer;
signal clear_state_counter_2_d      : std_logic;
signal clear_state_counter_2_r      : std_logic;
signal clear_state_counter_2_rr     : std_logic; 


signal fft_bin_seq_addr : bit_addr :=
    (   0,   1,   2,  3,    4,   5,   6,   7,   8,   9,  
    	 10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  
    	 20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  
    	 30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  
    	 40,  41,  42,  43,  44,  45,  46,  47,  48,  49,  
    	 50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  
    	 60,  61,  62,  63,  64,  65,  66,  67,  68,  69,  
    	 70,  71,  72,  73,  74,  75,  76,  77,  78,  79,  
    	 80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  
    	 90,  91,  92,  93,  94,  95,  96,  97,  98,  99,  
    	 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 
    	 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 
    	 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 
    	 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 
    	 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 
    	 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
       160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 
       170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 
       180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 
       190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 
       200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 
       210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 
       220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 
       230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 
       240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 
       250, 251, 252, 253, 254, 255 );
  
       
       

  -------------------------------------------------
	-- Function Write to a file the mem contents to check
	-------------------------------------------------
	impure function writeToFileMemRawContentsFwd1D(  signal fft_mem   : in MEM_ARRAY;
		                                               signal fft_bin_center_addr : in bit_addr
		                                            ) return result_type is
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable k            : integer;
	   variable fft_spec     : MEM_ARRAY;
	   variable data_write_var : bit_vector(67 downto 0);
	   begin
	   	 	for i in  0 to MAX_SAMPLES-1 loop
	         for j in 0 to MAX_SAMPLES-1 loop
	            k := fft_bin_center_addr(j);
	            fft_spec(i,k) := (fft_mem(i,j));
	         end loop;
	      end loop;
	     file_open(write_file_1d,"fft_1d_mem_raw_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_spec(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file_1d,mem_line_var);                  
	                  --report" Start writing to file ";
	              end loop;
	          end loop;
	     done := 1;
	     report" Done writing to file for init fft data";	  	     	 
	     file_close(write_file_1d);
  	   return result;  	       
  end function  writeToFileMemRawContentsFwd1D;
  
  -------------------------------------------------
	-- Function Write to a file the mem contents to check
	-------------------------------------------------
	impure function writeToFileMemRawContentsFwd1DFloat(  signal fft_mem   : in FLOAT_MEM_ARRAY;
		                                               signal fft_bin_center_addr : in bit_addr
		                                            ) return result_type is
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable k            : integer;
	   variable fft_spec     : FLOAT_MEM_ARRAY;
	   variable data_write_var : bit_vector(63 downto 0);
	   begin
	   	 	for i in  0 to MAX_SAMPLES-1 loop
	         for j in 0 to MAX_SAMPLES-1 loop
	            k := fft_bin_center_addr(j);
	            fft_spec(i,k) := (fft_mem(i,j));
	         end loop;
	      end loop;
	     file_open(write_file_1d_float,"fft_1d_mem_raw_float_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_spec(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file_1d_float,mem_line_var);                  
	                  --report" Start writing to file ";
	              end loop;
	          end loop;
	     done := 1;
	     report" Done writing to file for init FLOAT fft data";	  	     	 
	     file_close(write_file_1d_float);
  	   return result;  	       
  end function  writeToFileMemRawContentsFwd1DFloat;

impure function writeToFileMemRawContentsFwd2D(  signal fft_mem   : in MEM_ARRAY;
		                                               signal fft_bin_center_addr : in bit_addr
		                                            ) return result_type is
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable k            : integer;
	   variable fft_spec     : MEM_ARRAY;
	   variable data_write_var : bit_vector(67 downto 0);
	   begin
	   	 	for i in  0 to MAX_SAMPLES-1 loop
	         for j in 0 to MAX_SAMPLES-1 loop
	            k := fft_bin_center_addr(j);
	            fft_spec(i,k) := (fft_mem(i,j));
	         end loop;
	      end loop;
	     file_open(write_file_2d,"fft_2d_mem_test_raw_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_spec(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file_2d,mem_line_var);                  
	                  --report" Start writing to file ";
	              end loop;
	          end loop;
	     done := 1;
	     report" Done writing to file for fdbk fft data";	  	     	 
	     file_close(write_file_2d);
  	   return result;  	       
  end function  writeToFileMemRawContentsFwd2D;



begin
  
  
    -----------------------------------------
    -- FFT St mach contoller
    -----------------------------------------	 
    --U0 : entity work.fft_inbound_st_machine_controller
    U0 : entity xil_defaultlib.fft_inbound_st_machine_controller

    GENERIC MAP (
    --g_USE_DEBUG_H_INIT_i  =>  g_USE_DEBUG_H_INIT_i) -- 0 = no debug , 1 = debug
    g_USE_DEBUG_MODE_i  => g_USE_DEBUG_MODE_i
	  --   
    --) 
    )           
    PORT MAP(                                
    	                                   
    	  clk_i                  => clk_i,        -- : in std_logic; --clk_i,
        rst_i                  => rst_i,        -- : in std_logic; --rst_i,
                             
        master_mode_i          => master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
        --valid_i                => init_valid_data_i,  -- : in std_logic; --
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
              --delay_data_7_r                 <= (others=> '0');
       
              
            elsif(clk_i'event and clk_i = '1') then	
            	
            	delay_data_1_r                 <= init_data_i;
              delay_data_2_r                 <= delay_data_1_r;
              delay_data_3_r                 <= delay_data_2_r;
              delay_data_4_r                 <= delay_data_3_r;
              delay_data_5_r                 <= delay_data_4_r;
              delay_data_6_r                 <= delay_data_5_r;
              --delay_data_7_r                 <= delay_data_6_r;
  
      	    	
      	    end if;
      	    	
      	   
  end process delay_data_i;                       

     
    -- data offset from <39:6> because data is native 34 bits(1.33) & data read from mem
    -- that was 40 bits in length, with most sig fig big endian;
    --fft_input_data <= PAD_ZEROS & delay_data_6_r(79 downto 46) & PAD_ZEROS & delay_data_6_r(39 downto 6); -- 
    fft_input_data <= delay_data_6_r;
    -----------------------------------------
    --  FFT Core
    -----------------------------------------	
    U1 : entity work.xfft_LL_0 
  PORT MAP ( 
    aclk 													=>  clk_i, --: in STD_LOGIC;
    aresetn 											=>  not(rst_i), --: in STD_LOGIC;
    s_axis_config_tdata 					=>  s_axis_config_tdata_int, --: in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_axis_config_tvalid 					=>  s_axis_config_valid_int, --: in STD_LOGIC;
    s_axis_config_tready 					=>  s_axis_config_trdy_int, --: out STD_LOGIC;
    s_axis_data_tdata 						=>  fft_input_data, --: in STD_LOGIC_VECTOR ( 79 downto 0 ); ???? Need to delay
    s_axis_data_tvalid 						=>  s_axis_data_tvalid_int, --: in STD_LOGIC;
    s_axis_data_tready 						=>  s_axis_data_trdy_int, --: out STD_LOGIC;
    s_axis_data_tlast 						=>  s_axis_data_tlast_int, --: in STD_LOGIC;
    m_axis_data_tdata 						=>  dual_port_data_int, --: out STD_LOGIC_VECTOR ( 79 downto 0 );
    m_axis_data_tvalid 						=>  m_axis_data_tvalid_int, --: out STD_LOGIC;
    m_axis_data_tready 						=>  '1', --: in STD_LOGIC;
    m_axis_data_tlast 						=>  m_axis_data_tlast_int, --: out STD_LOGIC;
    event_frame_started 					=>  open, --: out STD_LOGIC;
    event_tlast_unexpected 				=>  open, --: out STD_LOGIC;
    event_tlast_missing 					=>  open, --: out STD_LOGIC;
    event_status_channel_halt 		=>  open, --: out STD_LOGIC;
    event_data_in_channel_halt 		=>  open, --: out STD_LOGIC;
    event_data_out_channel_halt 	=>  open --: out STD_LOGIC
  );
 
 -- split data for float input
 fft_input_data_float <= fft_input_data(71 downto 40) & fft_input_data(31 downto 0); 
  
    U2 : entity work.xfft_LL_1 
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
  

g_NO_U1_DEBUG : if g_USE_DEBUG_i = 0 generate -- default condition

  ----------------------------------------..
  -- Counters for Output Address and Verification
  ----------------------------------------
  -- counter for lower index
  state_counter_1 : process( clk_i, rst_i,m_axis_data_tlast_int_r)
    begin
      if  ( rst_i = '1' )   then
          state_counter_1_r       <=  0 ;
      elsif(  m_axis_data_tlast_int_r = '1' ) then
          state_counter_1_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
        if ( m_axis_data_tvalid_int = '1') then
          state_counter_1_r       <=  state_counter_1_r + 1;
        end if;
      end if;
  end process state_counter_1;
  
end generate g_NO_U1_DEBUG;


g_USE_U1_FLOAT : if g_USE_DEBUG_i = 2 generate -- default condition

  ----------------------------------------..
  -- Counters for Output Address and Verification
  ----------------------------------------
  -- counter for lower index
  state_counter_1 : process( clk_i, rst_i,m_axis_data_tlast_int_r)
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
--------------------------------------------------
-- For debug                       For debug
-- For debug                       For debug
-- For debug                       For debug
--
--        Generate data to debug wr ddr
-- For debug                       For debug
-- For debug                       For debug
-- For debug                       For debug
--
--------------------------------------------------
--g_USE_U0_DEBUG : if g_USE_DEBUG_i = 1 generate 
--		u0_dbg : entity work.blk_dbg_wr_mem_gen_0 
--		PORT MAP(  
--    clka    => clk_i,                      --: in STD_LOGIC;
--    ena     => m_axis_data_tvalid_int,     --: in STD_LOGIC;
--    addra   => std_logic_vector(to_unsigned(state_counter_1_r,ADDR_WIDTH)), --: in STD_LOGIC_VECTOR ( 7 downto 0 );
--    douta   => debug_dual_port_int        --: out STD_LOGIC_VECTOR ( 79 downto 0 )
--    );
   
-----------------------------------------
--  delay signals
-----------------------------------------	    
--delay_dual_port_control_reg : process(clk_i,rst_i)
--	begin
--		if(rst_i = '1') then
--			 debug_dual_port_addr_r <= (others => '0');
--			 debug_dual_port_wr_r   <= '0';
--		elsif(clk_i'event and clk_i = '1') then
--			 debug_dual_port_addr_r <= std_logic_vector(to_unsigned(state_counter_1_r,dual_port_addr_o'length)); 
--			 debug_dual_port_wr_r   <= m_axis_data_tvalid_int;			 
--	  end if;
--end process delay_dual_port_control_reg;
--    
--dual_port_wr_o       <=  debug_dual_port_wr_r;     
--dual_port_addr_o     <=  debug_dual_port_addr_r;         
--dual_port_data_o     <=  debug_dual_port_int; 
--
--end generate g_USE_U0_DEBUG;
    
-----------------------------------------
--  Assignments
-----------------------------------------	
g_NO_U0_DEBUG : if g_USE_DEBUG_i = 0 generate -- default condition
    dual_port_wr_o       <=  m_axis_data_tvalid_int;     
    dual_port_addr_o     <=  std_logic_vector(to_unsigned(state_counter_1_r,dual_port_addr_o'length));         
    dual_port_data_o     <=  dual_port_data_int; 
end generate g_NO_U0_DEBUG;

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

  ----------------------------------------..
  -- Counters
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
  --counter for upper index
  state_counter_2 : process( clk_i, rst_i,clear_state_counter_2_rr,m_axis_data_tlast_int_float)
    begin
      if ( rst_i = '1' ) then
          state_counter_2_r       <=  0 ;
      elsif(clear_state_counter_2_rr = '1') then
          state_counter_2_r       <=  0 ;
      elsif( clk_i'event and clk_i = '1') then
         if ( m_axis_data_tlast_int_float = '1') then
          state_counter_2_r       <=  state_counter_2_r + 1;
         end if;
      end if;
  end process state_counter_2;
  
 ----------------------------------------
  -- register mlast tvalid float
  ----------------------------------------.
    m_axis_data_tlast_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			 m_axis_data_tlast_int_r  <=  '0';

  	  elsif(clk_i'event and clk_i  = '1') then
         m_axis_data_tlast_int_r  <=  m_axis_data_tlast_int;
  	  end if;
  end process m_axis_data_tlast_reg;
   
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
  
   ----------------------------------------
  -- Decode terminal count
  ----------------------------------------.
  decode_terminal_count : process(state_counter_2_r)
  	begin
  		if (  state_counter_2_r = MAX_SAMPLES) then
  			clear_state_counter_2_d <= '1';
  	  else
  	  	clear_state_counter_2_d <= '0';
  	  end if;
  end process decode_terminal_count;
  
  ----------------------------------------
  -- Delay terminal count
  ----------------------------------------
   delay_terminal_count : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			clear_state_counter_2_r  <=  '0';
  			clear_state_counter_2_rr <=  '0';
  	  elsif(clk_i'event and clk_i  = '1') then
  	  	clear_state_counter_2_r  <=  clear_state_counter_2_d;
  	  	clear_state_counter_2_rr <=  clear_state_counter_2_r; 
  	  end if;
  end process delay_terminal_count;
                
  -----------------------------------------------------------------------
  -- Store FFT outputs to memory; We are reading an array built by  process record_outputs
  -----------------------------------------------------------------------.
  RamProcRawData1D : process(clk_i,rst_i, m_axis_data_tlast_int)
    begin
  	  if ( rst_i = '1' ) then
         --fft_raw_mem <= (Others => '0');
         dummy <= '1';
      elsif( ( m_axis_data_tlast_int = '1') and (master_mode_i = "00000") )then
         --fft_raw_mem <= (Others => '0');
         fft_raw_mem_1d(state_counter_2_r,state_counter_1_r) <= dual_port_data_int(73 downto 40) & dual_port_data_int(33 downto 0);
  	  elsif( (m_axis_data_tvalid_int = '1') and (master_mode_i = "00000") )then 		
  			 fft_raw_mem_1d(state_counter_2_r,state_counter_1_r) <= dual_port_data_int(73 downto 40) & dual_port_data_int(33 downto 0);
  	  elsif( (m_axis_data_tvalid_int_float = '1') and (master_mode_i = "00000") )then 		
  			 fft_raw_mem_1d_float(state_counter_2_r,state_counter_1_r) <= dual_port_data_int_float(63 downto 32) & dual_port_data_int_float(31 downto 0);  
  		end if;
   end process RamProcRawData1D;  
    
  RamProcRawData2D : process(clk_i,rst_i, m_axis_data_tlast_int)
    begin
  	  if ( rst_i = '1' ) then
         --fft_raw_mem <= (Others => '0');
         dummy <= '1';
      elsif( ( m_axis_data_tlast_int = '1') and (master_mode_i = "00001") )then
         --fft_raw_mem <= (Others => '0');
         fft_raw_mem_2d(state_counter_2_r,state_counter_1_r) <= dual_port_data_int(73 downto 40) & dual_port_data_int(33 downto 0);
  	  elsif( (m_axis_data_tvalid_int = '1') and (master_mode_i = "00001") )then 		
  			 fft_raw_mem_2d(state_counter_2_r,state_counter_1_r) <= dual_port_data_int(73 downto 40) & dual_port_data_int(33 downto 0);  				  
  		end if;
   end process RamProcRawData2D;  
    
  
  -------------------------------------------------------
	-- Write to a file the mem contents to check init data
	-------------------------------------------------------  
data_read : process(clear_state_counter_2_rr)

  --report " verfiication for 1-D FFTs enabled";

  begin
  	
   if ( (clear_state_counter_2_rr  = '1') and (master_mode_i = "00000") ) then -- Have completed MAX_SAMPLE FFT Computations( 1-D)o
        write_fft_1d_raw_done <= writeToFileMemRawContentsFwd1D(fft_raw_mem_1d,fft_bin_seq_addr);	
       report " Done writing FFTs init data for one frame";
   end if;
   	
    	
   if ( (clear_state_counter_2_rr  = '1') and (master_mode_i = "00000") ) then -- Have completed MAX_SAMPLE FFT Computations( 1-D)o
        write_fft_1d_raw_done_float <= writeToFileMemRawContentsFwd1DFloat(fft_raw_mem_1d_float,fft_bin_seq_addr);	
       report " Done writing FFTs init data Float for one frame";
   end if;
 
   	
    if ( (clear_state_counter_2_rr  = '1') and (master_mode_i = "00001") ) then -- Have completed MAX_SAMPLE FFT Computations( 1-D)o
        write_fft_2d_test_raw_done <= writeToFileMemRawContentsFwd2D(fft_raw_mem_2d,fft_bin_seq_addr);	
       report " Done writing FFTs test fdbk data for one frame";
   end if;
   	     

end process data_read;


          	
end  architecture struct; 
    