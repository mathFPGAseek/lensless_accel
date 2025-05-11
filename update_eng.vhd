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
-- filename: update_eng.vhd
-- Initial Date: 7/4/24
-- Descr: 
-- H,H* mult proc: mult hadmard w/ trans  & write to trans_mem_buffer
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity update_eng is
--generic(
--	     g_USE_DEBUG_i  : in natural := 1);
    port (
   
    clk_i                             : in std_logic;
		rst_i                             : in std_logic;
		master_mode_i                     : in std_logic_vector(4 downto 0);
		       
		-- FIFO inputs
		fifo_high_ovf_i                   : in std_logic;
		fifo_high_uf_i                    : in std_logic;
		       
		fifo_low_ovf_i                    : in std_logic;
		fifo_low_uf_i                     : in std_logic;	       
		       
		-- port 1 inputs
		       
		port_1_valid_in_i                 : in std_logic;
		port_1_data_in_i                  : in std_logic_vector(79 downto 0);  
		       
		-- port 2 inputs
		       
		port_2_valid_in_i                 : in std_logic;
		port_2_data_in_i                  : in std_logic_vector(79 downto 0); 
		       
		-- FIFO outputs
		fifo_high_rd_en_o                 : out std_logic;
		fifo_low_rd_en_o                  : out std_logic;
		       
		-- Data out
		valid_out_o                       : out std_logic;
		addr_out_o                        : out std_logic_vector(16 downto 0);
		data_out_o                        : out std_logic_vector(79 downto 0);
		       
		-- rdy flag
		rdy_o                             : out std_logic
		      

    );
    
end update_eng;

architecture struct of update_eng is




begin
	
    -- FIFO outputs
		fifo_high_rd_en_o     <= '0';
		fifo_low_rd_en_o      <= '0';
		       
		-- Data out
		valid_out_o           <= '0';
		addr_out_o            <= (others => '0');
		data_out_o            <= (others => '0');
		       
		-- rdy flag
		rdy_o                 <= '0';
	




end architecture struct;	