---- ExternalMemory.VHD
---- 2024.10.22
----
---- This SCOMP peripheral provides one 16-bit word of external memory for SCOMP.
---- Any value written to this peripheral can be read back.
--
--LIBRARY IEEE;
--LIBRARY LPM;
--
--USE IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.STD_LOGIC_ARITH.ALL;
--USE IEEE.STD_LOGIC_UNSIGNED.ALL;
--USE LPM.LPM_COMPONENTS.ALL;
--
--ENTITY ExternalMemory IS
--    PORT(
--        RESETN,
--        CS,
--        IO_WRITE : IN    STD_LOGIC;
--        IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--    );
--END ExternalMemory;
--
--ARCHITECTURE a OF ExternalMemory IS
--    SIGNAL SAVED : STD_LOGIC_VECTOR(15 DOWNTO 0);
--
--    BEGIN
--
--    -- Use Intel LPM IP to create tristate drivers
--    IO_BUS: lpm_bustri
--        GENERIC MAP (
--        lpm_width => 16
--    )
--    PORT MAP (
--        enabledt => CS AND NOT(IO_WRITE), -- when SCOMP reads
--        data     => SAVED,  -- provide this value
--        tridata  => IO_DATA -- driving the IO_DATA bus
--    );
--
--    PROCESS
--    BEGIN
--        WAIT UNTIL RISING_EDGE(CS);
--            IF IO_WRITE = '1' THEN -- If SCOMP is writing,
--                SAVED <= IO_DATA;  -- sample the input on the rising edge of CS
--            END IF;
--    END PROCESS;
--
--END a;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity ExternalMemory is
    Port (
        resetn       : in  std_logic;
        CS           : in  std_logic;
        write_enable : in  std_logic;
        clk          : in  std_logic;
        IO_DATA      : inout std_logic_vector(15 downto 0) -- 16-bit data
    );
end ExternalMemory;

architecture Behavioral of ExternalMemory is

    -- Address register for the target memory address
    signal address_register : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_data_in      : std_logic_vector(15 downto 0);
    signal mem_data_out     : std_logic_vector(15 downto 0);
    signal mem_write_enable : std_logic := '0';

begin

    -- Clocked process for writing and address register update
    process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                address_register <= (others => '0');
                mem_write_enable <= '0';
            else
                if CS = '1' then
                    -- Update address register if IO_DATA is 0x70 and write_enable is active
                    if IO_DATA = x"70" and write_enable = '1' then
                        address_register <= IO_DATA;
                    end if;

                    -- Handle memory write when io_address is 0x71
                    if IO_DATA = x"71" and write_enable = '1' then
                        mem_data_in <= IO_DATA;
                        mem_write_enable <= '1';
                    else
                        mem_write_enable <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Level-triggered process for reading from memory
    process(CS, IO_DATA)
    begin
        if CS = '1' and IO_DATA = x"71" and write_enable = '0' then
            IO_DATA <= mem_data_out; -- Output the data immediately when IO_DATA = 0x71
        else
            IO_DATA <= (others => 'Z'); -- Tri-state when not reading to avoid bus contention
        end if;
    end process;

    -- Instantiation of altsyncram
    mem_instance : altsyncram
        generic map (
            operation_mode => "SINGLE_PORT",          -- Single-port configuration
            width_a        => 16,                     -- Data width (16 bits)
            numwords_a     => 65536,                  -- Memory depth (adjustable)
            widthad_a      => 16,                     -- Address width (16-bit address space)
            outdata_reg_a  => "UNREGISTERED",         -- Unregistered output data
            address_aclr_a => "NONE",                 -- No address reset
            lpm_hint       => "ENABLE_RUNTIME_MOD=NO" -- Disable runtime modification
        )
        port map (
            clock0         => clk,                    -- Clock
            address_a      => address_register,       -- Address input
            data_a         => mem_data_in,            -- Data input
            wren_a         => mem_write_enable,       -- Write enable
            q_a            => mem_data_out            -- Data output
        );

end Behavioral;



--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
--library altsyncram_library;
--use altsyncram_library.altsyncram_library;
--
--entity ExternalMemory is
--    Port (
--        clk          : in  std_logic;
--        reset        : in  std_logic;
--        address_in   : in  std_logic_vector(15 downto 0); -- 16-bit address input
--        data_in      : in  std_logic_vector(15 downto 0); -- 16-bit data input
--        io_address   : in  std_logic_vector(7 downto 0);  -- 8-bit I/O address (0xFE for address, 0xFF for data access)
--        read_enable  : in  std_logic;
--        write_enable : in  std_logic;
--        data_out     : out std_logic_vector(15 downto 0)  -- 16-bit data output
--    );
--end ExternalMemory;
--
--architecture Behavioral of ExternalMemory is
--
--    -- Address register for the target memory address
--    signal address_register : std_logic_vector(15 downto 0) := (others => '0');
--    signal mem_data_in      : std_logic_vector(15 downto 0);
--    signal mem_data_out     : std_logic_vector(15 downto 0);
--    signal mem_write_enable : std_logic := '0';
--
--begin
--
--    -- Memory process
--    process(clk)
--    begin
--        if rising_edge(clk) then
--            if reset = '1' then
--                address_register <= (others => '0');
--                data_out <= (others => '0');
--                mem_write_enable <= '0';
--            else
--                -- Update address register if io_address is 0x70 and write_enable is active
--                if io_address = x"70" and write_enable = '1' then
--                    address_register <= address_in;
--                end if;
--
--                -- Handle memory access when io_address is 0x71
--                if io_address = x"71" then
--                    if write_enable = '1' then
--                        -- Write data to memory via RAM: 1-PORT
--                        mem_data_in <= data_in;
--                        mem_write_enable <= '1';
--                    elsif read_enable = '1' then
--                        -- Read data from memory via RAM: 1-PORT
--                        data_out <= mem_data_out;
--                        mem_write_enable <= '0';
--                    else
--                        mem_write_enable <= '0';
--                    end if;
--                else
--                    mem_write_enable <= '0';
--                end if;
--            end if;
--        end if;
--    end process;
--
--    -- Instantiation of RAM: 1-PORT
--    mem_instance : entity work.altsyncram_library
--        port map (
--            clock      => clk,               -- Clock
--            address    => address_register,  -- Address input
--            data       => mem_data_in,       -- Data input
--            wren       => mem_write_enable,  -- Write enable
--            q          => mem_data_out       -- Data output
--        );
--
--end Behavioral;


