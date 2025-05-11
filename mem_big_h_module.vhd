library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;


entity mem_big_h_module is
 Port (
    clk_i : in STD_LOGIC; 
    rst_i : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 79 downto 0 );
    vouta : out STD_LOGIC;
    dbg_qualify_state_i : in STD_LOGIC
  );

end mem_big_h_module;

architecture stub of mem_big_h_module is
--attribute syn_black_box : boolean;
--attribute black_box_pad_pin : string;
--attribute syn_black_box of stub : architecture is true;
--attribute black_box_pad_pin of stub : architecture is "clka,ena,wea[0:0],addra[7:0],dina[79:0],clkb,enb,addrb[7:0],doutb[79:0]";
--attribute x_core_info : string;
--attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";.
signal enable_read                  : std_logic;
signal enable_read_r                : std_logic;
signal enable_read_rr               : std_logic;

signal data_out_r                   : std_logic_vector( 79 downto 0);

	
	
begin
	
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
 
	
  -----------------------------------------
  -- Transpose mem_intf
  -----------------------------------------	
  		
  	u1 : entity work.blk_mem_big_h_image_gen_0 
  	PORT MAP ( 
  	clka  => clk_i,                                      --clka : in STD_LOGIC;
  	ena   => ena,                                        --ena : in STD_LOGIC;
  	wea   => wea,                                        --wea : in STD_LOGIC_VECTOR ( 0 to 0 );
  	addra => addra,                                      --addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
  	dina  => dina,                                       --dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
  	douta => data_out_r                                  --douta : out STD_LOGIC_VECTOR ( 79 downto 0 )
  	);

 	
  ----------------------------------------
  -- Assignments
  ----------------------------------------.
  
  douta <=  data_out_r;  
  vouta <=  enable_read_rr;
 
 
  
end architecture stub;