----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/31/2021 04:32:33 PM
-- Design Name: 
-- Module Name: MIPS - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MIPS is
  Port (
    clk : in STD_LOGIC
    
  );
end MIPS;

architecture Behavioral of MIPS is

component Memory
Port (
    clk : in STD_LOGIC;
Instr_EN,Read_EN,Write_EN : in STD_LOGIC;--RW=0 =>read , RW=1 =>write 
Instr_address : in unsigned(31 downto 0);
Instr_read : out STD_LOGIC_VECTOR(31 downto 0);
Data_address : in unsigned(31 downto 0);
Data_read : out STD_LOGIC_VECTOR(31 downto 0);
Data_write : in STD_LOGIC_VECTOR(31 downto 0)
 );
end component;

component Reg_Files
 Port (
  clk,Read_EN,Write_EN : in STD_LOGIC;
 Data_address : unsigned(4 downto 0);
 Data_accessLine_read : out STD_LOGIC_VECTOR(31 downto 0);
 Data_address2 : unsigned(4 downto 0);
 Data_accessLine_read2 : out STD_LOGIC_VECTOR(31 downto 0);
 Data_address_write : in unsigned(4 downto 0);
 Data_accessLine_write : in STD_LOGIC_VECTOR(31 downto 0)
 );
end component;

signal mem_read_EN,mem_write_EN,mem_Instr_EN: STD_LOGIC;
signal mem_address,mem_Instr_address: unsigned(31 downto 0);
signal mem_read,mem_write :  STD_LOGIC_VECTOR(31 downto 0);


signal RegFiles_Read_EN,RegFiles_Write_EN: STD_LOGIC;
signal RegFiles_read_address1,RegFiles_read_address2,RegFiles_write_address: unsigned(4 downto 0);
signal RegFiles_read1,RegFiles_read2,RegFiles_write :  STD_LOGIC_VECTOR(31 downto 0);

--Fetch stage signals
signal curr_instr_address,next_instr_address,branch_address : unsigned (31 downto 0);
signal PC : unsigned(31 downto 0):=x"00000000";
signal Instr : STD_LOGIC_VECTOR(31 downto 0);
signal PCsrc : STD_LOGIC:='0';
---------------------PIPELINE REGISTERS------M.Ezzat------
signal pipeline_stage_1_next_instr: unsigned(31 downto 0);
signal instr_pipeline_stage_1 : STD_LOGIC_VECTOR(31 downto 0);

signal is_branch,is_mem_read,is_mem_write,is_WB,is_load,ALUSrc,ALUOp,RegDst,is_jump : STD_LOGIC:='0';

signal pipeline_stage_2_is_branch,pipeline_stage_3_is_branch : STD_LOGIC:='0'; -- is_branch control signal
signal pipeline_stage_2_is_jump,pipeline_stage_3_is_jump : STD_LOGIC:='0'; -- is_branch control signal
signal pipeline_stage_2_is_mem_read,pipeline_stage_3_is_mem_read : STD_LOGIC:='0'; -- is_mem_read control signal
signal pipeline_stage_2_is_mem_write,pipeline_stage_3_is_mem_write : STD_LOGIC:='0'; -- is_mem_write control signal
signal pipeline_stage_2_is_WB,pipeline_stage_3_is_WB,pipeline_stage_4_is_WB : STD_LOGIC:='0'; -- is_WB control signal
signal pipeline_stage_2_is_load,pipeline_stage_3_is_load,pipeline_stage_4_is_load : STD_LOGIC:='0'; -- is_WB control signal

signal pipeline_stage_2_ALUSrc,pipeline_stage_2_RegDst :STD_LOGIC:='0'; -- is reg write control signal
signal pipeline_stage_2_ALUOp : std_logic_vector(2 downto 0);
signal pipeline_stage_2_R1,pipeline_stage_2_R2,pipeline_stage_2_sign_extend : unsigned(31 downto 0);
signal pipeline_stage_2_RegFile_write_dest,pipeline_stage_3_RegFile_write_dest,pipeline_stage_4_RegFile_write_dest : STD_LOGIC_VECTOR(4 downto 0);
signal pipeline_stage_3_jump_add_res: unsigned(31 downto 0);
signal pipeline_stage_3_isZero : std_logic:='0';
signal pipeline_stage_3_ALU_out,pipeline_stage_4_ALU_out: unsigned(31 downto 0);
signal pipeline_stage_3_write_data : unsigned(31 downto 0);
signal pipeline_stage_4_mem_read : unsigned(31 downto 0);

