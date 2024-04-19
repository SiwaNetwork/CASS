-------------------------------------------------------------
--	Filename:  PCMCIA.VHD
--   Authors: 
--		Adam Kwiatkowski with Alain Zarembowitch / MSS
--	Version: Rev 1
-- Last modified: 12/21/04
-- Inheritance: 	PCMCIA.VHD Rev 0
--
-- description:  PCMCIA interface. One side connects directly to the 
-- hardware, the other side to user-supplied streams via dual-port 
-- elastic buffers (one in each direction). Also inserts the CIS
-- when asked. Use only when generating the Option A (PCMCIA) project.
-- Support for 8-bit I/O transfers and 8/16-bits memory transfers.
-- No interrupt,DMA support.
-- Support for three virtual streams:
--	  CIS can be seen as an internal data source accessed by 8-bit attribute memory read transfer
--     IO transfers are transferred by the PCMCIA HBA by means of 8-bit I/O reads and writes 
--		Addresses decoded 0,2,4,6. See IORW.VHD component description for details.
--     Memory transfers are transferred by the PCMCIA HBA by means of 16-bit Memory reads and writes 
--		Addresses decoded 0,2,4,6. See MEMORY.VHD component description for details.

-- Without violating the concept of abstraction, the intent is to use Stream1 
---------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PCMCIA is
    port ( 

       --// Clocks, reset
	CLK_P: in std_logic;
		-- Main processing or I/O clock used outside of this component.
		-- All application interface signals are synchronous with CLK_P
		-- Key assumptions about speed: CLK_P > 8 MHz
	SYNC_RESET: in std_logic;
		-- synchronous reset at power up

    	--// Host bus adapter interface:
		-- Note: Pull-ups are defined in the constraint file.
	   PC_CARD_ADDR: in std_logic_vector(25 downto 0);
	      -- Address
	   PC_CARD_DATA: inout std_logic_vector(15 downto 0);
	      -- Data
	   PC_CARD_WP_IOIS16_N: out std_logic;
	      -- WP          During memory only interface
	      -- IOIS16#     During memory or I/O interface
			-- PULL-UP
	   PC_CARD_RESERVED_INPACK_N: out std_logic;
	      -- RESERVED    During memory only interface
	      -- INPACK#     During memory or I/O interface
	   PC_CARD_BVD2_SPKR_N: out std_logic;
	      -- BVD2        During memory only interface
	      -- SPKR#       During memory or I/O interface
			-- PULL-UP
	   PC_CARD_BVD1_STSCHG_N: out std_logic;
	      -- BVD1        During memory only interface
	      -- STSCHG#     During memory or I/O interface
			-- PULL-UP
	   PC_CARD_RESERVED_IORD_N: in std_logic;
	      -- RESERVED    During memory only interface
	      -- IORD#       During memory or I/O interface
	   PC_CARD_RESERVED_IOWR_N: in std_logic;
	      -- RESERVED    During memory only interface
	      -- IOWR#       During memory or I/O interface
	   PC_CARD_CE1_N: in std_logic;
	      -- CE1#
	   --PC_CARD_CE2_N: in std_logic;
	      -- CE2#
	   PC_CARD_OE_N: in std_logic;
	      -- OE#
	   PC_CARD_WE_N_IN: in std_logic;
	      -- WE#
	   PC_CARD_REG_N: in std_logic;
	      -- REG#
	   PC_CARD_WAIT_N: out std_logic;
	      -- WAIT#. Atmel uC to drive WAIT# active low while the FPGA is being configured.
	   PC_CARD_READY_IREQ_N: out std_logic;
	      -- READY       During memory only interface
	      -- IREQ#       During memory or I/O interface
			-- PULL-UP
	   PC_CARD_RESET_UC_MOSI: in std_logic;
	      -- RESET       During normal microcontroller operation
	      -- UC_MOSI     During microcontroller programming

   
	   --// user interfaces
		--// Stream1. 16-bit Memory read/write transactions
		-- Synchronous with CLK_P clock
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

	   --// user interfaces
		--// Stream2. 8-bit I/O read/write transactions at I/O address 0
		-- Synchronous with CLK_P clock
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
		-- Test points are under the shield. 6 at the edge connector.
		TEST_POINTS: out std_logic_vector(6 downto 1)
			);
