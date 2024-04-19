--------------------------------------------------------------------------
-- MSS copyright 1999-2004
-- Filename: SDRAM_CONTROLLER_TEST.VHD
-- Authors: 
--		Adam Kwiatkowski / MSS
--	Version: Rev 1
-- Last modified: 1/14/05
-- Inheritance: 	SDRAM_CONTROLLER.VHD rev0
--
-- description:  component to test proper operation of 256Mb SDRAM.
-- Writes 8Million 32-bit counter values into the SDRAM, then read it back.
---------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SDRAM_CONTROLLER_TEST is port (
   --// CLOCK, RESET
   ASYNC_RESET: in std_logic;
      -- Asynchronous reset, active high
   CLK: in std_logic;
      -- Reference clock

	START_TEST: in std_logic;
		-- triggers start of test

	END_OF_TEST: out std_logic;
	SUCCESSFULL_TEST: out std_logic;
		-- read when END_OF_TEST = '1'
	FIRST_FAILED_ADDRESS: out std_logic_vector(23 downto 0);
		-- read when END_OF_TEST = '1'
	FIRST_FAILED_DATA_WORD: out std_logic_vector(15 downto 0);
		-- read when END_OF_TEST = '1'
   
   --// Test Points
   --
   TEST_POINTS: out std_logic_vector(10 downto 1);

   --// SDRAM interface:
   SDRAM_A: out std_logic_vector(12 downto 0);
      -- Address lines.
   SDRAM_DQ: inout std_logic_vector(15 downto 0);
      -- Bi-directional data lines
   SDRAM_BA0: out std_logic;
   SDRAM_BA1: out std_logic;
   SDRAM_CAS_N: out std_logic;
   SDRAM_RAS_N: out std_logic;
   SDRAM_WE_N: out std_logic;
   SDRAM_CLK: out std_logic;
   SDRAM_CKE: out std_logic;
   SDRAM_CS_N: out std_logic;
   SDRAM_DQML: out std_logic;
   SDRAM_DQMH: out std_logic
	
   );
end entity;

