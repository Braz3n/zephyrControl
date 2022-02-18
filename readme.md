# Zephyr Control Unit

## Register Naming Schema
There are four 16-bit general-purpose registers, which are accessible as 8-bit values on the data bus.
The are named as followed:
 - PC (Program Counter)
 - A
 - B
 - C

The upper or lower byte in a register is indicated by appending either H (high byte) or L (low byte).

In addition to these registers, the MV instruction can reference the two 8-bit accumulator registers:
 - Q - Accumulator (Read and Write)
 - F - Accumulator flags (Read-Only)

## Opcode Breakdown
Most OpCodes are 5-bits long, with the remaining space occupied by register
addresses. The two exceptions to this at present are LDxY and STxY, which 
are only 3-bits long so as to allow space to address the necessary registers.

When discussing instructions, x/X and y/Y are used as placeholders for the first and second 
operand respectively. Lowercase is used for an 8-bit register, and uppercase is used for a 16-bit register.

All instructions are 8-bits long, though the LDLx (Load Literal to x) instruction involves loading
the next byte in memory after the instruction as a literal value.

The following table describes the opcodes, and the layout of the binary encoding for each instruction.
 - `0` and `1` characters are fixed zero or one in the instruction.
 - `x`, `X`, `y`, and `Y` characters indicate sections where the corresponding register address is encoded.

| OpCode   | Operand 0        | Operand 1         | Binary Code     | Description                                                               |
| -------- | ---------------- | ----------------- | --------------- | ------------------------------------------------------------------------- |
| `NOP`    |                  |                   | `0000 0000`     | No operation |
| `HALT`   |                  |                   | `0000 0001`     | Halt CPU |
| `LD x Y` | 8-bit register   | 16-bit register   | `110x xxYY`     | Load register x with data at address Y                                    |
| `ST x Y` | 8-bit register   | 16-bit register   | `111x xxYY`     | Load register x with data at address Y                                    |
| `LDL x`  | 8-bit register   |                   | `0000 1xxx`     | Load register x with next byte in memory                                  |
| `JPSC X` | 16-bit register  |                   | `0001 00XX`     | Conditional jump to address stored in register X if carry flag is set  |
| `JPCC X` | 16-bit register  |                   | `0001 01XX`     | Conditional jump to address stored in register X if carry flag is clear  |
| `JPSV X` | 16-bit register  |                   | `0001 10XX`     | Conditional jump to address stored in register X if overlow flag is set  |
| `JPCV X` | 16-bit register  |                   | `0001 11XX`     | Conditional jump to address stored in register X if overflow flag is clear  |
| `JPSS X` | 16-bit register  |                   | `0010 00XX`     | Conditional jump to address stored in register X if signed flag is set  |
| `JPCS X` | 16-bit register  |                   | `0010 01XX`     | Conditional jump to address stored in register X if signed flag is clear  |
| `JPSZ X` | 16-bit register  |                   | `0010 10XX`     | Conditional jump to address stored in register X if zero flag is set  |
| `JPCZ X` | 16-bit register  |                   | `0010 11XX`     | Conditional jump to address stored in register X if zero flag is clear  |
| `WRQ x`  | 8-bit register   |                   | `0111 0xxx`     | Write value in register x to Q                                             |
| `RDQ x`  | 8-bit register   |                   | `0111 1xxx`     | Read value from Q to register x                                             |
| `ADD x`  | 8-bit register   |                   | `0011 0xxx`     | Unsigned addition of register x to Q                                      |
| `ADC x`  | 8-bit register   |                   | `0011 1xxx`     | Unsigned addition with carry of register x to Q                                      |
| `SUB x`  | 8-bit register   |                   | `0100 0xxx`     | Unsigned subtraction of register x to Q                                   |    
| `SBB x`  | 8-bit register   |                   | `0100 1xxx`     | Unsigned subtraction of register x to Q                                   |    
| `AND x`  | 8-bit register   |                   | `0101 0xxx`     | Bitwise AND of register x and Q                                           |
| `OR x`   | 8-bit register   |                   | `0101 1xxx`     | Bitwise OR of register x and Q                                            |
| `XOR x`  | 8-bit register   |                   | `0110 1xxx`     | Bitwise XOR of register x and Q                                           |
| `NOTQ`   |                  |                   | `0110 0101`     | Bitwise NOT of Q                                                          |
| `INCQ`   |                  |                   | `0110 0110`     | Unsigned increment Q                                                      |
| `DECQ`   |                  |                   | `0110 0111`     | Unsigned decrement Q                                                      |
| `LSLQ`   |                  |                   | `0110 0000`     | Logical shift left |
| `LSRQ`   |                  |                   | `0110 0001`     | Logical shift right |
| `ASRQ`   |                  |                   | `0110 0010`     | Arithmetic shift right |
| `RLCQ`   |                  |                   | `0110 0011`     | Rotate left through carry |
| `RRCQ`   |                  |                   | `0110 0100`     | Rotate right through carry |
| `SETC`   |                  |                   | `0000 0010`     | Set carry flag |
| `CLRC`   |                  |                   | `0000 0011`     | Clear carry flag |
| `SETV`   |                  |                   | `0000 0100`     | Set overflow flag |
| `CLRV`   |                  |                   | `0000 0101`     | Clear overflow flag |
| `SETS`   |                  |                   | `0000 0110`     | Set signed flag |
| `CLRS`   |                  |                   | `0000 0111`     | Set signed flag |

Registers are addressed with the following addresses
| Register Name | Address (Bin) | Width  |     
| ------------- | ------------- | ------ |
| PC            | 00            | 16-bit |
| PCL           | 000           | 8-bit  |
| PCH           | 001           | 8-bit  |
| A             | 01            | 16-bit |
| AL            | 010           | 8-bit  |
| AH            | 011           | 8-bit  |
| B             | 10            | 16-bit |
| BL            | 100           | 8-bit  |
| BH            | 101           | 8-bit  |
| C             | 11            | 16-bit |
| CL            | 110           | 8-bit  |
| CH            | 111           | 8-bit  |

Any additional space in the 8-bit opcode after the instruction and registers
are encoded are filled with zeros.