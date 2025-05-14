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
-- filename: gen_proc_module.vhd
-- Initial Date: 6/19/24
-- Descr: Gen processor engine has (4) modes
-- FFT proc: Gen proc in bypass mode & write to F/E
-- H,H* mult proc: mult hadmard w/ trans  & write to trans_mem_buffer
-- Av-B,pad proc: subs w/ B & write to trans mem_buffer
-- update proc: vk - alpha*trans & proj & write to trans_mem_buffer & vk buffer
------------------------------------------------.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;
LIBRARY xil_defaultlib;
USE xil_defaultlib.all;


entity gen_proc_module is
generic(
	     --g_USE_DEBUG_i  : in natural := 1);
	     g_USE_DEBUG_MODE_i : in natural:= 0
	     );
    port (

	  clk_i               	         		: in std_logic;
    rst_i               	         		: in std_logic;
    
    master_mode_i                  		: in std_logic_vector(4 downto 0); -- Bits 5 & 6 describe engine mode.
  	
      --inputs
    from_trans_mem_valid_i            : in std_logic;
    from_trans_mem_data_i             : in std_logic_vector(79 downto 0); 
    
    from_h_mem_valid_i                : in std_logic;
    from_h_mem_data_i                 : in std_logic_vector(79 downto 0);
    	    
    from_h_star_mem_valid_i           : in std_logic;
    from_h_star_mem_data_i            : in std_logic_vector(79 downto 0);    	
        	    
    from_b_mem_valid_i                : in std_logic;
    from_b_mem_data_i                 : in std_logic_vector(79 downto 0);   	
         	    
    from_vk_mem_valid_i               : in std_logic;
    from_vk_mem_data_i                : in std_logic_vector(79 downto 0);      
  	
    -- outputs
    to_buffer_trans_mem_port_wr_o     : out std_logic;  
    to_buffer_trans_mem_port_addr_o   : out std_logic_vector(16 downto 0);
    to_buffer_trans_mem_port_data_o   : out std_logic_vector(79 downto 0);
    
    to_buffer_vk_mem_port_wr_o        : out std_logic;  
    to_buffer_vk_mem_port_addr_o      : out std_logic_vector(16 downto 0);
    to_buffer_vk_mem_port_data_o      : out std_logic_vector(79 downto 0); 	
   	 
    to_front_end_port_wr_o            : out std_logic;  
    to_front_end_port_data_o          : out std_logic_vector(79 downto 0);
  
    gen_proc_h_h_mult_rdy_o           : out std_logic;
    gen_proc_av_minus_b_rdy_o         : out std_logic;
    gen_proc_vk_mem_rdy_o             : out std_logic

    );
    
end gen_proc_module;

architecture struct of gen_proc_module is
	
-- master mode signals
signal master_mode_upper_bits_d                  : std_logic_vector(4 downto 0);
signal master_mode_upper_bits_r                  : std_logic_vector(4 downto 0);
	
-- mux control for rd fifo signals
signal mux_decode_for_fifo_rd_d                  : std_logic_vector(1 downto 0);
signal mux_decode_for_fifo_rd_r                  : std_logic_vector(1 downto 0);


-- mux to fifo high signals
signal mux_decode_for_fifo_high_d                 : std_logic_vector( 1 downto 0);
signal mux_to_fifo_high_valid_in_d     						: std_logic;
signal mux_to_fifo_high_data_in_d      						: std_logic_vector(79 downto 0);
signal mux_decode_for_fifo_high_r                 : std_logic_vector( 1 downto 0);	
signal mux_to_fifo_high_valid_in_r     						: std_logic;
signal mux_to_fifo_high_data_in_r      						: std_logic_vector(79 downto 0);
	
	
-- demux to fifo low and to output mux (bypass)
signal demux_decode_for_trans_d          				  : std_logic;
signal trans_mem_to_bypass_valid_out_d 						: std_logic;                     -- note: no follow-on reg
signal trans_mem_to_bypass_data_out_d  						: std_logic_vector(79 downto 0); -- note: no follow-on reg	
signal demux_to_fifo_low_valid_in_d    						: std_logic;
signal demux_to_fifo_low_data_in_d     						: std_logic_vector(79 downto 0);
signal demux_decode_for_trans_r          				  : std_logic;		
signal demux_to_fifo_low_valid_in_r    						: std_logic;
signal demux_to_fifo_low_data_in_r     						: std_logic_vector(79 downto 0);	

	
-- demux from FIFOs to internal engines	
signal demux_decode_for_internal_engines_d				: std_logic_vector(1 downto 0);	
signal fr_fifo_high_valid_out_d               		: std_logic;
signal fr_fifo_high_data_out_d                		: std_logic_vector(79 downto 0);
signal fr_fifo_high_valid_out_r               		: std_logic;
signal fr_fifo_high_data_out_r                		: std_logic_vector(79 downto 0);		
signal demux_to_h_mult_eng_port_1_valid_in_d  		: std_logic;
signal demux_to_h_mult_eng_port_1_data_in_d   		: std_logic_vector(79 downto 0);		
signal demux_to_h_mult_eng_port_2_valid_in_d  		: std_logic;
signal demux_to_h_mult_eng_port_2_data_in_d   		: std_logic_vector(79 downto 0);
signal demux_to_av_minus_b_eng_port_1_valid_in_d	: std_logic;
signal demux_to_av_minus_b_eng_port_1_data_in_d   : std_logic_vector(79 downto 0);
signal demux_to_av_minus_b_eng_port_2_valid_in_d	: std_logic;
signal demux_to_av_minus_b_eng_port_2_data_in_d   : std_logic_vector(79 downto 0);
signal demux_to_update_eng_port_1_valid_in_d      : std_logic;
signal demux_to_update_eng_port_1_data_in_d       : std_logic_vector(79 downto 0);
signal demux_to_update_eng_port_2_valid_in_d      : std_logic;
signal demux_to_update_eng_port_2_data_in_d       : std_logic_vector(79 downto 0);
signal demux_decode_for_internal_engines_r				: std_logic_vector(1 downto 0);	
signal fr_fifo_low_valid_out_d               		  : std_logic;
signal fr_fifo_low_data_out_d                		  : std_logic_vector(79 downto 0);
signal fr_fifo_low_valid_out_r               		  : std_logic;
signal fr_fifo_low_data_out_r                		  : std_logic_vector(79 downto 0);
signal demux_to_h_mult_eng_port_1_valid_in_r  		: std_logic;
signal demux_to_h_mult_eng_port_1_data_in_r   		: std_logic_vector(79 downto 0);		
signal demux_to_h_mult_eng_port_2_valid_in_r  		: std_logic;
signal demux_to_h_mult_eng_port_2_data_in_r   		: std_logic_vector(79 downto 0);
signal demux_to_av_minus_b_eng_port_1_valid_in_r	: std_logic;
signal demux_to_av_minus_b_eng_port_1_data_in_r   : std_logic_vector(79 downto 0);
signal demux_to_av_minus_b_eng_port_2_valid_in_r	: std_logic;
signal demux_to_av_minus_b_eng_port_2_data_in_r   : std_logic_vector(79 downto 0);
signal demux_to_update_eng_port_1_valid_in_r      : std_logic;
signal demux_to_update_eng_port_1_data_in_r       : std_logic_vector(79 downto 0);
signal demux_to_update_eng_port_2_valid_in_r      : std_logic;
signal demux_to_update_eng_port_2_data_in_r       : std_logic_vector(79 downto 0);


