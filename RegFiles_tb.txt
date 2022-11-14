----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/31/2021 04:13:43 PM
-- Design Name: 
-- Module Name: RegFiles_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;       -- for the signed, unsigned types and arithmetic ops


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RegFiles_tb is
--  Port ( );
end RegFiles_tb;

architecture Behavioral of RegFiles_tb is

component Reg_Files
 Port (
 clk,EN : in STD_LOGIC;
 Data_address : unsigned(4 downto 0);
 Data_accessLine_read : out STD_LOGIC_VECTOR(31 downto 0);
 Data_accessLine_write : in STD_LOGIC_VECTOR(31 downto 0)
 );
end component;


signal clk,EN : STD_LOGIC;
signal Data_address: unsigned(4 downto 0);
signal Data_accessLine_read,Data_accessLine_write : STD_LOGIC_VECTOR(31 downto 0);

begin
Reg: Reg_Files port map(clk,EN,Data_address,Data_accessLine_read,Data_accessLine_write);

process
begin
clk<='1'; wait for 10 ns;
clk<='0'; wait for 10 ns;
end process;

process begin
EN<='1';wait for 10 ns;
Data_address<="00000"; Data_accessLine_write<=x"00400101"; wait for 10 ns;
Data_address<="00000";  wait for 10 ns;
Data_address<="00001"; Data_accessLine_write<=x"11111111"; wait for 10 ns;
Data_address<="00000";  wait for 20 ns;
Data_address<="00001";  wait;
end process;

end Behavioral;
