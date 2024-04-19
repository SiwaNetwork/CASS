-------------------------------------------------------------
--	Filename:  CAPTURE_1_BIT_WORDS.VHD
-- Author: Alain Zarembowitch / MSS
--	Version: 2
--	Date last modified: 10-02-03
-- Inheritance: 	none
--
--
-- 
---------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CAPTURE_1_BIT_WORDS is port ( 
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
	WORD_1_BIT_IN: in std_logic;
		-- Input signal to be captured
	WORD_CLK_IN: in std_logic;
		-- WORD_1_BIT_IN will be read whenever WORD_CLK_IN = '1'.
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

architecture behavioral of CAPTURE_1_BIT_WORDS is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------

component RAMB4_S1_S1 port (
	DIA: in std_logic_vector (0 downto 0);
	DIB: in std_logic_vector (0 downto 0);
	ENA: in std_logic;
	ENB: in std_logic;
	WEA: in std_logic;
	WEB: in std_logic;
	RSTA: in std_logic;
	RSTB: in std_logic;
	CLKA: in std_logic;
	CLKB: in std_logic;
	ADDRA: in std_logic_vector (11 downto 0);
	ADDRB: in std_logic_vector (11 downto 0);
	DOA: out std_logic_vector (0 downto 0);
	DOB: out std_logic_vector (0 downto 0)); 
end component;


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


component WORD1_TO_WORD8 port (
	ASYNC_RESET: in std_logic;
		-- Asynchronous reset, active high
	CLK: in std_logic;
		-- Reference clock


	--// INPUTS 
	COMPONENT_RESET: in std_logic;
	WORD_IN: in std_logic;
		-- Word to be converted into a 64 bit word. Will be read when
		-- Valid when WORD_IN_CLK = '1'.
	WORD_IN_CLK: in std_logic;
		-- The data on the WORD_IN lines will be read when WORD_IN_CLK = '1'.


	--// OUTPUTS
	WORD_OUT: out std_logic_vector(7 downto 0);
		-- Word converted into byte. Valid when WORD_OUT_CLK = '1'.
	WORD_OUT_CLK: out std_logic
		-- One clock pulse wide pulse indicating that the byte on the WORD_OUT 
		-- lines is valid now.
	);
end component;

--------------------------------------------------------
--     SIGNALS
--------------------------------------------------------

--// Constants
signal ZERO: std_logic;
signal ONE: std_logic;
signal ZERO1: std_logic_vector(0 downto 0);


signal STATE_LOCAL: std_logic_vector(1 downto 0);
signal WRITE_POINTER: std_logic_vector(11 downto 0);
signal WRITE_POINTER_ADD_VALUE: std_logic_vector(11 downto 0);
signal WRITE_POINTER_PLUS_ADD_VALUE: std_logic_vector(11 downto 0);
signal WRITE_POINTER_PLUS_ONE: std_logic_vector(11 downto 0);
signal WRITE_POINTER_END: std_logic_vector(11 downto 0);
signal WRITE_ENABLE: std_logic;
signal READ_POINTER: std_logic_vector(11 downto 0);
signal DECIMATED_WORD_CLK: std_logic;
signal LAST_WORD_CAPTURED_PULSE: std_logic;
signal LAST_WORD_CAPTURED_PULSE_D: std_logic;
signal WORD_CLK: std_logic;
signal WORD_FROM_BUFFER: std_logic_vector(0 downto 0);
signal COUNTER_3_BIT: std_logic_vector(2 downto 0);
signal DIA: std_logic_vector(0 downto 0);

--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------

begin


--// COMSCOPE SOURCE CODE -----------
ZERO <= '0';
ONE <= '1';
ZERO1 <= (others => '0');


STATE <= STATE_LOCAL;


STATE_MACHINE_001: process(ASYNC_RESET, CLK, TRIGGER_POSITION)
begin
	if(ASYNC_RESET = '1') then
		STATE_LOCAL <= "01";
		WRITE_POINTER_END <= (others => '0');
	elsif rising_edge(CLK) then
		if (START_CAPTURING = '1') then
			STATE_LOCAL <= "01";
		elsif (TRIGGER_REARM = '1') then
			STATE_LOCAL <= "10";
		elsif (STATE_LOCAL = "10") and (TRIGGER = '1') then 
			-- trigger received, waiting for data and data capture completion
			-- trigger is only active if trace is re-armed
			STATE_LOCAL <= "11";
			-- remember the address at which we should stop capturing
			WRITE_POINTER_END <= WRITE_POINTER_PLUS_ADD_VALUE;
		elsif (STATE_LOCAL = "11") and (LAST_WORD_CAPTURED_PULSE = '1') then 
			STATE_LOCAL <= "00";
		end if;
	end if;
end process;


WRITE_POINTER_PLUS_ADD_VALUE <= WRITE_POINTER + WRITE_POINTER_ADD_VALUE;

-- compute end of buffer pointer location
-- Depending on whether the trigger is selected to be 
-- at 0%, 10%, 50% or 90% of the capture window
WRITE_POINTER_ADD_VALUE <= 
	"111001100110" when TRIGGER_POSITION = "01" else	-- trigger at 10% (3686)
	"100000000000" when TRIGGER_POSITION = "10" else 	-- trigger at 50% (2048)
	"000110011010" when TRIGGER_POSITION = "11" else 	-- trigger at 90% (410)
	"000000000000";						


WRITE_POINTER_PLUS_ONE <= WRITE_POINTER + 1;

LAST_WORD_CAPTURED_PULSE <= DECIMATED_WORD_CLK when (STATE_LOCAL = "11" and
									 WRITE_POINTER_PLUS_ONE = WRITE_POINTER_END) else '0';


WRITE_ENABLE <= DECIMATED_WORD_CLK when (STATE_LOCAL /= "00") else '0'; 


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


DELAY: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		LAST_WORD_CAPTURED_PULSE_D <= '0';
	elsif rising_edge(CLK) then
		LAST_WORD_CAPTURED_PULSE_D <= LAST_WORD_CAPTURED_PULSE;
	end if;
end process;


MANAGE_RP_AND_WORD_CLK: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		WORD_CLK <= '0';
		READ_POINTER <= (others => '0');
		COUNTER_3_BIT <= (others => '0');
	elsif rising_edge(CLK) then
		if (LAST_WORD_CAPTURED_PULSE = '1') then
			READ_POINTER <= WRITE_POINTER_END;
		elsif (NEXT_WORD_PLEASE = '1') or (LAST_WORD_CAPTURED_PULSE_D = '1') or
				(COUNTER_3_BIT /= "000") then
			COUNTER_3_BIT <= COUNTER_3_BIT + 1;
			READ_POINTER <= READ_POINTER + 1;
			WORD_CLK <= '1';
		else 
			WORD_CLK <= '0';
		end if;
	end if;
end process;

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

DIA <= "0" when WORD_1_BIT_IN = '0' else "1";

-- Instantiate the block RAM
RAMB_001:  RAMB4_S1_S1 port map(
	DIA => DIA,
	DIB => ZERO1,
	ENA => ONE,
	ENB => ONE,
	WEA => WRITE_ENABLE,
	WEB => ZERO,
	RSTA => ASYNC_RESET,
	RSTB => ASYNC_RESET,
	CLKA => CLK,
	CLKB => CLK,
	ADDRA => WRITE_POINTER,
	ADDRB => READ_POINTER,
	DOB => WORD_FROM_BUFFER
);


-- Instantiate the 1 bit to 8 bit conversion
WORD1_TO_WORD8_001:  WORD1_TO_WORD8 port map(
	ASYNC_RESET => ASYNC_RESET,
	CLK => CLK,
	COMPONENT_RESET => LAST_WORD_CAPTURED_PULSE,
	WORD_IN => WORD_FROM_BUFFER(0),
	WORD_IN_CLK => WORD_CLK,
	WORD_OUT => WORD_8_BIT_OUT,
	WORD_OUT_CLK => WORD_CLK_OUT
);

end behavioral;