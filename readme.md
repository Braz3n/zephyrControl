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
 - `x`, `X`, and `Y` characters indicate sections where the corresponding register address is encoded.
 - `-` characters indicate a bit that is not used in the decoding stage of an instruction. These should be left as 0 as a matter of course.

| OpCode   | Operand 0        | Operand 1         | Binary Code     | Description                                                               |
| -------- | ---------------- | ----------------- | --------------- | ------------------------------------------------------------------------- |
| `NOP`    |                  |                   | `0000 0---`     | No operation                                                              |
| `LDxY`   | 8-bit register   | 16-bit register   | `110x xxYY`     | Load register x with data at address Y                                    |
| `STxY`   | 8-bit register   | 16-bit register   | `111x xxYY`     | Load register x with data at address Y                                    |
| `LDLx`   | 8-bit register   |                   | `0000 1xxx`     | Load register x with next byte in memory                                  |
| `JMPX`   | 16-bit register  |                   | `0001 0-XX`     | Jump to address stored in register X                                      |
| `CJMPX`  | 16-bit register  |                   | `0001 1-XX`     | Conditional jump to address stored in register X if ALU zero flag is set  |
| `MVxQ`   | 8-bit register   |                   | `0010 0xxx`     | Move value in register x to Q                                             |
| `MVQx`   | 8-bit register   |                   | `0010 0xxx`     | Move value in Q to register x                                             |
| `MVFx`   | 8-bit register   |                   | `0010 0xxx`     | Move value in F to x                                                      |
| `ADDx`   | 8-bit register   |                   | `0011 0xxx`     | Unsigned addition of register x to Q                                      |
| `SUBx`   | 8-bit register   |                   | `0011 1xxx`     | Unsigned subtraction of register x to Q                                   |    
| `ANDx`   | 8-bit register   |                   | `0100 0xxx`     | Bitwise AND of register x and Q                                           |
| `NOTQ`   |                  |                   | `0100 1---`     | Bitwise NOT of Q                                                          |
| `XORx`   | 8-bit register   |                   | `0101 0xxx`     | Bitwise XOR of register x and Q                                           |
| `ORx`    | 8-bit register   |                   | `0101 1xxx`     | Bitwise OR of register x and Q                                            |
| `INCQ`   |                  |                   | `0110 0---`     | Unsigned increment Q                                                      |
| `DECQ`   |                  |                   | `0110 1---`     | Unsigned decrement Q                                                      |

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