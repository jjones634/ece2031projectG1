library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity ExternalMemory is
    Port (
        resetn       : in  std_logic;
        CS           : in  std_logic;
        write_enable : in  std_logic;
        IO_ADDR      : in  STD_LOGIC_VECTOR(10 downto 0);
        clk          : in  std_logic;
        IO_DATA      : inout std_logic_vector(15 downto 0) -- 16-bit data
    );
end ExternalMemory;

architecture Behavioral of ExternalMemory is

    -- Address register for the target memory address
    signal address_register : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_data_in      : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_data_out     : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_write_enable : std_logic := '0';
	 -- password signals
	 signal password_register : std_logic_vector(15 downto 0) := "0000000111111111";
	 signal password_entered : std_logic_vector(15 downto 0) := (others => '0');
	 signal access_granted : std_logic_vector(15 downto 0) := (others => '0');
	 -- 

begin

    -- Clocked process for register updates
    process(CS, write_enable, resetn)
    begin
			if resetn = '0' then
				 address_register <= (others => '0');
				 mem_write_enable <= '0';
				 mem_data_in      <= (others => '0');
				 access_granted	<= (others => '0');
			elsif CS = '1' then
				 -- set up password check
				 if IO_ADDR = x"72" and write_enable = '1' then
					password_entered <= IO_DATA;
					if password_entered = password_register then
						access_granted <= "0000000000000001";
					else
						access_granted <= "0000000000000000";
					end if;
				 end if;
				 
				 -- Update address register if IO_ADDR is 0x70 and write_enable is active
				 if IO_ADDR = x"70" and write_enable = '1' then
					address_register <= IO_DATA;
				 end if;

				 -- Handle memory access when IO_ADDR is 0x71
				 if IO_ADDR = x"71" and address_register < "0000000100000000" then --low enough address, no password needed
					  if write_enable = '1' then
							-- Write data to memory via altsyncram
							mem_data_in      <= IO_DATA;
							mem_write_enable <= '1';
					  else
							mem_write_enable <= '0';
					  end if;
				 elsif IO_ADDR = x"71" and address_register >= "0000000100000000" then --high address, need password (0x1FF or higher)
					if write_enable = '1' and access_granted = "0000000000000001" then
						mem_data_in      <= IO_DATA;
						mem_write_enable <= '1';
					 else
						mem_write_enable <= '0';
					 end if;
				 else
					  mem_write_enable <= '0';
				 end if;
			else
				 mem_write_enable <= '0';
			end if;
    end process;

    -- Combinational process for IO_DATA tri-state control
    process(resetn, CS, write_enable, IO_ADDR, mem_data_out)
    begin
        if resetn = '0' then
            IO_DATA <= (others => 'Z');
        elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register < "0000000100000000" then
            IO_DATA <= mem_data_out;
		  elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register >= "0000000100000000" and access_granted = "0000000000000001" then
            IO_DATA <= mem_data_out;
		  elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register >= "0000000100000000" and access_granted = "0000000000000000" then
            IO_DATA <= "0000000000000000"; --cant read high address with pass, so just give them 0s
		  elsif CS = '1' and IO_ADDR = x"72" and write_enable = '0' then
				IO_DATA      <= access_granted;
        else
            IO_DATA <= (others => 'Z');
        end if;
    end process;

    -- Instantiation of altsyncram
    mem_instance : altsyncram
        generic map (
            operation_mode => "SINGLE_PORT",
            width_a        => 16,
            numwords_a     => 1024,
            widthad_a      => 16,
            outdata_reg_a  => "UNREGISTERED",
            address_aclr_a => "NONE",
            lpm_hint       => "ENABLE_RUNTIME_MOD=NO"
        )
        port map (
            clock0    => clk,
            address_a => address_register,
            data_a    => mem_data_in,
            wren_a    => mem_write_enable,
            q_a       => mem_data_out
        );

end Behavioral;
