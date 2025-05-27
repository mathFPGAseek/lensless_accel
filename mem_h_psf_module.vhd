library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;
LIBRARY xil_defaultlib;
USE xil_defaultlib.all;


entity mem_h_psf_module is
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
  	       debug_capture_file_i : integer := 0;
  	       debug_state_i : in integer := 0;         -- = 0 no write = 1 write
  	       g_USE_DEBUG_MODE_i : in natural := 0   -- To use COE file
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

end mem_h_psf_module;

architecture stub of mem_h_psf_module is
--attribute syn_black_box : boolean;
--attribute black_box_pad_pin : string;.
--attribute syn_black_box of stub : architecture is true;
--attribute black_box_pad_pin of stub : architecture is "clka,ena,wea[0:0],addra[7:0],dina[79:0],clkb,enb,addrb[7:0],doutb[79:0]";
--attribute x_core_info : string;
--attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";.

-- For verification and synthesis
signal data_out_r                   : std_logic_vector( 79 downto 0);
signal data_out_no_debug_default_r  : std_logic_vector( 79 downto 0);
signal data_out_no_debug_fwd_2d_A_r        : std_logic_vector( 79 downto 0);
signal enable_read                  : std_logic;
signal enable_read_r                : std_logic;
signal enable_read_rr               : std_logic;


-------------------------------------------------	
-------------------------------------------------
-------------------------------------------------
-- For Verification Only Code below
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

-- signals for kludge
signal ena_to_mem_r                 : std_logic;
signal ena_to_mem_rr                : std_logic;
signal ena_to_mem_d                 : std_logic;


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
  --g_use_u1_no_debug : if debug_state_i = 0 generate -- default condition
 g_use_u1_no_debug : if g_USE_DEBUG_MODE_i = 0 generate -- default condition
 		
  	--u1 : entity work.blk_mem_gen_h_psf_mem_LL_0 
  	u1 : entity xil_defaultlib.blk_mem_gen_h_psf_mem_LL_0 

  	PORT MAP ( 
  	clka  => clk_i,                                      --clka : in STD_LOGIC;
  	--ena   => ena,                                      --ena : in STD_LOGIC;
  	ena   => ena_to_mem_d,                               --ena : in STD_LOGIC;
  	wea   => wea,                                        --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  	addra => addra,                                      --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  	dina  => dina,                                       --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  	douta => data_out_no_debug_default_r                 --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  	);

    data_out_r <= data_out_no_debug_default_r;
    
 end generate g_use_u1_no_debug;
 	
g_use_u2_debug_h_psf_mem : if g_USE_DEBUG_MODE_i = 1 generate -- debug H
 
u2 : entity work.blk_mem_debug_h_psf_mem_REGEN_LL_0 -- 256x256 entries of 2 + 3i( single float)
  PORT MAP ( 
  clka => clk_i, --clka : in STD_LOGIC;
  ena => ena_to_mem_d, --ena : in STD_LOGIC;
  wea => wea, --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  addra => addra, --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  dina  => dina, --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  douta => data_out_no_debug_fwd_2d_A_r --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );

  data_out_r <= data_out_no_debug_fwd_2d_A_r;


end generate g_use_u2_debug_h_psf_mem;

 
--    data_out_r <= data_out_no_debug_fwd_2d_A_r;
    
-- end generate g_use_u2_fwd_2d_A_debug;
 
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
 enable_read <= ena and not(wea(0));
 	
 	
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
  -- Assignments
  ----------------------------------------.
  
  douta <=  data_out_r;  
  vouta <=  enable_read_rr;
 
  
end architecture stub;