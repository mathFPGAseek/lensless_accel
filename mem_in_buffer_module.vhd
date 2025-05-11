library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_in_buffer_module is
	generic(
  	       g_USE_DEBUG_MODE_i : in natural := 0);
  
  
  Port ( 
    clk_i : in STD_LOGIC;
    rst_i : in STD_LOGIC;
    ena : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 7 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 79 downto 0 );
    clkb : in STD_LOGIC;
    enb : in STD_LOGIC;
    addrb : in STD_LOGIC_VECTOR ( 7 downto 0 );
    doutb : out STD_LOGIC_VECTOR ( 79 downto 0 )
  );

end mem_in_buffer_module;

architecture stub of mem_in_buffer_module is
--attribute syn_black_box : boolean;
--attribute black_box_pad_pin : string;
--attribute syn_black_box of stub : architecture is true;
--attribute black_box_pad_pin of stub : architecture is "clka,ena,wea[0:0],addra[7:0],dina[79:0],clkb,enb,addrb[7:0],doutb[79:0]";
--attribute x_core_info : string;
--attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";.
signal doutb_int    : std_logic_vector( 79 downto 0);
signal data_out_r   : std_logic_vector( 79 downto 0);
signal data_out_rr  : std_logic_vector( 79 downto 0);
	
	
begin
	
--U1 : entity work.blk_dual_mem_gen_0
--PORT MAP( 
--  clka      =>  clk_i,               --: in STD_LOGIC;.
--  ena       =>  ena,                --: in STD_LOGIC;
--  wea       =>  wea,                --: in STD_LOGIC_VECTOR ( 0 to 0 );
--  addra     =>  addra,               --: in STD_LOGIC_VECTOR ( 7 downto 0 );
--  dina      =>  dina,               --: in STD_LOGIC_VECTOR ( 79 downto 0 );
--  clkb      =>  clk_i,               --: in STD_LOGIC;
--  enb       =>  enb,               --: in STD_LOGIC;
--  addrb     =>  addrb,                --: in STD_LOGIC_VECTOR ( 7 downto 0 );
--  doutb     =>  doutb_int                --: out STD_LOGIC_VECTOR ( 79 downto 0 ).
--);
  
  U1 : entity work.blk_dual_mem_gen_no_reg_LL_0
  PORT MAP( 
    clka      =>  clk_i,               --: in STD_LOGIC;.
    ena       =>  ena,                --: in STD_LOGIC;
    wea       =>  wea,                --: in STD_LOGIC_VECTOR ( 0 to 0 );
    addra     =>  addra,               --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    dina      =>  dina,               --: in STD_LOGIC_VECTOR ( 79 downto 0 );
    clkb      =>  clk_i,               --: in STD_LOGIC;
    enb       =>  enb,               --: in STD_LOGIC;
    addrb     =>  addrb,                --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    doutb     =>  doutb_int                --: out STD_LOGIC_VECTOR ( 79 downto 0 ).
  );
  
  
  
  --delay_data_out : process(clk_i,rst_i)
  --	begin
  --		if(rst_i = '1') then
  --			
  --			data_out_r  <= (others => '0');
  --			data_out_rr <= (others => '0');
  --				
  --		elsif(clk_i'event and clk_i = '1') then
  --			
  --			data_out_r  <= doutb_int;
  --			data_out_rr <= data_out_r;
  --			
  --	  end if;
  --	  	
  --	end process  delay_data_out;
  --			
  -----------------------------------------
  --  Assignments
  -----------------------------------------	
  			
  --doutb <= data_out_rr;
  doutb <=  doutb_int;
  
end architecture stub;