------pipeline signals for register address for hazard control---
signal pipeline_stage_2_Req_address_1,pipeline_stage_3_Req_address_1,pipeline_stage_4_Req_address_1 : unsigned(4 downto 0);
signal pipeline_stage_2_Req_address_2,pipeline_stage_3_Req_address_2,pipeline_stage_4_Req_address_2 : unsigned(4 downto 0);

----------------------Decode Stage Signals----------------------------Gomaa---

signal R1_address,R2_address,R3_address : unsigned(4 downto 0);
signal RegIn1,RegIn2 : std_logic_vector(4 downto 0);
signal opcode : std_logic_vector(2 downto 0);
signal opcode_IR: std_logic_vector(3 downto 0);
signal sign_extend : STD_LOGIC_VECTOR(31 downto 0);

---------------------Execution Stage Signals ------------------------------------
signal jump_add_res : unsigned(31 downto 0);
signal ALU_in1,ALU_in2,ALU_out : unsigned(31 downto 0);
signal ALU_adder,ALU_sub : unsigned(31 downto 0);
signal isZero : STD_LOGIC:='0';
signal write_data : unsigned(31 downto 0);
---------------------------------Forwarding Signals---------------------------------M.Ezzat-----
signal Ex_stage_ALU_out_forwarding,MEM_stage_ALU_out_forwarding,ALU_in2_pre : unsigned(31 downto 0);
signal MEM_stage_memory_forwarding : unsigned(31 downto 0);

-------------------------------hazard control unit --------------------------------------------
signal ALU_forwarding_control_1,ALU_forwarding_control_2 : unsigned(1 downto 0);
signal mem_stage_forward_control,branch_forwarding_control : std_logic_vector(1 downto 0);
signal Stall_F,Stall_D,pipeline_stage_1_branch_stall,pipeline_stage_2_branch_stall,pipeline_stage_3_branch_stall,pipeline_stage_4_branch_stall : std_logic;

--falling signals
signal pipeline_stage_3_is_load_falling,pipeline_stage_4_is_load_falling,
pipeline_stage_2_is_WB_falling,pipeline_stage_3_is_WB_falling,pipeline_stage_4_is_WB_falling,
pipeline_stage_3_is_mem_write_falling : std_logic;
signal R1_address_falling,RegIn2_falling : unsigned(4 downto 0);

signal pipeline_stage_3_RegFile_write_dest_falling,pipeline_stage_4_RegFile_write_dest_falling
,pipeline_stage_2_Req_address_1_falling,
pipeline_stage_2_Req_address_2_falling,pipeline_stage_3_Req_address_2_falling:unsigned(4 downto 0);
------------------------------------------------------------------------------------------------
begin
mem_Instr_EN<='1';RegFiles_Read_EN<='1';

main_memory: Memory port map(clk,mem_Instr_EN,mem_read_EN,mem_write_EN,mem_Instr_address,Instr,mem_address,mem_read,mem_write);
RegFile: Reg_Files port map(clk,RegFiles_Read_EN,RegFiles_Write_EN,RegFiles_read_address1,RegFiles_read1,RegFiles_read_address2,RegFiles_read2,RegFiles_write_address,RegFiles_write);

-----------------------------Fetch stage--------------------------M.Ezzat+Gomaa-------------

PC_REG:process(clk)
begin
    if(rising_edge(clk) and (Stall_F='0'))then
        if(PCsrc='0')then
             PC<=PC + 1;
        else
             PC<=branch_address;
        end if;
    end if;
end process;
--next_instr_address<=PC + 1; -- +1 is used because each word is 32 bits , if it was 8 bits we would use +4
--curr_instr_address<=next_instr_address when PCsrc='0' else branch_address;
mem_Instr_address<=PC;
-----------------------------------------------------------------------------------------------------
--------------------------------PIPELINE 1st Stage---------------M.Ezzat+Gomaa--------------------------------------------
process(clk)
begin
    if(rising_edge(clk) and (Stall_D='0'))then
