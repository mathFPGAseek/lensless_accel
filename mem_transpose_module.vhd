library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--USE ieee.numeric_std.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;
--use IEEE.NUMERIC_STD.ALL;


entity mem_transpose_module is
	               -- debug signals : All signals go to mem,gen_proc, and master
                  -- DEBUG_STATE
                  -- := 000 -> NO debug 
                  -- := 001 -> DEBUG H      -> {Load F(v), Load H}      : trans  & f_H memory
                  -- := 010 -> DEBUG Inv A  -> {Load (H x F(v))}        : trans memory  
                  -- := 011 -> DEBUG Av-B   -> {Load Av, Load B}        : trans & b memory
                  -- := 100 -> DEBUG AH     -> {Load crop&pad(AV-b)}    : trans memory
                  -- := 101 -> DEBUG H*     -> {Load FH(v)), Load H*}   : trans & f_adj memory
                  -- := 110 -> DEBUG InvAH  -> {Load (H* x FH(v))}      : trans memory
                  -- := 111 -> DEBUG update -> {Load Grad, Vk}          : trans & vk memory
  generic(
  	       debug_capture_file_i : integer := 0;     -- = 0 no capture file; =1 capture file
  	       debug_state_i : in integer := 0;         -- = 0 no write       ; =1 write
  	       g_USE_DEBUG_MODE_i : in natural := 0     -- = 0 W/R external to this module; To use COE file = 1.
  	     );
  
  Port (
    clk_i : in STD_LOGIC; 
    rst_i : in STD_LOGIC;
    master_mode_i : in STD_LOGIC_VECTOR ( 4 downto 0 );
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 );
    vouta : out STD_LOGIC;
    dbg_qualify_state_i : in STD_LOGIC
  );

end mem_transpose_module;

architecture stub of mem_transpose_module is


-- For verification and synthesis
signal data_out_r                   : std_logic_vector( 79 downto 0);
signal data_out_no_debug_default_r  : std_logic_vector( 79 downto 0);
signal data_out_no_debug_fwd_2d_A_r        : std_logic_vector( 79 downto 0);
signal enable_read_rr               : std_logic;

COMPONENT blk_mem_gen_debug_h_transpose_mem_REGEN2_LL_0
	Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );
 END COMPONENT;

COMPONENT blk_mem_gen_debug_h_transpose_mem_REGEN_LL_0
	Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );
 END COMPONENT;

COMPONENT blk_mem_debug_h_transpose_seq_mem_LL_0 is
  Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );
 END COMPONENT;
-------------------------------------------------	
-------------------------------------------------
-------------------------------------------------
-- For Verification Only Code below
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

constant MAX_SAMPLES : integer := 2**8;  -- maximum number of samples in a frame
constant MAX_LINEAR_SAMPLES : integer := 2**16;
constant MAX_SAMPLES_MINUS_ONE: integer := MAX_SAMPLES -1;
constant IP_WIDTH    : integer := 32;
constant MEM_WIDTH   : integer := IP_WIDTH*2 -1;
type     MEM_ARRAY is array(0 to  MAX_SAMPLES-1,0 to MAX_SAMPLES-1) of std_logic_vector(MEM_WIDTH downto  0);
type     MEM_LINEAR is array(0 to  MAX_LINEAR_SAMPLES-1) of std_logic_vector(MEM_WIDTH downto  0);
type     bit_addr is array ( 0 to MAX_SAMPLES-1) of integer;
type     result_type is ( '0', '1');
signal   fft_raw_wr_mem : MEM_LINEAR;
signal   fft_raw_mem : MEM_ARRAY;
signal   h_read_mem  : MEM_ARRAY;
signal   h_write_mem : MEM_ARRAY;
file     write_file    : text;
signal   dummy         : std_logic := '1';
signal   dummy_h_read  : std_logic := '1';
signal   dummy_h_write : std_logic := '1';
signal   write_fft_1d_wr_raw_done : result_type;
signal   write_fft_1d_raw_done : result_type;
signal   write_h_init_done     : result_type;
signal   write_h_mult_done     : result_type;

signal   addra_int             : integer;

constant PAD_ZEROS  : std_logic_vector(5 downto 0) := (others=> '0');
	
