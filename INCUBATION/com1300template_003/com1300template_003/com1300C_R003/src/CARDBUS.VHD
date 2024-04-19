-------------------------------------------------------------
--	Filename:  CARDBUS.VHD
--   Authors: 
--		Adam Kwiatkowski  / MSS, Poornima Sarvadevabhatla
--	Version: Rev 0
-- Last modified: 05/23/05
-- Inheritance: 	PCMCIA.VHD Rev 1
--
-- Description:  CardBus interface. One side connects directly to the 
-- hardware, the other side to user-supplied streams via dual-port 
-- elastic buffers (one in each direction). Also inserts the CIS*
-- when asked. Use only when generating the Option C (CARDBUS) project.
-- Support for 8-bit I/O transfers and 32-bit memory transfers.
-- No interrupt or DMA support.
-- Support for three virtual streams:
--	  Configuration transfer are transferred by the CARDBUS HBA by means of 32-bit Configuration reads/writes
--		Addresses decoded: All. See Config_C.VHD component description for details.
--     IO transfers are transferred by the CARDBUS HBA by means of 8-bit I/O reads and writes 
--		Addresses decoded 0,4,8,12. See IORW_C.VHD component description for details.
--     Memory transfers are transferred by the CARDBUS HBA by means of 32-bit Memory reads and writes 
--		Addresses decoded 0,4,8,12. See MEMORY_C.VHD component description for details.
--
-- Added BAR's decode
-- Without violating the concept of abstraction, the intent is to use Stream1 
-- KEY ASSUMPTION:
-- 1. CB_CARD_CIRDY_N is always asserted one clock after the assertion 
--  	 of CB_CARD_CFRAME_N regardless of the transaction type.
-- 2. Decoded addresses are always valid.
---------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CARDBUS is
    port ( 

    	--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All VHDL user application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		ASYNC_RESET: in std_logic;
			-- asynchronous reset at power up. MANDATORY.

    	--// Host bus adapter interface:
	   	CB_CARD_ADDR_DATA: inout std_logic_vector(31 downto 0);
	     	-- Address and Data

		--// Command
		CB_CARD_CC_BE_N: in std_logic_vector(3 downto 0);
			-- CardBus command (defines transaction type) or Byte Enable,

		--// System
		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz. Global clock.
		CB_CARD_CCLKRUN_N: inout std_logic;
			-- Asserted if clock runs normally
			-- deasserted before clock stops or slow down (I/O)
		CB_CARD_CRST_N: in std_logic;
			-- Reset signal 
			-- Forces CardBus configuration registers to an initialized state 

		--// Interface Control
		CB_CARD_CPAR: inout std_logic;
			-- Parity signal (I/O)
		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
		CB_CARD_CTRDY_N: out std_logic;
			-- Target ready
		CB_CARD_CIRDY_N: in std_logic;
			-- Initiator ready
		CB_CARD_CSTOP_N: out std_logic;
			-- Target wants to stop the transaction
		CB_CARD_CDEVSEL_N: out std_logic;
			-- Device select 
			-- Asserted by target upon successful decoding of the address and command
		CB_CARD_CBLOCK_N: in std_logic;
			-- Lock the currently addressed memory target

		--// Miscellaneous Signals
		CB_CARD_CAUDIO_N: out std_logic;
			-- Card audio output. Not used: FPGA to pull high.
		CB_CARD_CSTSCHG_N: out std_logic;
			-- STSCHG#     During memory or I/O interface

		--// Error Reporting
		CB_CARD_CPERR_N: out std_logic;
			-- Data parity error
		CB_CARD_CSERR_N: out std_logic;
			-- System error

		CB_CARD_CINT_N: out std_logic;
			-- Interrupt request

		--// Arbitration (Bus Master Only)
		CB_CARD_CGNT_N: in std_logic;
			-- Bus arbitration grant. Not used BUT must be 
			-- pulled high according to specs. 
			-- USE as input and PULL-UP
		CB_CARD_CREQ_N: in std_logic;
			-- Arbitration request. MUST BE DECLARED AND USED AS INPUT.
			-- (otherwise alternative assignement for pin N1 conflicts
			-- with proper operation) !!!!!
  
		--// Stream1 32/8-bit Memory transactions
		-- Synchronous with CLK_P/CB_CARD_CCLK clocks
		DATA1_OUT: out std_logic_vector(7 downto 0);
		DATA1_OUT_SAMPLE_CLK: out std_logic;
			-- read DATA1_OUT at rising edge of CLK_P when DATA1_OUT_SAMPLE_CLK = '1'
			-- Note1: the user is responsible for checking DATA1_OUT_BUFFER_EMPTY before reading.
			-- Note 2: When the elastic buffer is not empty, DATA1_OUT is present 
			-- at this interface even before requesting it. The request DATA1_OUT_SAMPLE_CLK_REQ 
			-- only moves the read pointer to the next read location.
		DATA1_OUT_BUFFER_EMPTY: out std_logic;
		DATA1_OUT_SAMPLE_CLK_REQ: in std_logic;	
			-- requests data. If no data is available in the buffer, the
			-- DATA1_OUT_SAMPLE_CLK will stay low.
			-- (flow control)
		
		DATA1_IN: in std_logic_vector(7 downto 0);
		DATA1_IN_SAMPLE_CLK: in std_logic;
			-- read DATA1_IN at rising edge of CLK_P when DATA1_IN_SAMPLE_CLK = '1'
		DATA1_IN_SAMPLE_CLK_REQ: out std_logic;
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)

		--// Stream2. 8-bit I/O read/write transactions at I/O address 0
		-- Synchronous with CLK_P/CB_CARD_CCLK clocks
		DATA2_OUT: out std_logic_vector(7 downto 0);
		DATA2_OUT_SAMPLE_CLK: out std_logic;
			-- read DATA2_OUT at rising edge of CLK_P when DATA2_OUT_SAMPLE_CLK = '1'
			-- Note1: the user is responsible for checking DATA2_OUT_BUFFER_EMPTY before
			-- reading.
			-- Note 2: When the elastic buffer is not empty, DATA2_OUT is present 
			-- at this interface even before requesting it. The request DATA2_OUT_SAMPLE_CLK_REQ 
			-- only moves the read pointer to the next read location.
		DATA2_OUT_BUFFER_EMPTY: out std_logic;
		DATA2_OUT_SAMPLE_CLK_REQ: in std_logic;	
			-- requests data. If no data is available in the buffer, the
			-- DATA2_OUT_SAMPLE_CLK will stay low.
			-- (flow control)
		
		DATA2_IN: in std_logic_vector(7 downto 0);
		DATA2_IN_SAMPLE_CLK: in std_logic;
			-- read DATA2_IN at rising edge of CLK_P when DATA2_IN_SAMPLE_CLK = '1'
		DATA2_IN_SAMPLE_CLK_REQ: out std_logic;
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)

		--// Test Points
		REG0: in std_logic_vector(7 downto 0);
		REG1: in std_logic_vector(7 downto 0);

		DUMMY_OUTPUT: out std_logic;
			-- used to prevent the synthesis tool from optimizing
			-- the signals linked to this dummy output.
			-- (for example when we need to pull up an unused input signal)
		TEST_POINTS: out std_logic_vector(30 downto 1)