architecture behavior of SDRAM_CONTROLLER_TEST is
-----------------------------------------------------------------
-- COMPONENTS
-----------------------------------------------------------------
component SDRAM_CONTROLLER is port (
   --// CLOCK, RESET
   ASYNC_RESET: in std_logic;
      -- Asynchronous reset, active high
   CLK: in std_logic;
      -- Reference clock

   --// Control signals
   POWER_DOWN: in std_logic;
      -- High indicates low power mode. Low indicates normal
      -- mode. Note: after a power down the SDRAM will be
       -- re-initialized.

   UPLOAD_START_ADDR: in std_logic_vector(23 downto 0);
      -- Upload start address. Each address represents one 16-bit word.
   UPLOAD_END_ADDR: in std_logic_vector(23 downto 0);
      -- Upload end address. Each address represents one 16-bit word.
	 -- IMPORTANT REQUIREMENT: 
	 -- number of words written i.e(UPLOAD_END_ADDR - UPLOAD_START_ADDR + 1)
	 -- MUST BE A MULTIPLE OF 4 words.
   START_UPLOAD_PULSE: in std_logic;
      -- One clock pulse wide pulse indicating that we want to start
      -- an upload session.
   UPLOAD_COMPLETED_PULSE: out std_logic;
      -- One CLK wide pulse indicating that the current upload is
      -- completed.

   DOWNLOAD_START_ADDR: in std_logic_vector(23 downto 0);
      -- Download start address. Each address represents one 16-bit word.
   DOWNLOAD_END_ADDR: in std_logic_vector(23 downto 0);
      -- Download end address. Each address represents one 16-bit word.
	 -- IMPORTANT REQUIREMENT: 
	 -- number of words read i.e(DOWNLOAD_END_ADDR - DOWNLOAD_START_ADDR + 1)
	 -- MUST BE A MULTIPLE OF 4 words.
   START_SINGLE_DOWNLOAD_PULSE: in std_logic;
      -- One clock pulse wide pulse indicating that we want to start
      -- a single download session.
   START_CONTINUOUS_DOWNLOAD_PULSE: in std_logic;
      -- One clock pulse wide pulse indicating that we want to start
      -- a continuous download session.

   STOP_CURRENT_OPERATION_PULSE: in std_logic;
      -- One clock pulse wide pulse indicating that we want to cancel the
      -- current upload or download session.


   --// Monitoring signals
   WRITE_POINTER_OUT: out std_logic_vector(23 downto 0);
   READ_POINTER_OUT: out std_logic_vector(23 downto 0);
   SDRAM_DOWNLOAD_IN_PROGRESS: out std_logic;
      -- Asserted if download is in progress, deasserted otherwise.
      -- Exactly the same signals as SINGLE_DOWNLOAD_FLAG OR:ed
      -- with CONTINUOUS_DOWNLOAD_FLAG.
   SDRAM_UPLOAD_IN_PROGRESS: out std_logic;
      -- Asserted if upload is in progress, deasserted otherwise.
      -- Exactly the same signals as UPLOAD_FLAG.


   --// User interface (write to SDRAM)
   AT_LEAST_4_WORDS_AVAILABLE: in std_logic;
      -- User states that it is ready to write 4 words in rapid succession. 
	 -- Triggers a 4-word burst write cyle as soon as SDRAM is ready. 
	 -- Should stay high as long as 4-words of data are available for upload.
	 -- Enacted upon only if this component is in "UPLOAD" mode.
   DATA_IN: in std_logic_vector(15 downto 0);
      -- The 16 bit wide data word to be written to SDRAM.
 	 -- The user MUST provide the data in a timely manner, i.e. exactly one CLK after 
	 -- a data word is requested by DATA_ON_INPUT_WANTED. 4 words are to be written in a row.
   DATA_ON_INPUT_WANTED: out std_logic;
      -- Signal telling the user to send us data to be written to SDRAM. 
      -- expect the data on the very next clock cycle after the request was made.


   --// User interface (read from SDRAM)
   DATA_OUT_4W_REQ: in std_logic;
      -- signal requesting 4 words from the SDRAM.
	 -- Should stay high as long as data is needed.
	 -- Valid only if this component is in 'DOWNLOAD (continuous or one-time)" mode. 
   DATA_OUT: out std_logic_vector(15 downto 0);
      -- Data retrieved from the SDRAM memory. Read at rising edge of 
	 -- CLK when DATA_OUT_CLK = '1'.
   DATA_OUT_CLK: out std_logic;
      -- A one clock cycle per DATA_OUT wide pulse indicating that the
      -- data on the DATA_OUT lines are to be read.
   FIRST_WORD_OUT: out std_logic;
      -- Signal indicating that the data currently being sent out is the
      -- first in the chosen window. Aligned with the DATA_OUT_CLK.
   LAST_WORD_OUT: out std_logic;
      -- Only in use during a single download session. Signal indicating
      -- that the data currently being sent out is the last in the chosen
      -- window. Aligned with the DATA_OUT_CLK.

   --// Test points
   RD_TRIGGER: out std_logic;
   	-- one CLK pulse at the start of a SDRAM burst read cycle
   WR_TRIGGER: out std_logic;
   	-- one CLK pulse at the start of a SDRAM burst write cycle


   --// Direct SDRAM interface:
   SDRAM_A: out std_logic_vector(12 downto 0);
      -- Address lines.
   SDRAM_DQ: inout std_logic_vector(15 downto 0);
      -- Bi-directional data lines
   SDRAM_BA0: out std_logic;
   SDRAM_BA1: out std_logic;
   SDRAM_CAS_N: out std_logic;
   SDRAM_RAS_N: out std_logic;
   SDRAM_WE_N: out std_logic;
   SDRAM_CLK: out std_logic;
   SDRAM_CKE: out std_logic;
   SDRAM_CS_N: out std_logic;
   SDRAM_DQML: out std_logic;
   SDRAM_DQMH: out std_logic
   );
end component;

-----------------------------------------------------------------
-- SIGNALS
-----------------------------------------------------------------
-- Suffix _D indicates a one CLK delayed version of the net with the same name
-- Suffix _E indicates an extended precision version of the net with the same name
-- Suffix _N indicates an inverted version of the net with the same name
--// CONSTANTS
signal ZERO: std_logic;
signal ONE: std_logic;

