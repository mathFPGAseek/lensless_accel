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
-- filename: h_h_star_mult_eng.vhd
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
LIBRARY xil_defaultlib;
USE xil_defaultlib.all;


entity h_h_star_mult_eng is
  generic(
--	     g_USE_DEBUG_i  : in natural := 1);
         g_USE_DEBUG_MODE_i : in natural:= 0
         );
         
    port (
   
    clk_i                             : in std_logic;
		rst_i                             : in std_logic;
		master_mode_i                     : in std_logic_vector(4 downto 0);
		       
		       
		-- port 1 inputs
		       
		port_1_valid_in_i                 : in std_logic;
		port_1_data_in_i                  : in std_logic_vector(79 downto 0); --  a + bi
			                                                                    -- 71 downto 40 Im
		                                                                      -- 31 downto 0  Re
		-- port 2 inputs
		       
		port_2_valid_in_i                 : in std_logic;
		port_2_data_in_i                  : in std_logic_vector(79 downto 0); -- c + di 
		       
		       
		-- Data out
		valid_out_o                       : out std_logic;
		addr_out_o                        : out std_logic_vector(16 downto 0);
		data_out_o                        : out std_logic_vector(79 downto 0);
		       
		-- rdy flag
		h_h_star_done_o                  : out std_logic
		      

    );
    
end h_h_star_mult_eng;

architecture struct of h_h_star_mult_eng is
	
signal sub_re_input_valid_d            : std_logic;	
signal sub_re_input_valid_r            : std_logic;

signal add_im_input_valid_d            : std_logic;
signal add_im_input_valid_r            : std_logic;

signal ac_data_valid                   : std_logic;
signal bd_data_valid                   : std_logic;
signal ad_data_valid                   : std_logic;
signal bc_data_valid                   : std_logic;

signal ac_data                         : std_logic_vector(31 downto 0);
signal bd_data                         : std_logic_vector(31 downto 0);
signal ad_data                         : std_logic_vector(31 downto 0);
signal bc_data                         : std_logic_vector(31 downto 0);
	
signal ac_minus_bd_valid_d             : std_logic;
signal ac_minus_bd_valid_r             : std_logic;

signal ad_plus_bc_valid_d              : std_logic;
signal ad_plus_bc_valid_r              : std_logic;

  
signal ac_minus_bd_data_d               : std_logic_vector( 31 downto 0);
signal ac_minus_bd_data_r               : std_logic_vector( 31 downto 0);
  
  
signal ad_plus_bc_data_d               : std_logic_vector( 31 downto 0);
signal ad_plus_bc_data_r               : std_logic_vector( 31 downto 0);
	
signal port_1_u1_rdy                   : std_logic;
signal port_2_u1_rdy                   : std_logic;
signal port_1_u2_rdy                   : std_logic;
signal port_2_u2_rdy                   : std_logic;
signal port_1_u3_rdy                   : std_logic;
signal port_2_u3_rdy                   : std_logic;
signal port_1_u4_rdy                   : std_logic;
signal port_2_u4_rdy                   : std_logic;
signal port_1_u5_rdy                   : std_logic;
signal port_2_u5_rdy                   : std_logic;
signal port_1_u6_rdy                   : std_logic;
signal port_2_u6_rdy                   : std_logic;

signal addr_int                        : std_logic_vector(7 downto 0);

--signal s_axis_a_tlast_int            : std_logic;
--signal s_axis_b_tlast_int            : std_logic;

--signal m_axis_dout_tlast_int         : std_logic;

--signal addr_int                      : std_logic_vector(7 downto 0);
	
--signal not_reset                     : std_logic;

constant PAD_EIGHT_ZEROS : std_logic_vector(7 downto 0) := (others=> '0');
constant PAD_NINE_ZEROS  : std_logic_vector(8 downto 0) := (others=> '0');



