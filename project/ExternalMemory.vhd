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
	-- Stack and queue pointers
	signal stack_pointer 	 : std_logic_vector(15 downto 0) := x"0080"; -- 128 
	signal queue_front  	 : std_logic_vector(15 downto 0) := x"00C0"; -- 192
	signal queue_rear   	 : std_logic_vector(15 downto 0) := x"00C0"; -- 192
	signal queue_full       : std_logic := '0';
	signal queue_empty      : std_logic := '1';
	-- Data registers
   signal mem_data_in      : std_logic_vector(15 downto 0) := (others => '0');
   signal mem_data_out     : std_logic_vector(15 downto 0) := (others => '0');
   signal mem_write_enable : std_logic := '0';
	-- Password signals
	signal password_register: std_logic_vector(15 downto 0) := "0000000111111111"; -- 511
	signal password_entered : std_logic_vector(15 downto 0) := (others => '0');
	signal access_granted   : std_logic_vector(15 downto 0) := (others => '0');
	
begin
    -- Process block for writing to memory
    process(CS, resetn)
    begin
			if resetn = '0' then
				 address_register <= (others => '0');
				 mem_write_enable <= '0';
				 mem_data_in      <= (others => '0');
				 access_granted	<= (others => '0');
				 password_entered <= (others => '0');
				 stack_pointer    <= x"0080";
				 queue_front      <= x"00C0";
				 queue_rear       <= x"00C0";
				 queue_full       <= '0';
				 queue_empty      <= '1';
				 
			elsif CS = '1' then
			
				 -- Update address register if IO_ADDR is 0x70 and write_enable is active
				 if IO_ADDR = x"70" and write_enable = '1' then
					address_register <= IO_DATA;

				 -- Handle memory access when IO_ADDR is 0x71 in normal memory range
				 elsif IO_ADDR = x"71" and address_register < x"0080" then
					  if write_enable = '1' then
							-- Write data to memory via altsyncram
							mem_data_in      <= IO_DATA;
							mem_write_enable <= '1';
					  else
							mem_write_enable <= '0';
					  end if;
					  
				 -- Handle memory access when IO_ADDR is 0x73 (Stack)
				 elsif IO_ADDR = x"73" then
					if write_enable = '1' and stack_pointer < x"00C0" then
					   -- Write data to memory via altsyncram
					   -- Push: Write data and increment stack pointer
                  address_register <= stack_pointer;
						mem_data_in      <= IO_DATA;
						mem_write_enable <= '1';
						-- Handle stack limit
						if (stack_pointer + 1) <= x"00C0" then
							stack_pointer <= stack_pointer + 1;
						end if;
					 elsif write_enable = '0' and stack_pointer > x"0080" then
						stack_pointer    <= stack_pointer - 1;
				      address_register <= stack_pointer;
						mem_write_enable <= '0';
					 end if;
					 
			    -- Handle memory access when IO_ADDR is 0x74 (Queue)
				 elsif IO_ADDR = x"74" then
					if write_enable = '1' and queue_full = '0' then
					   -- Write data to memory via altsyncram
					   -- Push: Write data and increment queue rear pointer
					   address_register <= queue_rear;
						mem_data_in      <= IO_DATA;
						mem_write_enable <= '1';
						queue_rear <= queue_rear + 1;
						-- Handle wrap-around
						if queue_rear > x"00FF" then
							queue_rear <= x"00C0";
						end if;
						if queue_rear = queue_front then
							queue_full <= '1';
						end if;
						queue_empty <= '0';
					 elsif write_enable = '0' and queue_empty = '0' then
						address_register <= queue_front;
						queue_front      <= queue_front + 1;
						-- Handle wrap-around
						if queue_front > x"00FF" then
							queue_front <= x"00C0";
						end if;
						if queue_front = queue_rear then
							queue_empty <= '1';
						end if;
						queue_full       <= '0';
						mem_write_enable <= '0';
					 end if;
					 
				 -- Password check
				 elsif IO_ADDR = x"72" and write_enable = '1' then
					password_entered <= IO_DATA;
					if password_entered = password_register then
						access_granted <= x"0001";
					else
						access_granted <= x"0000";
					end if;
				 
				 -- Handle memory access when IO_ADDR is 0x71 in access controlled memory range
				 elsif IO_ADDR = x"71" and address_register >= x"0100" then
					if write_enable = '1' and access_granted = x"0001" then
					   -- Write data to memory via altsyncram
						mem_data_in      <= IO_DATA;
						mem_write_enable <= '1';
					else
						mem_write_enable <= '0';
					end if;
				 end if;
			else
				 mem_write_enable <= '0';
			end if;
    end process;

    -- Process block for reading from memory
    process(CS, resetn)
    begin
        if resetn = '0' then
            IO_DATA <= (others => 'Z');
		  -- Read data from memory via altsyncram in normal memory range		
        elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register < x"0080" then
            IO_DATA <= mem_data_out;
		  -- Read data from memory via altsyncram in access controlled memory range
		  elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register >= x"0100" and access_granted = x"0001" then
            IO_DATA <= mem_data_out;
		  elsif CS = '1' and IO_ADDR = x"71" and write_enable = '0' and address_register >= x"0100" and access_granted = x"0000" then
            IO_DATA <= x"0000"; -- access restricted, so just give them 0s
		  -- Show whether access is granted for access controlled memory
		  elsif CS = '1' and IO_ADDR = x"72" and write_enable = '0' then
				IO_DATA <= access_granted;
		  -- Read data from memory via altsyncram in stack memory range
		  elsif CS = '1' and IO_ADDR = x"73" and write_enable = '0' then
				IO_DATA <= mem_data_out;
		  -- Read data from memory via altsyncram in queue memory range
		  elsif CS = '1' and IO_ADDR = x"74" and write_enable = '0' then
				IO_DATA <= mem_data_out;
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