--signal READ_POINTER: std_logic_vector(23 downto 0);
--signal WRITE_POINTER: std_logic_vector(23 downto 0);

   --// Control signals
signal UPLOAD_COMPLETED_PULSE: std_logic;
signal START_ADDR: std_logic_vector(23 downto 0);
signal END_ADDR: std_logic_vector(23 downto 0);

   --// User interface (write to SDRAM)
signal DATA_IN: std_logic_vector(15 downto 0);
signal DATA_ON_INPUT_WANTED: std_logic;

   --// User interface (read from SDRAM)
signal DATA_OUT: std_logic_vector(15 downto 0);
signal DATA_OUT_D: std_logic_vector(15 downto 0);
signal DATA_OUT_CLK: std_logic;
signal DATA_OUT_CLK_D: std_logic;

signal SUCCESS: std_logic;

signal END_OF_TEST_LOCAL: std_logic;

signal RD_TRIGGER: std_logic;
signal WR_TRIGGER: std_logic;
    
signal DATA_COUNTER: std_logic_vector(24 downto 0);
   -- used to fill SDRAM during upload
   -- and to verify content during download

signal DL_MODE: std_logic := '0';  -- indicates download operation
signal ERROR_CONDITION: std_logic;
signal ERROR_CONDITION_D: std_logic;

-----------------------------------------------------------------
-- IMPLEMENTATION
-----------------------------------------------------------------
begin
--// CONSTANTS ---------------------
ZERO <= '0';
ONE <= '1';			   

--// SDRAM address range to be verified
-- Range must be a multiple of 4 word addresses.
START_ADDR <= (others => '0');
END_ADDR <= x"FFFFFF";   


SDRAM_CONTROLLER_001: SDRAM_CONTROLLER port map (
   --// CLOCK, RESET
   ASYNC_RESET => ASYNC_RESET,
   CLK => CLK,

   --// Control signals
   POWER_DOWN => ZERO,

   UPLOAD_START_ADDR => START_ADDR,
   UPLOAD_END_ADDR => END_ADDR,
   START_UPLOAD_PULSE => START_TEST,
   UPLOAD_COMPLETED_PULSE => UPLOAD_COMPLETED_PULSE,
   DOWNLOAD_START_ADDR => START_ADDR,
   DOWNLOAD_END_ADDR => END_ADDR,				   
   START_SINGLE_DOWNLOAD_PULSE => UPLOAD_COMPLETED_PULSE,
   START_CONTINUOUS_DOWNLOAD_PULSE => ZERO,
   STOP_CURRENT_OPERATION_PULSE => ZERO,

   --// Monitoring signals
--   WRITE_POINTER_OUT => WRITE_POINTER,
--   READ_POINTER_OUT => READ_POINTER,

   --// User interface (write to SDRAM)
   AT_LEAST_4_WORDS_AVAILABLE => ONE,
   DATA_IN => DATA_IN,
   DATA_ON_INPUT_WANTED => DATA_ON_INPUT_WANTED,

   --// User interface (read from SDRAM)
   DATA_OUT_4W_REQ => ONE,
   DATA_OUT => DATA_OUT,
   DATA_OUT_CLK => DATA_OUT_CLK,
   LAST_WORD_OUT => open,

	RD_TRIGGER => RD_TRIGGER,
	WR_TRIGGER => WR_TRIGGER,

   --// SDRAM interface:
   SDRAM_A => SDRAM_A,
   SDRAM_DQ => SDRAM_DQ,
   SDRAM_BA0 => SDRAM_BA0,
   SDRAM_BA1 => SDRAM_BA1,
   SDRAM_CAS_N => SDRAM_CAS_N,
   SDRAM_RAS_N => SDRAM_RAS_N,
   SDRAM_WE_N => SDRAM_WE_N,
   SDRAM_CLK => SDRAM_CLK,
   SDRAM_CKE => SDRAM_CKE,
   SDRAM_CS_N => SDRAM_CS_N,
   SDRAM_DQML => SDRAM_DQML,
   SDRAM_DQMH => SDRAM_DQMH
   );

   -----------------------------------------------------------------
   -- INITIALIZATION
   -----------------------------------------------------------------   
   
