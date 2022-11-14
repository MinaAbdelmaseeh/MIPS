----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/31/2021 04:08:08 PM
-- Design Name: 
-- Module Name: Reg_Files - Behavioral
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

entity Reg_Files is
  Port (
  clk,Read_EN,Write_EN : in STD_LOGIC;
  Data_address : unsigned(4 downto 0);
  Data_accessLine_read : out STD_LOGIC_VECTOR(31 downto 0);
  Data_address2 : unsigned(4 downto 0);
  Data_accessLine_read2 : out STD_LOGIC_VECTOR(31 downto 0);
  Data_address_write : in unsigned(4 downto 0);
  Data_accessLine_write : in STD_LOGIC_VECTOR(31 downto 0)
  );
end Reg_Files;

architecture Behavioral of Reg_Files is
TYPE RegFile IS ARRAY(0 TO 31) OF std_logic_vector(31 DOWNTO 0);
SIGNAL Reg_Files : RegFile;

begin

        Data_accessLine_read<=Reg_Files(to_integer(Data_address));
        Data_accessLine_read2<=Reg_Files(to_integer(Data_address2));
process(clk)
variable startup : boolean:=true;
begin
if(startup)then
    Reg_Files<= (others=>x"00000000");
    startup:=false;
end if;

if(falling_edge(clk)) then
    if(Write_EN='1') then
        Reg_Files(to_integer(Data_address_write))<=Data_accessLine_write;
    end if;
end if;

end process;


end Behavioral;
