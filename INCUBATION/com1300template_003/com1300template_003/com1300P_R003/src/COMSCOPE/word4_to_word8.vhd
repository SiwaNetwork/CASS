----------------------------------------------
-- MSS copyright 1999-2003
-- Filename: WORD4_TO_WORD8.VHD 
-- Primary project: ComBlocks
-- Authors: 
--		Bengt-Arne Bengtsson / MSS
--		
--
-- Edit date: See date of file in folder browser
-- Revision: 0.001
-- 
-- 4 bit word to 8 bit word word conversion. The first
-- incoming 8 bit word will be sent out as the MSB's of the 
-- WORD_OUT signal.
--
--
----------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity WORD4_TO_WORD8 is port ( 
	ASYNC_RESET: in std_logic;
		-- Asynchronous reset, active high
	CLK: in std_logic;
		-- Reference clock


	--// INPUTS 
	COMPONENT_RESET: in std_logic;
	WORD_IN: in std_logic_vector(3 downto 0);
		-- Word to be converted into a 8 bit word. Will be read when
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
end entity;


architecture BEHAVIOR of WORD4_TO_WORD8 is
-----------------------------------------------------------------
-- SIGNALS
-----------------------------------------------------------------
-- Suffix _D indicates a one CLK delayed version of the net with the same name
-- Suffix _E indicates an extended precision version of the net with the same name
-- Suffix _R indicates a reduced precision version of the net with the same name
-- Suffix _N indicates an inverted version of the net with the same name
-- Suffix _LOCAL indicates an exact version of the (output signal) net with the same name

signal WORD_OUT_BUFFER: std_logic_vector(3 downto 0);
signal WORD_COUNTER: std_logic;

-----------------------------------------------------------------
-- IMPLEMENTATION
-----------------------------------------------------------------
begin


PROCESS_INPUT_BITS_001: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		WORD_OUT <= (others => '0');
		WORD_OUT_CLK <= '0';
		WORD_OUT_BUFFER <= (others => '0');
		WORD_COUNTER <= '0';
	elsif rising_edge(CLK) then
		if (COMPONENT_RESET = '1') then
			WORD_OUT <= (others => '0');
			WORD_OUT_CLK <= '0';
			WORD_OUT_BUFFER <= (others => '0');
			WORD_COUNTER <= '0';
		else
	 		if (WORD_IN_CLK = '1') then
			-- A word is coming	
				WORD_COUNTER <= not WORD_COUNTER;		-- Counter will roll over; no need to reset
				if WORD_COUNTER = '1' then
					WORD_OUT(7 downto 4) <= WORD_OUT_BUFFER;
					WORD_OUT(3 downto 0) <= WORD_IN;
					WORD_OUT_CLK <= '1';
				else
					WORD_OUT_CLK <= '0';
					WORD_OUT_BUFFER <= WORD_IN;
				end if;
			else
				WORD_OUT_CLK <= '0';
			end if;
		end if;
  	end if;
end process;


end behavior;