--		IO_BAR : out std_logic_vector(31 downto 0);	  --IO base address register
--		MEM_BAR : out std_logic_vector(31 downto 0)	  --Memory base address register

			);
			
end entity;

architecture Behavioral of CARDBUS is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------
component CONFIG_C is port (

		--// CardBus signals
 		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz. Global clock.
		CB_CARD_CRST_N: in std_logic;
			-- Reset signal 
			-- Forces all CardBus configuration registers to an initialized state 
		CB_CARD_ADDR: in std_logic_vector(31 downto 0);
			-- Decoded address.  
			-- Latency 1 CCLK after CardBus signal.
			-- Auto-increment address during burst read and write.
			-- Aligned with CB_CARD_DATA_IN/CB_CARD_DATA_OUT
		CB_CARD_COMMAND_TYPE: in std_logic_vector(3 downto 0);
			-- Command type. Stable during transaction.
			-- Latency 1 CCLK after CardBus signal.
 		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
		CB_CARD_CIRDY_N: in std_logic;
			-- Initiator ready
		CB_CARD_DATA_IN: in std_logic_vector(31 downto 0);
			-- input data. Delayed 1 CCLK w.r.t. CardBus.

		CB_CARD_DATA_OUT: out std_logic_vector(31 downto 0);
			-- output data. Driven when CONFIG_DATA_OUT_READY = '1'
			-- must be ignored otherwise. Tri-stated when unused.
		CB_CARD_DATA_OUT_READY: out std_logic;
			-- see above

		--// Test Points
		REG0: in std_logic_vector(7 downto 0);
		REG1: in std_logic_vector(7 downto 0);

		IO_BAR : out std_logic_vector(31 downto 0);	  --IO base address register
		MEM_BAR : out std_logic_vector(31 downto 0)	  --Memory base address register


   );