constant MAX_SAMPLES_COUNTER_3 : integer := 384; -- 256 + 128 to mask first rd falling edge
	
-- counters

signal state_counter_2_r            : integer;
signal clear_state_counter_2_d      : std_logic;
signal clear_state_counter_2_r      : std_logic;
signal clear_state_counter_2_rr     : std_logic; 
signal enable_state_counter_2_d     : std_logic;
signal enable_state_counter_2_r     : std_logic;

signal state_counter_1_r            : integer;
signal state_counter_1_rr           : integer;
signal state_counter_1_rrr          : integer;
signal clear_state_counter_1_r      : std_logic; -- no _d because comes from registered last event


-- misc for verification
signal enable_read                  : std_logic;
signal enable_read_r                : std_logic;
signal delay_ena                    : std_logic;
signal falling_valid_event_d        : std_logic;
signal falling_valid_event_r        : std_logic;
signal falling_valid_event_rr       : std_logic;
signal falling_valid_event_rrr      : std_logic;
signal falling_valid_event_int      : std_logic;
signal qualify_state_r              : std_logic;
signal qualify_state_rr             : std_logic;
signal qualify_state_rrr            : std_logic;
signal qualify_state_rrrr           : std_logic;
signal qualify_state_int            : std_logic;

signal process_write_r              : std_logic;
signal process_write_d              : std_logic;

-- signals for kludge
signal ena_to_mem_r                 : std_logic;
signal ena_to_mem_rr                : std_logic;
signal ena_to_mem_d                 : std_logic;

-- debug signal for controlling write to debug memory instantiation
signal write_control_from_generic   : std_logic_vector( 0 downto 0);
	
signal enable_file_capture          : std_logic_vector( 0 downto 0);
	
	
-- signals for last write to buffer
signal enable_write                     : std_logic;

signal enable_write_r                   : std_logic;
signal enable_write_rr                 	: std_logic;

signal falling_edge_for_last_write_d		: std_logic;
signal falling_edge_for_last_write_r    : std_logic;

signal decoder_st_d                     : std_logic_vector( 1 downto 0);
signal decoder_st_r                     : std_logic_vector( 1 downto 0);

signal enable_last_read_d               : std_logic;
signal enable_last_read_r               : std_logic;
signal enable_last_read_rr              : std_logic;

signal falling_edge_for_last_read_d     : std_logic;
signal falling_edge_for_last_read_r     : std_logic;

