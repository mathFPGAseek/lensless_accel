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
-- filename: front_end_module.vhd
-- Initial Date: 10/6/23
-- Descr: Select Data for FFT 
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity front_end_module is
--generic(
--	    generic_i  : in natural);
    port (

	  clk_i               	          : in std_logic;
    rst_i               	          : in std_logic;
    
    master_mode_i                   : in std_logic_vector(4 downto 0);
    
    fr_init_data_i                  : in std_logic_vector(79 downto 0);
    fr_back_end_data_i              : in std_logic_vector(79 downto 0);
    fr_back_end_data2_i             : in std_logic_vector(79 downto 0);
    fr_fista_data_i                 : in std_logic_vector(79 downto 0);
    fr_fd_back_fifo_data_i          : in std_logic_vector(79 downto 0);
    
    fr_init_data_valid_i            : in std_logic;	
    fr_back_end_valid_i             : in std_logic;
    fr_back_end_valid2_i            : in std_logic;
    fr_fista_valid_i                : in std_logic;
    fr_fd_back_fifo_valid_i         : in std_logic;
    
  	
    -- Data to front end module
    to_fft_data_o                   : out std_logic_vector(79 downto 0);
    fista_accel_data_o              : out std_logic_vector(79 downto 0);
    	
    to_fft_valid_o                  : out std_logic;
    fista_accel_valid_o             : out std_logic

    );
    
end front_end_module ;

architecture struct of front_end_module  is  
	
-- signals

signal mux_data_select_d          : std_logic_vector(2 downto 0);
signal mux_data_select_r          : std_logic_vector(2 downto 0); 
signal mux_out_to_fft_data_d      : std_logic_vector(79 downto 0);  
signal mux_out_to_fft_data_r      : std_logic_vector(79 downto 0);

	
signal mux_control_select_d       : std_logic_vector(2 downto 0);
signal mux_control_select_r       : std_logic_vector(2 downto 0);   
signal mux_out_to_fft_control_d   : std_logic;	
signal mux_out_to_fft_control_r   : std_logic;

signal rst_n                      : std_logic;
--signal fr_init_data_int           : std_logic_vector(79 downto 0);
signal fr_init_data_int_re           : std_logic_vector(39 downto 0);
signal init_float_data_valid_int_re  : std_logic;
signal init_float_data_int_re        : std_logic_vector(31 downto 0);
signal padded_float_data_int_re      : std_logic_vector(79 downto 0);

constant PAD_SIX_ZEROS    : std_logic_vector(5 downto 0) := (others=> '0');
constant PAD_EIGHT_ZEROS  : std_logic_vector(7 downto 0) := (others=> '0');
constant PAD_40_ZEROS     : std_logic_vector(39 downto 0) := (others=> '0');
	
constant FIVE_E_TO_MINUS_26 : std_logic_vector(31 downto 0) := x"15779688"; -- 5e-26
   
begin


rst_n <= not(rst_i);
	
	
	
------------------------------------------------------------- Using conversion to float-------------------------------------------
------------------------------------------------------------- But now memory has been converted ----------------------------------
-- correct alignment from inbound flow..

-- fr_init_data_int <= PAD_ZEROS & fr_init_data_i(79 downto 46) & PAD_ZEROS & fr_init_data_i(39 downto 6);	
--fr_init_data_int_im <= PAD_SIX_ZEROS & fr_init_data_i(79 downto 46);
--fr_init_data_int_re <= PAD_SIX_ZEROS & fr_init_data_i(39 downto 6);

 
 	
-- Convert fixed to float

--U0 : entity work.floating_point_0
--  PORT MAP( 
--  aclk                 => aclk,						                  -- aclk : in STD_LOGIC;
--  s_axis_a_tvalid      => fr_init_data_valid_i,             -- s_axis_a_tvalid : in STD_LOGIC;
--  s_axis_a_tready      => open,                             -- s_axis_a_tready : out STD_LOGIC;
--  s_axis_a_tdata       => fr_init_data_int_im,              -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 39 downto 0 );
--  m_axis_result_tvalid => init_float_data_valid_int_im,     -- m_axis_result_tvalid : out STD_LOGIC;
--  m_axis_result_tready => '1',                              -- m_axis_result_tready : in STD_LOGIC;
--  m_axis_result_tdata  => init_float_data_int_im            -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
--  );