begin
	

    -----------------------------------------.
    -- H H_star St mach contoller
    -----------------------------------------	 
    U0 : entity xil_defaultlib.h_hstar_inbound_state_machine_controller 
    --U0 : entity work.h_hstar_inbound_state_machine_controller 
    GENERIC MAP(
    	   g_USE_DEBUG_MODE_i => g_USE_DEBUG_MODE_i
    )           
           
    PORT MAP(                                
    	                                   
    	  clk_i                  => clk_i,        -- : in std_logic; --clk_i,
        rst_i                  => rst_i,        -- : in std_logic; --rst_i,
                             
        master_mode_i          => master_mode_i,-- : in std_logic_vector(4 downto 0);                                                                                      
        valid_i                => port_1_valid_in_i,  -- : in std_logic; --
                           
        s_axis_data_tlast_o    => open,-- : out std_logic;
        
        buffer_addr_o          => addr_int,
                
        h_h_star_done_o        => h_h_star_done_o 
                            
    );
 

--s_axis_b_tlast_int <=  s_axis_b_tlast_int; 
--addr_out_o         <= "000000000" & addr_int;
--not_reset          <= not( rst_i);	

--U1 : entity work.cmpy_0 
--PORT MAP ( 
--    aclk                  =>    clk_i, --: in STD_LOGIC;
--    aresetn               =>    not_reset, --: in STD_LOGIC;
--    s_axis_a_tvalid       =>    port_1_valid_in_i, --: in STD_LOGIC;
--    s_axis_a_tlast        =>    s_axis_a_tlast_int, --: in STD_LOGIC;
--    s_axis_a_tdata        =>    port_1_data_in_i, --: in STD_LOGIC_VECTOR ( 79 downto 0 );
--    s_axis_b_tvalid       =>    port_2_valid_in_i, --: in STD_LOGIC;
--    s_axis_b_tlast        =>    s_axis_b_tlast_int, --: in STD_LOGIC;
--    s_axis_b_tdata        =>    port_2_data_in_i, --: in STD_LOGIC_VECTOR ( 79 downto 0 );
--    m_axis_dout_tvalid    =>    valid_out_o, --: out STD_LOGIC;
--    m_axis_dout_tlast     =>    m_axis_dout_tlast_int, --: out STD_LOGIC;
--    m_axis_dout_tdata     =>    data_out_o --: out STD_LOGIC_VECTOR ( 79 downto 0 ).
--  );

--   Port 1 : A + Bi.
--   Port 2 : C + Di
--   (AC - BD) Re + (AD + BC) Im