end component;


component MEMORY_C is
    port ( 

    	--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All VHDL user application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		SYNC_RESET: in std_logic;
			-- synchronous reset at power up

		--// CardBus signals
 		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz. Global clock.
		CB_CARD_ADDR: in std_logic_vector(31 downto 0);
			-- Decoded address.  
			-- Latency 1 CCLK after CardBus signal.
			-- Auto-increment address during burst read and write.
			-- Aligned with CB_CARD_DATA_IN/CB_CARD_DATA_OUT
		CB_CARD_COMMAND_TYPE: in std_logic_vector(3 downto 0);
			-- Command type. Stable during transaction.
			-- Latency 1 CCLK after CardBus signal.
		CB_CARD_CC_BE_N: in std_logic_vector(3 downto 0);
			-- CardBus command or Byte Enable,
		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
		CB_CARD_CIRDY_N: in std_logic;
			-- Initiator ready
		CB_CARD_DATA_IN: in std_logic_vector(31 downto 0);
			-- input data. Delayed 1 CCLK w.r.t. CardBus.

		CB_CARD_DATA_OUT: out std_logic_vector(31 downto 0);
			-- output data. Driven when MEM_DATA_OUT_READY = '1'
			-- must be ignored otherwise. Tri-stated when unused.
		CB_CARD_DATA_OUT_READY: out std_logic;
			-- see above
		--// user interfaces
	   	CB_CARD_ADDR_REF: in std_logic_vector(31 downto 0);
	     	-- User Address Reference

		--// Stream1 32/8-bit Memory transactions
		-- Synchronous with CLK_P/CB_CARD_CCLK clocks
		DATA1_OUT: out std_logic_vector(7 downto 0);
		DATA1_OUT_SAMPLE_CLK: out std_logic;
			-- read DATA1_OUT at rising edge of CLK_P when DATA1_OUT_SAMPLE_CLK = '1'
			-- Note1: the user is responsible for checking DATA1_OUT_BUFFER_EMPTY before reading.
			-- Note 2: When the elastic buffer is not empty, DATA1_OUT is present 
			-- at this interface even before requesting it. The request DATA1_OUT_SAMPLE_CLK_REQ 
			-- only moves the read pointer to the next read location.
		DATA1_OUT_BUFFER_EMPTY: out std_logic;
		DATA1_OUT_SAMPLE_CLK_REQ: in std_logic;	
			-- requests data. If no data is available in the buffer, the
			-- DATA1_OUT_SAMPLE_CLK will stay low.
			-- (flow control)
		
		DATA1_IN: in std_logic_vector(7 downto 0);
		DATA1_IN_SAMPLE_CLK: in std_logic;
			-- read DATA1_IN at rising edge of CLK_P when DATA1_IN_SAMPLE_CLK = '1'
		DATA1_IN_SAMPLE_CLK_REQ: out std_logic;
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)

		--// Test Points
		-- Test points are under the shield. 6 at the edge connector.
		TEST_POINTS: out std_logic_vector(6 downto 1)
			);			
