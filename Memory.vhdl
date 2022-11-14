----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/31/2021 02:26:15 PM
-- Design Name: 
-- Module Name: Memory - Behavioral
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
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;       -- for the signed, unsigned types and arithmetic ops
use ieee.std_logic_textio.all;
use std.textio.all;
entity Memory is
 Port (
    clk : in STD_LOGIC;
    Instr_EN,Read_EN,Write_EN : in STD_LOGIC;
    Instr_address : in unsigned(31 downto 0);
    Instr_read : out STD_LOGIC_VECTOR(31 downto 0);
    Data_address : in unsigned(31 downto 0);
    Data_read : out STD_LOGIC_VECTOR(31 downto 0);
    Data_write : in STD_LOGIC_VECTOR(31 downto 0)
 );
end Memory;

architecture Behavioral of Memory is

TYPE mem IS ARRAY(0 TO 4095) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL ram_block : mem;
begin


process(clk)
file f : TEXT;
constant filename: string :="C:\Users\Mina\Desktop\MIPS\TestBenches\Memory_data.txt";
variable l : line;
variable i : integer:=0;
variable b : std_logic_vector(31 downto 0);
variable startup : boolean:=true;
begin
   if(startup=true)then
        file_open(f,filename,read_mode);
        while((i<=30) and (not endfile(f)))loop
        readline(f,l);
        next when l(1)='#';
        read(l,b);
        ram_block(i)<=b;
        i:=i+1;
        end loop;
        file_close(f);
        startup:=false;
    end if;
if(falling_edge(clk))then
    if(Read_EN='1') then
        Data_read<=ram_block(to_integer(Data_address));
    end if;
    if(Instr_EN='1')then
        Instr_read<=ram_block(to_integer(Instr_address));
    end if;
end if;

if(falling_edge(clk)) then
    if(Write_EN='1') then
        ram_block(to_integer(Data_address))<=Data_write;
    end if;
end if;

end process;



end Behavioral;