DATA_COUNTER_GEN_001: process(CLK)
begin
	if rising_edge(CLK) then  
		if(START_TEST = '1') or (UPLOAD_COMPLETED_PULSE = '1') then
			DATA_COUNTER <= (START_ADDR & "0") - 1;         
		elsif((DATA_ON_INPUT_WANTED = '1')  or (DATA_OUT_CLK = '1'))then
			-- increment when SDRAM controller asks for input data or delivers output data
			-- We trust the SDRAM controller to ask for the right number of samples.
			DATA_COUNTER <= DATA_COUNTER + 1;      
		end if;
	end if;
end process;  


   -----------------------------------------------------------------
   -- Upload and fill SDRAM
   -----------------------------------------------------------------   
-- Time-multiplex 32-bit counter value into SDRAM, lower word first.                 
DATA_UL_001: process(DATA_COUNTER)
begin
	if(DATA_COUNTER(0) = '0') then
		DATA_IN <= DATA_COUNTER(16 downto 1);
   	else
		DATA_IN <= x"00" & DATA_COUNTER(24 downto 17);
	end if;		
end process; 

   -----------------------------------------------------------------
   -- Download and verify data content
   -----------------------------------------------------------------   
 
DL_MODE_GEN_001: process(CLK)
begin
	if rising_edge(CLK) then  
		if(START_TEST = '1') then
			DL_MODE <= '0';
		elsif(UPLOAD_COMPLETED_PULSE = '1') then
			DL_MODE <= '1';
		end if;
	end if;
end process;  

-- error condition
ERROR_CONDITION <= '1' when ((DL_MODE = '1') and (DATA_OUT_CLK_D = '1') and (DATA_OUT_D /= DATA_IN))
				else '0';

-- test is successful by default, unless an error condition is encountered.
SUCCESS_001: process(CLK)
begin
	if rising_edge(CLK) then      
		DATA_OUT_CLK_D <= DATA_OUT_CLK;   
		DATA_OUT_D <= DATA_OUT;
		ERROR_CONDITION_D <= ERROR_CONDITION;

		if(START_TEST = '1') then
			SUCCESS <= '1';
		elsif(ERROR_CONDITION = '1') then
			SUCCESS <= '0'; 
		end if;
	end if;
end process;
SUCCESSFULL_TEST <= SUCCESS;

-- remember the first address and data					
FAILURE_001: process(CLK)
begin
	if rising_edge(CLK) then   
		if((ERROR_CONDITION = '1') and (SUCCESS = '1')) then
			-- first instance of failure
			FIRST_FAILED_ADDRESS <= DATA_COUNTER(23 downto 0);
			FIRST_FAILED_DATA_WORD <= DATA_OUT;
		end if;
	end if;
end process;

END_OF_TEST_GEN_001: process(CLK)
begin
	if rising_edge(CLK) then 
		if((DL_MODE = '1') and  
			(DATA_COUNTER(23 downto 0) = END_ADDR)
			and 	(DATA_OUT_CLK_D = '1')) then
		 	END_OF_TEST_LOCAL <= '1';
		else
		 	END_OF_TEST_LOCAL <= '0';
		end if;
	end if;
end process;

-- END_OF_TEST <= '1' when ((DL_MODE = '1') and (DATA_COUNTER(23 downto 0) = END_ADDR)) else '0';

END_OF_TEST <= END_OF_TEST_LOCAL;

--// TEST POINTS --------------------------
TEST_POINTS(1) <= START_TEST;
TEST_POINTS(2) <= END_OF_TEST_LOCAL;
TEST_POINTS(3) <= DL_MODE;
TEST_POINTS(4) <= DATA_COUNTER(0);
TEST_POINTS(5) <= UPLOAD_COMPLETED_PULSE;
TEST_POINTS(6) <= DATA_COUNTER(23);
TEST_POINTS(7) <= ERROR_CONDITION_D;
TEST_POINTS(8) <= SUCCESS;
TEST_POINTS(9) <= RD_TRIGGER;
TEST_POINTS(10) <= WR_TRIGGER;

end behavior;