-- mux from engines
signal mux_decode_for_fr_engines_d                : std_logic_vector(1 downto 0);
signal mux_decode_for_fr_engines_r                : std_logic_vector(1 downto 0);
signal mux_fr_engines_valid_out_d                 : std_logic;
signal mux_fr_engines_addr_out_d                  : std_logic_vector(16 downto 0);
signal mux_fr_engines_data_out_d                  : std_logic_vector(79 downto 0);
signal mux_fr_engines_valid_out_r                 : std_logic;
signal mux_fr_engines_addr_out_r                  : std_logic_vector(16 downto 0);
signal mux_fr_engines_data_out_r                  : std_logic_vector(79 downto 0);
signal from_h_h_star_eng_valid_pr                 : std_logic;
signal from_h_h_star_eng_addr_pr                  : std_logic_vector(16 downto 0);
signal from_h_h_star_eng_data_pr                  : std_logic_vector(79 downto 0);
signal from_av_minus_b_eng_valid_pr               : std_logic;
signal from_av_minus_b_eng_addr_pr                : std_logic_vector(16 downto 0);
signal from_av_minus_b_eng_data_pr                : std_logic_vector(79 downto 0);
signal from_update_eng_valid_pr                   : std_logic;
signal from_update_eng_addr_pr                    : std_logic_vector(16 downto 0);
signal from_update_eng_data_pr                    : std_logic_vector(79 downto 0);
	

-- mux data select to buffer
signal mux_decode_to_buffer_d                     : std_logic;
signal mux_to_buffer_valid_out_d                  : std_logic;
signal mux_to_buffer_addr_out_d                   : std_logic_vector(16 downto 0);
signal mux_to_buffer_data_out_d                   : std_logic_vector(79 downto 0);
signal mux_decode_to_buffer_r                     : std_logic;
signal mux_to_buffer_valid_out_r                  : std_logic;
signal mux_to_buffer_addr_out_r                   : std_logic_vector(16 downto 0);
signal mux_to_buffer_data_out_r                   : std_logic_vector(79 downto 0);

-- mux data select to vk mem
signal mux_decode_to_vk_mem_d                     : std_logic;
signal mux_to_vk_mem_valid_out_d                  : std_logic;
signal mux_to_vk_mem_addr_out_d                   : std_logic_vector(16 downto 0);
signal mux_to_vk_mem_data_out_d                   : std_logic_vector(79 downto 0);
signal mux_decode_to_vk_mem_r                     : std_logic;
signal mux_to_vk_mem_valid_out_r                  : std_logic;
signal mux_to_vk_mem_addr_out_r                   : std_logic_vector(16 downto 0);
signal mux_to_vk_mem_data_out_r                   : std_logic_vector(79 downto 0);

	
-- mux data select to F/E
signal mux_decode_to_front_end_d                  : std_logic_vector(1 downto 0);
signal mux_to_front_end_valid_out_d               : std_logic;
signal mux_to_front_end_data_out_d                : std_logic_vector(79 downto 0);
signal mux_decode_to_front_end_r                  : std_logic_vector(1 downto 0);
signal mux_to_front_end_valid_out_r               : std_logic;
signal mux_to_front_end_data_out_r                : std_logic_vector(79 downto 0);

	
	
-- FIFO signals 
signal fr_fifo_high_ovf_r                         : std_logic;
signal fr_fifo_high_uf_r                          : std_logic;
signal fr_fifo_low_ovf_r                          : std_logic;
signal fr_fifo_low_uf_r                           : std_logic;

signal fr_fifo_high_ovf_pd                        : std_logic;
signal fr_fifo_high_uf_pd                         : std_logic;

signal fr_fifo_low_ovf_pd                         : std_logic;
signal fr_fifo_low_uf_pd                          : std_logic;

signal fr_mux_to_fifo_high_rd_d                   : std_logic;
signal fr_mux_to_fifo_high_rd_r                   : std_logic;
signal fr_mux_to_fifo_low_rd_d                    : std_logic;
signal fr_mux_to_fifo_low_rd_r                    : std_logic;

signal rd_en_fifo_high_fr_h_mult_eng_pr           : std_logic;
signal rd_en_fifo_low_fr_h_mult_eng_pr            : std_logic;
signal rd_en_fifo_high_fr_av_minus_b_eng_pr       : std_logic;
signal rd_en_fifo_low_fr_av_minus_b_eng_pr        : std_logic;
signal rd_en_fifo_high_fr_update_eng_pr           : std_logic;
signal rd_en_fifo_low_fr_update_eng_pr            : std_logic;

signal fr_fifo_high_data_out_pd                   : std_logic_vector(79 downto 0);
signal fr_fifo_high_valid_out_pd                  : std_logic;	

signal fr_fifo_low_data_out_pd                    : std_logic_vector(79 downto 0);
signal fr_fifo_low_valid_out_pd                   : std_logic;

-- rdy flags
signal rdy_flag_fr_h_h_star_mult_eng_pr           : std_logic;
signal rdy_flag_fr_av_minus_b_eng_pr              : std_logic;
signal rdy_flag_fr_update_eng_pr                  : std_logic;
                        		
		
------------------------------------------------- 
-- For Synthesis and Verification                          
-------------------------------------------------

-------------------------------------------------
-- For Debug  Only
-------------------------------------------------.
constant ADDR_WIDTH : integer := 8;


