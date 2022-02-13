library ieee;
use ieee.std_logic_1164.all;

package controlConstants is
    constant controlDualOperandOpCodeWidth : integer := 3;
    constant controlSingOperandOpCodeWidth : integer := 5;
    constant controlZeroOperandOpCodeWidth : integer := 5;

    -- No Operation
    constant cpuOpNOP   : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "00000"; -- No Operation - Do nothing
    -- Loading/Storing Data to Memory
    constant cpuOpLDLx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00001";  -- Load Literal - Load literal to 8-bit register
    constant cpuOpLDxY  : std_logic_vector(controlDualOperandOpCodeWidth-1 downto 0) := "110";  -- Load Address - Load from address (16-bit register) to 8-bit register
    constant cpuOpSTxY  : std_logic_vector(controlDualOperandOpCodeWidth-1 downto 0) := "111";  -- Store Address - Store from 8-bit register to address (16-bit register)
    -- Jump
    constant cpuOpJMPX  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00010";  -- Jump to Address - Jump to address (16-bit register)
    constant cpuOpCJMPX : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00011";  -- Conditional Jump to Address - Jump to address (16-bit register) if ALU Zero flag is set
    -- Arithmetic/Boolean Logic
    constant cpuOpMVxQ  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00100";  -- Move to Accumulator - Copy 8-bit register to accumulator register
    constant cpuOpMVQx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00101";  -- Move from Accumulator - Copy accumulator register to 8-bit register
    constant cpuOpMVFx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00101";  -- Move from Accumulator Flags - Copy flag register to 8-bit register
    constant cpuOpADDx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00110";  -- Add register x to Accumulator
    constant cpuOpSUBx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "00111";  -- Subtract register x from Accumulator
    constant cpuOpANDx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "01000";  -- Bitwise AND register x with accumulator
    constant cpuOpNOTQ  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "01001";  -- Bitwise NOT register x with accumulator
    constant cpuOpXORx  : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "01010";  -- Bitwise XOR register x with accumulator
    constant cpuOpORx   : std_logic_vector(controlSingOperandOpCodeWidth-1 downto 0) := "01011";  -- Bitwise OR register x with accumulator
    constant cpuOpINCQ  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "01100";  -- Increment accumulator
    constant cpuOpDECQ  : std_logic_vector(controlZeroOperandOpCodeWidth-1 downto 0) := "01101";  -- Decrement accumulator

end controlConstants;

package body controlConstants is
end controlConstants;