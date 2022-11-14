library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;       -- for the signed, unsigned types and arithmetic ops


entity Memory_tb is
--  Port ( );
end Memory_tb;


architecture Behavioral of Memory_tb is
component Memory
 Port (
    clk : in STD_LOGIC;
    EN,RW : in STD_LOGIC;--RW=0 =>read , RW=1 =>write 
    Data_address : unsigned(31 downto 0);
    Data_accessLine_read : out STD_LOGIC_VECTOR(31 downto 0);
    Data_accessLine_write : in STD_LOGIC_VECTOR(31 downto 0)
 );
end component;


signal clk,EN,RW : STD_LOGIC;
signal Data_address: unsigned(31 downto 0);
signal Data_accessLine_read,Data_accessLine_write : STD_LOGIC_VECTOR(31 downto 0);

begin
Mem: Memory port map(clk,EN,RW,Data_address,Data_accessLine_read,Data_accessLine_write);
process
begin
clk<='1'; wait for 10 ns;
clk<='0'; wait for 10 ns;
end process;

process begin
EN<='0';wait for 10 ns;
RW<='1';Data_address<=x"00000000"; Data_accessLine_write<=x"00400101"; wait for 10 ns;
RW<='0';Data_address<=x"00000000";  wait for 10 ns;
RW<='1';Data_address<=x"00000001"; Data_accessLine_write<=x"11111111"; wait for 10 ns;
RW<='0';Data_address<=x"00000000";  wait for 20 ns;
RW<='0';Data_address<=x"00000001";  wait;
end process;

end Behavioral;