begin

 master_mode_upper_bits_d <= master_mode_i(4 downto 0);
 	 
-----------------------------------------
-- Decode for Mux and Demux control
-----------------------------------------	 
--decode_logic_for_mux_demux_control : process(master_mode_upper_bits_r)
decode_logic_for_mux_demux_control : process(master_mode_upper_bits_r)

begin
	
	case master_mode_upper_bits_r is
		
				
		when  "00000" => -- Bypass processing 1-d fft or 1d ifft / 2-d fft or 2d ifft
								
			mux_decode_for_fifo_rd_d             <=   "00"; -- set for h mult but a Don't care for bypass
			mux_decode_for_fifo_high_d           <=   "00"; -- same as above
			demux_decode_for_trans_d             <=   '0';
			demux_decode_for_internal_engines_d  <=   "00"; -- same as above
			mux_decode_for_fr_engines_d          <=   "00"; -- same as above
			mux_decode_to_buffer_d               <=   '0';
			mux_decode_to_vk_mem_d               <=   '0';
			mux_decode_to_front_end_d            <= 	"10";	
		
	  		
		when  "00001" => -- Bypass processing 1-d fft or 1d ifft / 2-d fft or 2d ifft
								
			mux_decode_for_fifo_rd_d             <=   "00"; -- set for h mult but a Don't care for bypass
			mux_decode_for_fifo_high_d           <=   "00"; -- same as above
			demux_decode_for_trans_d             <=   '0';
			demux_decode_for_internal_engines_d  <=   "00"; -- same as above
			mux_decode_for_fr_engines_d          <=   "00"; -- same as above
			mux_decode_to_buffer_d               <=   '0';
			mux_decode_to_vk_mem_d               <=   '0';
			mux_decode_to_front_end_d            <= 	"10";		
		
		when  "00011" => -- H processing
			
			mux_decode_for_fifo_rd_d             <=  "00";
			mux_decode_for_fifo_high_d           <=  "00";
			demux_decode_for_trans_d             <=  '1';
			demux_decode_for_internal_engines_d  <=  "00";
			mux_decode_for_fr_engines_d          <=  "00";
			mux_decode_to_buffer_d               <=  '1';
			mux_decode_to_vk_mem_d               <=  '0';
			mux_decode_to_front_end_d            <=  "00";
			
		when  "00010" => -- H* processing
					
			mux_decode_for_fifo_rd_d             <=  "00";
			mux_decode_for_fifo_high_d           <=  "01";
			demux_decode_for_trans_d             <=  '1';
			demux_decode_for_internal_engines_d  <=  "00";
			mux_decode_for_fr_engines_d          <=  "00";
			mux_decode_to_buffer_d               <=  '1';
			mux_decode_to_vk_mem_d               <=  '0';
			mux_decode_to_front_end_d            <=  "00";
			
		when  "00110" => -- Av-b processing
								
			mux_decode_for_fifo_rd_d             <=  "01";
			mux_decode_for_fifo_high_d           <=  "10";
			demux_decode_for_trans_d             <=  '1';
			demux_decode_for_internal_engines_d  <=  "01";
			mux_decode_for_fr_engines_d          <=  "01";
			mux_decode_to_buffer_d               <=  '1';
			mux_decode_to_vk_mem_d               <=  '0';
			mux_decode_to_front_end_d            <=  "00";
	
				
		when  "00111" => -- Update processing			
					
			mux_decode_for_fifo_rd_d             <=   "10";
			mux_decode_for_fifo_high_d           <=   "11";
			demux_decode_for_trans_d             <=   '1';
			demux_decode_for_internal_engines_d  <=   "10";
			mux_decode_for_fr_engines_d          <=   "10";
			mux_decode_to_buffer_d               <=   '0';
			mux_decode_to_vk_mem_d               <=   '1';
			mux_decode_to_front_end_d            <=   "01";
		
		when others => -- same as bypass proc
							
			mux_decode_for_fifo_rd_d             <=   "00";
			mux_decode_for_fifo_high_d           <=   "00";
			demux_decode_for_trans_d             <=   '0';
			demux_decode_for_internal_engines_d  <=   "00";
			mux_decode_for_fr_engines_d          <=   "00";
			mux_decode_to_buffer_d               <=   '0';
			mux_decode_to_vk_mem_d               <=   '0';
			mux_decode_to_front_end_d            <=   "10";
	
			
	end case;
  
end process decode_logic_for_mux_demux_control;  
-----------------------------------------
-- Mux for FIFO control
-----------------------------------------	 
mux_control_select_to_rd_fifo : process(mux_decode_for_fifo_rd_r,
	                                      rd_en_fifo_high_fr_h_mult_eng_pr,
	                                      rd_en_fifo_low_fr_h_mult_eng_pr) 
begin
 		
 	case  mux_decode_for_fifo_rd_r is
 		
 		when "00" =>
 			
 			fr_mux_to_fifo_high_rd_d <= rd_en_fifo_high_fr_h_mult_eng_pr;
 			fr_mux_to_fifo_low_rd_d  <= rd_en_fifo_low_fr_h_mult_eng_pr; 			
 			 			
 		when "01" =>
 			
 			fr_mux_to_fifo_high_rd_d <= rd_en_fifo_high_fr_av_minus_b_eng_pr;
 			fr_mux_to_fifo_low_rd_d  <= rd_en_fifo_low_fr_av_minus_b_eng_pr;  
  		
 		when "10" =>
 			
 			fr_mux_to_fifo_high_rd_d <= rd_en_fifo_high_fr_update_eng_pr;
 			fr_mux_to_fifo_low_rd_d  <= rd_en_fifo_low_fr_update_eng_pr;
 			
 		when others =>
 
  	  fr_mux_to_fifo_high_rd_d <= '0';
  	  fr_mux_to_fifo_low_rd_d <= '0'; 		 		
 		
 	end case;
 	
end process mux_control_select_to_rd_fifo;	
 			               