-- States
  
  type st_controller_t is (
    state_quies,
    state_enable_last_read

  );
  
  signal ns_controller : st_controller_t;
  signal ps_controller : st_controller_t;

                  
	
	-------------------------------------------------
	-- Function Write to a file the mem contents to check 1D FFT
	-------------------------------------------------
	impure function writeToFileMemRawContentsFFTWrite(  signal fft_mem   : in MEM_LINEAR) return result_type is
  
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable data_write_var : bit_vector(63 downto 0);
	   begin
	     file_open(write_file,"MEM_TRANSPOSE_row_wr_mem_raw_fft_1d_float_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_LINEAR_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_mem(i));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file,mem_line_var);                  
	          end loop;
	      done := 1;
	      file_close(write_file);
	      report" Done writing to file ";	  
  	    return result;  	       
  end function  writeToFileMemRawContentsFFTWrite;
	
	
	-------------------------------------------------
	-- Function Write to a file the mem contents to check 1D FFT after Transpose Read
	-------------------------------------------------
  impure function writeToFileMemRawContents(  signal fft_mem   : in MEM_ARRAY) return result_type is
  
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable data_write_var : bit_vector(63 downto 0);
	   begin
	     file_open(write_file,"MEM_TRANSPOSE_col_rd_mem_raw_fft_1d_float_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_mem(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file,mem_line_var);                  
	              end loop;
	          end loop;
	      done := 1;
	      file_close(write_file);
	      report" Done writing to file ";	  
  	    return result;  	       
  end function  writeToFileMemRawContents;
  
  
	-------------------------------------------------
	-- Function Write to a file the mem contents to check Read of Start of H processing
	-------------------------------------------------
  impure function writeToFileMemRawContentsHRead(  signal fft_mem   : in MEM_ARRAY) return result_type is
  
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   --variable k            : integer;
	   --variable fft_spec     : MEM_ARRAY;
	   variable data_write_var : bit_vector(63 downto 0);
	   begin
	   	 	--for i in  0 to MAX_SAMPLES-1 loop
	      --   for j in 0 to MAX_SAMPLES-1 loop
	      --      k := fft_bin_center_addr(j);
	      --      fft_spec(i,k) := (fft_mem(i,j));
	      --   end loop;
	      --end loop;
	     file_open(write_file,"col_rd_h_mem_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  --data_write_var := to_bitvector(fft_spec(i,j));
	                  data_write_var := to_bitvector(fft_mem(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file,mem_line_var);                  
	                  --report" Start writing to file ";
	              end loop;
	          end loop;
	      done := 1;
	      file_close(write_file);
	      report" Done writing to file ";	  
  	    return result;  	       
  end function  writeToFileMemRawContentsHRead;
  
  -------------------------------------------------
	-- Function Write to a file the mem contents to check write of finish of H processing
	-------------------------------------------------
  impure function writeToFileMemRawContentsHWrite(  signal fft_mem   : in MEM_ARRAY) return result_type is
  
	   variable result       : result_type;    
	   variable mem_line_var : line;
	   variable done         : integer;
	   variable data_write_var : bit_vector(63 downto 0);
	   begin
	     file_open(write_file,"col_wr_h_mem_vectors.txt",write_mode);
	     report" File Opened for writing ";
	          for i in  0 to MAX_SAMPLES-1 loop
	              for j in 0 to MAX_SAMPLES-1 loop
	                  data_write_var := to_bitvector(fft_mem(i,j));
	                  write(mem_line_var ,data_write_var);
	                  writeline(write_file,mem_line_var);                  
	              end loop;
	          end loop;
	      done := 1;
	      file_close(write_file);
	      report" Done writing to file ";	  
  	    return result;  	       
  end function  writeToFileMemRawContentsHWrite;



-------------------------------------------------	
-------------------------------------------------
-------------------------------------------------.
-- For Verification Only Code Above
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

	
	
begin
	
  -----------------------------------------
  -- Transpose mem_intf
  -----------------------------------------.	
   g_use_u1_no_debug : if g_USE_DEBUG_MODE_i = 0 generate -- default condition
 		
  	u1 : entity work.blk_mem_image_gen_LL_0 
  	PORT MAP ( 
  	clka  => clk_i,                                      --clka : in STD_LOGIC;
  	ena   => ena_to_mem_d,                               --ena : in STD_LOGIC;
  	wea   => wea,                                        --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  	addra => addra,                                      --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  	dina  => dina,                                       --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  	douta => data_out_no_debug_default_r                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  	);

    data_out_r <= data_out_no_debug_default_r;
    
 end generate g_use_u1_no_debug;
 
 write_control_from_generic <= std_logic_vector(to_unsigned(debug_state_i,write_control_from_generic'length));
 	
 	
g_use_u2_debug_h_transpose_mem : if g_USE_DEBUG_MODE_i = 1 generate -- debug H
	
u2 : blk_mem_gen_debug_h_transpose_mem_REGEN2_LL_0 -- 256x256 entries of 2 + 3i( single float)
  PORT MAP ( 
  clka => clk_i, --clka : in STD_LOGIC;
  ena => ena_to_mem_d, --ena : in STD_LOGIC;
  wea => write_control_from_generic, --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => addra, --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => dina, --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_out_no_debug_fwd_2d_A_r --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );
 
--u2 : blk_mem_gen_debug_h_transpose_mem_REGEN_LL_0 -- 256x256 entries of 2 + 3i( single float)
--  PORT MAP ( 
--  clka => clk_i, --clka : in STD_LOGIC;
--  ena => ena_to_mem_d, --ena : in STD_LOGIC;
--  wea => write_control_from_generic, --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
--  addra => addra, --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
--  dina  => dina, --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
--  douta => data_out_no_debug_fwd_2d_A_r --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
--  );

  data_out_r <= data_out_no_debug_fwd_2d_A_r;

--u2 : entity blk_mem_debug_h_transpose_seq_mem_LL_0 
--u2 : blk_mem_debug_h_transpose_seq_mem_LL_0 

--  PORT MAP ( 
--    clka  => clk_i,--clka : in STD_LOGIC;
--    ena   => ena_to_mem_d,--ena : in STD_LOGIC;
--    wea   => write_control_from_generic,--wea : in STD_LOGIC_VECTOR ( 0 to 0 );
--    addra => addra,--addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
--    dina  => dina,--dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
--    douta => data_out_no_debug_fwd_2d_A_r--douta : out STD_LOGIC_VECTOR ( 79 downto 0 ).
--  );



end generate g_use_u2_debug_h_transpose_mem;


 
 -- kludge fix to read from transpose the last sample
 
 delay_ena_to_mem : process(clk_i, rst_i)
 	
 	 begin 
 	 	
 	 	 if (rst_i = '1') then
 	 	
 	 	 	 ena_to_mem_r  <= '0';
 	 	 	 ena_to_mem_rr <= '0';
 	 	 	
 	 	 elsif( clk_i'event and clk_i = '1') then
 	 	 	 ena_to_mem_r  <= ena;
 	 	 	 ena_to_mem_rr <= ena_to_mem_r;
 	 	 	 
 	 	 end if;
 	 	 	
 end process delay_ena_to_mem;
 
 ena_to_mem_d <= ena or ena_to_mem_r or ena_to_mem_rr;

-----------------------------------------------------------------
-----------------------------------------------------------------    
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
--Verification        Verify Block mem Rd            Verification
--Verification                                       Verification
--Verification       Use in conjuntion with Matlab   Verification
--Verification          folder:                      Verification
--Verification          file: verify_block_mem_rd.m  Verification
-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------
----------------------------------------
-- Write control
----------------------------------------.
process_write_d <= not(master_mode_i(2)) and not(master_mode_i(1)) and master_mode_i(0);
	
	proc_write_reg : process(clk_i,rst_i)
		begin
			if(rst_i = '1') then
				process_write_r <= '0';
			elsif(clk_i'event and clk_i = '1')then
				process_write_r <= process_write_d;
			end if;
				
	end process proc_write_reg;



----------------------------------------
-- Read control
----------------------------------------
 enable_read  <= ena and not(wea(0));
 	 	
 	
 delay_enable_read_reg  : process(clk_i, rst_i)
 		begin
 			if( rst_i = '1') then
 				enable_read_r     <= '0';
 				enable_read_rr    <= '0';
 				
 			elsif(clk_i'event and clk_i = '1') then
 				enable_read_r     <= enable_read;
 				enable_read_rr    <= enable_read_r;
 			end if;
 				
 end process delay_enable_read_reg;
  
  ----------------------------------------
  -- Counters for fast address Verification
  ----------------------------------------
  -- counter for lower index
  state_counter_1 : process( clk_i, rst_i,clear_state_counter_1_r)
    begin
      if  ( rst_i = '1' )   then
          state_counter_1_r       <=  0 ;
          state_counter_1_rr      <=  0 ;
          state_counter_1_rrr     <=  0 ;
      elsif( clear_state_counter_1_r = '1' ) then
          state_counter_1_r       <=  0 ;
          state_counter_1_rr      <=  0 ;
          state_counter_1_rrr     <=  0 ;              
      elsif( clk_i'event and clk_i = '1') then
        if (( enable_read = '1') or (enable_read_r = '1')) then
          state_counter_1_r       <=  state_counter_1_r + 1;
          state_counter_1_rr      <=  state_counter_1_r;
          state_counter_1_rrr     <=  state_counter_1_rr;
        end if;
      end if;
  end process state_counter_1;


 
 ----------------------------------------
 -- Counter for slow address
 ----------------------------------------
  state_counter_2 : process( clk_i, rst_i,clear_state_counter_2_rr)
    begin
      if ( rst_i = '1' ) then
          state_counter_2_r       <=  0;
         
      elsif(falling_edge_for_last_read_r = '1') then
          state_counter_2_r       <=  0;
         
      elsif( clk_i'event and clk_i = '1') then
         if ( falling_valid_event_rrr = '1') then 
          state_counter_2_r       <=  state_counter_2_r + 1;
          
         end if;
      end if;
  end process state_counter_2;
  
   ----------------------------------------.
  -- clear counter fast address
  ----------------------------------------.
    clear_state_counter_1_reg : process(clk_i, rst_i)
  	begin
  		if ( rst_i = '1') then
  			clear_state_counter_1_r  <=  '0';
  	  elsif(clk_i'event and clk_i  = '1') then
        clear_state_counter_1_r   <=  falling_valid_event_r;
  	  end if;
  end process clear_state_counter_1_reg;
  
  
   ----------------------------------------
  -- Decode terminal count for slow address
  ----------------------------------------.
  decode_terminal_count : process(state_counter_2_r)
  	begin
  		if (  state_counter_2_r = MAX_SAMPLES_MINUS_ONE ) then
  			clear_state_counter_2_d <= '1';
  	  else
  	  	clear_state_counter_2_d <= '0';
  	  end if;
  end process decode_terminal_count;
  
  
   ----------------------------------------
  -- Delay terminal count for slow address
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
  
  ----------------------------------------
 -- Logic for slow address and clear of fast address
 ----------------------------------------.
  
  -- Falling edge of mvalid.
  falling_edge_valid : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1') then
  			delay_ena <= '0';
  		elsif(clk_i'event and clk_i = '1') then
  			delay_ena <= enable_read;
  		end if;
  end process falling_edge_valid;
  
  falling_valid_event_int <= not(enable_read) and delay_ena;
  
  falling_edge_mvalid_reg : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1')	then
  			falling_valid_event_r   <= '0';
  			falling_valid_event_rr  <= '0';
  			falling_valid_event_rrr <= '0';

  	  elsif(clk_i'event and clk_i = '1') then
  	  	falling_valid_event_r   <= falling_valid_event_d;
  	  	falling_valid_event_rr  <= falling_valid_event_r;
  	  	falling_valid_event_rrr <= falling_valid_event_rr;

  	  end if;
  end process falling_edge_mvalid_reg;
  
  -- register signal for: Read state ( filter out all writes)
  
  falling_valid_event_d <= (falling_valid_event_int and qualify_state_int);
  	
  delay_qualify_state_reg : process(clk_i,rst_i)
  	begin
  		if(rst_i = '1') then
  			qualify_state_r    <= '0';
  			qualify_state_rr   <= '0';
  			qualify_state_rrr  <= '0';
  			qualify_state_rrrr <= '0';
  		elsif(clk_i'event and clk_i = '1')then
  			qualify_state_r    <= dbg_qualify_state_i;
  			qualify_state_rr   <= qualify_state_r;
  			qualify_state_rrr  <= qualify_state_rr;
  			qualify_state_rrrr <= qualify_state_rrr; 			
  		end if;
  end process delay_qualify_state_reg;
  
  qualify_state_int <= qualify_state_rrrr;       
            
              
 ----------------------------------------
 -- Logic for last write to buffer; All Memory controller reads and writes have ended
 ----------------------------------------
 
       -- generate extra write; when generated write falls kick of state to generate buffer addr
       -- when this signal falls this will be falling event used by counter 1 and counter 2 above.
   enable_write <= ena and (wea(0));
   	
   enable_write_reg  : process(clk_i, rst_i)
 		begin
 			if( rst_i = '1') then
 				enable_write_r     <= '0';
 				enable_write_rr    <= '0';
 				
 			elsif(clk_i'event and clk_i = '1') then
 				enable_write_r     <= enable_write;
 				enable_write_rr    <= enable_write_r; -- Use delay for falling edge detect
 			end if;
 				
  end process enable_write_reg;
  
  
  falling_edge_for_last_write_d <= not(enable_write_r)	and enable_write_rr;
  	
  falling_edge_for_last_write_reg_proc : process(clk_i,rst_i)	
  	begin
  		if(rst_i = '1') then
  			falling_edge_for_last_write_r <= '0';
  			
  		elsif(clk_i'event and clk_i = '1')then
  			falling_edge_for_last_write_r <= falling_edge_for_last_write_d;
  			
  		end if;
  			
  end process falling_edge_for_last_write_reg_proc;
  
  
 					----------------------------------------
  				-- Main State Machine (Comb).....
 				  ----------------------------------------  	
         st_mach_controller : process(
       	       falling_edge_for_last_write_r,
       	       state_counter_1_r,    	  
       	       ps_controller
            ) begin
       	
              case ps_controller is
       	
                 when state_quies =>
            	
            	     decoder_st_d <= "01"; 
            	
            	     if(( falling_edge_for_last_write_r = '1' ) and
            	     	  ( state_counter_2_r = 255) ) then 
            		 
            		     ns_controller <= state_enable_last_read;
            		     
            	    else
            		     ns_controller <= state_quies;
            		     
                  end if;
                  	
                 when state_enable_last_read =>
                 	
                 	 decoder_st_d <= "10";
                 	 
                 	   if( state_counter_1_r = 253) then
                 	 	
                 	 	 ns_controller <= state_quies;
                 	 	 
                 	 else
                 	 	
                 	 	 ns_controller <= state_enable_last_read;
                 	 	 
                 	 end if;
                 	 	
                 when others =>
                 	
                 	  ns_controller <= state_quies;
                 	  
             end case;   
         end process  st_mach_controller;   
         
         
         st_mach_controller_decode : process(
         	
         	decoder_st_r) begin
         		
         		            case  decoder_st_r  is
         		            	
         		            	
         		            	when "01" =>
         		            		
         		            		enable_last_read_d <= '0';
         		            		
         		            	when "10" =>
         		            		
         		            		enable_last_read_d <= '1';
         		            		
         		              when others => 
         		              	
         		              	enable_last_read_d <= '0';
         		              	
         		            end case;
         	end process st_mach_controller_decode;
         	
         	
         	st_mach_controller_registers : process(clk_i,rst_i)
         		
         		begin
         			if(rst_i = '1')then
         				enable_last_read_r <= '0';
         				enable_last_read_rr <= '0';
         				decoder_st_r <= (others=> '0');
         					
         				ps_controller <= state_quies;
         					
         		  elsif(clk_i'event and clk_i = '1')then
         		  	enable_last_read_r  <= enable_last_read_d;
         		  	enable_last_read_rr <= enable_last_read_r; -- use for delay of falling edge
         		  	decoder_st_r  <= decoder_st_d;
         		  	
         		  	ps_controller <= ns_controller;
         		  	
         		  end if;
         	end process st_mach_controller_registers;
         	
         	falling_edge_for_last_read_d <= not(enable_last_read_r)	and enable_last_read_rr;
         		
      
  	
         falling_edge_for_last_read_reg_proc : process(clk_i,rst_i)	
  	       begin
  		      if(rst_i = '1') then
  			      falling_edge_for_last_read_r <= '0';
  			
  		     elsif(clk_i'event and clk_i = '1')then
  			      falling_edge_for_last_read_r <= falling_edge_for_last_read_d;
  			
  		     end if;
  			
         end process falling_edge_for_last_read_reg_proc;	
         
         
  -----------------------------------------------------------------------
  -- Store Write inputs into Memory
  -----------------------------------------------------------------------. 
  
  addra_int <= to_integer(unsigned(addra));
        
  RamProcWrRawData : process(clk_i,rst_i)

    begin
  	  if ( rst_i = '1' ) then       
         dummy <= '1';
      	
  	  elsif enable_write = '1' then 		  
  		  fft_raw_wr_mem(addra_int) <= dina(71 downto 40) & dina(31 downto 0);  				  			  				  
				  
  		end if;
   end process RamProcWrRawData;
    

  -----------------------------------------------------------------------
  -- Store read outputs from memory; We are reading an array built by  process record_outputs
  -----------------------------------------------------------------------.
  --Note:
  -- mem(col,row), If the fast addr seq is ROW here in VHDL, and our Matlab is saved to file as  row striped( sample  0,1,2,3...255 is first row )
  -- also means we stack the row vectors on top of each other for the file, then
  -- then we build our vhdl mem array as [ 0     1    2 ... 255;
  --                                       256 257 258  ... 511]  this in COE; The Matlab is consistent with this VHDL process below 
  --
  -- Another way of thinking of the process below is that we are writing to the matrix h_read_mem( e.g.) down a row because
  -- our addressing from VHDL is down the column with addr: 0 256 512 .....
  RamProcRawData : process(clk_i,rst_i)

    begin
  	  if ( rst_i = '1' ) then       
         dummy <= '1';
      	
  	  elsif enable_read_rr = '1' then 		  
  		  fft_raw_mem(state_counter_1_rrr,state_counter_2_r) <= data_out_r(71 downto 40) & data_out_r(31 downto 0);  				  			  				  
				  
  		end if;
   end process RamProcRawData;  
  
  RamProcRawHReadData : process(clk_i,rst_i)
    begin
  	  if ( rst_i = '1' ) then
         dummy_h_read <= '1';
     elsif( (enable_read_rr = '1') and (master_mode_i = "00011") )then 			   		 
   		    h_read_mem(state_counter_2_r,state_counter_1_rrr) <= data_out_r(71 downto 40) & data_out_r(31 downto 0);  				  			  
  				  			  
  		end if;
   end process RamProcRawHReadData;
   
    RamProcRawHWriteData : process(clk_i,rst_i)
    begin
  	  if ( rst_i = '1' ) then
         dummy_h_write <= '1';
      elsif( (enable_read_rr = '1') and (master_mode_i = "00011") )then 			-- enable_read_rr instead of enable_write_rr
     	                                                                      -- because we enable WRITING to this buffer h_write_mem
     	                                                                      -- After we have done a enable_write_rr to the real
     	                                                                      -- memory in the FPGA.  		  
   		    h_write_mem(state_counter_2_r,state_counter_1_rrr) <= dina(71 downto 40) & dina(31 downto 0); 
   		    	
   	 elsif( (enable_last_read_r = '1') and (master_mode_i = "00011") ) then
   		
   		    h_write_mem(state_counter_2_r,state_counter_1_rrr) <= dina(71 downto 40) & dina(31 downto 0); 
 				  			  
  				  			  
  	 end if;
   end process RamProcRawHWriteData;   
    
  -------------------------------------------------
	-- Write to a file the mem contents to check
	-------------------------------------------------  
	
enable_file_capture <= std_logic_vector(to_unsigned(debug_capture_file_i,enable_file_capture'length));
	
data_write : process(process_write_r)

  --report " This is a read of one frame

  begin
   if( (process_write_r  = '1') and (enable_file_capture(0) = '1') ) then -- Have completed MAX_SAMPLE FFT Computations( 1-D)
       write_fft_1d_wr_raw_done <= writeToFileMemRawContentsFFTWrite(fft_raw_wr_mem);	
       report "Module: Mem Transpose -> Done write for one frame";
   end if;
end process data_write;

	
data_read : process(clear_state_counter_2_rr)

  --report " This is a read of one frame

  begin
   if( (clear_state_counter_2_rr  = '1') and (enable_file_capture(0) = '1') ) then -- Have completed MAX_SAMPLE FFT Computations( 1-D)
       write_fft_1d_raw_done <= writeToFileMemRawContents(fft_raw_mem);	
       report "Module: Mem Transpose -> Done Reads for one frame";
   end if;
end process data_read;


data_h_read : process(clear_state_counter_2_rr)

  --report " This is a read of one frame

  begin
   if ( (clear_state_counter_2_rr  = '1') and (master_mode_i = "00011") and (enable_file_capture(0) = '1')  ) then
        write_h_init_done   <= writeToFileMemRawContentsHRead(h_read_mem);	
       report "Module: Mem Transpose -> Done Reads for one frame of H Init";
   end if;
end process data_h_read;


data_h_write : process(clear_state_counter_2_rr)

  --report " This is a write of one frame

  begin
   if ( (clear_state_counter_2_rr  = '1') and (master_mode_i = "00011") and (enable_file_capture(0) = '1')  ) then
        write_h_mult_done   <= writeToFileMemRawContentsHWrite(h_write_mem);	
       report "Module: Mem Transpose -> Done writes for one frame of H Mult";
   end if;
end process data_h_write;

 
 	 	
  ----------------------------------------
  -- Assignments
  ----------------------------------------
  
  douta <=  data_out_r;  
  vouta <=  enable_read_rr;
 
  
end architecture stub;