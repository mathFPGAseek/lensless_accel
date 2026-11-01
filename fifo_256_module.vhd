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
-- filename: init_fifo_256_module.vhd
-- Initial Date: 9/27/26
-- Descr: FIFO to store addr for PS bus
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

   
entity  fifo_256_module  is
  port(
    clk 											: IN STD_LOGIC;
    srst 			                : IN STD_LOGIC;
    din                       : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    wr_en                     : IN STD_LOGIC;
    rd_en                     : IN STD_LOGIC;
    dout                      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full                      : OUT STD_LOGIC;
    empty                     : OUT STD_LOGIC;
    wr_rst_busy               : OUT STD_LOGIC;
    rd_rst_busy               : OUT STD_LOGIC
  );                        

end fifo_256_module;  

                                        

architecture struct of fifo_256_module is 
	
	signal din_r               : std_logic_vector(15 downto 0);
	signal din_rr              : std_logic_vector(15 downto 0);
	
	begin
		
	reg_wr_en_proc : process( clk, srst)
		
		begin
			
			 if ( srst = '1') then
			 	 din_r <= (others => '0');
			 	 din_rr <= (others => '0');
			 	 	
			 elsif( clk'event and clk = '1') then
			 	 din_r  <= din;
			 	 din_rr <= din_r;
			 	 
			 end if;
	end process reg_wr_en_proc;
			 	
			 	   
		
	u1 : entity  work.fifo_256
  PORT  MAP(
    clk 											=>  clk, --: IN STD_LOGIC;
    srst 			                =>  srst, --: IN STD_LOGIC;
    din                       =>  din_rr, --: IN STD_LOGIC_VECTOR(79 DOWNTO 0);
    wr_en                     =>  wr_en, --: IN STD_LOGIC;
    rd_en                     =>  rd_en, --: IN STD_LOGIC;
    dout                      =>  dout, --: OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
    full                      =>  full, --: OUT STD_LOGIC;
    empty                     =>  empty, --: OUT STD_LOGIC;
    wr_rst_busy               =>  wr_rst_busy,--: OUT STD_LOGIC;
    rd_rst_busy               =>  rd_rst_busy --: OUT STD_LOGIC
  );
  
 end architecture struct;