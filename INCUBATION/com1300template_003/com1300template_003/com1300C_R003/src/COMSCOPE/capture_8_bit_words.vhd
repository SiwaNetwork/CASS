-------------------------------------------------------------
--	Filename:  CAPTURE_8_BIT_WORDS.VHD
-- Author: Alain Zarembowitch / MSS
--	Version: 3
--	Date last modified: 8-26-06
-- Inheritance: 	none
--
-- Rev 3. 8-26-06 AZ
-- Corrected bug introduced when switching from RAMB4_S8_S8 to RAMB16_S9_S9
-- The addresses must be modulo 512, not modulo 2K
-- 
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity CAPTURE_8_BIT_WORDS is port ( 
	--GLOBAL CLOCKS
   CLK : in std_logic;				-- Master clock for this FPGA
	ASYNC_RESET: in std_logic;		-- Asynchronous reset active high


	-- Inputs
	DECIMATE_VALUE: in std_logic_vector(4 downto 0);
		-- Decimate value. Can be taken straight from the registers.
		-- The decimation will 2^DECIMATE_VALUE.
	TRIGGER_POSITION: in std_logic_vector(1 downto 0);
		-- 00		0 %
		-- 01		10 %
		-- 10		50 %
		-- 11		90 %
	WORD_8_BIT_IN: in std_logic_vector(7 downto 0);
		-- Input signal to be captured
	WORD_CLK_IN: in std_logic;
		-- WORD_4_BIT_IN will be read whenever WORD_CLK_IN = '1'.
	NEXT_WORD_PLEASE: in std_logic;
		-- Increments the READ_POINTER so that the next 8-bit 
		-- word is ready to be read.
	TRIGGER: in std_logic;
		-- Is one when a trigger was forced or if the trigger 
		-- conditions were met. One CLK cycle wide pulse.
	TRIGGER_REARM: in std_logic;
		-- One CLK cycle wide pulse used to rearm the trigger.
	START_CAPTURING: in std_logic;
		-- One CLK cycle wide pulse that makes sure data is
		-- being captured when nothing is going on. Necessary
		-- before a capture with a non-zero trigger offset.


	-- Outputs
	WORD_8_BIT_OUT: out std_logic_vector(7 downto 0);
		-- The signal that was stored in the RAM.
	WORD_CLK_OUT: out std_logic;
		-- WORD_8_BIT_OUT is valid when WORD_CLK_OUT = '1'.
	STATE: out std_logic_vector(1 downto 0)
		-- 01		CAPTURING
		-- 10		CAPTURING_WAITING_FOR_TRIGGER
		-- 11		CAPTURING_TRIGGER_DETECTED
		-- 00		CAPTURE_CEASED
);
end entity;

architecture behavioral of CAPTURE_8_BIT_WORDS is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------
component DECIMATE port (
	--GLOBAL CLOCKS
   CLK : in std_logic;				-- Master clock for this FPGA
	ASYNC_RESET: in std_logic;		-- Asynchronous reset active high

	-- Inputs
	DECIMATE_VALUE: in std_logic_vector(4 downto 0);
	SAMPLE_CLK_IN: in std_logic;

	-- Output
	DECIMATED_SAMPLE_CLK_OUT: out std_logic
);
end component;

--------------------------------------------------------
--     SIGNALS
--------------------------------------------------------

--// Constants
signal ZERO: std_logic;
signal ONE: std_logic;
signal ZERO8: std_logic_vector(7 downto 0);
signal ZERO1: std_logic_vector(0 downto 0);


-- State Machine Variables
type STATETYPE is (CAPTURING, CAPTURING_WAITING_FOR_TRIGGER, 
						 CAPTURING_TRIGGER_DETECTED, CAPTURE_CEASED);


signal STATE_LOCAL: STATETYPE;
signal WRITE_POINTER: std_logic_vector(8 downto 0);
signal WRITE_POINTER_E: std_logic_vector(10 downto 0);
signal WRITE_POINTER_ADD_VALUE: std_logic_vector(8 downto 0);
signal WRITE_POINTER_PLUS_ADD_VALUE: std_logic_vector(8 downto 0);
signal WRITE_POINTER_PLUS_ONE: std_logic_vector(8 downto 0);
signal WRITE_POINTER_END: std_logic_vector(8 downto 0);
signal WRITE_ENABLE: std_logic;
signal READ_POINTER: std_logic_vector(8 downto 0);
signal READ_POINTER_E: std_logic_vector(10 downto 0);
signal DECIMATED_WORD_CLK: std_logic;
signal LAST_WORD_CAPTURED_PULSE: std_logic;
signal LAST_WORD_CAPTURED_PULSE_D: std_logic;
signal WORD_CLK_OUT_LOCAL: std_logic;
signal NEXT_WORD_PLEASE_D: std_logic;
--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------

begin


--// COMSCOPE SOURCE CODE -----------
ZERO <= '0';
ONE <= '1';
ZERO8 <= (others => '0');


STATE <= "01" when STATE_LOCAL = CAPTURING else 
			"10" when STATE_LOCAL = CAPTURING_WAITING_FOR_TRIGGER else 
			"11" when STATE_LOCAL = CAPTURING_TRIGGER_DETECTED else 
			"00"; --  STATE_LOCAL = CAPTURE_CEASED