end component;

component IORW_C is
    port ( 
    	--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All VHDL user application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		SYNC_RESET: in std_logic;
			-- synchronous reset at power up

		--// CardBus signals
 		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz. Global clock.
		CB_CARD_ADDR: in std_logic_vector(31 downto 0);
			-- Decoded address.  
			-- Latency 1 CCLK after CardBus signal.
			-- Auto-increment address during burst read and write.
			-- Aligned with CB_CARD_DATA_IN/CB_CARD_DATA_OUT
		CB_CARD_COMMAND_TYPE: in std_logic_vector(3 downto 0);
			-- Command type. Stable during transaction.
			-- Latency 1 CCLK after CardBus signal.
		CB_CARD_CC_BE_N: in std_logic_vector(0 downto 0);
			-- CardBus Byte Enable bit 0
		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
		CB_CARD_CIRDY_N: in std_logic;
			-- Initiator ready
		CB_CARD_DATA_IN: in std_logic_vector(7 downto 0);
			-- input data. Delayed 1 CCLK w.r.t. CardBus.

		CB_CARD_DATA_OUT: out std_logic_vector(7 downto 0);
			-- output data. Driven when IO_DATA_OUT_READY = '1'
			-- must be ignored otherwise. Tri-stated when unused.
		CB_CARD_DATA_OUT_READY: out std_logic;
			-- see above

		--// user interfaces
	   	CB_CARD_ADDR_REF: in std_logic_vector(31 downto 0);
	     	-- User Address Reference

		--// Stream1 32/8-bit Memory transactions
		-- Synchronous with CLK_P/CB_CARD_CCLK clocks
		DATA1_OUT: out std_logic_vector(7 downto 0);
		DATA1_OUT_SAMPLE_CLK: out std_logic;
			-- read DATA1_OUT at rising edge of CLK_P when DATA1_OUT_SAMPLE_CLK = '1'
			-- Note1: the user is responsible for checking DATA1_OUT_BUFFER_EMPTY before reading.
			-- Note 2: When the elastic buffer is not empty, DATA1_OUT is present 
			-- at this interface even before requesting it. The request DATA1_OUT_SAMPLE_CLK_REQ 
			-- only moves the read pointer to the next read location.
		DATA1_OUT_BUFFER_EMPTY: out std_logic;
		DATA1_OUT_SAMPLE_CLK_REQ: in std_logic;	
			-- requests data. If no data is available in the buffer, the
			-- DATA1_OUT_SAMPLE_CLK will stay low.
			-- (flow control)
		
		DATA1_IN: in std_logic_vector(7 downto 0);
		DATA1_IN_SAMPLE_CLK: in std_logic;
			-- read DATA1_IN at rising edge of CLK_P when DATA1_IN_SAMPLE_CLK = '1'
		DATA1_IN_SAMPLE_CLK_REQ: out std_logic;
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)

		--// Test Points
		-- Test points are under the shield. 6 at the edge connector.
		TEST_POINTS: out std_logic_vector(6 downto 0)
			);
end component;

--------------------------------------------------------
--     ATTRIBUTES
--------------------------------------------------------

--------------------------------------------------------
--     SIGNALS
--------------------------------------------------------
-- Suffix _D indicates a one CLK delayed version of the net with the same name
-- Suffix _E indicates an extended precision version of the net with the same name
-- Suffix _N indicates an inverted version of the net with the same name

