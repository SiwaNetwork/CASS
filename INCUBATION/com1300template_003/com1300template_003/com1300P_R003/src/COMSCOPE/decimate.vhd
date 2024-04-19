-------------------------------------------------------------
--	Filename:  DECIMATE.VHD
-- Author: Alain Zarembowitch / MSS
--	Version: 2
--	Date last modified: 9-08-03
-- Inheritance: 	none
--
-- description: 
--
-- 
---------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DECIMATE is port ( 
	--GLOBAL CLOCKS
   CLK : in std_logic;				-- Master clock for this FPGA
	ASYNC_RESET: in std_logic;		-- Asynchronous reset active high

	-- Inputs
	DECIMATE_VALUE: in std_logic_vector(4 downto 0);
	SAMPLE_CLK_IN: in std_logic;

	-- Output
	DECIMATED_SAMPLE_CLK_OUT: out std_logic
);
end entity;

architecture behavioral of DECIMATE is

--------------------------------------------------------
--     SIGNALS
--------------------------------------------------------

signal DECIMATE_MASK1: std_logic_vector(31 downto 0);
signal DECIMATE_COUNTER1: std_logic_vector(31 downto 0);

--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------

begin


-- Decimate the sampling clock
DECIMATE_MUX_CLK1_001: process(ASYNC_RESET, CLK)
begin
	if(ASYNC_RESET = '1') then
		DECIMATE_COUNTER1 <= (others => '0');
	elsif rising_edge(CLK) then
		if(SAMPLE_CLK_IN = '1') then
			DECIMATE_COUNTER1 <= (DECIMATE_COUNTER1 + 1) and DECIMATE_MASK1;
		end if;
	end if;
end process;

-- Take sample when decimation counter is 0
DECIMATED_SAMPLE_CLK_OUT <= SAMPLE_CLK_IN when (DECIMATE_COUNTER1 = 0) else '0';

SELECT_DECIMATE1: process(DECIMATE_MASK1)
begin
	case DECIMATE_VALUE is
		when "00000" => DECIMATE_MASK1 <= x"00000000";
		when "00001" => DECIMATE_MASK1 <= x"00000001";
		when "00010" => DECIMATE_MASK1 <= x"00000003";
		when "00011" => DECIMATE_MASK1 <= x"00000007";
		when "00100" => DECIMATE_MASK1 <= x"0000000F";
		when "00101" => DECIMATE_MASK1 <= x"0000001F";
		when "00110" => DECIMATE_MASK1 <= x"0000003F";
		when "00111" => DECIMATE_MASK1 <= x"0000007F";
		when "01000" => DECIMATE_MASK1 <= x"000000FF";
		when "01001" => DECIMATE_MASK1 <= x"000001FF";
		when "01010" => DECIMATE_MASK1 <= x"000003FF";
		when "01011" => DECIMATE_MASK1 <= x"000007FF";
		when "01100" => DECIMATE_MASK1 <= x"00000FFF";
		when "01101" => DECIMATE_MASK1 <= x"00001FFF";
		when "01110" => DECIMATE_MASK1 <= x"00003FFF";
		when "01111" => DECIMATE_MASK1 <= x"00007FFF";
		when "10000" => DECIMATE_MASK1 <= x"0000FFFF";
		when "10001" => DECIMATE_MASK1 <= x"0001FFFF";
		when "10010" => DECIMATE_MASK1 <= x"0003FFFF";
		when "10011" => DECIMATE_MASK1 <= x"0007FFFF";
		when "10100" => DECIMATE_MASK1 <= x"000FFFFF";
		when "10101" => DECIMATE_MASK1 <= x"001FFFFF";
		when "10110" => DECIMATE_MASK1 <= x"003FFFFF";
		when "10111" => DECIMATE_MASK1 <= x"007FFFFF";
		when "11000" => DECIMATE_MASK1 <= x"00FFFFFF";
		when "11001" => DECIMATE_MASK1 <= x"01FFFFFF";
		when "11010" => DECIMATE_MASK1 <= x"03FFFFFF";
		when "11011" => DECIMATE_MASK1 <= x"07FFFFFF";
		when "11100" => DECIMATE_MASK1 <= x"0FFFFFFF";
		when "11101" => DECIMATE_MASK1 <= x"1FFFFFFF";
		when "11110" => DECIMATE_MASK1 <= x"3FFFFFFF";
		when others => DECIMATE_MASK1 <=  x"7FFFFFFF";
	end case;
end process;


end behavioral;