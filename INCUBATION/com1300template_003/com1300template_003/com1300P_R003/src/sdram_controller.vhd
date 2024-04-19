--------------------------------------------------------------------------
-- MSS copyright 1999-2004
-- Filename: SDRAM_CONTROLLER.VHD
-- Authors: 
--		Adam Kwiatkowski w/ Alain Zarembowitch / MSS
--	Version: Rev 1
-- Last modified: 1/18/05
-- Inheritance: 	SDRAM_CONTROLLER.VHD rev0
--
-- description:  256Mb SDRAM interface
-- Key assumption: CLK is 40 MHz. Otherwise change REFRESH_COUNTER and 
-- COUNTER_200_uS timer value, reliable at 40 but tested successfully at 50MHz
---------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SDRAM_CONTROLLER is port (
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
end entity;

architecture behavior of SDRAM_CONTROLLER is
-----------------------------------------------------------------
-- COMPONENTS
-----------------------------------------------------------------

-----------------------------------------------------------------
-- SIGNALS
-----------------------------------------------------------------
-- Suffix _D indicates a one CLK delayed version of the net with the same name
-- Suffix _E indicates an extended precision version of the net with the same name
-- Suffix _R indicates a reduced precision version of the net with the same name
-- Suffix _N indicates an inverted version of the net with the same name
-- Suffix _LOCAL indicates an exact version of the (output signal) net with the same name

signal WRITE_POINTER: std_logic_vector(23 downto 0);
   -- The addressing is as follows:
   -- bits 23-22:    00 - Device bank 0
   --                01 - Device bank 1
   --                10 - Device bank 2
   --                11 - Device bank 3
   -- bits 21-9:     Row address
   -- bits 8-0:      Column address
signal READ_POINTER: std_logic_vector(23 downto 0);
   -- The addressing is as follows:
   -- bits 23-22:    00 - Device bank 0
   --                01 - Device bank 1
   --                10 - Device bank 2
   --                11 - Device bank 3
   -- bits 21-9:     Row address
   -- bits 8-0:      Column address
signal GENERAL_PURPOSE_4_BIT_COUNTER: std_logic_vector(3 downto 0);
   -- This is a general purpose counter that will be used to meet timing
   -- requirements in the different states. It is the prior state's responsibility
   -- to reset the counter so that the next state using the counter knows it is
   -- always reset.
signal COUNTER_200_uS: std_logic_vector(13 downto 0);
   -- This counter creates a delay of 8200 > 8000 clock cycles after power up.
   -- A reference clock of 40 MHz is assumed. 1 clock period = 25 ns.
   -- To count up to 8000 takes 8000 x 25 ns = 200,000 ns = 200 microseconds.

signal REFRESH_COUNTER: std_logic_vector(9 downto 0);
   -- To meet the refresh requirements, this code will perform a distributed AUTO
   -- REFRESH every 15.625 us. Assuming the reference clock is running at 40 MHz
   -- this means that our clock cycle is 25 ns. Thus, we need a counter that counts
   -- to 15.625 us / 25 ns = 625. However, we could just have started a READ or a
   -- WRITE when it is time to do the refresh so we must allow time to finish the
   -- current operation first. Therefore, let's only count to 600.


-- STATE MACHINE VARIABLES
type STATETYPE is (INI_WAIT_FOR_200_uS, INI_PRECHARGE, INI_IN_IDLE_STATE,
                   MODE_REGISTER_PROGRAM, MODE_REGISTER_PROGRAM_IN_PROGRESS,
                   IDLE, WRITING, READING, APPLY_AN_AUTO_REFRESH);
signal STATE: STATETYPE;

-- COMMAND TYPE VARIABLES
type OPERATION_TYPE is (NOP_B, PRECHARGE_B, LOAD_MODE_REGISTER_B, ACTIVE, WRITE,
                        READ, AUTO_REFRESH_B);

signal OPERATION: OPERATION_TYPE;

signal START_UPLOAD_PULSE_REMEMBERED: std_logic;
signal START_SINGLE_DOWNLOAD_PULSE_REMEMBERED: std_logic;
signal START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED: std_logic;
signal STOP_OPERATION_REMEMBERED: std_logic;

signal UPLOAD_FLAG: std_logic;
signal SINGLE_DOWNLOAD_FLAG: std_logic;
signal CONTINUOUS_DOWNLOAD_FLAG: std_logic;
--signal SDRAM_DQ_D: std_logic_vector(15 downto 0);

signal STATE_IN_BITS: std_logic_vector(1 downto 0);
-----------------------------------------------------------------
-- IMPLEMENTATION
-----------------------------------------------------------------
begin

-----------------------------------------------------------------
-- DEFINE THE DIFFERENT OPERATIONS
-----------------------------------------------------------------
SDRAM_CS_N <= '0';

SDRAM_RAS_N <= '1' when OPERATION = NOP_B else
               '0' when OPERATION = ACTIVE else
               '1' when OPERATION = READ else
               '1' when OPERATION = WRITE else
               '0' when OPERATION = PRECHARGE_B else
               '0' when OPERATION = AUTO_REFRESH_B else
               '0' when OPERATION = LOAD_MODE_REGISTER_B else '0';


SDRAM_CAS_N <= '1' when OPERATION = NOP_B else
               '1' when OPERATION = ACTIVE else
               '0' when OPERATION = READ else
               '0' when OPERATION = WRITE else
               '1' when OPERATION = PRECHARGE_B else
               '0' when OPERATION = AUTO_REFRESH_B else
               '0' when OPERATION = LOAD_MODE_REGISTER_B else '0';


SDRAM_WE_N <= '1' when OPERATION = NOP_B else
              '1' when OPERATION = ACTIVE else
              '1' when OPERATION = READ else
              '0' when OPERATION = WRITE else
              '0' when OPERATION = PRECHARGE_B else
              '1' when OPERATION = AUTO_REFRESH_B else
              '0' when OPERATION = LOAD_MODE_REGISTER_B else '0';

-----------------------------------------------------------------
-- ACTUAL BEGINNING OF CODE
-----------------------------------------------------------------
-- inverted clock for better timing.
SDRAM_CLK <= not CLK when POWER_DOWN = '0' else '0';
SDRAM_CKE <= '1';

-- It's always wise to reclock signals coming from outside the FPGA before
-- using them. Note: the SDRAM uses our inverted clock; therefore, reclock
-- using the inverted clock.
--RECLOCK_INPUT_DATA_001: process(ASYNC_RESET, CLK)
--begin
--   if (ASYNC_RESET = '1') then
--      SDRAM_DQ_D <= (others => '0');
--   elsif falling_edge(CLK) then
--      SDRAM_DQ_D <= SDRAM_DQ;
--   end if;
--end process;


-- Reclock the falling edge reclocked data so that we get a rising
-- edge synchronous version of the data.
RECLOCK_INPUT_DATA_002: process(ASYNC_RESET, CLK)
begin
   if (ASYNC_RESET = '1') then
      DATA_OUT <= (others => '0');
   elsif rising_edge(CLK) then
      DATA_OUT <= SDRAM_DQ;
   end if;
end process;

SDRAM_DQML <= '0';
SDRAM_DQMH <= '0';

READ_POINTER_OUT <= READ_POINTER;
WRITE_POINTER_OUT <= WRITE_POINTER;
SDRAM_DOWNLOAD_IN_PROGRESS <= SINGLE_DOWNLOAD_FLAG or CONTINUOUS_DOWNLOAD_FLAG;
SDRAM_UPLOAD_IN_PROGRESS <= UPLOAD_FLAG;


-- This is a test point section (states in bits).
CONVERT_STATES_TO_BITS_001: process(ASYNC_RESET, CLK)
begin
   if (ASYNC_RESET = '1') then
      STATE_IN_BITS <= (others => '0');
   elsif rising_edge(CLK) then
      if (STATE = IDLE) then
         STATE_IN_BITS <= "01";
      elsif (STATE = WRITING) then
         STATE_IN_BITS <= "10";
      elsif (STATE = READING) then
         STATE_IN_BITS <= "11";
      else
         STATE_IN_BITS <= "00";
      end if;
   end if;
end process;


-- Since we could be doing an autorefresh when we get the start and stop
-- pulses, we must have a dedicated process to remember these signals until
-- they have been noticed by the actual SDRAM controller process. As soon
-- as we have an indication that they have been noticed, we must deassert
-- the remembered signals.
DETECT_START_AND_STOP_PULSES_001: process(ASYNC_RESET, CLK)
begin
   if (ASYNC_RESET = '1') then
      START_UPLOAD_PULSE_REMEMBERED <= '0';
      START_SINGLE_DOWNLOAD_PULSE_REMEMBERED <= '0';
      START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED <= '0';
      STOP_OPERATION_REMEMBERED <= '0';
   elsif rising_edge(CLK) then

      if (STOP_CURRENT_OPERATION_PULSE = '1') then
      -- If we detect a STOP_OPERATION_REMEMBERED, then raise the STOP_OPERATION_REMEMBERED flag.
         STOP_OPERATION_REMEMBERED <= '1';
      elsif (START_UPLOAD_PULSE = '1') or (START_SINGLE_DOWNLOAD_PULSE = '1') or
            (START_CONTINUOUS_DOWNLOAD_PULSE = '1') then
      -- If an operation start pulse is found, the deassert the STOP_OPERATION_REMEMBERED
      -- signal because it could be high.
         STOP_OPERATION_REMEMBERED <= '0';
      elsif (UPLOAD_FLAG = '0') and (SINGLE_DOWNLOAD_FLAG = '0') and
            (CONTINUOUS_DOWNLOAD_FLAG = '0') then
      -- When the state machine has pulled the UPLOAD_FLAG, SINGLE_DOWNLOAD_FLAG and the
      -- CONTINUOUS_DOWNLOAD_FLAG low, then we know that it has detected the
      -- STOP_OPERATION_REMEMBERED signal and we can pull STOP_OPERATION_REMEMBERED
      -- low.
         STOP_OPERATION_REMEMBERED <= '0';
      end if;


      if (STOP_CURRENT_OPERATION_PULSE = '1') then
      -- Deassert the START_UPLOAD_PULSE_REMEMBERED in case it was high,
      -- but not yet detected.
         START_UPLOAD_PULSE_REMEMBERED <= '0';
      elsif (START_UPLOAD_PULSE = '1') then
      -- If we detect a START_UPLOAD_PULSE, assert START_UPLOAD_PULSE_REMEMBERED.
         START_UPLOAD_PULSE_REMEMBERED <= '1';
      elsif (UPLOAD_FLAG = '1' and STATE = IDLE and REFRESH_COUNTER <= 600) then
      -- When the UPLOAD_FLAG has been pulled high in the IDLE state,
      -- then we know that the state machine has detected the
      -- START_UPLOAD_PULSE_REMEMBERED. It has also reset the write
      -- pointer, even if the previous operation was an upload as well.
         START_UPLOAD_PULSE_REMEMBERED <= '0';
      end if;


      if (STOP_CURRENT_OPERATION_PULSE = '1') then
      -- Deassert the START_SINGLE_DOWNLOAD_PULSE_REMEMBERED in case it was high,
      -- but not yet detected.
         START_SINGLE_DOWNLOAD_PULSE_REMEMBERED <= '0';
      elsif (START_SINGLE_DOWNLOAD_PULSE = '1') then
      -- If we detect a START_SINGLE_DOWNLOAD_PULSE, assert START_SINGLE_DOWNLOAD_PULSE_REMEMBERED.
         START_SINGLE_DOWNLOAD_PULSE_REMEMBERED <= '1';
      elsif (SINGLE_DOWNLOAD_FLAG = '1' and STATE = IDLE and REFRESH_COUNTER <= 600) then 
      -- When the SINGLE_DOWNLOAD_FLAG has been pulled high in the IDLE state,
      -- then we know that the state machine has detected the
      -- START_SINGLE_DOWNLOAD_PULSE_REMEMBERED. It has also reset the read
      -- pointer, even if the previous operation was a single download as well.
         START_SINGLE_DOWNLOAD_PULSE_REMEMBERED <= '0';
      end if;


      if (STOP_CURRENT_OPERATION_PULSE = '1') then
      -- Deassert the START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED in case it was high,
      -- but not yet detected.
         START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED <= '0';
      elsif (START_CONTINUOUS_DOWNLOAD_PULSE = '1') then
      -- If we detect a START_CONTINUOUS_DOWNLOAD_PULSE, assert
       -- START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED.
         START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED <= '1';
      elsif (CONTINUOUS_DOWNLOAD_FLAG = '1' and STATE = IDLE and REFRESH_COUNTER <= 600) then
      -- When the CONTINUOUS_DOWNLOAD_FLAG has been pulled high in the IDLE state,
      -- then we know that the state machine has detected the
      -- START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED. It has also reset the read
      -- pointer, even if the previous operation was a continuous download as well.
         START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED <= '0';
      end if;


    end if;
end process;



SDRAM_CONTROLLER_STATE_MACHINE_001: process(ASYNC_RESET, CLK)
begin
   if (ASYNC_RESET = '1') then
      OPERATION <= NOP_B;                                -- Apply a NOP operation:
      COUNTER_200_uS <= (others => '0');                 -- Reset counter
      GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');  -- Reset counter
      SDRAM_DQ <= (others => 'Z');
      SDRAM_A <= (others => '0');
      WRITE_POINTER <= (others => '0');
      READ_POINTER <= (others => '0');
      DATA_ON_INPUT_WANTED <= '0';
      DATA_OUT_CLK <= '0';
      FIRST_WORD_OUT <= '0';
      LAST_WORD_OUT <= '0';
      UPLOAD_FLAG <= '0';
      UPLOAD_COMPLETED_PULSE <= '0';
      SINGLE_DOWNLOAD_FLAG <= '0';
      CONTINUOUS_DOWNLOAD_FLAG <= '0';
      STATE <= INI_WAIT_FOR_200_uS;                      -- First state
   elsif rising_edge(CLK) then
      if (POWER_DOWN = '1') then
         OPERATION <= NOP_B;                                -- Apply a NOP operation:
         COUNTER_200_uS <= (others => '0');                 -- Reset counter
         GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');  -- Reset counter
         SDRAM_DQ <= (others => 'Z');
         SDRAM_A <= (others => '0');
         WRITE_POINTER <= (others => '0');
         READ_POINTER <= (others => '0');
         DATA_ON_INPUT_WANTED <= '0';
         DATA_OUT_CLK <= '0';
         FIRST_WORD_OUT <= '0';
         LAST_WORD_OUT <= '0';
         UPLOAD_FLAG <= '0';
         UPLOAD_COMPLETED_PULSE <= '0';
         SINGLE_DOWNLOAD_FLAG <= '0';
         CONTINUOUS_DOWNLOAD_FLAG <= '0';
         STATE <= INI_WAIT_FOR_200_uS;                      -- First state
      else

         if (STATE = APPLY_AN_AUTO_REFRESH) then
            REFRESH_COUNTER <= (others => '0');       -- Reset the counter when we are doing a refresh
         else
            REFRESH_COUNTER <= REFRESH_COUNTER + 1;   -- Otherwise, increment at each clock cycle
         end if;
         case STATE is

   -----------------------------------------------------------------
   -- INITIALIZATION
   -----------------------------------------------------------------

            when INI_WAIT_FOR_200_uS =>
               COUNTER_200_uS <= COUNTER_200_uS + 1;
               if (COUNTER_200_uS = 8200) then      -- Wait for 200 microseconds before
                  STATE <= INI_PRECHARGE;          -- switching state
               end if;

            when INI_PRECHARGE =>
               GENERAL_PURPOSE_4_BIT_COUNTER <= GENERAL_PURPOSE_4_BIT_COUNTER + 1;
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 1) then
                  STATE <= INI_IN_IDLE_STATE;
                  GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');    -- Always reset when done using
               end if;
               OPERATION <= PRECHARGE_B;     -- Apply a precharge.
               SDRAM_A(10) <= '1';           -- Precharge all banks

            when INI_IN_IDLE_STATE =>
               -- Apply two autorefreshes followed by three nop in between.
               -- The auto refresh rate is at worst 70 ns. After each AUTOREFRESH we
               -- must do NOP for 70 ns - 20 ns = 50 ns. Thus, three clock cycles of NOP
               -- will be sufficient.
               GENERAL_PURPOSE_4_BIT_COUNTER <= GENERAL_PURPOSE_4_BIT_COUNTER + 1;
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 8) then
                  STATE <= MODE_REGISTER_PROGRAM;
                  GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');    -- Always reset when done using
               end if;
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 0 or GENERAL_PURPOSE_4_BIT_COUNTER = 4) then
                  OPERATION <= AUTO_REFRESH_B;
               else
                  OPERATION <= NOP_B;
               end if;

   -----------------------------------------------------------------
   -- LOAD MODE REGISTER
   -----------------------------------------------------------------

            when MODE_REGISTER_PROGRAM =>
               -- Program the mode registers
               OPERATION <= LOAD_MODE_REGISTER_B;
               SDRAM_A(11 downto 10) <= "00";       -- Reserved
               SDRAM_A(9) <= '0';                   -- Programmed burst length
               SDRAM_A(8 downto 7) <= "00";         -- Op mode, always "00"
               SDRAM_A(6 downto 4) <= "011";        -- CAS Latency, 3
               SDRAM_A(3) <= '0';                   -- Sequential burst type
               SDRAM_A(2 downto 0) <= "010";        -- Burst Length 4
               STATE <= MODE_REGISTER_PROGRAM_IN_PROGRESS;

            when MODE_REGISTER_PROGRAM_IN_PROGRESS =>
               -- Apply a NOP operation:
               OPERATION <= NOP_B;
               STATE <= IDLE;

   -----------------------------------------------------------------
   -- IDLE
   -----------------------------------------------------------------

            when IDLE =>
            -- These signals could have been set in the READ state.
               DATA_OUT_CLK <= '0';
               LAST_WORD_OUT <= '0';

            -- This is the normal idle state.

               if (REFRESH_COUNTER > 600) then
               -- The refresh always has preference
                  STATE <= APPLY_AN_AUTO_REFRESH;

         --------------------------------------------------------------------
         -- Detect the remembered signals
         --------------------------------------------------------------------
               elsif (STOP_OPERATION_REMEMBERED = '1') then
               -- Terminate the current operation when we are told to do so.
                  UPLOAD_FLAG <= '0';
                  SINGLE_DOWNLOAD_FLAG <= '0';
                  CONTINUOUS_DOWNLOAD_FLAG <= '0';

               elsif (START_UPLOAD_PULSE_REMEMBERED = '1') then
               -- Set the UPLOAD_FLAG when we have noticed that an upload is wanted.
                  UPLOAD_FLAG <= '1';
                  SINGLE_DOWNLOAD_FLAG <= '0';
                  CONTINUOUS_DOWNLOAD_FLAG <= '0';
                  WRITE_POINTER <= UPLOAD_START_ADDR;

               elsif (START_SINGLE_DOWNLOAD_PULSE_REMEMBERED = '1') then
               -- Set the SINGLE_DOWNLOAD_FLAG when we have noticed that a single download is wanted.
                  UPLOAD_FLAG <= '0';
                  SINGLE_DOWNLOAD_FLAG <= '1';
                  CONTINUOUS_DOWNLOAD_FLAG <= '0';
                  READ_POINTER <= DOWNLOAD_START_ADDR;

               elsif (START_CONTINUOUS_DOWNLOAD_PULSE_REMEMBERED = '1') then
               -- Set the DOWNLOAD_FLAG when we have noticed that a
                -- download is wanted.
                  UPLOAD_FLAG <= '0';
                  SINGLE_DOWNLOAD_FLAG <= '0';
                  CONTINUOUS_DOWNLOAD_FLAG <= '1';
                  READ_POINTER <= DOWNLOAD_START_ADDR;

            --------------------------------------------------------------------
            -- Go to proper state once the remembered signals have been detected
            -- and decoded.
            --------------------------------------------------------------------

               elsif (UPLOAD_FLAG = '1' and AT_LEAST_4_WORDS_AVAILABLE = '1') then
               -- If we are currently uploading, continue to do so until no more data
               -- to read from the input elastic buffer.
                  STATE <= WRITING;

               elsif (SINGLE_DOWNLOAD_FLAG = '1' or CONTINUOUS_DOWNLOAD_FLAG = '1') and
                     (DATA_OUT_4W_REQ = '1') then
               -- If we are currently downloading, continue to do so until the output
               -- elastic buffer is about be full.
                  STATE <= READING;


               end if;

   -----------------------------------------------------------------
   -- WRITE
   -----------------------------------------------------------------

            when WRITING =>
               -- The sequence for the write is follows (with auto precharge):
               -- Active, NOP, write, NOP, NOP, NOP, NOP, NOP, NOP
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 8) then
                  STATE <= IDLE;
                  GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');  -- Always reset when done using
               else
                  GENERAL_PURPOSE_4_BIT_COUNTER <= GENERAL_PURPOSE_4_BIT_COUNTER + 1;
               end if;
               case GENERAL_PURPOSE_4_BIT_COUNTER is

                  when "0000" =>
                     OPERATION <= ACTIVE;
                     SDRAM_A(12 downto 0) <= WRITE_POINTER(21 downto 9);
                     SDRAM_BA0 <= WRITE_POINTER(22);
                     SDRAM_BA1 <= WRITE_POINTER(23);
                     DATA_ON_INPUT_WANTED <= '1';                -- Request word 1 of 4

                  when "0001" =>
                     OPERATION <= NOP_B;

                  when "0010" =>
                     OPERATION <= WRITE;
                     SDRAM_DQ <= DATA_IN;                       -- Store the 1st of 4 words
                     SDRAM_A(10) <= '1';                        -- Enable auto precharge
                     SDRAM_A(8 downto 0) <= WRITE_POINTER(8 downto 0);

                  when "0011" =>
                     SDRAM_DQ <= DATA_IN;                       -- Store word 2 of 4
                     OPERATION <= NOP_B;
                     WRITE_POINTER <= WRITE_POINTER + 4;        -- Increment WRITE_POINTER to the next memory location to be written to (next burst).

                  when "0100" =>
                     SDRAM_DQ <= DATA_IN;                       -- Store word 3 of 4
                     DATA_ON_INPUT_WANTED <= '0';               -- Stop the request (we just got the word)

                  when "0101" =>
                     SDRAM_DQ <= DATA_IN;                       -- Store word 4 of 4
                     if (WRITE_POINTER = (UPLOAD_END_ADDR + 1)) then  -- Stop uploading when we have
                        UPLOAD_FLAG <= '0';                     -- reached the end of the window.
                        UPLOAD_COMPLETED_PULSE <= '1';
                     end if;

                  when others =>
                     SDRAM_DQ <= (others => 'Z');
                     UPLOAD_COMPLETED_PULSE <= '0';

               end case;

   -----------------------------------------------------------------
   -- READ
   -----------------------------------------------------------------

            when READING =>
               -- The sequence for the read is follows (with auto precharge):
               -- Active, NOP, read, NOP, NOP, NOP, NOP, NOP
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 8) then
                  STATE <= IDLE;
                  GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');    -- Always reset when done using
               else
                  GENERAL_PURPOSE_4_BIT_COUNTER <= GENERAL_PURPOSE_4_BIT_COUNTER + 1;
               end if;
               case GENERAL_PURPOSE_4_BIT_COUNTER is

                  when "0000" =>
                     OPERATION <= ACTIVE;
                     SDRAM_A(12 downto 0) <= READ_POINTER(21 downto 9);
                     SDRAM_BA0 <= READ_POINTER(22);
                     SDRAM_BA1 <= READ_POINTER(23);

                  when "0001" =>
                     OPERATION <= READ;
                     SDRAM_A(10) <= '1';                        -- Enable auto precharge
                     SDRAM_A(8 downto 0) <= READ_POINTER(8 downto 0);

                  when "0010" =>
                     OPERATION <= NOP_B;

                  when "0011" =>
                     OPERATION <= NOP_B;

                  when "0100" =>
                     DATA_OUT_CLK <= '1';                        -- Send out the 1st of 4 words.
                     FIRST_WORD_OUT <= '1';
                     OPERATION <= NOP_B;

                  when "0101" =>
                     FIRST_WORD_OUT <= '0';

                  when "0110" =>
                    READ_POINTER <= READ_POINTER + 4;           -- Increment READ_POINTER
 
                  when "0111" =>
                     if (READ_POINTER = (DOWNLOAD_END_ADDR + 1)) then  -- Make sure we stay within the
                        if (SINGLE_DOWNLOAD_FLAG = '1') then     -- chosen window.
                        -- Single download mode:
                           SINGLE_DOWNLOAD_FLAG <= '0';
                           LAST_WORD_OUT <= '1';
                        else
                         -- Continuous mode:
                           READ_POINTER <= DOWNLOAD_START_ADDR;
                        end if;
                     end if;

                  when others =>
                     DATA_OUT_CLK <= '0';                        -- Send out the 4th of 4 words.
                     LAST_WORD_OUT <= '0';

               end case;

   -----------------------------------------------------------------
   -- AUTO REFRESH
   -----------------------------------------------------------------

            when APPLY_AN_AUTO_REFRESH =>
               -- Applying an autorefresh. First do a precharge, then do a NOP, then an
               -- autorefresh, then NOP for 66-25 ns = 41 ns ie 2 clock cycles, then an
               -- autorefresh, then NOP for 66-25 ns = 41 ns ie 2 clock cycles.
               if (GENERAL_PURPOSE_4_BIT_COUNTER = 8) then
                  STATE <= IDLE;
                  GENERAL_PURPOSE_4_BIT_COUNTER <= (others => '0');  -- Always reset when done using
               else
                  GENERAL_PURPOSE_4_BIT_COUNTER <= GENERAL_PURPOSE_4_BIT_COUNTER + 1;
               end if;
               case GENERAL_PURPOSE_4_BIT_COUNTER is
                  when "0000" => OPERATION <= PRECHARGE_B;
                  when "0001" => OPERATION <= NOP_B;
                  when "0010" => OPERATION <= AUTO_REFRESH_B;
                                              SDRAM_A(10) <= '1';    -- Auto refresh all banks
                  when "0011" => OPERATION <= NOP_B;
                  when "0100" => OPERATION <= NOP_B;
                  when "0101" => OPERATION <= AUTO_REFRESH_B;
                  when "0110" => OPERATION <= NOP_B;
                  when "0111" => OPERATION <= NOP_B;
                  when others => OPERATION <= NOP_B;
               end case;

         end case;
      end if;
   end if;
end process;

--// test points
WR_TRIGGER <= '1' when ((GENERAL_PURPOSE_4_BIT_COUNTER = "0000") and (STATE = WRITING)) else '0';
RD_TRIGGER <= '1' when ((GENERAL_PURPOSE_4_BIT_COUNTER = "0000") and (STATE = READING)) else '0';

end behavior;