end entity;

architecture Behavioral of PCMCIA is
--------------------------------------------------------
--      COMPONENTS
--------------------------------------------------------
component CIS_P is port (
   --// Host bus adapter interface:
   PC_CARD_CE1_N: in std_logic;
      -- CE1#
   PC_CARD_OE_N: in std_logic;
      -- OE#
   PC_CARD_REG_N: in std_logic;
      -- REG#
   CIS_ADDR: in std_logic_vector(11 downto 0);
      -- Address
   CIS_DATA: out std_logic_vector(7 downto 0);
      -- Data
   CIS_DATA_READY: out std_logic
		-- high when CIS_DATA is being read. low otherwise
   );
end component;


component MEMORY_P is	port ( 

    		--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		SYNC_RESET: in std_logic;
			-- synchronous reset at power up
			
	    --// Host bus adapter interface:
	   PC_CARD_ADDR: in std_logic_vector(5 downto 0);
	      -- Address
			-- Valid Memory range?
			-- This component only decodes the lower 8 address bits (0-255)

	   PC_CARD_DATA_IN: in std_logic_vector(15 downto 0);
	   PC_CARD_DATA_OUT: out std_logic_vector(15 downto 0);
	   PC_CARD_DATA_READY: out std_logic;
	   	 -- PC_CARD_DATA_READY indicates that this component actively drives
		 -- the PCMCIA data bus (during data or status read).

	   PC_CARD_CE1_N: in std_logic;
	      -- CE1#
	   --PC_CARD_CE2_N: in std_logic;
	      -- CE2#	   
	   PC_CARD_OE_N: in std_logic;
	      -- OE#
	   PC_CARD_WE_N_IN: in std_logic;
	      -- WE#
	   PC_CARD_REG_N: in std_logic;
	      -- REG#

	   --// control
	   PC_CARD_ADDR_REF: in std_logic_vector(5 downto 0);
	   	-- base address to be decoded during memory read/write cycles

	   --// user interfaces
		--// Stream1. 16-bit Memory read/write transactions
		-- Synchronous with CLK_P clock
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
		DATA1_IN_SAMPLE_CLK_REQ: out std_logic
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)
			);
end component;