--// bus I/O
signal CB_CARD_ADDR: std_logic_vector(31 downto 0);
signal CB_CARD_COMMAND_TYPE: std_logic_vector(3 downto 0);
signal CB_CARD_CFRAME_N_D: std_logic;
signal CB_CARD_CFRAME_N_D2: std_logic;
signal CB_CARD_DATA_IN: std_logic_vector(31 downto 0);
signal CB_CARD_CIRDY_N_D: std_logic;
signal CB_CARD_DATA_OUT: std_logic_vector(31 downto 0);

--// Configuration
signal CONFIG_DATA_OUT: std_logic_vector(31 downto 0);
signal CONFIG_DATA_OUT_READY: std_logic;

--// MEMORY
signal MEM_DATA_OUT: std_logic_vector(31 downto 0);
signal MEM_DATA_OUT_READY: std_logic;
signal TP_MEM: std_logic_vector(6 downto 1);

--// I/O RW
signal IO_DATA_OUT: std_logic_vector(7 downto 0);
signal IO_DATA_OUT_READY: std_logic;
signal TP_IO: std_logic_vector(6 downto 0);

signal MEM_BAR : std_logic_vector( 31 downto 0);
signal IO_BAR : std_logic_vector( 31 downto 0);

--// CardBus internal signals
signal CB_CARD_MEM_ADDR_REF: std_logic_vector(31 downto 0);
 	-- base address to be decoded during memory read/write cycles
signal CB_CARD_IO_ADDR_REF: std_logic_vector(31 downto 0);
 	-- base address to be decoded during IO read/write cycles

--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------
begin
--------------------------------------------------------------------------
-- COMMON FUNCTIONS
--------------------------------------------------------------------------
-- Reclock bus inputs for use in other processes
RECLOCK_001: process(CB_CARD_CCLK, CB_CARD_CFRAME_N, CB_CARD_CIRDY_N)
begin
	if rising_edge(CB_CARD_CCLK) then
		CB_CARD_CFRAME_N_D <= CB_CARD_CFRAME_N;
		CB_CARD_CFRAME_N_D2 <= CB_CARD_CFRAME_N_D;
		CB_CARD_CIRDY_N_D <= CB_CARD_CIRDY_N;
	end if;
end process;

-- which address? 
-- save BE
ADDRESS_001: process(CB_CARD_CCLK, CB_CARD_CFRAME_N, CB_CARD_ADDR_DATA)
begin
	if rising_edge(CB_CARD_CCLK) then
		if((CB_CARD_CFRAME_N = '0') and (CB_CARD_CFRAME_N_D = '1')) then
			-- initial 32-bit address ready at the first clock when CFRAME# is active low
			CB_CARD_ADDR <= CB_CARD_ADDR_DATA;
	  	end if;
	end if;
end process;

-- which command type?
COMMAND_TYPE_001: process(CB_CARD_CCLK, CB_CARD_CFRAME_N, CB_CARD_CC_BE_N)
begin
	if rising_edge(CB_CARD_CCLK) then
		-- 4-bit command type is ready at the first clock after CFRAME# is asserted
		if((CB_CARD_CFRAME_N = '0') and (CB_CARD_CFRAME_N_D = '1')) then
			CB_CARD_COMMAND_TYPE <= CB_CARD_CC_BE_N;
	  	end if;
	end if;
end process;

-- latch input data when host is writing (Goal is to avoid timing problems)
-- Write commands: I/O write, Memory write, Configuration write, Memory write and invalidate.
INPUT_DATA_001: process(CB_CARD_CCLK, CB_CARD_CIRDY_N, CB_CARD_ADDR_DATA)
begin
	if rising_edge(CB_CARD_CCLK) then
		if((CB_CARD_CIRDY_N = '0') and (CB_CARD_COMMAND_TYPE(1 downto 0) = "11")) then
			CB_CARD_DATA_IN <= CB_CARD_ADDR_DATA;
	  	end if;
	end if;
