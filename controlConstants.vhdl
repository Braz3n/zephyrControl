library ieee;
use ieee.std_logic_1164.all;

package controlConstants is    
    constant controlMoveOperandOpCodeWidth : integer := 2;
    constant controlLdStOperandOpCodeWidth : integer := 3;
    constant controlDataOperandOpCodeWidth : integer := 5;
    constant controlAddrOperandOpCodeWidth : integer := 6;
    constant controlZeroOperandOpCodeWidth : integer := 8;

    -- CPU Level
    constant cpuOpNOP   : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000000";  -- No Operation - Do nothing
    constant cpuOpHALT  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000001";  -- Halt CPU - Do nothing until reset
    -- Loading/Storing Data to Memory
    constant cpuOpMVxy  : std_logic_vector(controlMoveOperandOpCodeWidth-1 downto 0) := "10";        -- Move data between registers - Copy 8-bit register to another 8-bit register 
    constant cpuOpLDLx  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "000010";    -- Load Literal - Load literal to 8-bit register
    constant cpuOpLDxY  : std_logic_vector(controlLdStOperandOpCodeWidth-1 downto 0) := "110";       -- Load from address - Load from address (16-bit register) to 8-bit register
    constant cpuOpSTxY  : std_logic_vector(controlLdStOperandOpCodeWidth-1 downto 0) := "111";       -- Store to address - Store from 8-bit register to address (16-bit register)
    -- Jump
    constant cpuOpJPSC  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "000100";    -- Jump if set (carry flag) - Jump to address (16-bit register)
    constant cpuOpJPCC  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "000101";    -- Jump if clear (carry flag) - Jump to address (16-bit register)
    constant cpuOpJPSV  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "000110";    -- Jump if set (overflow flag) - Jump to address (16-bit register)
    constant cpuOpJPCV  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "000111";    -- Jump if clear (overflow flag) - Jump to address (16-bit register)
    constant cpuOpJPCN  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "001000";    -- Jump if set (negative flag) - Jump to address (16-bit register)
    constant cpuOpJPSN  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "001001";    -- Jump if clear (negative flag) - Jump to address (16-bit register)
    constant cpuOpJPSZ  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "001010";    -- Jump if set (zero flag) - Jump to address (16-bit register)
    constant cpuOpJPCZ  : std_logic_vector(controlAddrOperandOpCodeWidth-1 downto 0) := "001011";    -- Jump if clear (zero flag) - Jump to address (16-bit register)
    -- ALU Read/Write
    constant cpuOpWRQx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01110";     -- Write to Accumulator - Copy 8-bit register to accumulator register
    constant cpuOpRDQx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01111";     -- Read from Accumulator - Copy accumulator register to 8-bit register
    -- ALU Arithmetic
    constant cpuOpADDx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "00110";     -- Add register x to Accumulator
    constant cpuOpADCx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "00111";     -- Add with carry register x to Accumulator
    constant cpuOpSUBx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01000";     -- Subtract register x from Accumulator
    constant cpuOpSBBx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01001";     -- Subtract with borrow register x from Accumulator
    -- ALU Bitwise Logic
    constant cpuOpANDx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01010";     -- Bitwise AND register x with accumulator
    constant cpuOpORx   : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01011";     -- Bitwise OR register x with accumulator
    constant cpuOpXORx  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01101";     -- Bitwise XOR register x with accumulator
    constant cpuOpNOTQ  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "01100101";  -- Bitwise NOT register accumulator
    constant cpuOpINCQ  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "01100110";  -- Increment accumulator
    constant cpuOpDECQ  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "01100111";  -- Decrement accumulator
    -- ALU Shifts/Rotations
    constant cpuOpLSLQ  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01100000";  -- Logical shift left accumulator
    constant cpuOpLSRQ  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01100001";  -- Logical shift right accumulator
    constant cpuOpASRQ  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01100010";  -- Arithmetic shift right accumulator
    constant cpuOpRLCQ  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01100011";  -- Rotate accumulator left through carry
    constant cpuOpRRCQ  : std_logic_vector(controlDataOperandOpCodeWidth-1 downto 0) := "01100100";  -- Rotate accumulator right through carry
    -- ALU Flags
    constant cpuOpSETC  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000010";  -- Set carry flag
    constant cpuOpCLRC  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000011";  -- Clear carry flag
    constant cpuOpSETV  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000100";  -- Set overflow flag
    constant cpuOpCLRV  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000101";  -- Clear overflow flag
    constant cpuOpSETN  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000110";  -- Set negative flag
    constant cpuOpCLRN  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000111";  -- Clear negative flag

end controlConstants;

package body controlConstants is
end controlConstants;