-----------------------------------------
-- Mux & demux
-----------------------------------------.	
 mux_data_select_to_fifo_high : process(mux_decode_for_fifo_high_r,
 	                                      from_h_mem_valid_i,
 	                                      from_h_mem_data_i,
 	                                      from_h_star_mem_valid_i,
 	                                      from_h_star_mem_data_i,
 	                                      from_b_mem_valid_i,
 	                                      from_b_mem_data_i,
 	                                      from_vk_mem_valid_i,
 	                                      from_vk_mem_data_i)
    	begin
    		
    	case mux_decode_for_fifo_high_r is
    		
    		when "00" => 
    			
    			mux_to_fifo_high_valid_in_d <= from_h_mem_valid_i;   			
    			mux_to_fifo_high_data_in_d  <= from_h_mem_data_i;
 
     		
    		when "01" => 
    			
    			mux_to_fifo_high_valid_in_d <= from_h_star_mem_valid_i;   			
    			mux_to_fifo_high_data_in_d  <= from_h_star_mem_data_i;

    		
    		when "10" => 
    			
    			mux_to_fifo_high_valid_in_d <= from_b_mem_valid_i;   			
    			mux_to_fifo_high_data_in_d  <= from_b_mem_data_i;

    		
    		when "11" => 
    			
    			mux_to_fifo_high_valid_in_d <= from_vk_mem_valid_i;   			
    			mux_to_fifo_high_data_in_d  <= from_vk_mem_data_i;
   	
    	  when others =>   	  	
    	  	   			
    			mux_to_fifo_high_valid_in_d <= '0';   			
    			mux_to_fifo_high_data_in_d  <=  (others=> '0');

    	  	
    	end case;
    		
    		
    end process mux_data_select_to_fifo_high;
    
 demux_data_select_for_trans_mem : process(demux_decode_for_trans_r,
 	                                         from_trans_mem_valid_i,
 	                                         from_trans_mem_data_i)
 	   begin
 	   	
 	   case demux_decode_for_trans_r is
 	   	
 	   	 when '0' =>
 	   	 		   	 		 	
 	   	 	trans_mem_to_bypass_valid_out_d <= from_trans_mem_valid_i;
 	   	 	trans_mem_to_bypass_data_out_d	<= from_trans_mem_data_i; 
 	   	 	
 	   	 	demux_to_fifo_low_valid_in_d    <= '0';
 	   	 	demux_to_fifo_low_data_in_d     <= (others => '0'); 
 	     	 	
 	   	 when '1' =>
 	   	 		   	 		   	 		 	
 	   	 	trans_mem_to_bypass_valid_out_d <= '0';
 	   	 	trans_mem_to_bypass_data_out_d	<= (others => '0'); 
 	   	 	
 	   	 	demux_to_fifo_low_valid_in_d    <= from_trans_mem_valid_i;
 	   	 	demux_to_fifo_low_data_in_d     <= from_trans_mem_data_i; 

 	   	
    	 when others =>   	  	
  	   	 		   	 		 	
 	   	 	trans_mem_to_bypass_valid_out_d <= '0';
 	   	 	trans_mem_to_bypass_data_out_d	<= (others => '0'); 
 	   	 	
 	   	 	demux_to_fifo_low_valid_in_d    <= '0';
 	   	 	demux_to_fifo_low_data_in_d     <= (others => '0');
 	   
 	  end case;
 	  	
 end process demux_data_select_for_trans_mem; 
 	
 
 demux_data_select_to_internal_engines : process(demux_decode_for_internal_engines_r,
 	                                               fr_fifo_high_valid_out_r,
 	                                               fr_fifo_high_data_out_r,
 	                                               fr_fifo_low_valid_out_r,
 	                                               fr_fifo_low_data_out_r)
 	    begin
 	    	
 	    case demux_decode_for_internal_engines_r is
 	    	
 	    	
 	    	when "00"  =>
 	    		
 	    		demux_to_h_mult_eng_port_1_valid_in_d     <=  fr_fifo_high_valid_out_r;
 	    		demux_to_h_mult_eng_port_1_data_in_d      <=  fr_fifo_high_data_out_r;
 	    			    		 	    		
 	    		demux_to_h_mult_eng_port_2_valid_in_d     <=  fr_fifo_low_valid_out_r;
 	    		demux_to_h_mult_eng_port_2_data_in_d      <=  fr_fifo_low_data_out_r;    		    			    		  		
 	    			    		
 	    		demux_to_av_minus_b_eng_port_1_valid_in_d <=  '0'; 
 	    		demux_to_av_minus_b_eng_port_1_data_in_d  <=  (others => '0');
 	    		
 	    		demux_to_av_minus_b_eng_port_2_valid_in_d <=  '0';
 	    		demux_to_av_minus_b_eng_port_2_data_in_d  <=  (others => '0');
 	 	      			    		
 	    		demux_to_update_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_1_data_in_d      <=  (others => '0');   		
 	    		 	      			    		
 	    		demux_to_update_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_2_data_in_d      <=  (others => '0');

  	    	
 	    	when "01"  =>
 	    		
 	    		demux_to_h_mult_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_1_data_in_d      <=  (others => '0');
 	    			    		 	    		
 	    		demux_to_h_mult_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_2_data_in_d      <=  (others => '0');    		    			    		  		
 	    			    		
 	    		demux_to_av_minus_b_eng_port_1_valid_in_d <=  fr_fifo_high_valid_out_r; 
 	    		demux_to_av_minus_b_eng_port_1_data_in_d  <=  fr_fifo_high_data_out_r;
 	    		
 	    		demux_to_av_minus_b_eng_port_2_valid_in_d <=  fr_fifo_low_valid_out_r;
 	    		demux_to_av_minus_b_eng_port_2_data_in_d  <=  fr_fifo_low_data_out_r;
 	 	      			    		
 	    		demux_to_update_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_1_data_in_d      <=  (others => '0');   		
 	    		 	      			    		
 	    		demux_to_update_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_2_data_in_d      <=  (others => '0');

     	    	
 	    	when "10"  =>
 	    		
 	    		demux_to_h_mult_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_1_data_in_d      <=  (others => '0');
 	    			    		 	    		
 	    		demux_to_h_mult_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_2_data_in_d      <=  (others => '0');    		    			    		  		
 	    			    		
 	    		demux_to_av_minus_b_eng_port_1_valid_in_d <=  '0'; 
 	    		demux_to_av_minus_b_eng_port_1_data_in_d  <=  (others => '0');
 	    		
 	    		demux_to_av_minus_b_eng_port_2_valid_in_d <=  '0';
 	    		demux_to_av_minus_b_eng_port_2_data_in_d  <=  (others => '0');
 	 	      			    		
 	    		demux_to_update_eng_port_1_valid_in_d     <=  fr_fifo_high_valid_out_r;
 	    		demux_to_update_eng_port_1_data_in_d      <=  fr_fifo_high_data_out_r;   		
 	    		 	      			    		
 	    		demux_to_update_eng_port_2_valid_in_d     <=  fr_fifo_low_valid_out_r;
 	    		demux_to_update_eng_port_2_data_in_d      <=  fr_fifo_low_data_out_r;

       when others =>      	
       	   		
 	    		demux_to_h_mult_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_1_data_in_d      <=  (others => '0');
 	    			    		 	    		
 	    		demux_to_h_mult_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_h_mult_eng_port_2_data_in_d      <=  (others => '0');    		    			    		  		
 	    			    		
 	    		demux_to_av_minus_b_eng_port_1_valid_in_d <=  '0'; 
 	    		demux_to_av_minus_b_eng_port_1_data_in_d  <=  (others => '0');
 	    		
 	    		demux_to_av_minus_b_eng_port_2_valid_in_d <=  '0';
 	    		demux_to_av_minus_b_eng_port_2_data_in_d  <=  (others => '0');
 	 	      			    		
 	    		demux_to_update_eng_port_1_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_1_data_in_d      <=  (others => '0');   		
 	    		 	      			    		
 	    		demux_to_update_eng_port_2_valid_in_d     <=  '0';
 	    		demux_to_update_eng_port_2_data_in_d      <=  (others => '0');
   
    end case;
       	
   end process  demux_data_select_to_internal_engines;	