U1: entity xil_defaultlib.floating_point_mult_REGEN_LL_0 -- A(Re)*C(Re)
  PORT MAP ( 
  aclk                   => clk_i,    --- aclk : in STD_LOGIC;
  aresetn                => not(rst_i),
  s_axis_a_tvalid        => port_1_valid_in_i,         -- s_axis_a_tvalid : in STD_LOGIC;
  s_axis_a_tready        => port_1_u1_rdy,         -- s_axis_a_tready : out STD_LOGIC;
  s_axis_a_tdata         => port_1_data_in_i(31 downto 0),         -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  s_axis_b_tvalid        => port_2_valid_in_i,         -- s_axis_b_tvalid : in STD_LOGIC;
  s_axis_b_tready        => port_2_u1_rdy,         -- s_axis_b_tready : out STD_LOGIC;
  s_axis_b_tdata         => port_2_data_in_i(31 downto 0),         -- s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  m_axis_result_tvalid   => ac_data_valid,         -- m_axis_result_tvalid : out STD_LOGIC;
  m_axis_result_tready   => '1',         -- m_axis_result_tready : in STD_LOGIC;
  m_axis_result_tdata    => ac_data         -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
 

U2: entity xil_defaultlib.floating_point_mult_REGEN_LL_0 -- B(Im)*D(Im)
  PORT MAP ( 
  aclk                   => clk_i,    --- aclk : in STD_LOGIC;
  aresetn                => not(rst_i),
  s_axis_a_tvalid        => port_1_valid_in_i,         -- s_axis_a_tvalid : in STD_LOGIC;
  s_axis_a_tready        => port_1_u2_rdy,         -- s_axis_a_tready : out STD_LOGIC;
  s_axis_a_tdata         => port_1_data_in_i(71 downto 40),         -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  s_axis_b_tvalid        => port_2_valid_in_i,         -- s_axis_b_tvalid : in STD_LOGIC;
  s_axis_b_tready        => port_2_u2_rdy,         -- s_axis_b_tready : out STD_LOGIC;
  s_axis_b_tdata         => port_2_data_in_i(71 downto 40),         -- s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  m_axis_result_tvalid   => bd_data_valid,         -- m_axis_result_tvalid : out STD_LOGIC;
  m_axis_result_tready   => '1',         -- m_axis_result_tready : in STD_LOGIC;
  m_axis_result_tdata    => bd_data         -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  ); 



U3: entity xil_defaultlib.floating_point_mult_REGEN_LL_0 -- A(Re)*D(Im).
  PORT MAP ( 
  aclk                   => clk_i,    --- aclk : in STD_LOGIC;
  aresetn                => not(rst_i),
  s_axis_a_tvalid        => port_1_valid_in_i,         -- s_axis_a_tvalid : in STD_LOGIC;
  s_axis_a_tready        => port_1_u3_rdy,         -- s_axis_a_tready : out STD_LOGIC;
  s_axis_a_tdata         => port_1_data_in_i(31 downto 0),         -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  s_axis_b_tvalid        => port_2_valid_in_i,         -- s_axis_b_tvalid : in STD_LOGIC;
  s_axis_b_tready        => port_2_u3_rdy,         -- s_axis_b_tready : out STD_LOGIC;
  s_axis_b_tdata         => port_2_data_in_i(71 downto 40),         -- s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  m_axis_result_tvalid   => ad_data_valid,         -- m_axis_result_tvalid : out STD_LOGIC;
  m_axis_result_tready   => '1',         -- m_axis_result_tready : in STD_LOGIC;
  m_axis_result_tdata    => ad_data         -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  
  
U4: entity xil_defaultlib.floating_point_mult_REGEN_LL_0 -- B(Im)*C(Re)
  PORT MAP ( 
  aclk                   => clk_i,    --- aclk : in STD_LOGIC;
  aresetn                => not(rst_i),
  s_axis_a_tvalid        => port_1_valid_in_i,         -- s_axis_a_tvalid : in STD_LOGIC;
  s_axis_a_tready        => port_1_u4_rdy,         -- s_axis_a_tready : out STD_LOGIC;
  s_axis_a_tdata         => port_1_data_in_i(71 downto 40),         -- s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  s_axis_b_tvalid        => port_2_valid_in_i,         -- s_axis_b_tvalid : in STD_LOGIC;
  s_axis_b_tready        => port_2_u4_rdy,         -- s_axis_b_tready : out STD_LOGIC;
  s_axis_b_tdata         => port_2_data_in_i(31 downto 0),         -- s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  m_axis_result_tvalid   => bc_data_valid,         -- m_axis_result_tvalid : out STD_LOGIC;
  m_axis_result_tready   => '1',         -- m_axis_result_tready : in STD_LOGIC;
  m_axis_result_tdata    => bc_data         -- m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );                                         

 -----------------------------------------	                                         
 -- (AC - BD ) Re
 -----------------------------------------.	

 U5: entity xil_defaultlib.floating_point_sub_LL_0
  PORT MAP ( 
   aclk                   => clk_i, --: in STD_LOGIC;
   s_axis_a_tvalid        => sub_re_input_valid_r,--s_axis_a_tvalid : in STD_LOGIC;
   s_axis_a_tready        => port_1_u5_rdy,--s_axis_a_tready : out STD_LOGIC;
   s_axis_a_tdata         => ac_data,--s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
   s_axis_b_tvalid        => sub_re_input_valid_r,--s_axis_b_tvalid : in STD_LOGIC;
   s_axis_b_tready        => port_2_u5_rdy,--s_axis_b_tready : out STD_LOGIC;
   s_axis_b_tdata         => bd_data,--s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
   m_axis_result_tvalid   => ac_minus_bd_valid_d,--m_axis_result_tvalid : out STD_LOGIC;
   m_axis_result_tready   => '1',--m_axis_result_tready : in STD_LOGIC;
   m_axis_result_tdata    => ac_minus_bd_data_d--m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  ); 
  
  
 -----------------------------------------	                                         
 -- (AD + BC ) Im
 -----------------------------------------
 
 U6: entity xil_defaultlib.floating_point_add_LL_0
  PORT MAP ( 
   aclk                   => clk_i, --: in STD_LOGIC;
   s_axis_a_tvalid        => add_im_input_valid_r,--s_axis_a_tvalid : in STD_LOGIC;
   s_axis_a_tready        => port_1_u6_rdy,--s_axis_a_tready : out STD_LOGIC;
   s_axis_a_tdata         => ad_data,--s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
   s_axis_b_tvalid        => add_im_input_valid_r,--s_axis_b_tvalid : in STD_LOGIC;
   s_axis_b_tready        => port_2_u6_rdy,--s_axis_b_tready : out STD_LOGIC;
   s_axis_b_tdata         => bc_data,--s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
   m_axis_result_tvalid   => ad_plus_bc_valid_d,--m_axis_result_tvalid : out STD_LOGIC;
   m_axis_result_tready   => '1',--m_axis_result_tready : in STD_LOGIC;
   m_axis_result_tdata    => ad_plus_bc_data_d--m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  ); 
  
 
  
  sub_re_input_valid_d <= ac_data_valid and bd_data_valid;
  add_im_input_valid_d <= ad_data_valid and bc_data_valid;
  
  -----------------------------------------.
  --  Register Valids
  -----------------------------------------	
  reg_valid : process( clk_i,rst_i) 
  	
  	begin
  		if( rst_i = '1') then 
  			
  			sub_re_input_valid_r <= '0';
  			add_im_input_valid_r <= '0';
  			
  			ac_minus_bd_valid_r  <= '0';
  			ad_plus_bc_valid_r   <= '0';
  			
  		elsif(clk_i'event and clk_i = '1') then
  			
  			sub_re_input_valid_r <= sub_re_input_valid_d;
  			add_im_input_valid_r <= add_im_input_valid_d;
  			
  			ac_minus_bd_valid_r  <= ac_minus_bd_valid_d;
  			ad_plus_bc_valid_r   <= ad_plus_bc_valid_d;
  			
  	  end if;
  	  	
  end process reg_valid;
  
  
  -----------------------------------------.
  --  Register Data
  -----------------------------------------	
  reg_data : process( clk_i,rst_i) 
  	
  	begin
  		if( rst_i = '1') then 
  			
  			ac_minus_bd_data_r   <= (others => '0');
  			ad_plus_bc_data_r    <= (others => '0');
  		
  			
  		elsif(clk_i'event and clk_i = '1') then
  						
  			ac_minus_bd_data_r   <= ac_minus_bd_data_d;
  			ad_plus_bc_data_r    <= ad_plus_bc_data_d;
  		
  			
  	  end if;
  	  	
  end process reg_data;
  
 
  -----------------------------------------
  -- Output Data  & Output Valid
  -----------------------------------------	 
  
  valid_out_o    <= ac_minus_bd_valid_r and ad_plus_bc_valid_r;
  data_out_o     <= PAD_EIGHT_ZEROS & ad_plus_bc_data_r( 31 downto 0) & PAD_EIGHT_ZEROS & ac_minus_bd_data_r(31 downto 0);
  addr_out_o 	   <= PAD_NINE_ZEROS & addr_int;		                   
end architecture struct;	