end process;


--------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------
-- Combine the Card Information Services (CIS) table with 
-- CardBus-specific Configuration registers.
CONFIG_C_001: CONFIG_C port map(
	CB_CARD_CCLK => CB_CARD_CCLK,
	CB_CARD_CRST_N => CB_CARD_CRST_N,
	CB_CARD_ADDR => CB_CARD_ADDR,
	CB_CARD_COMMAND_TYPE => CB_CARD_COMMAND_TYPE,
	CB_CARD_CFRAME_N => CB_CARD_CFRAME_N,
	CB_CARD_CIRDY_N => CB_CARD_CIRDY_N,
	CB_CARD_DATA_IN => CB_CARD_DATA_IN,
	CB_CARD_DATA_OUT => CONFIG_DATA_OUT,
	CB_CARD_DATA_OUT_READY => CONFIG_DATA_OUT_READY,
	REG0 => REG0,
	REG1 => REG1,
	IO_BAR => IO_BAR,
	MEM_BAR => MEM_BAR

);


--------------------------------------------------------------------------
-- MEMORY
--------------------------------------------------------------------------
-- Decoding base address
CB_CARD_MEM_ADDR_REF <= MEM_BAR;

-- normal 32-bit memory transaction
MEMORY_C_001: MEMORY_C port map(

	CLK_P => CLK_P,
	SYNC_RESET => ASYNC_RESET,
	--// bus
	CB_CARD_CCLK => CB_CARD_CCLK,
	CB_CARD_ADDR => CB_CARD_ADDR,
	CB_CARD_COMMAND_TYPE => CB_CARD_COMMAND_TYPE,
	CB_CARD_CC_BE_N => CB_CARD_CC_BE_N,
	CB_CARD_CFRAME_N => CB_CARD_CFRAME_N,
	CB_CARD_CIRDY_N => CB_CARD_CIRDY_N,
	CB_CARD_DATA_IN => CB_CARD_DATA_IN,
	CB_CARD_DATA_OUT => MEM_DATA_OUT,
	CB_CARD_DATA_OUT_READY => MEM_DATA_OUT_READY,
	--// control
	CB_CARD_ADDR_REF => CB_CARD_MEM_ADDR_REF,
	--// user
	DATA1_IN_SAMPLE_CLK => DATA1_IN_SAMPLE_CLK,
	DATA1_IN_SAMPLE_CLK_REQ => DATA1_IN_SAMPLE_CLK_REQ,
	DATA1_IN => DATA1_IN,
	DATA1_OUT => DATA1_OUT,
	DATA1_OUT_SAMPLE_CLK_REQ => DATA1_OUT_SAMPLE_CLK_REQ,
	DATA1_OUT_SAMPLE_CLK => DATA1_OUT_SAMPLE_CLK,
	DATA1_OUT_BUFFER_EMPTY => DATA1_OUT_BUFFER_EMPTY,
	TEST_POINTS => TP_MEM
);
		
--------------------------------------------------------------------------
-- I/O RW
--------------------------------------------------------------------------
-- I/O Read/Write
-- Decoding base address
CB_CARD_IO_ADDR_REF <= IO_BAR;