--        pipeline_stage_1_next_instr<=next_instr_address; --not used
        if(PCSrc='0')then
            instr_pipeline_stage_1<=Instr;
            pipeline_stage_1_branch_stall<='0';
        else
            instr_pipeline_stage_1<=x"00000000"; -- instruction with no change
            pipeline_stage_1_branch_stall<='1';
        end if;
    end if;
end process;
---------------------------------------------------------------------------------------------------
------------------ DECODE STAGE ------------------------------------M.Ezzat + M.Gomaa--------------------------------

opcode_IR<=instr_pipeline_stage_1(18 downto 15);
opcode <= instr_pipeline_stage_1(18 downto 16);
R1_address <= unsigned(instr_pipeline_stage_1(14 downto 10)); -- register 1 address
R2_address <= unsigned(instr_pipeline_stage_1(9 downto 5)); -- register 2 address
R3_address <= unsigned(instr_pipeline_stage_1(4 downto 0)); -- register 3 address

with opcode select RegIn1<=
    std_logic_vector(R3_address) when "100", -- load
    std_logic_vector(R3_address) when "101", -- store
    "00000" when "110", -- jump
    std_logic_vector(R1_address) when "111", -- branch
    std_logic_vector(R2_address) when others;

with opcode select RegIn2<=
    "00000" when "100", --load
    std_logic_vector(R1_address)  when "101", --store
    std_logic_vector(R1_address) when "110", -- jump
    std_logic_vector(R3_address)  when "111", -- branch
    std_logic_vector(R3_address)  when others;
    
RegFiles_read_address1<=unsigned(RegIn1);
RegFiles_read_address2<=unsigned(RegIn2);

with opcode select sign_extend<=
x"000000"&"000"&std_logic_vector(R2_address)   when "100",
x"000000"&"000"&std_logic_vector(R2_address)   when "101",
x"000000"&"000"&std_logic_vector(R2_address)   when "110",
x"000000"&"000"&std_logic_vector(R2_address)   when "111",
(others=>'Z') when others;

with opcode_IR select sign_extend<=
x"000000"&"000"&std_logic_vector(R3_address)     when "0011",
x"000000"&"000"&std_logic_vector(R3_address)     when "0001",
(others=>'Z') when others;

-----------------------------DecodeStage - Control unit------------------------------------------------------------------
Process(clk)
begin
    if(falling_edge(clk)) then
        if(opcode="111") then --- branch control
            is_branch<='1';
        else
            is_branch<='0';
        end if;
        
        if(opcode="110")then
            is_jump<='1';
        else
            is_jump<='0';
        end if;
        
    --    if(opcode="111" or opcode="110")then
    --        PCSrc<='1';
    --    else
    --        PCSrc<='0';
    --    end if;
        if(opcode="100")then -- load
            is_mem_read<='1';
            is_load<='1';
        else
            is_mem_read<='0';
            is_load<='0';
        end if;
        
        if(opcode="101")then
            is_mem_write<='1';
        else 
            is_mem_write<='0';
        end if;
        
        if(opcode="000" or opcode="001" or opcode="010" or opcode="011" or opcode="100")then
            is_WB<='1';
        else
            is_WB<='0';
        end if;
        
        if(opcode_IR="0001" or opcode_IR="0011" or opcode="100" or opcode="101") then
            ALUSrc<='1';
        else
            ALUSrc<='0';
        end if;
        -- more control is needed!
    end if;
end process;

-------- branch calculation-------------------------------------
--jump_add_res<=unsigned(RegFiles_read2) + unsigned(sign_extend); -- no forwarding
with branch_forwarding_control select jump_add_res<=
    unsigned(RegFiles_read2) + unsigned(sign_extend) when "00",
    Ex_stage_ALU_out_forwarding + unsigned(sign_extend)when "01",
    MEM_stage_ALU_out_forwarding+ unsigned(sign_extend) when "10",
    MEM_stage_memory_forwarding + unsigned(sign_extend)when others; -- when "11"
----------------------------------------------------------------
----------------- zero check -------------------- 
with RegFiles_read1 select isZero<=
'1' when x"00000000",
'0' when others;
--------------------------------------------------