component IORW_P is port (

    		--// Clocks, reset
		CLK_P: in std_logic;
			-- Main processing or I/O clock used outside of this component.
			-- All application interface signals are synchronous with CLK_P
			-- Key assumptions about speed: CLK_P > 8 MHz
		SYNC_RESET: in std_logic;
			-- synchronous reset at power up
			
	    --// Host bus adapter interface:
	   PC_CARD_ADDR: in std_logic_vector(5 downto 0);
	      -- Address
			-- Valid Memory range?
			-- This component only decodes the lower 8 address bits (0-255)

	   PC_CARD_DATA_IN: in std_logic_vector(7 downto 0);
	   PC_CARD_DATA_OUT: out std_logic_vector(7 downto 0);
	   PC_CARD_DATA_READY: out std_logic;
	   	 -- PC_CARD_VALID_IOR indicates that this component actively drives
		 -- the PCMCIA data bus (during data or status read).
		
		--/ IO Interface
	   PC_CARD_RESERVED_IORD_N: in std_logic;
	      -- RESERVED    During memory only interface
	      -- IORD#       During memory or I/O interface
	   PC_CARD_RESERVED_IOWR_N: in std_logic;
	      -- RESERVED    During memory only interface
	      -- IOWR#       During memory or I/O interface
			-- PULL-UP

	   PC_CARD_CE1_N: in std_logic;
	      -- CE1#
	   --PC_CARD_CE2_N: in std_logic;
	      -- CE2#
	   --// control
	   PC_CARD_ADDR_REF: in std_logic_vector(5 downto 0);
	   	-- base address to be decoded during memory read/write cycles

	   --// user interfaces
		--// Stream1. 8-bit I/O read/write transactions at I/O address 0
		-- Synchronous with CLK_P clock
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
		DATA1_IN_SAMPLE_CLK_REQ: out std_logic
			-- requests data when the input elastic buffer is less than half full. 
			-- (flow control)
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

--// CIS
signal CIS_DATA: std_logic_vector(7 downto 0);
signal CIS_DATA_READY: std_logic;

--// MEMORY
signal MEMORY_DATA: std_logic_vector(15 downto 0);
signal MEMORY_DATA_READY: std_logic;

--// I/O RW
signal IORW_DATA: std_logic_vector(7 downto 0);
signal IORW_DATA_READY: std_logic;

--// PCMCIA internal signals
signal PC_CARD_MEM_ADDR_REF: std_logic_vector(5 downto 0);
 	-- base address to be decoded during memory read/write cycles
signal PC_CARD_IO_ADDR_REF: std_logic_vector(5 downto 0);
 	-- base address to be decoded during IO read/write cycles


--------------------------------------------------------
--      IMPLEMENTATION
--------------------------------------------------------
begin
--------------------------------------------------------------------------
-- CIS
--------------------------------------------------------------------------
-- CIS can be seen as an Internal data source
-- Reply with CIS information stored in ROM when asked
CIS_P_001: CIS_P port map (
	--// input
	PC_CARD_CE1_N => PC_CARD_CE1_N,
	PC_CARD_OE_N => PC_CARD_OE_N,
	PC_CARD_REG_N => PC_CARD_REG_N, 
	CIS_ADDR => PC_CARD_ADDR(11 downto 0),
	--// output
	CIS_DATA => CIS_DATA,
	CIS_DATA_READY => CIS_DATA_READY	-- to make it tri-state
);

--------------------------------------------------------------------------
-- MEMORY
--------------------------------------------------------------------------
-- MEMORY 
-- Decoding base address
PC_CARD_MEM_ADDR_REF <= (others => '0');

MEMORY_P_001: MEMORY_P port map (
	CLK_P => CLK_P,
	SYNC_RESET => SYNC_RESET,
	--// bus
	PC_CARD_CE1_N => PC_CARD_CE1_N,
--	PC_CARD_CE2_N => PC_CARD_CE2_N,
	PC_CARD_OE_N => PC_CARD_OE_N,
	PC_CARD_WE_N_IN => PC_CARD_WE_N_IN,
	PC_CARD_REG_N => PC_CARD_REG_N, 
	PC_CARD_ADDR => PC_CARD_ADDR(5 downto 0),
	PC_CARD_DATA_IN => PC_CARD_DATA,
	PC_CARD_DATA_OUT => MEMORY_DATA,
	PC_CARD_DATA_READY => MEMORY_DATA_READY,
	--// control
	PC_CARD_ADDR_REF => PC_CARD_MEM_ADDR_REF,
	--// user
	DATA1_IN_SAMPLE_CLK => DATA1_IN_SAMPLE_CLK,
	DATA1_IN => DATA1_IN,
	DATA1_OUT => DATA1_OUT,
	DATA1_OUT_SAMPLE_CLK_REQ => DATA1_OUT_SAMPLE_CLK_REQ,
	DATA1_OUT_SAMPLE_CLK => DATA1_OUT_SAMPLE_CLK,
	DATA1_OUT_BUFFER_EMPTY => DATA1_OUT_BUFFER_EMPTY,
	DATA1_IN_SAMPLE_CLK_REQ => DATA1_IN_SAMPLE_CLK_REQ
);

--------------------------------------------------------------------------
-- I/O RW
--------------------------------------------------------------------------
-- I/O Read/Write
-- Decoding base address
PC_CARD_IO_ADDR_REF <= (others => '0');

IORW_P_001: IORW_P port map (
	CLK_P => CLK_P,
	SYNC_RESET => SYNC_RESET,
	--// bus
	PC_CARD_CE1_N => PC_CARD_CE1_N,
--	PC_CARD_CE2_N => PC_CARD_CE2_N,
	PC_CARD_RESERVED_IORD_N => PC_CARD_RESERVED_IORD_N,
   	PC_CARD_RESERVED_IOWR_N => PC_CARD_RESERVED_IOWR_N,
	PC_CARD_ADDR => PC_CARD_ADDR(5 downto 0),
	PC_CARD_DATA_IN => PC_CARD_DATA(7 downto 0),
	PC_CARD_DATA_OUT => IORW_DATA,
	PC_CARD_DATA_READY => IORW_DATA_READY,
	--// control
	PC_CARD_ADDR_REF => PC_CARD_IO_ADDR_REF,
	--// user
	DATA1_IN => DATA2_IN,
	DATA1_IN_SAMPLE_CLK => DATA2_IN_SAMPLE_CLK,
	DATA1_OUT_SAMPLE_CLK_REQ => DATA2_OUT_SAMPLE_CLK_REQ,
	DATA1_OUT => DATA2_OUT,
	DATA1_OUT_SAMPLE_CLK => DATA2_OUT_SAMPLE_CLK,
	DATA1_OUT_BUFFER_EMPTY => DATA2_OUT_BUFFER_EMPTY,
	DATA1_IN_SAMPLE_CLK_REQ => DATA2_IN_SAMPLE_CLK_REQ
);

--------------------------------------------------------------------------
-- PCMCIA BUS INTERFACE OUTPUT SIGNALS
--------------------------------------------------------------------------
--// Output multiplexer
-- From one of five sources: CIS, Stream1 data, Stream1 flow control, 
-- Stream2 data, Stream2 flow control
OUTPUT_DATA_MUX_OO1: process(CIS_DATA_READY, MEMORY_DATA_READY, IORW_DATA_READY, CIS_DATA, MEMORY_DATA, IORW_DATA)
begin
	if (CIS_DATA_READY = '1') then
		--CIS data out
		PC_CARD_DATA(7 downto 0) <= CIS_DATA;
	elsif(MEMORY_DATA_READY = '1') then
		-- Memory Data Out
		PC_CARD_DATA <= MEMORY_DATA;
	elsif(IORW_DATA_READY = '1') then
		-- I/O Data Out
		PC_CARD_DATA(7 downto 0) <= IORW_DATA;
		PC_CARD_DATA(15 downto 8) <= (others => 'Z');
   	else
		PC_CARD_DATA <= (others => 'Z');
  	end if;
end process;

--------------------------------------------------------------------------
-- ASSIGN THE PC CARD PINS
--------------------------------------------------------------------------

-- all I/O transfers are 8-bit only. Active only when a valid IOR at a decoded
-- address is detected. Otherwise, high-impedance.
PC_CARD_WP_IOIS16_N <= '1' when (IORW_DATA_READY = '1') else 'Z'; 
							  -- Valid IORead  (8-bit I/O read to a decoded address)
							  -- Pulled high in constraint file (i.e. the memory range is read only)

PC_CARD_READY_IREQ_N <= 'Z';	-- No interrupt support. 
								-- Pulled high in constraint file

PC_CARD_RESERVED_INPACK_N <= '0' when (IORW_DATA_READY = '1') else 'Z';
								-- Input port acknowledge. Asserted during I/O read transfers from a PC
								-- when it recognizes the address. Valid I/O read address 0, 2 & 6.

PC_CARD_BVD2_SPKR_N <= '1' when (IORW_DATA_READY = '1') else 'Z';
                       -- Speakers not in use	                    
							  -- Pulled high in constraint file (i.e. the batteries are good)

PC_CARD_BVD1_STSCHG_N <= '1' when (IORW_DATA_READY = '1') else 'Z';
                         -- Pin Replacement Register is not in use, thus don't use this pin
								 -- Pulled high in constraint file (i.e. the batteries are good)

-- We will always meet the timing, thus tie the WAIT# signal high.
PC_CARD_WAIT_N <= '1';


end behavioral;