IORW_C_001: IORW_C port map (
	CLK_P => CLK_P,
	SYNC_RESET => ASYNC_RESET,
	--// bus
	CB_CARD_CCLK => CB_CARD_CCLK,
	CB_CARD_ADDR => CB_CARD_ADDR,
	CB_CARD_COMMAND_TYPE => CB_CARD_COMMAND_TYPE,
	CB_CARD_CC_BE_N => CB_CARD_CC_BE_N(0 downto 0),
	CB_CARD_CFRAME_N => CB_CARD_CFRAME_N,
	CB_CARD_CIRDY_N => CB_CARD_CIRDY_N,
	CB_CARD_DATA_IN => CB_CARD_DATA_IN(7 downto 0),
	CB_CARD_DATA_OUT => IO_DATA_OUT,
	CB_CARD_DATA_OUT_READY => IO_DATA_OUT_READY,
	--// control
	CB_CARD_ADDR_REF => CB_CARD_IO_ADDR_REF,
	--// user
	DATA1_IN => DATA2_IN,
	DATA1_IN_SAMPLE_CLK => DATA2_IN_SAMPLE_CLK,
	DATA1_OUT_SAMPLE_CLK_REQ => DATA2_OUT_SAMPLE_CLK_REQ,
	DATA1_OUT => DATA2_OUT,
	DATA1_OUT_SAMPLE_CLK => DATA2_OUT_SAMPLE_CLK,
	DATA1_OUT_BUFFER_EMPTY => DATA2_OUT_BUFFER_EMPTY,
	DATA1_IN_SAMPLE_CLK_REQ => DATA2_IN_SAMPLE_CLK_REQ,
	TEST_POINTS => TP_IO
);


--------------------------------------------------------------------------
-- BUS INTERFACE OUTPUT SIGNALS
--------------------------------------------------------------------------
-- manage Target Control signal: CB_CARD_CTRDY_N (for all relevant read and write transactions).
CB_CARD_CTRDY_N_GEN_001: process(CB_CARD_CCLK, CB_CARD_CIRDY_N, ASYNC_RESET)
begin
	if (ASYNC_RESET = '1') then
		CB_CARD_CTRDY_N <= '1';
	elsif rising_edge(CB_CARD_CCLK) then
		if((CB_CARD_CFRAME_N_D = '0') and (CB_CARD_CIRDY_N = '0')) then
			-- deassert when last data phase is complete
			-- Note: same for CB_CARD_CDEVSEL_N, as we do not use wait states.
			CB_CARD_CTRDY_N <= '0';
		else
			CB_CARD_CTRDY_N <= '1';
	  	end if;
	end if;
end process;

-- manage Target Control signal: CB_CARD_CDEVSEL_N (for all relevant read and write transactions).
CB_CARD_CDEVSEL_N_GEN_001: process(CB_CARD_CCLK, CB_CARD_CIRDY_N, ASYNC_RESET)
begin
	if (ASYNC_RESET = '1') then
		CB_CARD_CDEVSEL_N <= '1';
	elsif rising_edge(CB_CARD_CCLK) then
		if((CB_CARD_CFRAME_N_D = '0') and (CB_CARD_CIRDY_N = '0')) then
			-- deassert when last data phase is complete
			CB_CARD_CDEVSEL_N <= '0';
		else
			CB_CARD_CDEVSEL_N <= '1';
	  	end if;
	end if;
end process;


-- drive relevant data when corresponding data is ready otherwise High 'Z'
CB_CARD_DATA_OUT <= CONFIG_DATA_OUT when (CONFIG_DATA_OUT_READY = '1') 	
			else MEM_DATA_OUT when (MEM_DATA_OUT_READY  = '1') 
			else x"000000" & IO_DATA_OUT when (IO_DATA_OUT_READY  = '1') 
			else (others => 'Z');

CB_CARD_ADDR_DATA <= CB_CARD_DATA_OUT;


-- Interrupts are not supported
CB_CARD_CINT_N <= '1';

-- Flow control
CB_CARD_CSTOP_N <= '1';

CB_CARD_CAUDIO_N <= '1';
CB_CARD_CSTSCHG_N <= '1';
CB_CARD_CPERR_N <= '1';
CB_CARD_CSERR_N <= '1';
CB_CARD_CCLKRUN_N <= 'Z';


DUMMY_OUTPUT <= CB_CARD_CGNT_N and CB_CARD_CREQ_N and CB_CARD_CBLOCK_N; 
	-- used to prevent the synthesis tool from optimizing
	-- the signals linked to this dummy output.
	-- (for example when we need to pull up an unused input signal)

