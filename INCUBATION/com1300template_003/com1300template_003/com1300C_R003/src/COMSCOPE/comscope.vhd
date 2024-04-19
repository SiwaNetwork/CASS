-------------------------------------------------------------
--	Filename:  COMSCOPE.VHD
-- Author: Alain Zarembowitch / MSS
--	Version: 2
--	Date last modified: 9-08-03
-- Inheritance: 	none
--
--
-- 
---------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity COMSCOPE is port ( 
	--GLOBAL CLOCKS
   CLK : in std_logic;				-- Master clock for this FPGA
	ASYNC_RESET: in std_logic;		-- Asynchronous reset active high


	-- Choose between signed or unsigned representation
	SIGNED_REPRESENTATION_U_SIGNED_N: in std_logic;
		-- '0'  	Unsigned
		-- '1'  	Signed


	-- Input registers
	REG237: in std_logic_vector(7 downto 0);
	REG238: in std_logic_vector(7 downto 0);
	REG239: in std_logic_vector(7 downto 0);
	REG240: in std_logic_vector(7 downto 0);
	REG241: in std_logic_vector(7 downto 0);
	REG242: in std_logic_vector(7 downto 0);
	REG243: in std_logic_vector(7 downto 0);
	REG244: in std_logic_vector(7 downto 0);
	REG245: in std_logic_vector(7 downto 0);
	REG246: in std_logic_vector(7 downto 0);
	REG247: in std_logic_vector(7 downto 0);
	REG248: in std_logic_vector(7 downto 0);
	REG249: in std_logic_vector(7 downto 0);


	-- Trace 1 input signals
	-- 1-bit signals
	SIGNAL_1_BIT_1_1: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_1_1: in std_logic;
	SIGNAL_1_BIT_1_2: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_1_2: in std_logic;
	SIGNAL_1_BIT_1_3: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_1_3: in std_logic;
	SIGNAL_1_BIT_1_4: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_1_4: in std_logic;

	-- 2-bit signals
	SIGNAL_2_BIT_1_1: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_1_1: in std_logic;
	SIGNAL_2_BIT_1_2: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_1_2: in std_logic;
	SIGNAL_2_BIT_1_3: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_1_3: in std_logic;
	SIGNAL_2_BIT_1_4: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_1_4: in std_logic;

	-- 4-bit signals
	SIGNAL_4_BIT_1_1: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_1_1: in std_logic;
	SIGNAL_4_BIT_1_2: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_1_2: in std_logic;
	SIGNAL_4_BIT_1_3: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_1_3: in std_logic;
	SIGNAL_4_BIT_1_4: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_1_4: in std_logic;

	-- 8-bit signals
	SIGNAL_8_BIT_1_1: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_1_1: in std_logic;
	SIGNAL_8_BIT_1_2: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_1_2: in std_logic;
	SIGNAL_8_BIT_1_3: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_1_3: in std_logic;
	SIGNAL_8_BIT_1_4: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_1_4: in std_logic;

	-- 16-bit signals
	SIGNAL_16_BIT_1_1: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_1_1: in std_logic;
	SIGNAL_16_BIT_1_2: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_1_2: in std_logic;
	SIGNAL_16_BIT_1_3: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_1_3: in std_logic;
	SIGNAL_16_BIT_1_4: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_1_4: in std_logic;
	-- Add signals as necessary (up to 127 signals total per trace)


	-- Trace 2 input signals
	-- 1-bit signals
	SIGNAL_1_BIT_2_1: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_2_1: in std_logic;
	SIGNAL_1_BIT_2_2: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_2_2: in std_logic;
	SIGNAL_1_BIT_2_3: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_2_3: in std_logic;
	SIGNAL_1_BIT_2_4: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_2_4: in std_logic;

	-- 2-bit signals
	SIGNAL_2_BIT_2_1: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_2_1: in std_logic;
	SIGNAL_2_BIT_2_2: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_2_2: in std_logic;
	SIGNAL_2_BIT_2_3: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_2_3: in std_logic;
	SIGNAL_2_BIT_2_4: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_2_4: in std_logic;

	-- 4-bit signals
	SIGNAL_4_BIT_2_1: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_2_1: in std_logic;
	SIGNAL_4_BIT_2_2: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_2_2: in std_logic;
	SIGNAL_4_BIT_2_3: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_2_3: in std_logic;
	SIGNAL_4_BIT_2_4: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_2_4: in std_logic;

	-- 8-bit signals
	SIGNAL_8_BIT_2_1: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_2_1: in std_logic;
	SIGNAL_8_BIT_2_2: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_2_2: in std_logic;
	SIGNAL_8_BIT_2_3: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_2_3: in std_logic;
	SIGNAL_8_BIT_2_4: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_2_4: in std_logic;

	-- 16-bit signals
	SIGNAL_16_BIT_2_1: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_2_1: in std_logic;
	SIGNAL_16_BIT_2_2: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_2_2: in std_logic;
	SIGNAL_16_BIT_2_3: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_2_3: in std_logic;
	SIGNAL_16_BIT_2_4: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_2_4: in std_logic;
	-- Add signals as necessary (up to 127 signals total per trace)


	-- Trace 3 input signals
	-- 1-bit signals
	SIGNAL_1_BIT_3_1: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_3_1: in std_logic;
	SIGNAL_1_BIT_3_2: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_3_2: in std_logic;
	SIGNAL_1_BIT_3_3: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_3_3: in std_logic;
	SIGNAL_1_BIT_3_4: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_3_4: in std_logic;

	-- 2-bit signals
	SIGNAL_2_BIT_3_1: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_3_1: in std_logic;
	SIGNAL_2_BIT_3_2: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_3_2: in std_logic;
	SIGNAL_2_BIT_3_3: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_3_3: in std_logic;
	SIGNAL_2_BIT_3_4: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_3_4: in std_logic;

	-- 4-bit signals
	SIGNAL_4_BIT_3_1: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_3_1: in std_logic;
	SIGNAL_4_BIT_3_2: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_3_2: in std_logic;
	SIGNAL_4_BIT_3_3: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_3_3: in std_logic;
	SIGNAL_4_BIT_3_4: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_3_4: in std_logic;

	-- 8-bit signals
	SIGNAL_8_BIT_3_1: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_3_1: in std_logic;
	SIGNAL_8_BIT_3_2: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_3_2: in std_logic;
	SIGNAL_8_BIT_3_3: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_3_3: in std_logic;
	SIGNAL_8_BIT_3_4: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_3_4: in std_logic;

	-- 16-bit signals
	SIGNAL_16_BIT_3_1: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_3_1: in std_logic;
	SIGNAL_16_BIT_3_2: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_3_2: in std_logic;
	SIGNAL_16_BIT_3_3: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_3_3: in std_logic;
	SIGNAL_16_BIT_3_4: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_3_4: in std_logic;
	-- Add signals as necessary (up to 127 signals total per trace)


	-- Trace 4 input signals
	-- 1-bit signals
	SIGNAL_1_BIT_4_1: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_4_1: in std_logic;
	SIGNAL_1_BIT_4_2: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_4_2: in std_logic;
	SIGNAL_1_BIT_4_3: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_4_3: in std_logic;
	SIGNAL_1_BIT_4_4: in std_logic;
	SIGNAL_1_BIT_SAMPLE_CLK_4_4: in std_logic;

	-- 2-bit signals
	SIGNAL_2_BIT_4_1: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_4_1: in std_logic;
	SIGNAL_2_BIT_4_2: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_4_2: in std_logic;
	SIGNAL_2_BIT_4_3: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_4_3: in std_logic;
	SIGNAL_2_BIT_4_4: in std_logic_vector(1 downto 0);
	SIGNAL_2_BIT_SAMPLE_CLK_4_4: in std_logic;

	-- 4-bit signals
	SIGNAL_4_BIT_4_1: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_4_1: in std_logic;
	SIGNAL_4_BIT_4_2: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_4_2: in std_logic;
	SIGNAL_4_BIT_4_3: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_4_3: in std_logic;
	SIGNAL_4_BIT_4_4: in std_logic_vector(3 downto 0);
	SIGNAL_4_BIT_SAMPLE_CLK_4_4: in std_logic;

	-- 8-bit signals
	SIGNAL_8_BIT_4_1: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_4_1: in std_logic;
	SIGNAL_8_BIT_4_2: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_4_2: in std_logic;
	SIGNAL_8_BIT_4_3: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_4_3: in std_logic;
	SIGNAL_8_BIT_4_4: in std_logic_vector(7 downto 0);
	SIGNAL_8_BIT_SAMPLE_CLK_4_4: in std_logic;

	-- 16-bit signals
	SIGNAL_16_BIT_4_1: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_4_1: in std_logic;
	SIGNAL_16_BIT_4_2: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_4_2: in std_logic;
	SIGNAL_16_BIT_4_3: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_4_3: in std_logic;
	SIGNAL_16_BIT_4_4: in std_logic_vector(15 downto 0);
	SIGNAL_16_BIT_SAMPLE_CLK_4_4: in std_logic;
	-- Add signals as necessary (up to 127 signals total per trace)



	-- Trigger signals
	-- 1-bit Triggers
	TRIGGER_1_BIT_1: in std_logic;
	TRIGGER_1_BIT_SAMPLE_CLK_1: in std_logic;
	TRIGGER_1_BIT_2: in std_logic;
	TRIGGER_1_BIT_SAMPLE_CLK_2: in std_logic;
	TRIGGER_1_BIT_3: in std_logic;
	TRIGGER_1_BIT_SAMPLE_CLK_3: in std_logic;
	TRIGGER_1_BIT_4: in std_logic;
	TRIGGER_1_BIT_SAMPLE_CLK_4: in std_logic;

	-- 2-bit Triggers
	TRIGGER_2_BIT_1: in std_logic_vector(1 downto 0);
	TRIGGER_2_BIT_SAMPLE_CLK_1: in std_logic;
	TRIGGER_2_BIT_2: in std_logic_vector(1 downto 0);
	TRIGGER_2_BIT_SAMPLE_CLK_2: in std_logic;
	TRIGGER_2_BIT_3: in std_logic_vector(1 downto 0);
	TRIGGER_2_BIT_SAMPLE_CLK_3: in std_logic;
	TRIGGER_2_BIT_4: in std_logic_vector(1 downto 0);
	TRIGGER_2_BIT_SAMPLE_CLK_4: in std_logic;

	-- 4-bit Triggers
	TRIGGER_4_BIT_1: in std_logic_vector(3 downto 0);
	TRIGGER_4_BIT_SAMPLE_CLK_1: in std_logic;
	TRIGGER_4_BIT_2: in std_logic_vector(3 downto 0);
	TRIGGER_4_BIT_SAMPLE_CLK_2: in std_logic;
	TRIGGER_4_BIT_3: in std_logic_vector(3 downto 0);
	TRIGGER_4_BIT_SAMPLE_CLK_3: in std_logic;
	TRIGGER_4_BIT_4: in std_logic_vector(3 downto 0);
	TRIGGER_4_BIT_SAMPLE_CLK_4: in std_logic;

	-- 8-bit Triggers
	TRIGGER_8_BIT_1: in std_logic_vector(7 downto 0);
	TRIGGER_8_BIT_SAMPLE_CLK_1: in std_logic;
	TRIGGER_8_BIT_2: in std_logic_vector(7 downto 0);
	TRIGGER_8_BIT_SAMPLE_CLK_2: in std_logic;
	TRIGGER_8_BIT_3: in std_logic_vector(7 downto 0);
	TRIGGER_8_BIT_SAMPLE_CLK_3: in std_logic;
	TRIGGER_8_BIT_4: in std_logic_vector(7 downto 0);
	TRIGGER_8_BIT_SAMPLE_CLK_4: in std_logic;

	-- 16-bit Triggers
	TRIGGER_16_BIT_1: in std_logic_vector(15 downto 0);
	TRIGGER_16_BIT_SAMPLE_CLK_1: in std_logic;
	TRIGGER_16_BIT_2: in std_logic_vector(15 downto 0);
	TRIGGER_16_BIT_SAMPLE_CLK_2: in std_logic;
	TRIGGER_16_BIT_3: in std_logic_vector(15 downto 0);
	TRIGGER_16_BIT_SAMPLE_CLK_3: in std_logic;
	TRIGGER_16_BIT_4: in std_logic_vector(15 downto 0);
	TRIGGER_16_BIT_SAMPLE_CLK_4: in std_logic;
	-- Add triggers as necessary (up to 127 trigger signals total)


	-- Output registers
	REG250: out std_logic_vector(7 downto 0);
	REG251: out std_logic_vector(7 downto 0);


	-- Other input signals
	TRIGGER_REARM_TOGGLE: in std_logic;
	FORCE_TRIGGER_TOGGLE: in std_logic;
	REG250_READ: in std_logic;
	START_CAPTURE_TOGGLE: in std_logic
);
end entity;