PCSrc<=(isZero and is_branch) or is_jump;
branch_address<=jump_add_res;
-------------------------------PipeLine 2nd Stage --------------------------------
process(clk)
begin
    if(rising_edge(clk))then
    pipeline_stage_2_branch_stall<=pipeline_stage_1_branch_stall;
        if(Stall_D='0' and pipeline_stage_1_branch_stall='0')then
    --        pipeline_stage_2_next_instr<=pipeline_stage_1_next_instr; -- not used
            pipeline_stage_2_R1<=unsigned(RegFiles_read1); --- std_logic_vector to unsigned conversion ---- check for errors in the simulations
            pipeline_stage_2_R2<=unsigned(RegFiles_read2);
            pipeline_stage_2_sign_extend<=unsigned(sign_extend);
            pipeline_stage_2_RegFile_write_dest<=std_logic_vector(R1_address);
            pipeline_stage_2_Req_address_1<=unsigned(RegIn1);
            pipeline_stage_2_Req_address_2<=unsigned(RegIn2);
            
            ----======Control flags=====-----
            -------------MEM-----------------
            pipeline_stage_2_is_mem_read<=is_mem_read;
            pipeline_stage_2_is_mem_write<=is_mem_write;
            ------------WB---------------
            pipeline_stage_2_is_WB<=is_WB;
            pipeline_stage_2_is_load<=is_load;
            -------------EX--------------
            pipeline_stage_2_ALUSrc<=ALUSrc;
            pipeline_stage_2_ALUOp<=opcode;
            --=========================--
         else
                pipeline_stage_2_is_mem_read<='0';
                pipeline_stage_2_is_mem_write<='0';
                pipeline_stage_2_is_WB<='0';
                pipeline_stage_2_is_load<='0';
         end if;
     end if;
    if(falling_edge(clk))then
        pipeline_stage_2_Req_address_1_falling<=unsigned(RegIn1);
        pipeline_stage_2_Req_address_2_falling<=unsigned(RegIn2);
        R1_address_falling<=R1_address;
        
    end if;
end process;

---------------------------------EX STAGE-------------------------------------------

--ALU_in1<=pipeline_stage_2_R1; -- no forwarding
with ALU_forwarding_control_1 select ALU_in1<=
pipeline_stage_2_R1 when "00",
Ex_stage_ALU_out_forwarding when "01",
MEM_stage_ALU_out_forwarding when "10",
MEM_stage_memory_forwarding when others; -- when "11"

with pipeline_stage_2_ALUSrc select ALU_in2<=
ALU_in2_pre when '0',
pipeline_stage_2_sign_extend when others;

with ALU_forwarding_control_2 select ALU_in2_pre<=
pipeline_stage_2_R2 when "00",
Ex_stage_ALU_out_forwarding when "01",
MEM_stage_ALU_out_forwarding when "10",
MEM_stage_memory_forwarding when others; -- when "11"

------------=========ALU========-------------
ALU_adder<=ALU_in1 + ALU_in2;
ALU_sub  <=ALU_in1 - ALU_in2;
with pipeline_stage_2_ALUOp select ALU_out<=
 ALU_adder               when "000", -- add
 ALU_sub                 when "001", -- sub
 ALU_in1 and ALU_in2     when "010", -- and
 ALU_in1 or ALU_in2      when "011", -- or
 ALU_adder               when "100", -- load
 ALU_adder               when "101", -- store
 x"00000000"             when "110", -- jump
 x"00000000"             when others; -- branch


-- write_data<=pipeline_stage_2_R2; -- no memory forwarding
with mem_stage_forward_control select write_data<=
pipeline_stage_2_R2 when "00",
Ex_stage_ALU_out_forwarding when "01",
MEM_stage_ALU_out_forwarding when "10",
MEM_stage_memory_forwarding when others; -- when "11"