mux_data_select_fr_engines : process(mux_decode_for_fr_engines_r,
	                                   from_h_h_star_eng_valid_pr,
	                                   from_h_h_star_eng_addr_pr,
	                                   from_h_h_star_eng_data_pr,
	                                   from_av_minus_b_eng_valid_pr,
	                                   from_av_minus_b_eng_addr_pr,
	                                   from_av_minus_b_eng_data_pr,
	                                   from_update_eng_valid_pr,
	                                   from_update_eng_addr_pr,
	                                   from_update_eng_data_pr)
   begin
    		
    	case mux_decode_for_fr_engines_r is
    		
    		when "00" => 

    			mux_fr_engines_valid_out_d <= from_h_h_star_eng_valid_pr;
    			mux_fr_engines_addr_out_d  <= from_h_h_star_eng_addr_pr;   			
      		mux_fr_engines_data_out_d  <= from_h_h_star_eng_data_pr;
 
     		
    		when "01" => 
    			
    			mux_fr_engines_valid_out_d <= from_av_minus_b_eng_valid_pr;
    			mux_fr_engines_addr_out_d  <= from_av_minus_b_eng_addr_pr;   			
      		mux_fr_engines_data_out_d  <= from_av_minus_b_eng_data_pr;
    		
    		when "10" => 
 
    			mux_fr_engines_valid_out_d <= from_update_eng_valid_pr;
    			mux_fr_engines_addr_out_d  <= from_update_eng_addr_pr;   			
      		mux_fr_engines_data_out_d  <= from_update_eng_data_pr;
   	
    	  when others =>   	  	

    			mux_fr_engines_valid_out_d <= '0';
    			mux_fr_engines_addr_out_d  <= (others=> '0');   			
      		mux_fr_engines_data_out_d  <= (others=> '0');
 
    	  	
    	end case;
    		
    		
    end process mux_data_select_fr_engines;
        
    
mux_data_select_to_buffer : process(mux_decode_to_buffer_r,
	                                  mux_fr_engines_valid_out_r,
	                                  mux_fr_engines_addr_out_r,
	                                  mux_fr_engines_data_out_r)
   begin
    		
    	case mux_decode_to_buffer_r is
    		
    		     		
    		when '0' => 
 
    			mux_to_buffer_valid_out_d       <= '0';
    			mux_to_buffer_addr_out_d        <= (others => '0');
      		mux_to_buffer_data_out_d        <= (others => '0');

    		
    		when '1' => 

    			mux_to_buffer_valid_out_d       <= mux_fr_engines_valid_out_r;
    			mux_to_buffer_addr_out_d        <= mux_fr_engines_addr_out_r;
      		mux_to_buffer_data_out_d        <= mux_fr_engines_data_out_r;
    	
    	  when others =>   	  	
 
    			mux_to_buffer_valid_out_d       <= '0';
    			mux_to_buffer_addr_out_d        <= (others => '0');
      		mux_to_buffer_data_out_d        <= (others => '0');
  	  	
    	end case;
    		
    		
    end process mux_data_select_to_buffer;
  
  
mux_data_select_to_vk_mem : process(mux_decode_to_vk_mem_r,
	                                  mux_fr_engines_valid_out_r,
	                                  mux_fr_engines_addr_out_r,
	                                  mux_fr_engines_data_out_r)
   begin
    		
    	case mux_decode_to_vk_mem_r is
    		   		
    		when '0' => 
 
    			mux_to_vk_mem_valid_out_d       <= '0';
    			mux_to_vk_mem_addr_out_d        <= (others => '0');
      		mux_to_vk_mem_data_out_d        <= (others => '0');
  
    		
    		when '1' => 

    			mux_to_vk_mem_valid_out_d       <= mux_fr_engines_valid_out_r;
    			mux_to_vk_mem_addr_out_d        <= mux_fr_engines_addr_out_r;
      		mux_to_vk_mem_data_out_d        <= mux_fr_engines_data_out_r;
    	
    	  when others =>   	  	
 
    			mux_to_vk_mem_valid_out_d       <= '0';
    			mux_to_vk_mem_addr_out_d        <= (others => '0');
      		mux_to_vk_mem_data_out_d        <= (others => '0');
  	  	
    	end case;
    		
    		
    end process mux_data_select_to_vk_mem;
        
    
    
mux_data_select_to_front_end : process(mux_decode_to_front_end_r,
	                                     mux_fr_engines_valid_out_r,
	                                     mux_fr_engines_data_out_r,
	                                     trans_mem_to_bypass_valid_out_d,
	                                     trans_mem_to_bypass_data_out_d)
   begin
    		
    	case mux_decode_to_front_end_r is
    		
    		   		
    		when "00" => 
 
    			mux_to_front_end_valid_out_d <= '0';
      		mux_to_front_end_data_out_d  <= (others=> '0');

    		
    		when "01" => 

    			mux_to_front_end_valid_out_d <= mux_fr_engines_valid_out_r;
      		mux_to_front_end_data_out_d  <= mux_fr_engines_data_out_r;
 
     		
    		when "10" => 
    			
    			mux_to_front_end_valid_out_d <= trans_mem_to_bypass_valid_out_d; -- TEMP!!!: Note this is not reg
      		mux_to_front_end_data_out_d  <= trans_mem_to_bypass_data_out_d;
   	
    	  when others =>   	  	

    			mux_to_front_end_valid_out_d <= '0';
      		mux_to_front_end_data_out_d  <= (others=> '0');
 
    	  	
    	end case;
    		
    		
    end process mux_data_select_to_front_end;
    
    -- mux and demux for fifo control