architecture behavioral of COMSCOPE is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------

component CAPTURE_1_BIT_WORDS port (
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
end component;


component CAPTURE_2_BIT_WORDS port (
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
	WORD_2_BIT_IN: in std_logic_vector(1 downto 0);
		-- Input signal to be captured.
	WORD_CLK_IN: in std_logic;
		-- WORD_2_BIT_IN will be read whenever WORD_CLK_IN = '1'.
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
end component;


component CAPTURE_4_BIT_WORDS port (
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
	WORD_4_BIT_IN: in std_logic_vector(3 downto 0);
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
end component;


component CAPTURE_8_BIT_WORDS port (
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
end component;


component CAPTURE_16_BIT_WORDS port (
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
	WORD_16_BIT_IN: in std_logic_vector(15 downto 0);
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
end component;

--------------------------------------------------------
--     SIGNALS
--------------------------------------------------------


--// Constants
signal ZERO: std_logic;
signal ONE: std_logic;
signal ZERO8: std_logic_vector(7 downto 0);


signal NEXT_WORD_PLEASE: std_logic;
signal TRIGGER_A: std_logic;
signal TRIGGER_B: std_logic;
signal TRIGGER: std_logic;
signal TRIGGER_REARM_TOGGLE_D: std_logic:= '0';
signal TRIGGER_REARM_TOGGLE_D2: std_logic:= '0';
signal TRIGGER_REARM: std_logic;
signal FORCE_TRIGGER_TOGGLE_D: std_logic:= '0';
signal FORCE_TRIGGER_TOGGLE_D2: std_logic:= '0';
signal REG250_READ_D: std_logic;
signal REG250_READ_D2: std_logic;
signal START_CAPTURE_TOGGLE_D: std_logic:= '0';
signal START_CAPTURE_TOGGLE_D2: std_logic:= '0';
signal START_CAPTURE: std_logic;


--// Trace 1-4 multiplexed input signals
signal SELECTED_SIGNAL_1: std_logic_vector(15 downto 0);
signal SELECTED_SIGNAL_SAMPLE_CLK_1: std_logic;
signal SELECTED_SIGNAL_2: std_logic_vector(15 downto 0);
signal SELECTED_SIGNAL_SAMPLE_CLK_2: std_logic;
signal SELECTED_SIGNAL_3: std_logic_vector(15 downto 0);
signal SELECTED_SIGNAL_SAMPLE_CLK_3: std_logic;
signal SELECTED_SIGNAL_4: std_logic_vector(15 downto 0);
signal SELECTED_SIGNAL_SAMPLE_CLK_4: std_logic;


--// Selected trigger signal
signal SELECTED_TRIGGER: std_logic_vector(15 downto 0);
signal SELECTED_TRIGGER_SAMPLE_CLK: std_logic;

-- Tigger threshold
signal TRIGGER_THRESHOLD: std_logic_vector(15 downto 0);

-- Captured signals for traces 1-4
signal CAPTURED_1_BIT_SIGNAL_1: std_logic_vector(7 downto 0);
signal CAPTURED_2_BIT_SIGNAL_1: std_logic_vector(7 downto 0);
signal CAPTURED_4_BIT_SIGNAL_1: std_logic_vector(7 downto 0);
signal CAPTURED_8_BIT_SIGNAL_1: std_logic_vector(7 downto 0);
signal CAPTURED_16_BIT_SIGNAL_1: std_logic_vector(7 downto 0);
signal CAPTURED_1_BIT_SIGNAL_2: std_logic_vector(7 downto 0);
signal CAPTURED_2_BIT_SIGNAL_2: std_logic_vector(7 downto 0);
signal CAPTURED_4_BIT_SIGNAL_2: std_logic_vector(7 downto 0);
signal CAPTURED_8_BIT_SIGNAL_2: std_logic_vector(7 downto 0);
signal CAPTURED_16_BIT_SIGNAL_2: std_logic_vector(7 downto 0);
signal CAPTURED_1_BIT_SIGNAL_3: std_logic_vector(7 downto 0);
signal CAPTURED_2_BIT_SIGNAL_3: std_logic_vector(7 downto 0);
signal CAPTURED_4_BIT_SIGNAL_3: std_logic_vector(7 downto 0);
signal CAPTURED_8_BIT_SIGNAL_3: std_logic_vector(7 downto 0);
signal CAPTURED_16_BIT_SIGNAL_3: std_logic_vector(7 downto 0);
signal CAPTURED_1_BIT_SIGNAL_4: std_logic_vector(7 downto 0);
signal CAPTURED_2_BIT_SIGNAL_4: std_logic_vector(7 downto 0);
signal CAPTURED_4_BIT_SIGNAL_4: std_logic_vector(7 downto 0);
signal CAPTURED_8_BIT_SIGNAL_4: std_logic_vector(7 downto 0);
signal CAPTURED_16_BIT_SIGNAL_4: std_logic_vector(7 downto 0);


-- Selected captured signals for traces 1-4 
signal SELECTED_CAPTURED_SIGNAL_1: std_logic_vector(7 downto 0);
signal SELECTED_CAPTURED_SIGNAL_2: std_logic_vector(7 downto 0);
signal SELECTED_CAPTURED_SIGNAL_3: std_logic_vector(7 downto 0);
signal SELECTED_CAPTURED_SIGNAL_4: std_logic_vector(7 downto 0);


-- States for traces 1-4
signal STATE_1_BIT_SIGNAL_1: std_logic_vector(1 downto 0);
signal STATE_2_BIT_SIGNAL_1: std_logic_vector(1 downto 0);
signal STATE_4_BIT_SIGNAL_1: std_logic_vector(1 downto 0);
signal STATE_8_BIT_SIGNAL_1: std_logic_vector(1 downto 0);
signal STATE_16_BIT_SIGNAL_1: std_logic_vector(1 downto 0);
signal STATE_1_BIT_SIGNAL_2: std_logic_vector(1 downto 0);
signal STATE_2_BIT_SIGNAL_2: std_logic_vector(1 downto 0);
signal STATE_4_BIT_SIGNAL_2: std_logic_vector(1 downto 0);
signal STATE_8_BIT_SIGNAL_2: std_logic_vector(1 downto 0);
signal STATE_16_BIT_SIGNAL_2: std_logic_vector(1 downto 0);
signal STATE_1_BIT_SIGNAL_3: std_logic_vector(1 downto 0);
signal STATE_2_BIT_SIGNAL_3: std_logic_vector(1 downto 0);
signal STATE_4_BIT_SIGNAL_3: std_logic_vector(1 downto 0);
signal STATE_8_BIT_SIGNAL_3: std_logic_vector(1 downto 0);
signal STATE_16_BIT_SIGNAL_3: std_logic_vector(1 downto 0);
signal STATE_1_BIT_SIGNAL_4: std_logic_vector(1 downto 0);
signal STATE_2_BIT_SIGNAL_4: std_logic_vector(1 downto 0);
signal STATE_4_BIT_SIGNAL_4: std_logic_vector(1 downto 0);
signal STATE_8_BIT_SIGNAL_4: std_logic_vector(1 downto 0);
signal STATE_16_BIT_SIGNAL_4: std_logic_vector(1 downto 0);


-- Seleced states for traces 1-4
signal SELECTED_STATE_1: std_logic_vector(1 downto 0);
signal SELECTED_STATE_2: std_logic_vector(1 downto 0);
signal SELECTED_STATE_3: std_logic_vector(1 downto 0);
signal SELECTED_STATE_4: std_logic_vector(1 downto 0);

-- State Machine Variables
type THRESHOLD_STATETYPE is (ONE_BIT_THRESHOLD, TWO_BIT_THRESHOLD, 
			FOUR_BIT_THRESHOLD, EIGHT_BIT_THRESHOLD, SIXTEEN_BIT_THRESHOLD);
signal THRESHOLD_SIZE: THRESHOLD_STATETYPE;


-- Trigger signal MSb and trigger threshold MSb
signal TRIGGER_SIGNAL_MSb: std_logic;
signal TRIGGER_THRESHOLD_MSb: std_logic;
signal COMPARISON_RESULT_USIGNED: std_logic;
signal COMPARISON_RESULT_SIGNED: std_logic;
signal COMPARISON_RESULT: std_logic;
signal COMPARISON_RESULT_D: std_logic;
signal EQUAL: std_logic;
signal EQUAL_D: std_logic;

--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------

begin


--// COMSCOPE SOURCE CODE -----------
ZERO <= '0';
ONE <= '1';
ZERO8 <= (others => '0');


-- Trace 1 input signal multiplexing
INPUT_MUX_TRACE1_001: process(ASYNC_RESET, CLK, REG240)
begin
	if(ASYNC_RESET = '1') then
		SELECTED_SIGNAL_1 <= (others => '0');
		SELECTED_SIGNAL_SAMPLE_CLK_1 <= '0';
		SELECTED_CAPTURED_SIGNAL_1 <= (others => '0'); 
		SELECTED_STATE_1 <= "00";
	elsif rising_edge(CLK) then

		case REG240(6 downto 0) is
		-- Select one among the different signals to capture for trace 1
			when "0000001" => SELECTED_SIGNAL_1(7 downto 0) <= SIGNAL_8_BIT_1_1(7 downto 0);
									SELECTED_SIGNAL_1(15 downto 8) <= (others => '0');
									SELECTED_SIGNAL_SAMPLE_CLK_1 <= SIGNAL_8_BIT_SAMPLE_CLK_1_1;
									SELECTED_CAPTURED_SIGNAL_1 <= CAPTURED_8_BIT_SIGNAL_1;
									SELECTED_STATE_1 <= STATE_8_BIT_SIGNAL_1;
			when "0000010" => SELECTED_SIGNAL_1(7 downto 0) <= SIGNAL_8_BIT_1_2(7 downto 0);
									SELECTED_SIGNAL_1(15 downto 8) <= (others => '0');
									SELECTED_SIGNAL_SAMPLE_CLK_1 <= SIGNAL_8_BIT_SAMPLE_CLK_1_2;
									SELECTED_CAPTURED_SIGNAL_1 <= CAPTURED_8_BIT_SIGNAL_1;
									SELECTED_STATE_1 <= STATE_8_BIT_SIGNAL_1;
			when "0000011" => SELECTED_SIGNAL_1(7 downto 0) <= SIGNAL_8_BIT_1_3(7 downto 0);
									SELECTED_SIGNAL_1(15 downto 8) <= (others => '0');
									SELECTED_SIGNAL_SAMPLE_CLK_1 <= SIGNAL_8_BIT_SAMPLE_CLK_1_3;
									SELECTED_CAPTURED_SIGNAL_1 <= CAPTURED_8_BIT_SIGNAL_1;
									SELECTED_STATE_1 <= STATE_8_BIT_SIGNAL_1;
			when "0000100" => SELECTED_SIGNAL_1(7 downto 0) <= SIGNAL_8_BIT_1_4(7 downto 0);
									SELECTED_SIGNAL_1(15 downto 8) <= (others => '0');
									SELECTED_SIGNAL_SAMPLE_CLK_1 <= SIGNAL_8_BIT_SAMPLE_CLK_1_4;
									SELECTED_CAPTURED_SIGNAL_1 <= CAPTURED_8_BIT_SIGNAL_1;
									SELECTED_STATE_1 <= STATE_8_BIT_SIGNAL_1;
			when others	 	=> SELECTED_SIGNAL_1 <= (others => '0');
									SELECTED_SIGNAL_SAMPLE_CLK_1 <= '0';
									SELECTED_CAPTURED_SIGNAL_1 <= (others => '0'); 
									SELECTED_STATE_1 <= "00";
		end case;
	end if;
end process;


-- Trace 2 input signal multiplexing
INPUT_MUX_TRACE2_001: process(ASYNC_RESET, CLK, REG242)
begin
	if(ASYNC_RESET = '1') then
		SELECTED_SIGNAL_2 <= (others => '0');
		SELECTED_SIGNAL_SAMPLE_CLK_2 <= '0';
		SELECTED_CAPTURED_SIGNAL_2 <= (others => '0'); 
		SELECTED_STATE_2 <= "00";
	elsif rising_edge(CLK) then
		-- Select one among the different signals to capture for trace 2
		if(REG242(6 downto 0) = "0000001") then
			SELECTED_SIGNAL_2(7 downto 0) <= SIGNAL_8_BIT_2_1;
			SELECTED_SIGNAL_2(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_2 <= SIGNAL_8_BIT_SAMPLE_CLK_2_1;
			SELECTED_CAPTURED_SIGNAL_2 <= CAPTURED_8_BIT_SIGNAL_2;
			SELECTED_STATE_2 <= STATE_8_BIT_SIGNAL_2;
		elsif(REG242(6 downto 0) = "0000010") then
			SELECTED_SIGNAL_2(7 downto 0) <= SIGNAL_8_BIT_2_2;
			SELECTED_SIGNAL_2(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_2 <= SIGNAL_8_BIT_SAMPLE_CLK_2_2;
			SELECTED_CAPTURED_SIGNAL_2 <= CAPTURED_8_BIT_SIGNAL_2;
			SELECTED_STATE_2 <= STATE_8_BIT_SIGNAL_2;
		elsif(REG242(6 downto 0) = "0000011") then
			SELECTED_SIGNAL_2(7 downto 0) <= SIGNAL_8_BIT_2_3;
			SELECTED_SIGNAL_2(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_2 <= SIGNAL_8_BIT_SAMPLE_CLK_2_3;
			SELECTED_CAPTURED_SIGNAL_2 <= CAPTURED_8_BIT_SIGNAL_2;
			SELECTED_STATE_2 <= STATE_8_BIT_SIGNAL_2;
		elsif(REG242(6 downto 0) = "0000100") then
			SELECTED_SIGNAL_2(7 downto 0) <= SIGNAL_8_BIT_2_4;
			SELECTED_SIGNAL_2(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_2 <= SIGNAL_8_BIT_SAMPLE_CLK_2_4;
			SELECTED_CAPTURED_SIGNAL_2 <= CAPTURED_8_BIT_SIGNAL_2;
			SELECTED_STATE_2 <= STATE_8_BIT_SIGNAL_2;
	  	else
			SELECTED_SIGNAL_2 <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_2 <= '0';
			SELECTED_CAPTURED_SIGNAL_2 <= (others => '0'); 
			SELECTED_STATE_2 <= "00";
		end if;
	end if;
end process;


-- Trace 3 input signal multiplexing
INPUT_MUX_TRACE3_001: process(ASYNC_RESET, CLK, REG244)
begin
	if(ASYNC_RESET = '1') then
		SELECTED_SIGNAL_3 <= (others => '0');
		SELECTED_SIGNAL_SAMPLE_CLK_3 <= '0';
		SELECTED_CAPTURED_SIGNAL_3 <= (others => '0'); 
		SELECTED_STATE_3 <= "00";
	elsif rising_edge(CLK) then
		-- Select one among the different signals to capture for trace 2
		if(REG244(6 downto 0) = "0000001") then
			SELECTED_SIGNAL_3(7 downto 0) <= SIGNAL_8_BIT_3_1;
			SELECTED_SIGNAL_3(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_3 <= SIGNAL_8_BIT_SAMPLE_CLK_3_1;
			SELECTED_CAPTURED_SIGNAL_3 <= CAPTURED_8_BIT_SIGNAL_3;
			SELECTED_STATE_3 <= STATE_8_BIT_SIGNAL_3;
		elsif(REG244(6 downto 0) = "0000010") then
			SELECTED_SIGNAL_3(7 downto 0) <= SIGNAL_8_BIT_3_2;
			SELECTED_SIGNAL_3(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_3 <= SIGNAL_8_BIT_SAMPLE_CLK_3_2;
			SELECTED_CAPTURED_SIGNAL_3 <= CAPTURED_8_BIT_SIGNAL_3;
			SELECTED_STATE_3 <= STATE_8_BIT_SIGNAL_3;
		elsif(REG244(6 downto 0) = "0000011") then
			SELECTED_SIGNAL_3(7 downto 0) <= SIGNAL_8_BIT_3_3;
			SELECTED_SIGNAL_3(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_3 <= SIGNAL_8_BIT_SAMPLE_CLK_3_3;
			SELECTED_CAPTURED_SIGNAL_3 <= CAPTURED_8_BIT_SIGNAL_3;
			SELECTED_STATE_3 <= STATE_8_BIT_SIGNAL_3;
		elsif(REG244(6 downto 0) = "0000100") then
			SELECTED_SIGNAL_3(7 downto 0) <= SIGNAL_8_BIT_3_4;
			SELECTED_SIGNAL_3(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_3 <= SIGNAL_8_BIT_SAMPLE_CLK_3_4;
			SELECTED_CAPTURED_SIGNAL_3 <= CAPTURED_8_BIT_SIGNAL_3;
			SELECTED_STATE_3 <= STATE_8_BIT_SIGNAL_3;
	  	else
			SELECTED_SIGNAL_3 <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_3 <= '0';
			SELECTED_CAPTURED_SIGNAL_3 <= (others => '0'); 
			SELECTED_STATE_3 <= "00";
		end if;
	end if;
end process;

-- Trace 4 input signal multiplexing
INPUT_MUX_TRACE4_001: process(ASYNC_RESET, CLK, REG246)
begin
	if(ASYNC_RESET = '1') then
		SELECTED_SIGNAL_4 <= (others => '0');
		SELECTED_SIGNAL_SAMPLE_CLK_4 <= '0';
		SELECTED_CAPTURED_SIGNAL_4 <= (others => '0'); 
		SELECTED_STATE_4 <= "00";
	elsif rising_edge(CLK) then
		-- Select one among the different signals to capture for trace 2
		if(REG246(6 downto 0) = "0000001") then
			SELECTED_SIGNAL_4(7 downto 0) <= SIGNAL_8_BIT_4_1;
			SELECTED_SIGNAL_4(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_4 <= SIGNAL_8_BIT_SAMPLE_CLK_4_1;
			SELECTED_CAPTURED_SIGNAL_4 <= CAPTURED_8_BIT_SIGNAL_4;
			SELECTED_STATE_4 <= STATE_8_BIT_SIGNAL_4;
		elsif(REG246(6 downto 0) = "0000010") then
			SELECTED_SIGNAL_4(7 downto 0) <= SIGNAL_8_BIT_4_2;
			SELECTED_SIGNAL_4(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_4 <= SIGNAL_8_BIT_SAMPLE_CLK_4_2;
			SELECTED_CAPTURED_SIGNAL_4 <= CAPTURED_8_BIT_SIGNAL_4;
			SELECTED_STATE_4 <= STATE_8_BIT_SIGNAL_4;
		elsif(REG246(6 downto 0) = "0000011") then
			SELECTED_SIGNAL_4(7 downto 0) <= SIGNAL_8_BIT_4_3;
			SELECTED_SIGNAL_4(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_4 <= SIGNAL_8_BIT_SAMPLE_CLK_4_3;
			SELECTED_CAPTURED_SIGNAL_4 <= CAPTURED_8_BIT_SIGNAL_4;
			SELECTED_STATE_4 <= STATE_8_BIT_SIGNAL_4;
		elsif(REG246(6 downto 0) = "0000100") then
			SELECTED_SIGNAL_4(7 downto 0) <= SIGNAL_8_BIT_4_4;
			SELECTED_SIGNAL_4(15 downto 8) <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_4 <= SIGNAL_8_BIT_SAMPLE_CLK_4_4;
			SELECTED_CAPTURED_SIGNAL_4 <= CAPTURED_8_BIT_SIGNAL_4;
			SELECTED_STATE_4 <= STATE_8_BIT_SIGNAL_4;
	  	else
			SELECTED_SIGNAL_4 <= (others => '0');
			SELECTED_SIGNAL_SAMPLE_CLK_4 <= '0';
			SELECTED_CAPTURED_SIGNAL_4 <= (others => '0'); 
			SELECTED_STATE_4 <= "00";
		end if;
	end if;
end process;


-- Input multiplexer, trigger signals
INPUT_MUX_TRIGGER_001: process(ASYNC_RESET, CLK, REG248)
begin
	if(ASYNC_RESET = '1') then
		SELECTED_TRIGGER <= (others => '0');
		SELECTED_TRIGGER_SAMPLE_CLK <= '0';
		TRIGGER_THRESHOLD <= (others => '0');
	elsif rising_edge(CLK) then
		-- Select one among the different 16-bit signals to trigger on
		case REG248(6 downto 0) is
			when "0000001" => SELECTED_TRIGGER(0) <= TRIGGER_1_BIT_1;
									SELECTED_TRIGGER(15 downto 1) <= (others => '0');
									SELECTED_TRIGGER_SAMPLE_CLK <= TRIGGER_1_BIT_SAMPLE_CLK_1;
									TRIGGER_THRESHOLD(0) <= REG249(0);
									TRIGGER_THRESHOLD(15 downto 1) <= (others => '0');
									THRESHOLD_SIZE <= ONE_BIT_THRESHOLD;
			when "0000010" => SELECTED_TRIGGER(0) <= TRIGGER_1_BIT_2;
									SELECTED_TRIGGER(15 downto 1) <= (others => '0');
									SELECTED_TRIGGER_SAMPLE_CLK <= TRIGGER_1_BIT_SAMPLE_CLK_2;
									TRIGGER_THRESHOLD(0) <= REG249(0);
									TRIGGER_THRESHOLD(15 downto 1) <= (others => '0');
									THRESHOLD_SIZE <= ONE_BIT_THRESHOLD;
			when others => 	SELECTED_TRIGGER <= (others => '0');
									SELECTED_TRIGGER_SAMPLE_CLK <= '0';
									TRIGGER_THRESHOLD <= (others => '0');
		end case;
	end if;
end process;

TRIGGER_SIGNAL_MSb <= '0' when SIGNED_REPRESENTATION_U_SIGNED_N = '0' else
		SELECTED_TRIGGER(0); --when (THRESHOLD_SIZE = ONE_BIT_THRESHOLD) else
--		SELECTED_TRIGGER(1) when (THRESHOLD_SIZE = TWO_BIT_THRESHOLD) else
--		SELECTED_TRIGGER(3) when (THRESHOLD_SIZE = FOUR_BIT_THRESHOLD) else
--		SELECTED_TRIGGER(7) when (THRESHOLD_SIZE = EIGHT_BIT_THRESHOLD) else
--		SELECTED_TRIGGER(15); -- (THRESHOLD_SIZE = SIXTEEN_BIT_THRESHOLD)

TRIGGER_THRESHOLD_MSb <= '0' when SIGNED_REPRESENTATION_U_SIGNED_N = '0' else
		TRIGGER_THRESHOLD(0) when (THRESHOLD_SIZE = ONE_BIT_THRESHOLD) else
		TRIGGER_THRESHOLD(1) when (THRESHOLD_SIZE = TWO_BIT_THRESHOLD) else
		TRIGGER_THRESHOLD(3) when (THRESHOLD_SIZE = FOUR_BIT_THRESHOLD) else
		TRIGGER_THRESHOLD(7) when (THRESHOLD_SIZE = EIGHT_BIT_THRESHOLD) else
		TRIGGER_THRESHOLD(15); -- (THRESHOLD_SIZE = SIXTEEN_BIT_THRESHOLD)

RESAMPLE_001: process(ASYNC_RESET, CLK, TRIGGER_REARM_TOGGLE, FORCE_TRIGGER_TOGGLE,
								START_CAPTURE_TOGGLE, REG250_READ)
begin
	if(ASYNC_RESET = '1') then
		TRIGGER_REARM_TOGGLE_D <= '0';
		TRIGGER_REARM_TOGGLE_D2 <= '0';
		FORCE_TRIGGER_TOGGLE_D <= '0';
		FORCE_TRIGGER_TOGGLE_D2 <= '0';
		START_CAPTURE_TOGGLE_D <= '0';
		START_CAPTURE_TOGGLE_D2 <= '0';
		REG250_READ_D <= '0';
		REG250_READ_D2 <= '0';
	elsif rising_edge(CLK) then
		TRIGGER_REARM_TOGGLE_D <= TRIGGER_REARM_TOGGLE;
		TRIGGER_REARM_TOGGLE_D2 <= TRIGGER_REARM_TOGGLE_D;
		FORCE_TRIGGER_TOGGLE_D <= FORCE_TRIGGER_TOGGLE;
		FORCE_TRIGGER_TOGGLE_D2 <= FORCE_TRIGGER_TOGGLE_D;
		START_CAPTURE_TOGGLE_D <= START_CAPTURE_TOGGLE;
		START_CAPTURE_TOGGLE_D2 <= START_CAPTURE_TOGGLE_D;
		REG250_READ_D <= REG250_READ;
		REG250_READ_D2 <= REG250_READ_D;
	end if;
end process;


TRIGGER_REARM <= '1' when (TRIGGER_REARM_TOGGLE_D /= TRIGGER_REARM_TOGGLE_D2) else '0';

START_CAPTURE <= '1' when (START_CAPTURE_TOGGLE_D /= START_CAPTURE_TOGGLE_D2) else '0';

NEXT_WORD_PLEASE <= '1' when (REG250_READ_D = '0' and REG250_READ_D2 = '1') else '0';


-- Compare the selected trigger signal with the trigger threshold.
COMPARISON_RESULT_USIGNED <= '1' when (SELECTED_TRIGGER > TRIGGER_THRESHOLD) else '0';

EQUAL <= '1' when (SELECTED_TRIGGER = TRIGGER_THRESHOLD) else '0';

-- more complex but faster?
COMPARISON_RESULT_SIGNED <= '1' when (SELECTED_TRIGGER > TRIGGER_THRESHOLD) and 
	(TRIGGER_SIGNAL_MSb = TRIGGER_THRESHOLD_MSb) else
	'1' when (TRIGGER_SIGNAL_MSb = '0') and (TRIGGER_THRESHOLD_MSb = '1') else '0';

-- AZ trying to optimize timing
--COMPARISON_RESULT_SIGNED <= 
--		COMPARISON_RESULT_USIGNED when TRIGGER_SIGNAL_MSb = TRIGGER_THRESHOLD_MSb else
--		'1' when (TRIGGER_SIGNAL_MSb = '0') and (TRIGGER_THRESHOLD_MSb = '1') else '0';


COMPARISON_RESULT <= COMPARISON_RESULT_SIGNED when SIGNED_REPRESENTATION_U_SIGNED_N = '1' else
							COMPARISON_RESULT_USIGNED;


-- Trigger conditioning
-- Make it fully independent of trace settings / states, as the 
-- trigger signal is shared among several traces.
-- Threshold is unsigned.
-- AZ trying to optimize timing
TRIGGER_A <= '1' when (FORCE_TRIGGER_TOGGLE_D /= FORCE_TRIGGER_TOGGLE_D2) else '0';

TRIGGER_B <= SELECTED_TRIGGER_SAMPLE_CLK  
				when (REG248(7) = '1' and (COMPARISON_RESULT = '1' or EQUAL = '1') and 
		  							 	 				COMPARISON_RESULT_D = '0' and EQUAL_D = '0') 
				or (REG248(7) = '0' and (COMPARISON_RESULT = '0' or EQUAL = '1') and 
										   			COMPARISON_RESULT_D = '1' and EQUAL_D = '0') 
				else '0';

TRIGGER <= TRIGGER_A or TRIGGER_B;	-- force trigger or automatic trigger

--TRIGGER <= '1' when (FORCE_TRIGGER_TOGGLE_D /= FORCE_TRIGGER_TOGGLE_D2) else 
--			  '0' when (SELECTED_TRIGGER_SAMPLE_CLK = '0') else 
--			  '1' when (REG248(7) = '1' and (COMPARISON_RESULT = '1' or EQUAL = '1') and 
--		  							 	 				COMPARISON_RESULT_D = '0' and EQUAL_D = '0') else
--			  '1' when (REG248(7) = '0' and (COMPARISON_RESULT = '0' or EQUAL = '1') and 
--										   			COMPARISON_RESULT_D = '1' and EQUAL_D = '0') else '0';


CONDITIONAL_RESAMPLING_001: process(ASYNC_RESET, CLK, SELECTED_TRIGGER_SAMPLE_CLK, 
												COMPARISON_RESULT, EQUAL)
begin
	if(ASYNC_RESET = '1') then
		COMPARISON_RESULT_D <= '0';
		EQUAL_D <= '0';
	elsif rising_edge(CLK) then
		if (SELECTED_TRIGGER_SAMPLE_CLK = '1') then
			-- remember last comparison result (to detect rising/falling edge)
			COMPARISON_RESULT_D <= COMPARISON_RESULT;
			EQUAL_D <= EQUAL;
		end if;
	end if;
end process;


-- Address 0    - 511  -> Trace 1
-- Address 512  - 1023 -> Trace 2
-- Address 1024 - 1535 -> Trace 3
-- Address 1536 - 2047 -> Trace 4
REG250 <= SELECTED_CAPTURED_SIGNAL_1 when REG238(2 downto 1) = "00" else  
			 SELECTED_CAPTURED_SIGNAL_2 when REG238(2 downto 1) = "01" else  
			 SELECTED_CAPTURED_SIGNAL_3 when REG238(2 downto 1) = "10" else  
			 SELECTED_CAPTURED_SIGNAL_4;  


-- Bit 0: 	0: No capture in progress
--				1: At least one trace is capturing
-- Bit 1: 	0: Trigger not found
--				1: Trigger found (reset upon resuming capture)
-- Bit 2: 	Start capture toggle
-- Bit 3: 	Trigger re-arm toggle
MONITORING_001: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		REG251 <= (others => '0');
	elsif rising_edge(CLK) then
		if (SELECTED_STATE_1 = "00") and (SELECTED_STATE_2 = "00") and
			(SELECTED_STATE_3 = "00") and (SELECTED_STATE_4 = "00") then
			REG251(0) <= '0';
		else 
			REG251(0) <= '1';
		end if;
		if (START_CAPTURE = '1') then
			REG251(1) <= '0';
		elsif((SELECTED_STATE_1 = "10") or (SELECTED_STATE_2 = "10") or
				(SELECTED_STATE_3 = "10") or (SELECTED_STATE_4 = "10")) and 
				(TRIGGER = '1') then
			REG251(1) <= '1';
		end if;
		REG251(2) <= START_CAPTURE_TOGGLE;
		REG251(3) <= TRIGGER_REARM_TOGGLE;
	end if;
end process;


--------------------------------------------------------------------------
-- COMPONENT INSTANTIATIONS
--------------------------------------------------------------------------


-- Instantiate 1-bit capture component for trace 1
-- Instantiate 2-bit capture component for trace 1
-- Instantiate 4-bit capture component for trace 1
-- Instantiate 8-bit capture component for trace 1
TRACE_1_CAPTURE_8_BIT_WORDS_001: CAPTURE_8_BIT_WORDS port map(
   CLK=> CLK,
	ASYNC_RESET => ASYNC_RESET,
	DECIMATE_VALUE => REG241(4 downto 0),
	TRIGGER_POSITION => REG241(6 downto 5),
	WORD_8_BIT_IN => SELECTED_SIGNAL_1(7 downto 0),
	WORD_CLK_IN => SELECTED_SIGNAL_SAMPLE_CLK_1,
	NEXT_WORD_PLEASE => NEXT_WORD_PLEASE,
	TRIGGER => TRIGGER,
	TRIGGER_REARM => TRIGGER_REARM,
	START_CAPTURING => START_CAPTURE,
	WORD_8_BIT_OUT => CAPTURED_8_BIT_SIGNAL_1,
	STATE => STATE_8_BIT_SIGNAL_1
);
-- Instantiate 16-bit capture component for trace 1

-- Instantiate 1-bit capture component for trace 2
-- Instantiate 2-bit capture component for trace 2
-- Instantiate 4-bit capture component for trace 2
-- Instantiate 8-bit capture component for trace 2
-- Instantiate 8-bit capture component for trace 2
TRACE_2_CAPTURE_8_BIT_WORDS_001: CAPTURE_8_BIT_WORDS port map(
   CLK=> CLK,
	ASYNC_RESET => ASYNC_RESET,
	DECIMATE_VALUE => REG243(4 downto 0),
	TRIGGER_POSITION => REG243(6 downto 5),
	WORD_8_BIT_IN => SELECTED_SIGNAL_2(7 downto 0),
	WORD_CLK_IN => SELECTED_SIGNAL_SAMPLE_CLK_2,
	NEXT_WORD_PLEASE => NEXT_WORD_PLEASE,
	TRIGGER => TRIGGER,
	TRIGGER_REARM => TRIGGER_REARM,
	START_CAPTURING => START_CAPTURE,
	WORD_8_BIT_OUT => CAPTURED_8_BIT_SIGNAL_2,
	STATE => STATE_8_BIT_SIGNAL_2
);
-- Instantiate 16-bit capture component for trace 2

-- Instantiate 1-bit capture component for trace 3
-- Instantiate 2-bit capture component for trace 3
-- Instantiate 4-bit capture component for trace 3
-- Instantiate 8-bit capture component for trace 3
TRACE_3_CAPTURE_8_BIT_WORDS_001: CAPTURE_8_BIT_WORDS port map(
   CLK=> CLK,
	ASYNC_RESET => ASYNC_RESET,
	DECIMATE_VALUE => REG245(4 downto 0),
	TRIGGER_POSITION => REG245(6 downto 5),
	WORD_8_BIT_IN => SELECTED_SIGNAL_3(7 downto 0),
	WORD_CLK_IN => SELECTED_SIGNAL_SAMPLE_CLK_3,
	NEXT_WORD_PLEASE => NEXT_WORD_PLEASE,
	TRIGGER => TRIGGER,
	TRIGGER_REARM => TRIGGER_REARM,
	START_CAPTURING => START_CAPTURE,
	WORD_8_BIT_OUT => CAPTURED_8_BIT_SIGNAL_3,
	STATE => STATE_8_BIT_SIGNAL_3
);
-- Instantiate 16-bit capture component for trace 3


-- Instantiate 1-bit capture component for trace 4
-- Instantiate 2-bit capture component for trace 4
-- Instantiate 4-bit capture component for trace 4
-- Instantiate 8-bit capture component for trace 4
TRACE_4_CAPTURE_8_BIT_WORDS_001: CAPTURE_8_BIT_WORDS port map(
   CLK=> CLK,
	ASYNC_RESET => ASYNC_RESET,
	DECIMATE_VALUE => REG247(4 downto 0),
	TRIGGER_POSITION => REG247(6 downto 5),
	WORD_8_BIT_IN => SELECTED_SIGNAL_4(7 downto 0),
	WORD_CLK_IN => SELECTED_SIGNAL_SAMPLE_CLK_4,
	NEXT_WORD_PLEASE => NEXT_WORD_PLEASE,
	TRIGGER => TRIGGER,
	TRIGGER_REARM => TRIGGER_REARM,
	START_CAPTURING => START_CAPTURE,
	WORD_8_BIT_OUT => CAPTURED_8_BIT_SIGNAL_4,
	STATE => STATE_8_BIT_SIGNAL_4
);
-- Instantiate 16-bit capture component for trace 4

end behavioral;