--------------------------PipeLine Stage 3 ------------------------------
process(clk)
begin
    if(rising_edge(clk))then
        pipeline_stage_3_branch_stall<=pipeline_stage_2_branch_stall;
    
        pipeline_stage_3_ALU_out<=unsigned(ALU_out);
        pipeline_stage_3_write_data<=write_data;
        pipeline_stage_3_RegFile_write_dest<=pipeline_stage_2_RegFile_write_dest;
        
        pipeline_stage_3_is_mem_read<=pipeline_stage_2_is_mem_read;
        pipeline_stage_3_is_mem_write<=pipeline_stage_2_is_mem_write;
        
        
        pipeline_stage_3_is_WB<=pipeline_stage_2_is_WB;
        pipeline_stage_3_is_load<=pipeline_stage_2_is_load;
        
        pipeline_stage_3_Req_address_1<=pipeline_stage_2_Req_address_1;
        pipeline_stage_3_Req_address_2<=pipeline_stage_2_Req_address_2;

    end if;
    
    if(falling_edge(clk))then --falling edge signals for hazard control unit
            pipeline_stage_3_RegFile_write_dest_falling<=unsigned(pipeline_stage_2_RegFile_write_dest);
            pipeline_stage_3_is_mem_write_falling<=pipeline_stage_2_is_mem_write;            
            pipeline_stage_3_is_WB_falling<=pipeline_stage_2_is_WB;
            pipeline_stage_3_is_load_falling<=pipeline_stage_2_is_load;            
            pipeline_stage_3_Req_address_2_falling<=pipeline_stage_2_Req_address_2;
        end if;
    
end process;
Ex_stage_ALU_out_forwarding<=pipeline_stage_3_ALU_out;
---------------------- MEM STAGE ----------------------------------------------------

mem_address<=pipeline_stage_3_ALU_out;
mem_write<=std_logic_vector(pipeline_stage_3_write_data);

mem_read_EN<=pipeline_stage_3_is_mem_read;
mem_write_EN<=pipeline_stage_3_is_mem_write;

-----------------------Pipeline stage 4-------------------------------------------------------------
process(clk)
begin
    if(rising_edge(clk))then
        pipeline_stage_4_branch_stall<=pipeline_stage_3_branch_stall;
        
        pipeline_stage_4_mem_read<=unsigned(mem_read);
        pipeline_stage_4_is_WB<=pipeline_stage_3_is_WB;
        pipeline_stage_4_is_load<=pipeline_stage_3_is_load;
        pipeline_stage_4_RegFile_write_dest<=pipeline_stage_3_RegFile_write_dest;
        pipeline_stage_4_ALU_out<=pipeline_stage_3_ALU_out;
        pipeline_stage_4_Req_address_1<=pipeline_stage_3_Req_address_1;
        pipeline_stage_4_Req_address_2<=pipeline_stage_3_Req_address_2;
    end if;
        if(falling_edge(clk))then
        pipeline_stage_4_is_WB_falling<=pipeline_stage_3_is_WB;
        pipeline_stage_4_is_load_falling<=pipeline_stage_3_is_load;
        pipeline_stage_4_RegFile_write_dest_falling<=unsigned(pipeline_stage_3_RegFile_write_dest);
    end if;
end process;
MEM_stage_memory_forwarding<=pipeline_stage_4_mem_read;
MEM_stage_ALU_out_forwarding<=pipeline_stage_4_ALU_out;
---------------------------WB STAGE-------------------------------------------------------------------------
with pipeline_stage_4_is_load select RegFiles_write<=
std_logic_vector(pipeline_stage_4_mem_read) when '1',
std_logic_vector(pipeline_stage_4_ALU_out) when others;

RegFiles_write_address<=unsigned(pipeline_stage_4_RegFile_write_dest);
RegFiles_Write_EN<=pipeline_stage_4_is_WB;
--------------------------================HAZARD Control unit===================-------------------------------------------------------------------

Stall_D<=  '1'  when (pipeline_stage_3_is_load_falling='1' and (unsigned(pipeline_stage_3_RegFile_write_dest_falling)=pipeline_stage_2_Req_address_1_falling or unsigned(pipeline_stage_3_RegFile_write_dest_falling)=pipeline_stage_2_Req_address_2_falling)) else -- when read after write
           '1' when (PCSrc='1' and  is_WB='1' and R1_address_falling=pipeline_stage_2_Req_address_2_falling) else
           '1' when (PCSrc='1' and pipeline_stage_3_is_load_falling='1' and pipeline_stage_3_RegFile_write_dest_falling=pipeline_stage_2_Req_address_2_falling)else
           '1' when (PCSrc='1' and pipeline_stage_4_is_load_falling='1' and pipeline_stage_4_RegFile_write_dest_falling=pipeline_stage_2_Req_address_2_falling)else
           '0';
