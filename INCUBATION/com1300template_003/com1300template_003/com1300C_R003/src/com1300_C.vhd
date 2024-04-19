-------------------------------------------------------------
--	Filename:  COM-1300C.VHD
-- Authors: 
--		Adam Kwiatkowski w/ Alain Zarembowitch / MSS, Poornima Sarvadevabhatla
--	Version: Rev 3
-- Last modified: 5/01/07
-- Inheritance: 	COM1300 rev1
--
-- description:  COM-1300 module, VHDL code template.
-- Includes the following VHDL drivers: 
-- CardBus, Config, IORW, Memory, 256Mb SDRAM driver, 
-- SDRAM test, ComScope. 
-- SDRAM test results are available on J1(3:2).
-- Using this code, it is possible to load new FPGA configurations
-- into the flash memory through the CardBus interface.
-- The intent is to load this baseline version as a 'protected boot' program
-- which is not erasable by the user and always recoverable (see 
-- specifications for the detailed procedure).
-- Includes constraint file COM-1300_C.ucf
-- Option C is for CardBus (32-bit)
--
-- Rev 3 PS: 
-- Switched to latest version of ComScope
-- Switched to Xilinx ISE 8.2i
---------------------------------------------------------------
library IEEE, unisim;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use unisim.vcomponents.all;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity com1300_C is
    Port ( 
		--GLOBAL CLOCKS
	   CLK_IN1 : in std_logic;	
			-- 40 MHz master clock for this FPGA, internal to the module
	   CLK_IN2 : in std_logic;		
			-- Clock from external ComBlocks through pin A1 of the 40-pin connector
	 
	   --// Host bus adapter interface:
	   	CB_CARD_ADDR_DATA: inout std_logic_vector(31 downto 0);
	     	-- Address and Data
		CB_CARD_CC_BE_N: in std_logic_vector(3 downto 0);
			-- CardBus command or Byte Enable, to define type of transaction
		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz
		CB_CARD_CCLKRUN_N: inout std_logic;
			-- Asserted if clock runs normally
			-- deasserted before clock stops or slow down (I/O)
		CB_CARD_CRST_N: in std_logic;
			-- Reset signal 
			-- Forces all CardBus configuration registers to an initialized state 
		CB_CARD_CPAR: inout std_logic;
			-- Parity signal (I/O)
		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
			-- PULL-UP
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
		CB_CARD_CAUDIO_N: out std_logic;
			-- Card audio output. Not used: FPGA to pull high.
			-- PULL-UP?
		CB_CARD_CSTSCHG_N: out std_logic;
			-- STSCHG#     During memory or I/O interface
					-- PULL-UP  ?
		CB_CARD_CPERR_N: out std_logic;
			-- Data parity error
		CB_CARD_CSERR_N: out std_logic;
			-- System error

		CB_CARD_CINT_N: out std_logic;
			-- Interrupt request
			-- PULL-UP?
		CB_CARD_CGNT_N: in std_logic;
			-- Bus arbitration grant. Not applicable. FPGA pulls high
			-- PULL-UP
		CB_CARD_CREQ_N: in std_logic;
			-- Arbitration request. 
			-- Not applicable as the COM-1300 is never master. Pull high
 

	   --// SDRAM interface. Single 256Mb SDRAM
		-- -7E: Maximum clock speed 133 MHz, 7.5 ns delay @ CL=2
	   SDRAM_A: out std_logic_vector(12 downto 0);
	      -- Address lines. 
	   SDRAM_DQ: inout std_logic_vector(15 downto 0);
	      -- Bi-directional data lines
			-- Single IC. Only 256Mb. thus 16-bit wide interface
			-- out of a possible 32.
	   SDRAM_BA0: out std_logic;
	   SDRAM_BA1: out std_logic;
	   SDRAM_CAS_N: out std_logic;
	   SDRAM_RAS_N: out std_logic;
	   SDRAM_WE_N: out std_logic;
	   SDRAM_CLK: out std_logic;
	   SDRAM_CKE: out std_logic;
	   SDRAM_CS_N: out std_logic;
	      -- SDRAM chip select bar
		SDRAM_DQML: out std_logic;
		SDRAM_DQMH: out std_logic;

		--// ComBlock 40-pin Interface
		J1: inout std_logic_vector(34 downto 2);		

		--// Monitoring & Control: Atmel controller interface
		UC_AD: inout std_logic_vector(7 downto 0);
		UC_WRN: in std_logic;
		UC_RDN: in std_logic;
		UC_ALE: in std_logic;
		UC_FLASH_CSN: in std_logic;
			-- '0' when uC talks to the flash memory, '1' when otherwise (i.e. possibly
			-- talk to the FPGAs).

		--// Monitoring & Control: Serial ports interface
		-- L = comblock 40-pin interface
		-- R = PCMCIA/CardBus interface
		RX_L: in std_logic; 	
		TX_L: out std_logic;

		--// Test Points
		TEST_POINTS: out std_logic_vector(6 downto 1);
			-- Test points are under the shield. 6 at the edge connector.
		DUMMY_OUTPUT: out std_logic;
			-- used to prevent the synthesis tool from optimizing
			-- the signals linked to this dummy output.
			-- (for example when we need to pull up an unused input signal)
		INITB: out std_logic
			-- easy access test point: INIT#. Easy access with scope.
			  
			  );
end entity;