--padded_init_float_data_int_im <= PAD_EIGHT_ZEROS & init_float_data_int_im;

--U1 : entity work.floating_point_1
--  PORT MAP( 
--  aclk                 => clk_i,						                -- aclk : in STD_LOGIC;
--  aresetn              => rst_n,
--  s_axis_a_tvalid      => fr_init_data_valid_i,             -- s_axis_a_tvalid : in STD_LOGIC;
--  s_axis_a_tready      => open,                             -- s_axis_a_tready : out STD_LOGIC;
--  s_axis_a_tdata       => fr_init_data_int_re,              -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 39 downto 0 );
--  m_axis_result_tvalid => init_float_data_valid_int_re,     -- m_axis_result_tvalid : out STD_LOGIC;
--  m_axis_result_tready => '1',                              -- m_axis_result_tready : in STD_LOGIC;
--  m_axis_result_tdata  => init_float_data_int_re            -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
--  );

----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------.


init_float_data_valid_int_re <= fr_init_data_valid_i;
init_float_data_int_re       <= fr_init_data_i(31 downto 0); -- Real portion
-- This is nominal data flow
padded_float_data_int_re <= PAD_40_ZEROS & PAD_EIGHT_ZEROS & init_float_data_int_re;


--debug hack; force value to 5.0e-26 to stress test fft
--padded_float_data_int_re <= PAD_EIGHT_ZEROS & FIVE_E_TO_MINUS_26 & PAD_EIGHT_ZEROS & FIVE_E_TO_MINUS_26;