Stall_F<=  '1'  when pipeline_stage_3_is_load_falling='1' and (unsigned(pipeline_stage_3_RegFile_write_dest_falling)=pipeline_stage_2_Req_address_1_falling or unsigned(pipeline_stage_3_RegFile_write_dest_falling)=pipeline_stage_2_Req_address_2_falling) else
           '1' when (PCSrc='1' and  is_WB='1' and R1_address_falling=pipeline_stage_2_Req_address_2_falling) else
           '1' when (PCSrc='1' and pipeline_stage_3_is_load_falling='1' and pipeline_stage_3_RegFile_write_dest_falling=pipeline_stage_2_Req_address_2_falling)else
           '0';

ALU_forwarding_control_1<= "01" when(pipeline_stage_3_is_WB='1' and pipeline_stage_3_is_load='0' and unsigned(pipeline_stage_3_RegFile_write_dest)= pipeline_stage_2_Req_address_1) else -- reg to reg operation
                           "10" when(pipeline_stage_4_is_WB='1' and pipeline_stage_4_is_load='0' and unsigned(pipeline_stage_4_RegFile_write_dest)= pipeline_stage_2_Req_address_1) else -- reg to reg operation
                           "11" when(pipeline_stage_4_is_WB='1' and pipeline_stage_4_is_load='1' and unsigned(pipeline_stage_4_RegFile_write_dest)= pipeline_stage_2_Req_address_1) else -- mem operation
                           "00"; -- no forwarding is needed!
ALU_forwarding_control_2<= "01" when(pipeline_stage_3_is_WB='1' and pipeline_stage_3_is_load='0' and unsigned(pipeline_stage_3_RegFile_write_dest)= pipeline_stage_2_Req_address_2) else -- reg to reg operation
                           "10" when(pipeline_stage_4_is_WB='1' and pipeline_stage_4_is_load='0' and unsigned(pipeline_stage_4_RegFile_write_dest)= pipeline_stage_2_Req_address_2) else -- reg to reg operation
                           "11" when(pipeline_stage_4_is_WB='1' and pipeline_stage_4_is_load='1' and unsigned(pipeline_stage_4_RegFile_write_dest)= pipeline_stage_2_Req_address_2) else -- mem operation
                           "00"; -- no forwarding is needed!
mem_stage_forward_control<="01" when(pipeline_stage_2_is_mem_write='1' and pipeline_stage_3_is_load='0' and pipeline_stage_3_is_WB='1' and unsigned(pipeline_stage_3_RegFile_write_dest)=pipeline_stage_2_Req_address_2)else -- ex stage forwarding
                           "10" when(pipeline_stage_2_is_mem_write='1' and pipeline_stage_4_is_load='0' and pipeline_stage_4_is_WB='1' and unsigned(pipeline_stage_4_RegFile_write_dest)=pipeline_stage_2_Req_address_2)else -- mem stage alu forwarding
                           "11" when(pipeline_stage_2_is_mem_write='1' and pipeline_stage_4_is_load='1' and unsigned(pipeline_stage_4_RegFile_write_dest)=pipeline_stage_2_Req_address_2) else -- load after store forwarding
                           "00";
branch_forwarding_control<="01" when(pipeline_stage_3_is_load='0' and pipeline_stage_3_is_WB='1' and unsigned(pipeline_stage_3_RegFile_write_dest)=pipeline_stage_2_Req_address_2)else -- ex stage forwarding
                           "10" when(pipeline_stage_4_is_load='0' and pipeline_stage_4_is_WB='1' and unsigned(pipeline_stage_4_RegFile_write_dest)=pipeline_stage_2_Req_address_2)else -- mem stage alu forwarding
                           "11" when(pipeline_stage_4_is_load='1' and unsigned(pipeline_stage_4_RegFile_write_dest)=pipeline_stage_2_Req_address_2) else -- branch after load forwarding
                           "00";                           

---------------------------------------------------------------------------------------------------------------------------------------------------
end Behavioral;