architecture Behavioral of com1300_C is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------
component CARDBUS is
    port ( 
    	--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		ASYNC_RESET: in std_logic;
			-- asynchronous reset at power up. MANDATORY.

    	--// Host bus adapter interface:
	   	CB_CARD_ADDR_DATA: inout std_logic_vector(31 downto 0);
	     	-- Address and Data

		--// Command
		CB_CARD_CC_BE_N: in std_logic_vector(3 downto 0);
			-- CardBus command or Byte Enable, to define type of transaction

		--// System
		CB_CARD_CCLK: in std_logic;
			-- CardBus clock signal, 0 to 33 MHz. Global clock.
		CB_CARD_CCLKRUN_N: inout std_logic;
			-- Asserted if clock runs normally
			-- deasserted before clock stops or slow down (I/O)
		CB_CARD_CRST_N: in std_logic;
			-- Reset signal 
			-- Forces all CardBus configuration registers to an initialized state 

		--// Interface Control
		CB_CARD_CPAR: inout std_logic;
			-- Parity signal (I/O)
		CB_CARD_CFRAME_N: in std_logic;
			-- Data Frame indicator
			-- PULL-UP
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
			-- Note1: the user is responsible for checking DATA1_OUT_BUFFER_EMPTY before
			-- reading.
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
end component;

component SDRAM_CONTROLLER_TEST is port (
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
end component;


component COMSCOPE is 
	port ( 
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

--// CONSTANTS
signal ZERO: std_logic;
signal ONE: std_logic;
signal ZERO2: std_logic_vector(1 downto 0);
signal ZERO4: std_logic_vector(3 downto 0);
signal ZERO8: std_logic_vector(7 downto 0);
signal ZERO16: std_logic_vector(15 downto 0);

--// CLOCKS, RESETS
signal CLK_IN1_A: std_logic;
signal CLK_IN2_A:	std_logic;
signal CLKFX_W_001: std_logic;	-- synthesized processing clock before going global
signal CLK0_BUF: std_logic;
signal CLK_P: std_logic;
signal CLK_IO: std_logic;
signal CB_CARD_CCLKG: std_logic;
signal DCM_LOCKED_001: std_logic;
signal COUNTER8:  std_logic_vector(2 downto 0);
signal ASYNC_RESET: std_logic;
	-- asynchronous reset
signal RESET_COUNTER: std_logic_vector(5 downto 0) := "000000";	-- initialize for simulations

--// user data streams
signal DATA1A: std_logic_vector(7 downto 0);
signal DATA1A_BUFFER_EMPTY:  std_logic;
signal DATA1A_SAMPLE_CLK_REQ:  std_logic;	
signal DATA1A_SAMPLE_CLK:  std_logic;	
signal DATA1B: std_logic_vector(7 downto 0);
signal DATA1B_SAMPLE_CLK: std_logic;
signal DATA1B_SAMPLE_CLK_REQ: std_logic;
signal DATA2A: std_logic_vector(7 downto 0);
signal DATA2A_SAMPLE_CLK:  std_logic;
signal DATA2A_BUFFER_EMPTY:  std_logic;
signal DATA2A_SAMPLE_CLK_REQ:  std_logic;	
signal DATA2B: std_logic_vector(7 downto 0);
signal DATA2B_SAMPLE_CLK: std_logic;
signal DATA2B_SAMPLE_CLK_REQ: std_logic;
signal TP_PCMCIA: std_logic_vector(6 downto 1);

--// SDRAM 
signal SDRAM_A_LOCAL:  std_logic_vector(12 downto 0);
signal SDRAM_DQ_LOCAL:  std_logic_vector(15 downto 0);
signal SDRAM_BA0_LOCAL:  std_logic;
signal SDRAM_BA1_LOCAL:  std_logic;
signal SDRAM_CAS_N_LOCAL:  std_logic;
signal SDRAM_RAS_N_LOCAL:  std_logic;
signal SDRAM_WE_N_LOCAL:  std_logic;
signal SDRAM_CLK_LOCAL:  std_logic;
signal SDRAM_CKE_LOCAL:  std_logic;
signal SDRAM_CS_N_LOCAL:  std_logic;
signal SDRAM_DQML_LOCAL:  std_logic;
signal SDRAM_DQMH_LOCAL:  std_logic;


--// ComScope traces
signal S1_1: std_logic_vector(7 downto 0);	
signal S1_1_CLK: std_logic;
signal S1_1B_CLK: std_logic;
signal S1_2: std_logic_vector(7 downto 0);	
signal S1_2_CLK: std_logic;
signal S1_2B_CLK: std_logic;
signal S1_3: std_logic_vector(7 downto 0);	
signal S1_3_CLK: std_logic;
signal S1_3B_CLK: std_logic;
signal S1_4: std_logic_vector(7 downto 0);	
signal S1_4_CLK: std_logic;
signal S1_4B_CLK: std_logic;

signal S2_1: std_logic_vector(7 downto 0);	
signal S2_1_CLK: std_logic;
signal S2_1B_CLK: std_logic;
signal S2_2: std_logic_vector(7 downto 0);	
signal S2_2_CLK: std_logic;
signal S2_2B_CLK: std_logic;
signal S2_3: std_logic_vector(7 downto 0);	
signal S2_3_CLK: std_logic;
signal S2_3B_CLK: std_logic;
signal S2_4: std_logic_vector(7 downto 0);	
signal S2_4_CLK: std_logic;
signal S2_4B_CLK: std_logic;

signal T1: std_logic;
signal T1_CLK: std_logic;
signal T2: std_logic;
signal T2_CLK: std_logic;

--// TEST POINTS
signal TP_SDRAM_CONTROLLER: std_logic_vector(10 downto 1);
signal FIRST_FAILED_ADDRESS: std_logic_vector(23 downto 0);
signal FIRST_FAILED_DATA_WORD: std_logic_vector(15 downto 0);
signal SDRAM_END_OF_TEST: std_logic;
signal SDRAM_SUCCESSFULL_TEST: std_logic;
signal TP_CARDBUS: std_logic_vector(30 downto 1);

signal TRIGGER_REARM_TOGGLE: std_logic:= '0';
signal FORCE_TRIGGER_TOGGLE: std_logic:= '0';
signal START_CAPTURE_TOGGLE: std_logic:= '0';
signal REG250_READ: std_logic;

--// Atmel uc interface
signal UC_ADDRESS: std_logic_vector(7 downto 0);
signal UC_ADDR_D: std_logic_vector(7 downto 0);
signal UC_ADDR_D2: std_logic_vector(7 downto 0);
signal UC_RDN_D: std_logic;
signal UC_RDN_D2: std_logic;
signal TX_PCMCIA_TOGGLE: std_logic;
signal TX_PCMCIA_TOGGLE_D: std_logic;
signal TX_PCMCIA_TOGGLE_D2: std_logic;
signal CONFIG_CHANGE_TOGGLE: std_logic;
signal CONFIG_CHANGE_TOGGLE_D: std_logic;
signal CONFIG_CHANGE_TOGGLE_D2: std_logic;
signal CONFIG_CHANGE_PULSE: std_logic;

--// Control Registers
signal REG0: std_logic_vector(7 downto 0);
signal REG1: std_logic_vector(7 downto 0);
signal REG2: std_logic_vector(7 downto 0);
signal REG3: std_logic_vector(7 downto 0);
signal REG4: std_logic_vector(7 downto 0);
signal REG5: std_logic_vector(7 downto 0);
signal REG6: std_logic_vector(7 downto 0);
signal REG7: std_logic_vector(7 downto 0);
signal REG8: std_logic_vector(7 downto 0);
signal REG9: std_logic_vector(7 downto 0);
signal REG10: std_logic_vector(7 downto 0);
signal REG11: std_logic_vector(7 downto 0);
signal REG12: std_logic_vector(7 downto 0);
signal REG13: std_logic_vector(7 downto 0);
signal REG14: std_logic_vector(7 downto 0);
signal REG15: std_logic_vector(7 downto 0);
signal REG16: std_logic_vector(7 downto 0);
signal REG17: std_logic_vector(7 downto 0);
signal REG18: std_logic_vector(7 downto 0);
signal REG19: std_logic_vector(7 downto 0);
signal REG20: std_logic_vector(7 downto 0);
signal REG255: std_logic_vector(7 downto 0);

--// ComScope control registers
signal REG237: std_logic_vector(7 downto 0):= "00000000";
signal REG238: std_logic_vector(7 downto 0):= "00000000";
signal REG239: std_logic_vector(7 downto 0):= "00000000";
signal REG240: std_logic_vector(7 downto 0):= "00001101";	-- Trace 1 signal selection
signal REG241: std_logic_vector(7 downto 0):= "00000000";	-- Trigger position, decimation
signal REG242: std_logic_vector(7 downto 0):= "00001110";	-- Trace 2 signal selection
signal REG243: std_logic_vector(7 downto 0):= "00000000";	-- Trigger position, decimation
signal REG244: std_logic_vector(7 downto 0):= "00000000";	-- Trace 3 signal selection
signal REG245: std_logic_vector(7 downto 0):= "00000000";	-- Trigger position, decimation
signal REG246: std_logic_vector(7 downto 0):= "00000000";	-- Trace 4 signal selection
signal REG247: std_logic_vector(7 downto 0):= "00000000";	-- Trigger position, decimation
signal REG248: std_logic_vector(7 downto 0):= "10001101";	-- Trigger edge, trigger signal
signal REG249: std_logic_vector(7 downto 0):= "10111111";	-- Trigger threshold
signal REG250: std_logic_vector(7 downto 0):= "00000000";
signal REG251: std_logic_vector(7 downto 0):= "00000000";

--data signals
signal SEND_COUNTER_MEM: std_logic_vector(7 downto 0); 

--signal MEM_BAR : std_logic_vector( 31 downto 0);
--signal IO_BAR : std_logic_vector( 31 downto 0);

--// FPGA option and revision (ASCII format)
-- These two ASCII characters appear in the Comblock Control Center.
-- '0' = 48
-- 'A' = 65
constant OPTION: std_logic_vector(7 downto 0) := x"43";	-- 'C'
constant REVISION: std_logic_vector(7 downto 0) := x"33";	-- '3'
--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------

begin
--// CONSTANTS ---------------------
ZERO <= '0';
ONE <= '1';
ZERO2 <= "00";
ZERO4 <= (others => '0');
ZERO8 <= (others => '0');
ZERO16 <= (others => '0');

--// CardBus controller
-- The controller supports two data streams:
-- Stream1 is used for Monitoring & Control. Data is sent to the Atmel uC.
-- 	CardBus transaction: 8-bit I/O read/write at I/O address 0.
-- Stream2 is used for high-speed user data transfer (application-specific).
--		CardBus transaction: 32-bit memory transfer at Memory address 0.
CARDBUS_001: CARDBUS port map(
	CLK_P => CLK_P, 
	ASYNC_RESET => ASYNC_RESET,

	--// CardBus. Connect directly to bus i/o pins except for global clock.
	CB_CARD_ADDR_DATA => CB_CARD_ADDR_DATA,
	CB_CARD_CC_BE_N => CB_CARD_CC_BE_N,
	CB_CARD_CCLK => CB_CARD_CCLKG,
	CB_CARD_CCLKRUN_N => CB_CARD_CCLKRUN_N,
	CB_CARD_CRST_N => CB_CARD_CRST_N,
	CB_CARD_CPAR => CB_CARD_CPAR,
	CB_CARD_CFRAME_N => CB_CARD_CFRAME_N,
	CB_CARD_CTRDY_N => CB_CARD_CTRDY_N,
	CB_CARD_CIRDY_N => CB_CARD_CIRDY_N,
	CB_CARD_CSTOP_N => CB_CARD_CSTOP_N,
	CB_CARD_CDEVSEL_N => CB_CARD_CDEVSEL_N,
	CB_CARD_CBLOCK_N => CB_CARD_CBLOCK_N,
	CB_CARD_CAUDIO_N => CB_CARD_CAUDIO_N,
	CB_CARD_CSTSCHG_N => CB_CARD_CSTSCHG_N,
	CB_CARD_CPERR_N => CB_CARD_CPERR_N,
	CB_CARD_CSERR_N => CB_CARD_CSERR_N,
	CB_CARD_CINT_N => CB_CARD_CINT_N,
	CB_CARD_CGNT_N => CB_CARD_CGNT_N,
	CB_CARD_CREQ_N => CB_CARD_CREQ_N,

	-- M&C message to Atmel uC
	DATA2_OUT => DATA2A,
	DATA2_OUT_SAMPLE_CLK => open,
	DATA2_OUT_BUFFER_EMPTY => DATA2A_BUFFER_EMPTY,
	DATA2_OUT_SAMPLE_CLK_REQ => DATA2A_SAMPLE_CLK_REQ,
 
	-- M&C message from Atmel uC. Flow control unnecessary (short messages)
	DATA2_IN => DATA2B,
	DATA2_IN_SAMPLE_CLK => DATA2B_SAMPLE_CLK,
	DATA2_IN_SAMPLE_CLK_REQ => open,

	DATA1_OUT => DATA1A,
	DATA1_OUT_SAMPLE_CLK => DATA1A_SAMPLE_CLK,
	DATA1_OUT_BUFFER_EMPTY => DATA1A_BUFFER_EMPTY,
	DATA1_OUT_SAMPLE_CLK_REQ => DATA1A_SAMPLE_CLK_REQ,
	DATA1_IN => DATA1B,
	DATA1_IN_SAMPLE_CLK => DATA1B_SAMPLE_CLK,
	DATA1_IN_SAMPLE_CLK_REQ => DATA1B_SAMPLE_CLK_REQ,


	REG0 => REG0,
	REG1 => REG1,
	DUMMY_OUTPUT => DUMMY_OUTPUT,
	TEST_POINTS => TP_CARDBUS
);


-- Sending data to the host memory
SEND_TO_HOST_001: process(CLK_P, DATA1B_SAMPLE_CLK_REQ)
begin
	if rising_edge(CLK_P)  then
		if (DATA1B_SAMPLE_CLK_REQ = '1') then
			SEND_COUNTER_MEM <= SEND_COUNTER_MEM + 1;
			DATA1B_SAMPLE_CLK <= '1';
			DATA1B <= SEND_COUNTER_MEM;
		else
			DATA1B_SAMPLE_CLK <= '0';
		end if;
	end if;
end process;

--// RESET ---------------------
-- Generate a reset pulse after power up. 
-- The reset counter starts at 0 and counts to 32 where it stays.
-- The ASYNC_RESET is active while the counter stays below 32.
RESET_COUNTER_GEN_001: process(CLK_P)
begin
	if rising_edge(CLK_P) then
		if(RESET_COUNTER(5) = '0') then
			RESET_COUNTER <= RESET_COUNTER + 1;
	  	end if;
  	end if;
end process;

ASYNC_RESET <= not(RESET_COUNTER(5));

-- Global buffers
IBUFG_001: IBUFG  port map (I=> CLK_IN1, O=> CLK_IN1_A);	
BUFG_001: BUFG  port map (I=> CLKFX_W_001, O=> CLK_P);	
	-- processing clock (130 MHz). 
BUFG_002: BUFG  port map (I=> CLK0_BUF, O=> CLK_IO);	
	-- I/O clock (40 MHz). 
BUFG_003: BUFG  port map (I=> CLK_IN2, O=> CLK_IN2_A);	
	-- input clock
BUFG_004: BUFG  port map (I=> CB_CARD_CCLK, O=> CB_CARD_CCLKG);	
	-- cardbus clock.


-- DCM used as frequency synthesizer for processing clock. 40 MHz x M / D = 130 MHz, where M = 4, D = 2.
-- M and D are set through the attributes above.
U_DCM001 : DCM
    Generic map (
      CLK_FEEDBACK => "1X",
      CLKDV_DIVIDE => 2.0,
      CLKFX_DIVIDE => 4,
      CLKFX_MULTIPLY => 4,
      CLKIN_DIVIDE_BY_2 => FALSE,
      CLKIN_PERIOD => 25.0,
      CLKOUT_PHASE_SHIFT => "NONE",
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
      DFS_FREQUENCY_MODE => "LOW",
      DLL_FREQUENCY_MODE => "LOW",
      DUTY_CYCLE_CORRECTION => TRUE,
      PHASE_SHIFT => 0,
      STARTUP_WAIT => FALSE)
     port map (
      CLKIN => CLK_IN1_A,
      CLKFB => CLK_IO,
      RST => ZERO,
      PSEN => ZERO,
      PSINCDEC => ZERO,
      PSCLK => ZERO,
      DSSEN => ZERO,
      CLK0 => CLK0_BUF,
      CLKFX => CLKFX_W_001,
      LOCKED => DCM_LOCKED_001);

-- Test clocks. Generate a divide-by-8 clock and forward to 
-- the INIT# test point (located next to the 'DONE' test point)
-- This is an easy way to verify that the VHDL code is properly implemented
-- and that no glitches exist on an external or internal clock.
process(ASYNC_RESET, CLK_P)
begin
	if(ASYNC_RESET = '1') then
		COUNTER8 <= "000";
	elsif rising_edge(CLK_P) then
		COUNTER8 <= COUNTER8 + 1;
	end if;
end process;
INITB <= COUNTER8(2);


--// SDRAM controller
--SDRAM_CONTROLLER_001: SDRAM_CONTROLLER port map(
--	ASYNC_RESET => ASYNC_RESET,
--	CLK => CLK_P,
	-- SDRAM IC interface
--	SDRAM_A => SDRAM_A,
--	SDRAM_DQ => SDRAM_DQ,
--	SDRAM_BA0 => SDRAM_BA0,
--	SDRAM_BA1 => SDRAM_BA1,
--	SDRAM_CAS_N => SDRAM_CAS_N,
--	SDRAM_RAS_N => SDRAM_RAS_N, 
--	SDRAM_WE_N => SDRAM_WE_N,
--	SDRAM_CLK => SDRAM_CLK,
--	SDRAM_CKE => SDRAM_CKE, 
--	SDRAM_CS_N => SDRAM_CS_N, 
--	SDRAM_DQML => SDRAM_DQML,
--	SDRAM_DQMH => SDRAM_DQMH
--);

--// Test SDRAM controller
-- Start test manually from the ComBlock Control Center, by refreshing the control registers.
SDRAM_CONTROLLER_TEST_001: SDRAM_CONTROLLER_TEST port map(
	ASYNC_RESET => ASYNC_RESET,
	CLK => CLK_P,
	--// Test interface (connect to 40 pin)
	START_TEST => CONFIG_CHANGE_PULSE,
	END_OF_TEST => SDRAM_END_OF_TEST,
	SUCCESSFULL_TEST => SDRAM_SUCCESSFULL_TEST,
 	FIRST_FAILED_DATA_WORD => FIRST_FAILED_DATA_WORD,
	FIRST_FAILED_ADDRESS  => FIRST_FAILED_ADDRESS,
	TEST_POINTS => TP_SDRAM_CONTROLLER,

	-- SDRAM IC interface
	SDRAM_A => SDRAM_A_LOCAL,
	SDRAM_DQ => SDRAM_DQ_LOCAL,
	SDRAM_BA0 => SDRAM_BA0_LOCAL,
	SDRAM_BA1 => SDRAM_BA1_LOCAL,
	SDRAM_CAS_N => SDRAM_CAS_N_LOCAL,
	SDRAM_RAS_N => SDRAM_RAS_N_LOCAL, 
	SDRAM_WE_N => SDRAM_WE_N_LOCAL,
	SDRAM_CLK => SDRAM_CLK_LOCAL,
	SDRAM_CKE => SDRAM_CKE_LOCAL, 
	SDRAM_CS_N => SDRAM_CS_N_LOCAL, 
	SDRAM_DQML => SDRAM_DQML_LOCAL,
	SDRAM_DQMH => SDRAM_DQMH_LOCAL
);

SDRAM_A <= SDRAM_A_LOCAL;
SDRAM_DQ <= SDRAM_DQ_LOCAL;
SDRAM_BA0 <= SDRAM_BA0_LOCAL;
SDRAM_BA1 <= SDRAM_BA1_LOCAL;
SDRAM_CAS_N <= SDRAM_CAS_N_LOCAL;
SDRAM_RAS_N <= SDRAM_RAS_N_LOCAL;
SDRAM_WE_N <= SDRAM_WE_N_LOCAL;
SDRAM_CLK <= SDRAM_CLK_LOCAL;
SDRAM_CKE <= SDRAM_CKE_LOCAL;
SDRAM_CS_N <= SDRAM_CS_N_LOCAL;
SDRAM_DQML <= SDRAM_DQML_LOCAL;
SDRAM_DQMH <= SDRAM_DQMH_LOCAL;

--// Comscope --------------
-- Define Comscope traces here 
-- Trace 1
S1_1 <= SDRAM_A_LOCAL(7 downto 0);
S1_1_CLK <= '1';
S1_2 <= "000" & SDRAM_A_LOCAL(12 downto 8);
S1_2_CLK <= '1';
S1_3 <= SDRAM_DQ_LOCAL(7 downto 0);
S1_3_CLK <= '1';
S1_4 <= SDRAM_DQ_LOCAL(15 downto 8);
S1_4_CLK <= '1';

-- Trace 2
S2_1 <= SDRAM_BA0_LOCAL & SDRAM_BA1_LOCAL & SDRAM_CAS_N_LOCAL & SDRAM_RAS_N_LOCAL 
	& SDRAM_WE_N_LOCAL & SDRAM_CKE_LOCAL & SDRAM_DQML_LOCAL & SDRAM_DQMH_LOCAL;
S2_1_CLK <= '1';
S2_2 <= FIRST_FAILED_DATA_WORD(7 downto 0);
S2_2_CLK <= '1';
S2_3 <= FIRST_FAILED_DATA_WORD(15 downto 8);
S2_3_CLK <= '1';
S2_4 <= FIRST_FAILED_ADDRESS(7 downto 0);
S2_4_CLK <= '1';

-- Trigger (1-bit format, undefined)
T1_CLK <= '1';
T1 <= TP_SDRAM_CONTROLLER(8);	-- UPLOAD COMPLETED PULSE
T2_CLK <= '1';
T2 <= CONFIG_CHANGE_PULSE;	-- START TEST

S1_1B_CLK <= S1_1_CLK or REG240(7);	-- Nominal sampling clock or real-time processing clock
S1_2B_CLK <= S1_2_CLK or REG240(7);	-- Nominal sampling clock or real-time processing clock
S1_3B_CLK <= S1_3_CLK or REG240(7);	-- Nominal sampling clock or real-time processing clock
S1_4B_CLK <= S1_4_CLK or REG240(7);	-- Nominal sampling clock or real-time processing clock

S2_1B_CLK <= S2_1_CLK or REG242(7);	-- Nominal sampling clock or real-time processing clock
S2_2B_CLK <= S2_2_CLK or REG242(7);	-- Nominal sampling clock or real-time processing clock
S2_3B_CLK <= S2_3_CLK or REG242(7);	-- Nominal sampling clock or real-time processing clock
S2_4B_CLK <= S2_4_CLK or REG242(7);	-- Nominal sampling clock or real-time processing clock

COMSCOPE_001: COMSCOPE port map(
   CLK => CLK_P,
	ASYNC_RESET => ASYNC_RESET,
	SIGNED_REPRESENTATION_U_SIGNED_N => REG248(6),	-- trigger format signed(1) or unsigned(0)
	REG237 => REG237,
	REG238 => REG238,
	REG239 => REG239,
	REG240 => REG240,
	REG241 => REG241,
	REG242 => REG242,
	REG243 => REG243,
	REG244 => REG244,
	REG245 => REG245,
	REG246 => REG246,
	REG247 => REG247,
	REG248 => REG248,
	REG249 => REG249,
	SIGNAL_1_BIT_1_1 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_1_1 => ZERO,
	SIGNAL_1_BIT_1_2 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_1_2 => ZERO,
	SIGNAL_1_BIT_1_3 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_1_3 => ZERO,
	SIGNAL_1_BIT_1_4 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_1_4 => ZERO,
	SIGNAL_2_BIT_1_1 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_1_1 => ZERO,
	SIGNAL_2_BIT_1_2 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_1_2 => ZERO,
	SIGNAL_2_BIT_1_3 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_1_3 => ZERO,
	SIGNAL_2_BIT_1_4 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_1_4 => ZERO,
	SIGNAL_4_BIT_1_1 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_1_1 => ZERO,
	SIGNAL_4_BIT_1_2 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_1_2 => ZERO,
	SIGNAL_4_BIT_1_3 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_1_3 => ZERO,
	SIGNAL_4_BIT_1_4 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_1_4 => ZERO,
	SIGNAL_8_BIT_1_1 => S1_1,
	SIGNAL_8_BIT_SAMPLE_CLK_1_1 => S1_1B_CLK,
	SIGNAL_8_BIT_1_2 => S1_2,
	SIGNAL_8_BIT_SAMPLE_CLK_1_2 => S1_2B_CLK,
	SIGNAL_8_BIT_1_3 => S1_3,
	SIGNAL_8_BIT_SAMPLE_CLK_1_3 => S1_3B_CLK,
	SIGNAL_8_BIT_1_4 => S1_4,
	SIGNAL_8_BIT_SAMPLE_CLK_1_4 => S1_4B_CLK,
	SIGNAL_16_BIT_1_1 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_1_1 => ZERO,
	SIGNAL_16_BIT_1_2 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_1_2 => ZERO,
	SIGNAL_16_BIT_1_3 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_1_3 => ZERO,
	SIGNAL_16_BIT_1_4 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_1_4 => ZERO,
	SIGNAL_1_BIT_2_1 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_2_1 => ZERO,
	SIGNAL_1_BIT_2_2 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_2_2 => ZERO,
	SIGNAL_1_BIT_2_3 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_2_3 => ZERO,
	SIGNAL_1_BIT_2_4 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_2_4 => ZERO,
	SIGNAL_2_BIT_2_1 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_2_1 => ZERO,
	SIGNAL_2_BIT_2_2 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_2_2 => ZERO,
	SIGNAL_2_BIT_2_3 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_2_3 => ZERO,
	SIGNAL_2_BIT_2_4 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_2_4 => ZERO,
	SIGNAL_4_BIT_2_1 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_2_1 => ZERO,
	SIGNAL_4_BIT_2_2 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_2_2 => ZERO,
	SIGNAL_4_BIT_2_3 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_2_3 => ZERO,
	SIGNAL_4_BIT_2_4 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_2_4 => ZERO,
	SIGNAL_8_BIT_2_1 => S2_1,
	SIGNAL_8_BIT_SAMPLE_CLK_2_1 => S2_1B_CLK,
	SIGNAL_8_BIT_2_2 => S2_2,
	SIGNAL_8_BIT_SAMPLE_CLK_2_2 => S2_2B_CLK,
	SIGNAL_8_BIT_2_3 => S2_3,
	SIGNAL_8_BIT_SAMPLE_CLK_2_3 => S2_3B_CLK,
	SIGNAL_8_BIT_2_4 => S2_4,
	SIGNAL_8_BIT_SAMPLE_CLK_2_4 => S2_4B_CLK,
	SIGNAL_16_BIT_2_1 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_2_1 => ZERO,
	SIGNAL_16_BIT_2_2 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_2_2 => ZERO,
	SIGNAL_16_BIT_2_3 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_2_3 => ZERO,
	SIGNAL_16_BIT_2_4 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_2_4 => ZERO,
	SIGNAL_1_BIT_3_1 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_3_1 => ZERO,
	SIGNAL_1_BIT_3_2 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_3_2 => ZERO,
	SIGNAL_1_BIT_3_3 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_3_3 => ZERO,
	SIGNAL_1_BIT_3_4 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_3_4 => ZERO,
	SIGNAL_2_BIT_3_1 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_3_1 => ZERO,
	SIGNAL_2_BIT_3_2 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_3_2 => ZERO,
	SIGNAL_2_BIT_3_3 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_3_3 => ZERO,
	SIGNAL_2_BIT_3_4 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_3_4 => ZERO,
	SIGNAL_4_BIT_3_1 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_3_1 => ZERO,
	SIGNAL_4_BIT_3_2 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_3_2 => ZERO,
	SIGNAL_4_BIT_3_3 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_3_3 => ZERO,
	SIGNAL_4_BIT_3_4 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_3_4 => ZERO,
	SIGNAL_8_BIT_3_1 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_3_1 => ZERO,
	SIGNAL_8_BIT_3_2 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_3_2 => ZERO,
	SIGNAL_8_BIT_3_3 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_3_3 => ZERO,
	SIGNAL_8_BIT_3_4 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_3_4 => ZERO,
	SIGNAL_16_BIT_3_1 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_3_1 => ZERO,
	SIGNAL_16_BIT_3_2 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_3_2 => ZERO,
	SIGNAL_16_BIT_3_3 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_3_3 => ZERO,
	SIGNAL_16_BIT_3_4 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_3_4 => ZERO,
	SIGNAL_1_BIT_4_1 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_4_1 => ZERO,
	SIGNAL_1_BIT_4_2 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_4_2 => ZERO,
	SIGNAL_1_BIT_4_3 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_4_3 => ZERO,
	SIGNAL_1_BIT_4_4 => ZERO,
	SIGNAL_1_BIT_SAMPLE_CLK_4_4 => ZERO,
	SIGNAL_2_BIT_4_1 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_4_1 => ZERO,
	SIGNAL_2_BIT_4_2 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_4_2 => ZERO,
	SIGNAL_2_BIT_4_3 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_4_3 => ZERO,
	SIGNAL_2_BIT_4_4 => ZERO2,
	SIGNAL_2_BIT_SAMPLE_CLK_4_4 => ZERO,
	SIGNAL_4_BIT_4_1 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_4_1 => ZERO,
	SIGNAL_4_BIT_4_2 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_4_2 => ZERO,
	SIGNAL_4_BIT_4_3 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_4_3 => ZERO,
	SIGNAL_4_BIT_4_4 => ZERO4,
	SIGNAL_4_BIT_SAMPLE_CLK_4_4 => ZERO,
	SIGNAL_8_BIT_4_1 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_4_1 => ZERO,
	SIGNAL_8_BIT_4_2 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_4_2 => ZERO,
	SIGNAL_8_BIT_4_3 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_4_3 => ZERO,
	SIGNAL_8_BIT_4_4 => ZERO8,
	SIGNAL_8_BIT_SAMPLE_CLK_4_4 => ZERO,
	SIGNAL_16_BIT_4_1 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_4_1 => ZERO,
	SIGNAL_16_BIT_4_2 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_4_2 => ZERO,
	SIGNAL_16_BIT_4_3 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_4_3 => ZERO,
	SIGNAL_16_BIT_4_4 => ZERO16,
	SIGNAL_16_BIT_SAMPLE_CLK_4_4 => ZERO,
	TRIGGER_1_BIT_1 => T1,
	TRIGGER_1_BIT_SAMPLE_CLK_1 => T1_CLK,
	TRIGGER_1_BIT_2 => T2,
	TRIGGER_1_BIT_SAMPLE_CLK_2 => T2_CLK,
	TRIGGER_1_BIT_3 => ZERO,
	TRIGGER_1_BIT_SAMPLE_CLK_3 => ZERO,
	TRIGGER_1_BIT_4 => ZERO,
	TRIGGER_1_BIT_SAMPLE_CLK_4 => ZERO,
	TRIGGER_2_BIT_1 => ZERO2,
	TRIGGER_2_BIT_SAMPLE_CLK_1 => ZERO,
	TRIGGER_2_BIT_2 => ZERO2,
	TRIGGER_2_BIT_SAMPLE_CLK_2 => ZERO,
	TRIGGER_2_BIT_3 => ZERO2,
	TRIGGER_2_BIT_SAMPLE_CLK_3 => ZERO,
	TRIGGER_2_BIT_4 => ZERO2,
	TRIGGER_2_BIT_SAMPLE_CLK_4 => ZERO,
	TRIGGER_4_BIT_1 => ZERO4,
	TRIGGER_4_BIT_SAMPLE_CLK_1 => ZERO,
	TRIGGER_4_BIT_2 => ZERO4,
	TRIGGER_4_BIT_SAMPLE_CLK_2 => ZERO,
	TRIGGER_4_BIT_3 => ZERO4,
	TRIGGER_4_BIT_SAMPLE_CLK_3 => ZERO,
	TRIGGER_4_BIT_4 => ZERO4,
	TRIGGER_4_BIT_SAMPLE_CLK_4 => ZERO,
	TRIGGER_8_BIT_1 => ZERO8,
	TRIGGER_8_BIT_SAMPLE_CLK_1 => ZERO,
	TRIGGER_8_BIT_2 => ZERO8,
	TRIGGER_8_BIT_SAMPLE_CLK_2 => ZERO,
	TRIGGER_8_BIT_3 => ZERO8,
	TRIGGER_8_BIT_SAMPLE_CLK_3 => ZERO,
	TRIGGER_8_BIT_4 => ZERO8,
	TRIGGER_8_BIT_SAMPLE_CLK_4 => ZERO,
	TRIGGER_16_BIT_1 => ZERO16,
	TRIGGER_16_BIT_SAMPLE_CLK_1 => ZERO,
	TRIGGER_16_BIT_2 => ZERO16,
	TRIGGER_16_BIT_SAMPLE_CLK_2 => ZERO,
	TRIGGER_16_BIT_3 => ZERO16,
	TRIGGER_16_BIT_SAMPLE_CLK_3 => ZERO,
	TRIGGER_16_BIT_4 => ZERO16,
	TRIGGER_16_BIT_SAMPLE_CLK_4 => ZERO,
	REG250 => REG250,
	REG251 => REG251,
	TRIGGER_REARM_TOGGLE => TRIGGER_REARM_TOGGLE,
	FORCE_TRIGGER_TOGGLE => FORCE_TRIGGER_TOGGLE,
	REG250_READ => REG250_READ,
	START_CAPTURE_TOGGLE => START_CAPTURE_TOGGLE
);

--// INSERT YOUR VHDL CODE HERE -----------

--// TEST POINTS
J1(2) <= SDRAM_END_OF_TEST;
J1(3) <= SDRAM_SUCCESSFULL_TEST;
--J1(2) <= TP_CARDBUS(11);	--TP_IO(0)  '1' when (BUF1A_SIZE = 0) else '0';
--J1(3) <= TP_CARDBUS(12);	--TP_IO(1)  DETECTED_READ_STATUS_CYCLE;
J1(4) <= TP_CARDBUS(13);	--TP_IO(2)  DETECTED_READ_DATA_CYCLE;

J1(5) <= TP_CARDBUS(14);	--TP_IO(3)  RPTR1B(0) --atmel reading
J1(6) <= TP_CARDBUS(15);	--TP_IO(4)  WPTR1B(0) --Host writing
J1(7) <= TP_CARDBUS(16);	--TP_IO(5)  RPTR1A(0) --Host reading
J1(8) <= TP_CARDBUS(17);	--TP_IO(6)  WPTR1A(0) --atmel writing

J1(9) <= TP_CARDBUS(5);	--MEM_DATA_OUT_READY   
J1(11) <= TP_CARDBUS(6);	--CONFIG_DATA_OUT_READY   
J1(12) <= TP_CARDBUS(7);	--IO_DATA_OUT_READY   

J1(13) <= TP_CARDBUS(1);	   
J1(14) <= TP_CARDBUS(2);
J1(15) <= TP_CARDBUS(3);
J1(16) <= TP_CARDBUS(4);

J1(17) <= TP_CARDBUS(8);
J1(18) <= TP_CARDBUS(9);	
J1(19) <= TP_CARDBUS(10);	

J1(21) <= TP_CARDBUS(14);	
J1(22) <= TP_CARDBUS(15);	
J1(23) <= TP_CARDBUS(16);	
J1(24) <= TP_CARDBUS(17);	
J1(25) <= TP_CARDBUS(18);	
J1(26) <= TP_CARDBUS(19);	
J1(27) <= TP_CARDBUS(20);	
J1(28) <= TP_CARDBUS(21);	
J1(29) <= TP_CARDBUS(22);	

J1(31) <= TP_CARDBUS(23);	
J1(32) <= TP_CARDBUS(24);
J1(33) <= TP_CARDBUS(25); 	
J1(34) <= TP_CARDBUS(26);

--// MONITORING & CONTROL -------------
--// Serial interfaces are used for module-to-module communication.
-- Do not change this section unless indicated in the comments.
-- REG255 reserved for reading 4 serial port inputs
-- These signals are pulled high (to mimic stop bit).
REG255(0) <= RX_L	;	-- port 1 left = ComBlock 40-pin interface
REG255(1) <= '1'	;	-- port 2 bottom n/a for COM-1300
REG255(2) <= '1'	;	-- port 3 right N/A for COM-1300
--REG255(3) <= '1'; 	-- Future use. Connect to PCMCIA/CardBus port, byte ready #  
REG255(3) <= DATA2A_BUFFER_EMPTY; 	-- PCMCIA/CardBus port, byte ready #  
	-- indicates AVAILABILITY of 8-bit byte from PCMCIA. Not actual data.
	-- When low, uC must read byte from PCMCIA
REG255(7 downto 4) <= "0000";

-- Reclock TX_PCMCIA_TOGGLE
RECLOCK_TX_PCMCIA_TOGGLE: process(ASYNC_RESET, CLK_P,TX_PCMCIA_TOGGLE)
begin
	if(ASYNC_RESET = '1') then
		TX_PCMCIA_TOGGLE_D <= '0';
		TX_PCMCIA_TOGGLE_D2 <= '0';
		DATA2B_SAMPLE_CLK <= '0';
	elsif rising_edge(CLK_P) then
		TX_PCMCIA_TOGGLE_D <= TX_PCMCIA_TOGGLE;
		TX_PCMCIA_TOGGLE_D2 <= TX_PCMCIA_TOGGLE_D;
		if(TX_PCMCIA_TOGGLE_D /= TX_PCMCIA_TOGGLE_D2) then
			DATA2B_SAMPLE_CLK <= '1';
		else
			DATA2B_SAMPLE_CLK <= '0';
		end if;
	end if;
end process;


--// Atmel microcontroller interface
-- Used for monitoring and control.
-- address latch
UC_ADDR_001: process(ASYNC_RESET, UC_ALE, UC_FLASH_CSN, UC_AD)
begin
	if(ASYNC_RESET = '1') then
		UC_ADDRESS <= (others => '0');
	elsif falling_edge(UC_ALE) then
		if(UC_FLASH_CSN = '1') then
			UC_ADDRESS <= UC_AD;
	  	end if;
  	end if;
end process;

RECLOCK_ADDR_D: process(ASYNC_RESET, CLK_P, UC_ADDRESS)
begin
	if(ASYNC_RESET = '1') then
		UC_ADDR_D <= (others =>'0');
		UC_ADDR_D2 <= (others =>'0');
	elsif rising_edge(CLK_P) then
		UC_ADDR_D <= UC_ADDRESS;
		UC_ADDR_D2 <= UC_ADDR_D;
	end if;
end process;


RECLOCK_RDN_D: process(ASYNC_RESET, CLK_P, UC_RDN)
begin
	if(ASYNC_RESET = '1') then
		UC_RDN_D <= '0';
		UC_RDN_D2 <= '0';
		DATA2A_SAMPLE_CLK_REQ <= '0';
	elsif rising_edge(CLK_P) then
		UC_RDN_D <= UC_RDN;
		UC_RDN_D2 <= UC_RDN_D;
		if (UC_RDN_D = '1') and (UC_RDN_D2 = '0') and (UC_ADDR_D2 = 254)then
			DATA2A_SAMPLE_CLK_REQ <= '1';
		else
			DATA2A_SAMPLE_CLK_REQ <= '0';
		end if;
	end if;
end process;

-- read
UC_READ_001: process(UC_FLASH_CSN, UC_RDN, UC_ADDRESS, REG15, REG16, 
	REG17, REG18, REG19, REG20, REG250, REG251, REG255, DATA2A)
begin
	if(UC_FLASH_CSN = '1') and (UC_RDN = '0') then
		if(UC_ADDRESS(7 downto 2) = "111111") then
			if(UC_ADDRESS(1 downto 0) = "11") then
				UC_AD <= REG255;			-- reg 255. Async serial from 3 connectors
			elsif(UC_ADDRESS(1 downto 0) = "10") then
				UC_AD <= DATA2A;		-- reg 254 = 8-bit data from PCMCIA
			elsif(UC_ADDRESS(1 downto 0) = "01") then
				UC_AD <= REVISION;	-- reg 253 = fpga revision
			elsif(UC_ADDRESS(1 downto 0) = "00") then
				UC_AD <= OPTION;		-- reg 252 = fpga option
			else
				UC_AD <= "ZZZZZZZZ";
			end if;
		elsif(UC_ADDRESS= 15) then
			UC_AD <= REG15;	
		elsif(UC_ADDRESS= 16) then
			UC_AD <= REG16;
		elsif(UC_ADDRESS= 17) then
			UC_AD <= REG17;
		elsif(UC_ADDRESS= 18) then
			UC_AD <= REG18;
		elsif(UC_ADDRESS= 19) then
			UC_AD <= REG19;
		elsif(UC_ADDRESS= 20) then
			UC_AD <= REG20;
		elsif (UC_ADDRESS = 251) then
			UC_AD <= REG251;		-- reg 251 =comscope  status
		elsif (UC_ADDRESS = 250) then
			UC_AD <= REG250;		-- reg 250 = comscope data byte
		else
			UC_AD <= "ZZZZZZZZ";
		end if;
	else
		UC_AD <= "ZZZZZZZZ";
 	end if;
end process;

-- detect when address 250 is being read
REG250_READ <= '1' when (UC_FLASH_CSN = '1') and (UC_RDN = '0') and (UC_ADDRESS = 250) else '0';

-- write. 
-- Registers 0 through 15 are control registers.
UC_WRITE_001: process(ASYNC_RESET, UC_FLASH_CSN, UC_WRN, UC_ADDRESS, UC_AD)
begin
	if(ASYNC_RESET = '1') then
		-- CAREFUL!!!!!! 
		-- when the external clock comes from a bigger FPGA, the ASYNC_RESET
		-- may arrive here AFTER the Atmel uC has configured the registers.
		-- We should avoid resetting the registers.
		TX_L <= '1';	-- stop bit
	 elsif falling_edge(UC_WRN) then

		if (UC_ADDRESS(7 downto 4) = "0000") then
			if (UC_ADDRESS(3 downto 0) = "0000") then
				REG0 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0001") then
				REG1 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0010") then
				REG2 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0011") then
				REG3 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0100") then
				REG4 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0101") then
				REG5 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0110") then
				REG6 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "0111") then
				REG7 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1000") then
				REG8 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1001") then
				REG9 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1010") then
				REG10 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1011") then
				REG11 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1100") then
				REG12 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1101") then
				REG13 <= UC_AD;
			end if;
			if (UC_ADDRESS(3 downto 0) = "1110") then
				REG14 <= UC_AD;
				CONFIG_CHANGE_TOGGLE <= not CONFIG_CHANGE_TOGGLE;	
				-- Configuration change toggles upon writing the last control register
			end if;
		end if;
		if (UC_ADDRESS = 254) then
			-- REG254 write reserved for output serial (asynchronous serial format)
			TX_L <= UC_AD(0);
		end if;
		if (UC_ADDRESS = 255) then
			-- REG255 write reserved for output serial (8-bit parallel format)
			DATA2B <= UC_AD;
			TX_PCMCIA_TOGGLE <= not TX_PCMCIA_TOGGLE;
		end if;
	end if;
end process;

--// reserved COMSCOPE
UC_WRITE_002: process(ASYNC_RESET, UC_FLASH_CSN, UC_WRN, UC_ADDRESS, UC_AD, 
	FORCE_TRIGGER_TOGGLE, TRIGGER_REARM_TOGGLE, START_CAPTURE_TOGGLE)
begin
	if(ASYNC_RESET = '1') then
		-- Do not enter default values here. Any default value entered here will be
		-- overwritten by the microprocessor, typically within 10ms after the FPGA is configured.
	elsif falling_edge(UC_WRN) then
		if(UC_FLASH_CSN = '1') then
			-- Reserved for ComScope			
			if (UC_ADDRESS = 237) then
				REG237 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 238) then
				REG238 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 239) then
				REG239 <= UC_AD;
			end if;
			if (UC_ADDRESS = 240) then
				REG240 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 241) then
				REG241 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 242) then
				REG242 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 243) then
				REG243 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 244) then
				REG244 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 245) then
				REG245 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 246) then
				REG246 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 247) then
				REG247 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 248) then
				REG248 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 249) then
				REG249 <= UC_AD;	
			end if;
			if (UC_ADDRESS = 250) then 
				-- detect one-shot force trigger	
				if(UC_AD(0) = '1') then	
					FORCE_TRIGGER_TOGGLE <= not(FORCE_TRIGGER_TOGGLE);
				end if;	
				-- detect one-shot re-arm	
				if(UC_AD(1) = '1') then	
					TRIGGER_REARM_TOGGLE <= not(TRIGGER_REARM_TOGGLE);
				end if;	
				-- start capturing again
				if(UC_AD(2) = '1') then	
					START_CAPTURE_TOGGLE <= not (START_CAPTURE_TOGGLE);
				end if;	
			end if;
		end if;
	end if;
end process;

-- Reclock CONFIG_CHANGE_TOGGLE to be synchronous with processing clock CLK_P
RECLOCK_002: process(ASYNC_RESET, CLK_P)
begin
	if(ASYNC_RESET = '1') then
		CONFIG_CHANGE_TOGGLE_D <= '0';
		CONFIG_CHANGE_TOGGLE_D2 <= '0';
		CONFIG_CHANGE_PULSE <= '0';
	elsif rising_edge(CLK_P) then
		CONFIG_CHANGE_TOGGLE_D <= CONFIG_CHANGE_TOGGLE;
		CONFIG_CHANGE_TOGGLE_D2 <= CONFIG_CHANGE_TOGGLE_D;
		if(CONFIG_CHANGE_TOGGLE_D /= CONFIG_CHANGE_TOGGLE_D2) then
			CONFIG_CHANGE_PULSE <= '1';
		else
			CONFIG_CHANGE_PULSE <= '0';
		end if;
	end if;
end process;


end Behavioral;