-----------------------------------------
-- Registers
-----------------------------------------	
register_proc : process(clk_i, rst_i)

begin
	
	if (rst_i = '1')	then
	
	
		-- To High FIFO from mem mux
		mux_to_fifo_high_valid_in_r <= '0';
	  mux_to_fifo_high_data_in_r  <= (others => '0');
	  
	  -- To Low FIFO from trans mem demux
	  demux_to_fifo_low_valid_in_r <= '0';
	  demux_to_fifo_low_data_in_r  <= (others => '0');
	  
	  -- From High FIFO
	  fr_fifo_high_valid_out_r <= '0';
	  fr_fifo_high_data_out_r  <= (others => '0');
	  
	  -- From Low FIFO
	  fr_fifo_low_valid_out_r <= '0';
	  fr_fifo_low_data_out_r  <= (others => '0');
	  
	  -- Demux from FIFO to Engines
	  
 	  demux_to_h_mult_eng_port_1_valid_in_r     <=  '0';
 	  demux_to_h_mult_eng_port_1_data_in_r      <=  (others => '0');
 	  	    		 	    		
 	  demux_to_h_mult_eng_port_2_valid_in_r     <=  '0';
 	  demux_to_h_mult_eng_port_2_data_in_r      <=  (others => '0');    		    			    		  		
 	  	    		
 	  demux_to_av_minus_b_eng_port_1_valid_in_r <=  '0'; 
 	  demux_to_av_minus_b_eng_port_1_data_in_r  <=  (others => '0');
 	  
 	  demux_to_av_minus_b_eng_port_2_valid_in_r <=  '0';
 	  demux_to_av_minus_b_eng_port_2_data_in_r  <=  (others => '0');
 	 	 			    		
 	  demux_to_update_eng_port_1_valid_in_r     <=  '0';
 	  demux_to_update_eng_port_1_data_in_r      <=  (others => '0');   		
 	   	      			    		
 	  demux_to_update_eng_port_2_valid_in_r     <=  '0';
 	  demux_to_update_eng_port_2_data_in_r      <=  (others => '0');
	  
	  -- Mux from Engines
	  
	  mux_fr_engines_valid_out_r                <=  '0';
    mux_fr_engines_addr_out_r                 <=  (others => '0');   			
    mux_fr_engines_data_out_r                 <=  (others => '0');
 
    -- Out muxes
    
    mux_to_buffer_valid_out_r                 <= '0';
    mux_to_buffer_addr_out_r                  <= (others => '0');
    mux_to_buffer_data_out_r                  <= (others => '0');   
     
    mux_to_vk_mem_valid_out_r                 <= '0';
    mux_to_vk_mem_addr_out_r                  <= (others => '0');
    mux_to_vk_mem_data_out_r                  <= (others => '0');
    	
    mux_to_front_end_valid_out_r              <= '0';
    mux_to_front_end_data_out_r               <= (others => '0');
    	
    -- Dedicated FIFO & Control
   	
   	fr_mux_to_fifo_high_rd_r                  <= '0';
   	fr_mux_to_fifo_low_rd_r                   <= '0';
   	
   	fr_fifo_high_ovf_r                        <= '0';
   	fr_fifo_high_uf_r                         <= '0';
   	
   	  	
   	fr_fifo_low_ovf_r                         <= '0';
   	fr_fifo_low_uf_r                          <= '0';
   	
   	-- mux and demux control
   	
   	mux_decode_for_fifo_high_r                <= (others => '0');
		demux_decode_for_trans_r                  <= '0';
		demux_decode_for_internal_engines_r       <= (others => '0');
		mux_decode_for_fr_engines_r               <= (others => '0');
		mux_decode_to_vk_mem_r                    <= '0';
		mux_decode_to_buffer_r                    <= '0';
		mux_decode_to_front_end_r                 <= (others => '0');
		
		-- master mode bits	
		master_mode_upper_bits_r                  <= (others => '0');
		
  
	
  elsif(clk_i'event and  clk_i = '1') then
	
		-- To High FIFO from mem mux
		mux_to_fifo_high_valid_in_r <= mux_to_fifo_high_valid_in_d;
	  mux_to_fifo_high_data_in_r  <= mux_to_fifo_high_data_in_d;
	  
	  -- To Low FIFO from trans mem demux
	  demux_to_fifo_low_valid_in_r <= demux_to_fifo_low_valid_in_d;
	  demux_to_fifo_low_data_in_r  <= demux_to_fifo_low_data_in_d;
	  
	  -- From High FIFO
	  fr_fifo_high_valid_out_r <= fr_fifo_high_valid_out_pd;
	  fr_fifo_high_data_out_r  <= fr_fifo_high_data_out_pd;
	  
	  -- From Low FIFO
	  fr_fifo_low_valid_out_r <= fr_fifo_low_valid_out_pd;
	  fr_fifo_low_data_out_r  <= fr_fifo_low_data_out_pd;
	  
	  -- Demux from FIFO to Engines
	  
 	  demux_to_h_mult_eng_port_1_valid_in_r     <=  demux_to_h_mult_eng_port_1_valid_in_d;
 	  demux_to_h_mult_eng_port_1_data_in_r      <=  demux_to_h_mult_eng_port_1_data_in_d;
 	  	    		 	    		
 	  demux_to_h_mult_eng_port_2_valid_in_r     <=  demux_to_h_mult_eng_port_2_valid_in_d;
 	  demux_to_h_mult_eng_port_2_data_in_r      <=  demux_to_h_mult_eng_port_2_data_in_d;    		    			    		  		
 	  	    		
 	  demux_to_av_minus_b_eng_port_1_valid_in_r <=  demux_to_av_minus_b_eng_port_1_valid_in_d; 
 	  demux_to_av_minus_b_eng_port_1_data_in_r  <=  demux_to_av_minus_b_eng_port_1_data_in_d;
 	  
 	  demux_to_av_minus_b_eng_port_2_valid_in_r <=  demux_to_av_minus_b_eng_port_2_valid_in_d;
 	  demux_to_av_minus_b_eng_port_2_data_in_r  <=  demux_to_av_minus_b_eng_port_2_data_in_d;
 	 	 			    		
 	  demux_to_update_eng_port_1_valid_in_r     <=  demux_to_update_eng_port_1_valid_in_d;
 	  demux_to_update_eng_port_1_data_in_r      <=  demux_to_update_eng_port_1_data_in_d;   		
 	   	      			    		
 	  demux_to_update_eng_port_2_valid_in_r     <=  demux_to_update_eng_port_2_valid_in_d;
 	  demux_to_update_eng_port_2_data_in_r      <=  demux_to_update_eng_port_2_data_in_d;
	  
	  -- Mux from Engines
	  
	  mux_fr_engines_valid_out_r                <=  mux_fr_engines_valid_out_d;
    mux_fr_engines_addr_out_r                 <=  mux_fr_engines_addr_out_d;   			
    mux_fr_engines_data_out_r                 <=  mux_fr_engines_data_out_d;
 
    -- Out muxes
    
    mux_to_buffer_valid_out_r                 <= mux_to_buffer_valid_out_d;
    mux_to_buffer_addr_out_r                  <= mux_to_buffer_addr_out_d;
    mux_to_buffer_data_out_r                  <= mux_to_buffer_data_out_d;   
     
    mux_to_vk_mem_valid_out_r                 <= mux_to_vk_mem_valid_out_d;
    mux_to_vk_mem_addr_out_r                  <= mux_to_vk_mem_addr_out_d;
    mux_to_vk_mem_data_out_r                  <= mux_to_vk_mem_data_out_d;
    
    mux_to_front_end_valid_out_r              <= mux_to_front_end_valid_out_d;
    mux_to_front_end_data_out_r               <= mux_to_front_end_data_out_d;
    
    
    -- Dedicated FIFO control & status.
    	
   	fr_mux_to_fifo_high_rd_r                  <= fr_mux_to_fifo_high_rd_d;
   	fr_mux_to_fifo_low_rd_r                   <= fr_mux_to_fifo_low_rd_d;  	
     	
    -- Dedicated FIFO & Control
   	
   	fr_fifo_high_ovf_r                        <= fr_fifo_high_ovf_pd;
   	fr_fifo_high_uf_r                         <= fr_fifo_high_uf_pd;
   	
   	  	
   	fr_fifo_low_ovf_r                         <= fr_fifo_low_ovf_pd;
   	fr_fifo_low_uf_r                          <= fr_fifo_low_uf_pd;
   	
   	-- mux and demux control
     	     			
		mux_decode_for_fifo_high_r                <= mux_decode_for_fifo_high_d;
		demux_decode_for_trans_r                  <= demux_decode_for_trans_d;
		demux_decode_for_internal_engines_r       <= demux_decode_for_internal_engines_d;
		mux_decode_for_fr_engines_r               <= mux_decode_for_fr_engines_d;
		mux_decode_to_vk_mem_r                    <= mux_decode_to_vk_mem_d;
		mux_decode_to_buffer_r                    <= mux_decode_to_buffer_d;
		mux_decode_to_front_end_r                 <= mux_decode_to_front_end_d;
		
		
		-- master mode bits	
		master_mode_upper_bits_r                  <= master_mode_upper_bits_d;
		
	 	
  	
  end if;

end process register_proc;


-----------------------------------------
-- FIFOS
-----------------------------------------	

--U0 : entity work.fifo_generator_0 
--  PORT MAP (    
--    clk          =>   clk_i, -- in STD_LOGIC;
--    srst         =>   rst_i, -- in STD_LOGIC;
--    din          =>   mux_to_fifo_high_data_in_r, -- in STD_LOGIC_VECTOR ( 79 downto 0 );
--    wr_en        =>   mux_to_fifo_high_valid_in_r, -- in STD_LOGIC;
--    rd_en        =>   fr_mux_to_fifo_high_rd_r, -- in STD_LOGIC;
--    dout         =>   fr_fifo_high_data_out_pd, -- out STD_LOGIC_VECTOR ( 79 downto 0 );
--    full         =>   open, -- out STD_LOGIC;
--    overflow     =>   fr_fifo_high_ovf_pd, -- out STD_LOGIC;
--    empty        =>   open, -- out STD_LOGIC;
--    valid        =>   fr_fifo_high_valid_out_pd, -- out STD_LOGIC;
--    underflow    =>   fr_fifo_high_uf_pd, -- out STD_LOGIC;
--    wr_rst_busy  =>   open, -- out STD_LOGIC;
--    rd_rst_busy  =>   open -- out STD_LOGIC
--  );


fr_fifo_high_data_out_pd   <= mux_to_fifo_high_data_in_r; -- pass thru, no FIFO
fr_fifo_high_valid_out_pd  <= mux_to_fifo_high_valid_in_r;

--U1 : entity work.fifo_generator_0 
--  PORT MAP (    
--    clk          =>   clk_i, -- in STD_LOGIC;
--    srst         =>   rst_i, -- in STD_LOGIC;
--    din          =>   demux_to_fifo_low_data_in_r, -- in STD_LOGIC_VECTOR ( 79 downto 0 );
--    wr_en        =>   demux_to_fifo_low_valid_in_r, -- in STD_LOGIC;
--    rd_en        =>   fr_mux_to_fifo_low_rd_r, -- in STD_LOGIC;
--    dout         =>   fr_fifo_low_data_out_pd, -- out STD_LOGIC_VECTOR ( 79 downto 0 );
--    full         =>   open, -- out STD_LOGIC;
--    overflow     =>   fr_fifo_low_ovf_pd, -- out STD_LOGIC;
--    empty        =>   open, -- out STD_LOGIC;
--    valid        =>   fr_fifo_low_valid_out_pd, -- out STD_LOGIC;
--    underflow    =>   fr_fifo_low_uf_pd, -- out STD_LOGIC;
--    wr_rst_busy  =>   open, -- out STD_LOGIC;
--    rd_rst_busy  =>   open -- out STD_LOGIC
--  );

fr_fifo_low_data_out_pd  <= demux_to_fifo_low_data_in_r;
fr_fifo_low_valid_out_pd <= demux_to_fifo_low_valid_in_r;


-----------------------------------------
-- H & H* Mult
-----------------------------------------.
U2 : entity xil_defaultlib.h_h_star_mult_eng
	GENERIC MAP(
			g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
	)
	PORT MAP(
		       clk_i                                 => clk_i,
		       rst_i                                 => rst_i,
		       master_mode_i                         => master_mode_i,
		    
		       -- port 1 inputs
		       
		       port_1_valid_in_i                     => demux_to_h_mult_eng_port_1_valid_in_r,
		       port_1_data_in_i                      => demux_to_h_mult_eng_port_1_data_in_r,
		       
		       -- port 2 inputs
		       
		       port_2_valid_in_i                     => demux_to_h_mult_eng_port_2_valid_in_r,
		       port_2_data_in_i                      => demux_to_h_mult_eng_port_2_data_in_r,
		       
		      
		       -- Data out
		       valid_out_o                           => from_h_h_star_eng_valid_pr,
		       addr_out_o                            => from_h_h_star_eng_addr_pr,
		       data_out_o                            => from_h_h_star_eng_data_pr,
		       
		       -- rdy flag
		       h_h_star_done_o                      => rdy_flag_fr_h_h_star_mult_eng_pr
		       
);
	
--	from_h_h_star_eng_valid_pr <= '0';
--	from_h_h_star_eng_addr_pr  <= (others=> '0');
--	from_h_h_star_eng_data_pr  <= (others=> '0');
--	rdy_flag_fr_h_h_star_mult_eng_pr <= '0';	
	
-----------------------------------------
-- Av-b 
-----------------------------------------	
U3 : entity work.av_minus_b_eng
	PORT MAP(
		       clk_i                                 => clk_i,
		       rst_i                                 => rst_i,
		       master_mode_i                         => master_mode_i,
		       
		       -- FIFO inputs
		       fifo_high_ovf_i                       => fr_fifo_high_ovf_r,
		       fifo_high_uf_i                        => fr_fifo_high_uf_r,
		       
		       fifo_low_ovf_i                        => fr_fifo_low_ovf_r,
		       fifo_low_uf_i                         => fr_fifo_low_uf_r,	       
		       
		       -- port 1 inputs
		       
		       port_1_valid_in_i                     => demux_to_av_minus_b_eng_port_1_valid_in_r,
		       port_1_data_in_i                      => demux_to_av_minus_b_eng_port_1_data_in_r,
		       
		       -- port 2 inputs
		       
		       port_2_valid_in_i                     => demux_to_av_minus_b_eng_port_2_valid_in_r,
		       port_2_data_in_i                      => demux_to_av_minus_b_eng_port_2_data_in_r,
		       
		       -- FIFO outputs
		       fifo_high_rd_en_o                     => rd_en_fifo_high_fr_av_minus_b_eng_pr,
		       fifo_low_rd_en_o                      => rd_en_fifo_low_fr_av_minus_b_eng_pr,
		       
		       -- Data out
		       valid_out_o                           => from_av_minus_b_eng_valid_pr,
		       addr_out_o                            => from_av_minus_b_eng_addr_pr,
		       data_out_o                            => from_av_minus_b_eng_data_pr,
		       
		       -- rdy flag
		       rdy_o                                 => rdy_flag_fr_av_minus_b_eng_pr
		       
	);


-----------------------------------------
-- Vk+1 update
-----------------------------------------	
U4 : entity work.update_eng
	PORT MAP(
		       clk_i                                 => clk_i,
		       rst_i                                 => rst_i,
		       master_mode_i                         => master_mode_i,
		       
		       -- FIFO inputs
		       fifo_high_ovf_i                       => fr_fifo_high_ovf_r,
		       fifo_high_uf_i                        => fr_fifo_high_uf_r,
		       
		       fifo_low_ovf_i                        => fr_fifo_low_ovf_r,
		       fifo_low_uf_i                         => fr_fifo_low_uf_r,	       
		       
		       -- port 1 inputs
		       
		       port_1_valid_in_i                     => demux_to_update_eng_port_1_valid_in_r,
		       port_1_data_in_i                      => demux_to_update_eng_port_1_data_in_r,
		       
		       -- port 2 inputs
		       
		       port_2_valid_in_i                     => demux_to_update_eng_port_2_valid_in_r,
		       port_2_data_in_i                      => demux_to_update_eng_port_2_data_in_r,
		       
		       -- FIFO outputs
		       fifo_high_rd_en_o                     => rd_en_fifo_high_fr_update_eng_pr,
		       fifo_low_rd_en_o                      => rd_en_fifo_low_fr_update_eng_pr,
		       
		       -- Data out
		       valid_out_o                           => from_update_eng_valid_pr,
		       addr_out_o                            => from_update_eng_addr_pr,
		       data_out_o                            => from_update_eng_data_pr,
		       
		       -- rdy flag
		       rdy_o                                 => rdy_flag_fr_update_eng_pr
		       
	);


-----------------------------------------
-- Outputs
-----------------------------------------	

to_buffer_trans_mem_port_wr_o    <= mux_to_buffer_valid_out_r;     --     : out std_logic;  
to_buffer_trans_mem_port_addr_o  <= mux_to_buffer_addr_out_r;      --     : out std_logic_vector(16 downto 0);
to_buffer_trans_mem_port_data_o  <= mux_to_buffer_data_out_r;      --     : out std_logic_vector(79 downto 0);
                                          
to_buffer_vk_mem_port_wr_o       <= mux_to_vk_mem_valid_out_r;     --     : out std_logic;  
to_buffer_vk_mem_port_addr_o     <= mux_to_vk_mem_addr_out_r;      --     : out std_logic_vector(16 downto 0);
to_buffer_vk_mem_port_data_o     <= mux_to_vk_mem_data_out_r;      --     : out std_logic_vector(79 downto 0); 	
   	                                  --     
to_front_end_port_wr_o           <= mux_to_front_end_valid_out_r;  --     : out std_logic;  
to_front_end_port_data_o         <= mux_to_front_end_data_out_r;   --     : out std_logic_vector(79 downto 0);

gen_proc_h_h_mult_rdy_o          <= rdy_flag_fr_h_h_star_mult_eng_pr;
gen_proc_av_minus_b_rdy_o        <= rdy_flag_fr_av_minus_b_eng_pr;
gen_proc_vk_mem_rdy_o            <= rdy_flag_fr_update_eng_pr;

                                         

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


          	
end  architecture struct; 
    