--------------------------------------------------------------------------
-- COMPUTE PARITY BIT
--------------------------------------------------------------------------
-- required output
CB_CARD_CPAR_GEN_001: process(CB_CARD_CCLK, CB_CARD_CC_BE_N)
begin
	if rising_edge(CB_CARD_CCLK) then
		if((CONFIG_DATA_OUT_READY = '1')  or (MEM_DATA_OUT_READY = '1') or (IO_DATA_OUT_READY  = '1')) then
			CB_CARD_CPAR <= ((CB_CARD_DATA_OUT(0) xor CB_CARD_DATA_OUT(1)) xor (CB_CARD_DATA_OUT(2) xor CB_CARD_DATA_OUT(3)) xor (CB_CARD_DATA_OUT(4) xor CB_CARD_DATA_OUT(5)) xor
						(CB_CARD_DATA_OUT(6) xor CB_CARD_DATA_OUT(7)) xor (CB_CARD_DATA_OUT(8) xor CB_CARD_DATA_OUT(9)) xor (CB_CARD_DATA_OUT(10) xor CB_CARD_DATA_OUT(11)) xor
						(CB_CARD_DATA_OUT(12) xor CB_CARD_DATA_OUT(13)) xor (CB_CARD_DATA_OUT(14) xor CB_CARD_DATA_OUT(15)) xor (CB_CARD_DATA_OUT(16) xor CB_CARD_DATA_OUT(17)) xor
						(CB_CARD_DATA_OUT(18) xor CB_CARD_DATA_OUT(19)) xor (CB_CARD_DATA_OUT(20) xor CB_CARD_DATA_OUT(21)) xor (CB_CARD_DATA_OUT(22) xor CB_CARD_DATA_OUT(23)) xor
						(CB_CARD_DATA_OUT(24) xor CB_CARD_DATA_OUT(25)) xor (CB_CARD_DATA_OUT(26) xor CB_CARD_DATA_OUT(27)) xor (CB_CARD_DATA_OUT(28) xor CB_CARD_DATA_OUT(29)) xor
						(CB_CARD_DATA_OUT(30) xor CB_CARD_DATA_OUT(31)) xor (CB_CARD_CC_BE_N(0) xor CB_CARD_CC_BE_N(1)) xor (CB_CARD_CC_BE_N(2) xor CB_CARD_CC_BE_N(3)));	
		else 
			CB_CARD_CPAR <= 'Z';		
		end if;
	end if;
end process;

--------------------------------------------------------------------------
-- TEST POINTS
--------------------------------------------------------------------------
TEST_POINTS(1) <= '1' when ((CB_CARD_CFRAME_N = '0') and (CB_CARD_CFRAME_N_D = '1')) else '0';
TEST_POINTS(2) <= '1' when (CB_CARD_ADDR = CB_CARD_IO_ADDR_REF) else '0';
TEST_POINTS(3) <= '1' when (CB_CARD_CC_BE_N = 2) else '0';
TEST_POINTS(4) <= '1' when (CB_CARD_ADDR_DATA = CB_CARD_IO_ADDR_REF) else '0';

TEST_POINTS(5) <= MEM_DATA_OUT_READY;
TEST_POINTS(6) <= CONFIG_DATA_OUT_READY;
TEST_POINTS(7) <= IO_DATA_OUT_READY;
TEST_POINTS(8) <= '1' when CB_CARD_ADDR_DATA(7 downto 0) = x"40" else '0';
TEST_POINTS(9) <= '1' when CB_CARD_ADDR_DATA(15 downto 8) = x"40" else '0';
TEST_POINTS(10) <= '1' when CB_CARD_ADDR_DATA(23 downto 16) = x"40" else '0';
TEST_POINTS(17 downto 11) <= TP_IO(6 downto 0);
TEST_POINTS(23 downto 18) <= TP_MEM(6 downto 1);

end behavioral;