-----------------------------------------.
-----------------------------------------
-- DATA PATH
-----------------------------------------
-----------------------------------------			
	
	
	  -----------------------------------------
    -- Mux Data decoder
    -----------------------------------------	
    mux_data_select_to_fft : process( master_mode_i )
    	begin
    		
    	case master_mode_i is
    		
    		when "00000" => -- A-1D-FWD-WR
    			
    			mux_data_select_d <= "000";
    		
    	  when "00001" =>
    	  	
    	  	mux_data_select_d <= "100";
    			
    	  when others =>
    	  	
    	  	mux_data_select_d <= "111";
    	  	
    	end case;
    		
    		
    end process mux_data_select_to_fft;
    
    -----------------------------------------
    -- Mux Data decoder registers
    -----------------------------------------	
    mux_data_select_to_fft_registers : process(clk_i, rst_i)
    	
    	begin
    		
    		if( rst_i = '1') then
    			
    		  mux_data_select_r <= "000";
    		  
    		elsif( clk_i'event and clk_i = '1') then
    			
    			mux_data_select_r <= mux_data_select_d;
    			
    		end if;
    			
    end process mux_data_select_to_fft_registers;
  
    -----------------------------------------
    -- Mux output to FFT
    -----------------------------------------.	
    mux_data_to_fft : process (mux_data_select_r,
    	                         --fr_init_data_int,
    	                         padded_float_data_int_re,
    	                         fr_back_end_data_i,
    	                         fr_back_end_data2_i,
    	                         fr_fista_data_i,
    	                         fr_fd_back_fifo_data_i )
    	begin
    		
    		case mux_data_select_r is
    			
    			
    			when "000" =>
    				
    				--mux_out_to_fft_data_d <=  fr_init_data_i;
    			  --mux_out_to_fft_data_d <=  fr_init_data_int;
            mux_out_to_fft_data_d <= padded_float_data_int_re;
    				
    			when "001" =>
    				
    				mux_out_to_fft_data_d <=  fr_back_end_data_i;  				
    				
    			when "010" =>
    				
    				mux_out_to_fft_data_d <=  fr_back_end_data2_i;  				
    				
    		  when "011" =>
    		  	
    		    mux_out_to_fft_data_d <=  fr_fista_data_i;
    		  	   		  	
    		  when "100" =>
    		  	
    		  	mux_out_to_fft_data_d <=  fr_fd_back_fifo_data_i;
    		  	   		  	
    		  when others => 
    		  	
    		  	--mux_out_to_fft_data_d <=  fr_init_data_int;
    		  	mux_out_to_fft_data_d <= padded_float_data_int_re;

    		  	
        end case;
    end process mux_data_to_fft;
   
    -----------------------------------------
    -- Mux output to FFT Registers
    -----------------------------------------	 		  	
    mux_data_to_fft_registers : process(clk_i, rst_i)
    	begin
    		
    		if ( rst_i = '1') then
    			 mux_out_to_fft_data_r <= (others=> '0');
    			 	
    		elsif(clk_i'event and clk_i = '1') then
    			
    			 mux_out_to_fft_data_r <= mux_out_to_fft_data_d;
    			 
    		end if;
    			
    end process mux_data_to_fft_registers;
    
-----------------------------------------
-----------------------------------------
-- CONTROL PATH
-----------------------------------------
-----------------------------------------	

	  -----------------------------------------
    -- Mux Data decoder
    -----------------------------------------	
    mux_control_select_to_fft : process( master_mode_i )
    	begin
    		
    	case master_mode_i is
    		
    		when "00000" => -- A-1D-FWD-WR
    			
    			mux_control_select_d <= "000";
    	
    	 		
    		when "00001" => -- A-1D-FWD-WR
    			
    			mux_control_select_d <= "100";
    			
    			
    	  when others =>
    	  	
    	  	mux_control_select_d <= "111";
    	  	
    	end case;
    		
    		
    end process mux_control_select_to_fft;
    
    -----------------------------------------
    -- Mux Data decoder registers
    -----------------------------------------	
    mux_control_select_to_fft_registers : process(clk_i, rst_i)
    	
    	begin
    		
    		if( rst_i = '1') then
    			
    		  mux_control_select_r <= "000";
    		  
    		elsif( clk_i'event and clk_i = '1') then
    			
    			mux_control_select_r <= mux_control_select_d;
    			
    		end if;
    			
    end process mux_control_select_to_fft_registers;
  
    -----------------------------------------
    -- Mux control output to FFT
    -----------------------------------------..	
    mux_control_to_fft : process(mux_control_select_r,
    														 --fr_init_data_valid_i,
    														 init_float_data_valid_int_re,
    														 fr_back_end_valid_i,
    														 fr_back_end_valid2_i,
    														 fr_fista_valid_i,
    														 fr_fd_back_fifo_valid_i )
    	begin
    		
    		case mux_control_select_r is
    			
    			
    			when "000" =>
    				
    				--mux_out_to_fft_control_d <=  fr_init_data_valid_i;
    				mux_out_to_fft_control_d <=  init_float_data_valid_int_re;

    			when "001" =>
    				
    				mux_out_to_fft_control_d <=  fr_back_end_valid_i; 				
    				
    			when "010" =>
    				
    				mux_out_to_fft_control_d <=  fr_back_end_valid2_i;  				
    				
    		  when "011" =>
    		  	
    		    mux_out_to_fft_control_d <=  fr_fista_valid_i;
    		  	   		  	
    		  when "100" =>
    		  	
    		  	mux_out_to_fft_control_d <=  fr_fd_back_fifo_valid_i;
    		  	   		  	
    		  when others => 
    		  	
    		  	--mux_out_to_fft_control_d <=  fr_init_data_valid_i;
    		  	mux_out_to_fft_control_d <=  init_float_data_valid_int_re;

    		  	
        end case;
    end process mux_control_to_fft;
   
    -----------------------------------------
    -- Mux  control output to FFT Registers
    -----------------------------------------	 		  	
    mux_control_to_fft_registers : process(clk_i, rst_i)
    	begin
    		
    		if ( rst_i = '1') then
    			 mux_out_to_fft_control_r <= '0';
    			 	
    		elsif(clk_i'event and clk_i = '1') then
    			
    			 mux_out_to_fft_control_r <= mux_out_to_fft_control_d;
    			 
    		end if;
    			
    end process mux_control_to_fft_registers;    
    
    -----------------------------------------.
    --  Assignments
    -----------------------------------------	
     to_fft_data_o         <= mux_out_to_fft_data_r;
     fista_accel_data_o    <= mux_out_to_fft_data_r;
     
     to_fft_valid_o        <= mux_out_to_fft_control_r;
     fista_accel_valid_o  <= mux_out_to_fft_control_r; 
            	
end  architecture struct; 
    