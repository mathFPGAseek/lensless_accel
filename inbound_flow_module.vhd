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
-- filename: inbound_flow_module.vhd
-- Initial Date: 9/30/23
-- Descr: Fista accel top 
--
------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity inbound_flow_module is
--generic(
--	    generic_i  : in natural);

    generic(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug
	      g_USE_DEBUG_MODE_i : in natural :=  0
	  ); -- 0 = no debug , 1 = debug

    port (

	  clk_i               	         : in std_logic;
    rst_i               	         : in std_logic;
    
    master_mode_i                  : in std_logic_vector(4 downto 0);
    mem_init_start_i               : in std_logic; 
    
    fft_rdy_i                      : in std_logic;
  	
    -- Data to front end module
    init_data_o                    : out std_logic_vector(79 downto 0);
    init_valid_data_o              : out std_logic

    );
    
end inbound_flow_module;

architecture struct of inbound_flow_module is  
	
-- signals
signal addr_int    : std_logic_vector ( 16 downto 0 );
signal en_int      : std_logic;
signal en_r        : std_logic;
signal en_rr       : std_logic;
signal en_rrr       : std_logic;


--signal re_dout     : std_logic_vector ( 33 downto 0 );
--signal re_dout     : std_logic_vector ( 39 downto 0 );
signal re_dout     : std_logic_vector ( 31 downto 0 );      
      

--constant
constant IMAG_ZEROS : std_logic_vector(39 downto 0) := (others=> '0');
constant PAD_8_ZEROS : std_logic_vector(7 downto 0) := (others=> '0');



begin
  
  
    -----------------------------------------.
    -- Init St mach contoller
    -----------------------------------------	
    
    U0 : entity work.init_st_machine_controller
    GENERIC MAP(
	    --g_USE_DEBUG_i  =>  ONE) -- 0 = no debug , 1 = debug
	      g_USE_DEBUG_MODE_i  =>  g_USE_DEBUG_MODE_i -- 0 = no debug , 1 = debug
    )
    
    PORT MAP(
    	
    	clk_i                                       => clk_i, --: in std_logic;
        rst_i               	                    => rst_i, --: in std_logic;
                                                    
        master_mode_i                             => master_mode_i, --: in std_logic_vector(4 downto 0);                                                                                        
        mem_init_start_i                          => mem_init_start_i ,--: in std_logic;
        
        fft_rdy_i                                 =>  fft_rdy_i,   
                                           
        addr_o                                    => addr_int, --: out std_logic;
        en_o                                      => en_int --: out std_logic;
                                             
                                           
    );

    
    -----------------------------------------.
    --  init memory
    -----------------------------------------	
    -- From Python code of diffuser cam we have an init value;
    -- we will start with psf
    
   --U1 : entity work.blk_mem_gen_init_0 
   --PORT MAP ( 
   --     clka        =>     clk_i,          --: in STD_LOGIC;
   --     ena         =>     en_int,         --: in STD_LOGIC;
   --     addra       =>     addr_int,       --: in STD_LOGIC_VECTOR ( 16 downto 0 );
   --     douta       =>     re_dout         --: out STD_LOGIC_VECTOR ( 33 downto 0 )
   --);
    
   --U1 : entity work.blk_mem_40bit_gen_0 
   --PORT MAP ( 
   -- clka            =>      clk_i,         --: in STD_LOGIC;
   -- ena             =>      en_int,        --: in STD_LOGIC;
   -- addra           =>      addr_int(15 downto 0),      --: in STD_LOGIC_VECTOR ( 15 downto 0 );
   --douta           =>      re_dout        --: out STD_LOGIC_VECTOR ( 39 downto 0 )
  --);
                                        
  
   U1 : entity work.blk_mem_32bit_gen_REGEN_LL_0 
   PORT MAP ( 
    clka            =>      clk_i,         --: in STD_LOGIC;
    ena             =>      en_int,        --: in STD_LOGIC;
    addra           =>      addr_int(15 downto 0),      --: in STD_LOGIC_VECTOR ( 15 downto 0 );
    douta           =>      re_dout        --: out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

    -----------------------------------------
    --  delay init memory valid
    -----------------------------------------.	
    delay_init_memory_valid : process(clk_i, rst_i)
    	begin
    		if(rst_i = '1') then
    			en_r     <= '0';
    			en_rr    <= '0';
    			en_rrr   <= '0';
    			
    		elsif(clk_i'event and clk_i = '1')then
    			en_r     <= en_int;
    			en_rr    <= en_r;
    			en_rrr   <= en_rr;
    			
    		end if;
    			
    end process  delay_init_memory_valid;

    
    -----------------------------------------
    --  inbound fifo
    -----------------------------------------	
    
    -----------------------------------------
    --  inbound state machine
    -----------------------------------------	
    
    -----------------------------------------
    --  Assignments
    -----------------------------------------	
     init_data_o <= IMAG_ZEROS & PAD_8_ZEROS & re_dout; 
     init_valid_data_o <= en_rr;
     --init_valid_data_o <= en_rrr;

            	
end  architecture struct; 
    