STATE_MACHINE_001: process(ASYNC_RESET, CLK, TRIGGER_POSITION)
begin
	if(ASYNC_RESET = '1') then
		STATE_LOCAL <= CAPTURING;
		WRITE_POINTER_END <= (others => '0');
	elsif rising_edge(CLK) then
		if (START_CAPTURING = '1') then
			STATE_LOCAL <= CAPTURING;
		elsif (TRIGGER_REARM = '1') then
			STATE_LOCAL <= CAPTURING_WAITING_FOR_TRIGGER;
		elsif (STATE_LOCAL = CAPTURING_WAITING_FOR_TRIGGER) and (TRIGGER = '1') then
			-- trigger received, waiting for data and data capture completion
			-- trigger is only active if trace is re-armed
			STATE_LOCAL <= CAPTURING_TRIGGER_DETECTED;
			-- remember the address at which we should stop capturing
			WRITE_POINTER_END <= WRITE_POINTER_PLUS_ADD_VALUE;
		elsif (STATE_LOCAL = CAPTURING_TRIGGER_DETECTED) and (LAST_WORD_CAPTURED_PULSE = '1') then
			STATE_LOCAL <= CAPTURE_CEASED;
		end if;
	end if;
end process;


WRITE_POINTER_PLUS_ADD_VALUE <= WRITE_POINTER + WRITE_POINTER_ADD_VALUE;

-- compute end of buffer pointer location
-- Depending on whether the trigger is selected to be 
-- at 0%, 10%, 50% or 90% of the capture window
WRITE_POINTER_ADD_VALUE <= 
	"111001101" when TRIGGER_POSITION = "01" else -- trigger at 10% (461)
	"100000000" when TRIGGER_POSITION = "10" else -- trigger at 50% (256)
	"000110011" when TRIGGER_POSITION = "11" else -- trigger at 90% (51)
	"000000000"; 											 -- trigger at 0% (0)


WRITE_POINTER_PLUS_ONE <= WRITE_POINTER + 1;

LAST_WORD_CAPTURED_PULSE <= DECIMATED_WORD_CLK when (STATE_LOCAL = CAPTURING_TRIGGER_DETECTED and
									 WRITE_POINTER_PLUS_ONE = WRITE_POINTER_END) else '0';


WRITE_ENABLE <= DECIMATED_WORD_CLK when (STATE_LOCAL /= CAPTURE_CEASED) else '0'; 


MANAGE_WP: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		WRITE_POINTER <= (others => '0');
	elsif rising_edge(CLK) then
		if (WRITE_ENABLE = '1') then
			WRITE_POINTER <= WRITE_POINTER_PLUS_ONE;
		end if;
	end if;
end process;


MANAGE_RP: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		READ_POINTER <= (others => '0');
		WORD_CLK_OUT_LOCAL <= '0';
		LAST_WORD_CAPTURED_PULSE_D <= '0';
		NEXT_WORD_PLEASE_D <= '0';
	elsif rising_edge(CLK) then
		NEXT_WORD_PLEASE_D <= NEXT_WORD_PLEASE;
		LAST_WORD_CAPTURED_PULSE_D	<= LAST_WORD_CAPTURED_PULSE;
		WORD_CLK_OUT_LOCAL <= NEXT_WORD_PLEASE_D or LAST_WORD_CAPTURED_PULSE_D;
		if (LAST_WORD_CAPTURED_PULSE = '1') then
			READ_POINTER <= WRITE_POINTER_END;
		elsif (NEXT_WORD_PLEASE = '1') then
			READ_POINTER <= READ_POINTER + 1;
		end if;
	end if;
end process;

WORD_CLK_OUT <= WORD_CLK_OUT_LOCAL;

--------------------------------------------------------------------------
-- COMPONENT INSTANTIATIONS
--------------------------------------------------------------------------

-- Instantiate the decimation
DECIMATE_001: DECIMATE port map(
	CLK => CLK,
	ASYNC_RESET => ASYNC_RESET,
	DECIMATE_VALUE => DECIMATE_VALUE,
	SAMPLE_CLK_IN => WORD_CLK_IN,
	DECIMATED_SAMPLE_CLK_OUT => DECIMATED_WORD_CLK
);

-- Instantiate the block RAM
-- Extend wptr/rptr precision to mimic previous RAMB4_S8_S8
WRITE_POINTER_E <= "00" & WRITE_POINTER;
READ_POINTER_E <= "00" & READ_POINTER;
RAMB_001 : RAMB16_S9_S9
port map (
   DOA => open,      
   DOB => WORD_8_BIT_OUT,      
   DOPA => open,    
   DOPB => open,    
   ADDRA => WRITE_POINTER_E,	-- modulo 512 address. Uses 1/4 of the RAMB
   ADDRB => READ_POINTER_E,   -- modulo 512 address. Uses 1/4 of the RAMB
   CLKA => CLK,    
   CLKB => CLK,    
   DIA => WORD_8_BIT_IN,      
   DIB => ZERO8,      
   DIPA => ZERO1,    
   DIPB => ZERO1,    
   ENA => ONE,      
   ENB => ONE,      
   SSRA => ZERO,    
   SSRB => ZERO,    
   WEA => WRITE_ENABLE,      
   WEB => ZERO       
);


end behavioral;