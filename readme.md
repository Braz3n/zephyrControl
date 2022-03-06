# Zephyr Control Unit

This is the control unit for the Zephyr CPU project, a simple 8-bit CPU architecture.

## Register Naming Schema
There are four 16-bit general-purpose registers, which are accessible as 8-bit values on the data bus.
The are named as followed:
 - PC (Program Counter)
 - A
 - B
 - C

The upper or lower byte in a register is indicated by appending either H (high byte) or L (low byte).

In addition to these registers, the WRQ and RDQ instructions can reference the 8-bit accumulator register, Q.

## Opcode Breakdown
When discussing instructions, x/X and y/Y are used as placeholders for the first and second 
operand respectively. Lowercase is used for an 8-bit register, and uppercase is used for a 16-bit register.

All instructions are 8-bits long, though the LDLx (Load Literal to x) instruction involves loading
the next byte in memory after the instruction as a literal value.

The following table describes the opcodes, and the layout of the binary encoding for each instruction.
 - `0` and `1` characters are fixed zero or one in the instruction.
 - `x`, `X`, `y`, and `Y` characters indicate sections where the corresponding register address is encoded.

| OpCode   | Operand 0        | Operand 1         | Binary Code     | Description                                                                   |
| -------- | ---------------- | ----------------- | --------------- | ----------------------------------------------------------------------------- |
| `NOP`    |                  |                   | `0000 0000`     | No operation                                                                  |
| `HALT`   |                  |                   | `0000 0001`     | Halt CPU                                                                      |
| `LD x Y` | 8-bit register   | 16-bit register   | `110x xxYY`     | Load register x with data at address Y                                        |
| `ST x Y` | 8-bit register   | 16-bit register   | `111x xxYY`     | Load register x with data at address Y                                        |
| `LDL x`  | 8-bit register   |                   | `0000 1xxx`     | Load register x with next byte in memory                                      |
| `MV x y` | 8-bit register   | 8-bit register    | `10xx xyyy`     | Copy value in register x to register y                                        |
| `JPSC X` | 16-bit register  |                   | `0001 00XX`     | Conditional jump to address stored in register X if carry flag is set         |
| `JPCC X` | 16-bit register  |                   | `0001 01XX`     | Conditional jump to address stored in register X if carry flag is clear       |
| `JPSV X` | 16-bit register  |                   | `0001 10XX`     | Conditional jump to address stored in register X if overlow flag is set       |
| `JPCV X` | 16-bit register  |                   | `0001 11XX`     | Conditional jump to address stored in register X if overflow flag is clear    |
| `JPSN X` | 16-bit register  |                   | `0010 00XX`     | Conditional jump to address stored in register X if negative flag is set      |
| `JPCN X` | 16-bit register  |                   | `0010 01XX`     | Conditional jump to address stored in register X if negative flag is clear    |
| `JPSZ X` | 16-bit register  |                   | `0010 10XX`     | Conditional jump to address stored in register X if zero flag is set          |
| `JPCZ X` | 16-bit register  |                   | `0010 11XX`     | Conditional jump to address stored in register X if zero flag is clear        |
| `WRQ x`  | 8-bit register   |                   | `0111 0xxx`     | Write value in register x to Q                                                |
| `RDQ x`  | 8-bit register   |                   | `0111 1xxx`     | Read value from Q to register x                                               |
| `ADD x`  | 8-bit register   |                   | `0011 0xxx`     | Unsigned addition of register x to Q                                          |
| `ADC x`  | 8-bit register   |                   | `0011 1xxx`     | Unsigned addition with carry of register x to Q                               |
| `SUB x`  | 8-bit register   |                   | `0100 0xxx`     | Unsigned subtraction of register x to Q                                       |    
| `SBB x`  | 8-bit register   |                   | `0100 1xxx`     | Unsigned subtraction of register x to Q                                       |    
| `AND x`  | 8-bit register   |                   | `0101 0xxx`     | Bitwise AND of register x and Q                                               |
| `OR x`   | 8-bit register   |                   | `0101 1xxx`     | Bitwise OR of register x and Q                                                |
| `XOR x`  | 8-bit register   |                   | `0110 1xxx`     | Bitwise XOR of register x and Q                                               |
| `NOTQ`   |                  |                   | `0110 0101`     | Bitwise NOT of Q                                                              |
| `INCQ`   |                  |                   | `0110 0110`     | Unsigned increment Q                                                          |
| `DECQ`   |                  |                   | `0110 0111`     | Unsigned decrement Q                                                          |
| `LSLQ`   |                  |                   | `0110 0000`     | Logical shift left                                                            |
| `LSRQ`   |                  |                   | `0110 0001`     | Logical shift right                                                           |
| `ASRQ`   |                  |                   | `0110 0010`     | Arithmetic shift right                                                        |
| `RLCQ`   |                  |                   | `0110 0011`     | Rotate left through carry                                                     |
| `RRCQ`   |                  |                   | `0110 0100`     | Rotate right through carry                                                    |
| `SETC`   |                  |                   | `0000 0010`     | Set carry flag                                                                |
| `CLRC`   |                  |                   | `0000 0011`     | Clear carry flag                                                              |
| `SETV`   |                  |                   | `0000 0100`     | Set overflow flag                                                             |
| `CLRV`   |                  |                   | `0000 0101`     | Clear overflow flag                                                           |
| `SETN`   |                  |                   | `0000 0110`     | Set negative flag                                                             |
| `CLRN`   |                  |                   | `0000 0111`     | Clear negative flag                                                           |

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


Below is a map of the 8-bit ISA space, where each row represents the first half of the instruction, and each column represents the second half of the instruction.
For example, NOP is 0x00, and ADC AL is 0x3A.

|    |    x0      |     x1     |     x2     |     x3    |     x4    |     x5    |     x6    |     x7    |     x8     |      x9    |     xA    |      xB   |     xC    |    xD     |     xE    |    xF     |
|----|------------|------------|------------|-----------|-----------|-----------|-----------|-----------|------------|------------|-----------|-----------|-----------|-----------|-----------|-----------|
| 0x | NOP        | HALT       | SETC       | CLRC      | SETV      | CLRV      | SETN      | CLRN      | LDL PCL    | LDL PCH    | LDL AL    | LDL AH    | LDL BL    | LDL BH    | LDL CL    | LDL CH    |
| 1x | JPSC PC    | JPSC A     | JPSC B     | JPSC C    | JPCC PC   | JPCC A    | JPCC B    | JPCC C    | JPSV PC    | JPSV A     | JPSV B    | JPSV C    | JPCV PC   | JPCV A    | JPCV B    | JPCV C    |
| 2x | JPSN PC    | JPSN A     | JPSN B     | JPSN C    | JPCN PC   | JPCN A    | JPCN B    | JPCN C    | JPSZ PC    | JPSZ A     | JPSZ B    | JPSZ C    | JPCZ PC   | JPCZ A    | JPCZ B    | JPCZ C    |
| 3x | ADD PCL    | ADD PCH    | ADD AL     | ADD AH    | ADD BL    | ADD BH    | ADD CL    | ADD CH    | ADC PCL    | ADC PCH    | ADC AL    | ADC AH    | ADC BL    | ADC BH    | ADC CL    | ADC CH    |
| 4x | SUB PCL    | SUB PCH    | SUB AL     | SUB AH    | SUB BL    | SUB BH    | SUB CL    | SUB CH    | SBB PCL    | SBB PCH    | SBB AL    | SBB AH    | SBB BL    | SBB BH    | SBB CL    | SBB CH    |
| 5x | AND PCL    | AND PCH    | AND AL     | AND AH    | AND BL    | AND BH    | AND CL    | AND CH    | OR PCL     | OR PCH     | OR AL     | OR AH     | OR BL     | OR BH     | OR CL     | OR CH     |
| 6x | LSLQ       | LSRQ       | ASRQ       | RLCQ      | RRCQ      | NOTQ      |INCQ       | DECQ      | XOR PCL    | XOR PCH    | XOR AL    | XOR AH    | XOR BL    | XOR BH    | XOR CL    | XOR CH    |  
| 7x | WRQ PCL    | WRQ PCH    | WRQ AL     | WRQ AH    | WRQ BL    | WRQ BH    | WRQ CL    | WRQ CH    | RDQ PCL    | RDQ PCH    | RDQ AL    | RDQ AH    | RDQ BL    | RDQ BH    | RDQ CL    | RDQ CH    |
| 8x | MV PCL PCL | MV PCL PCH | MV PCL AL  | MV PCL AH | MV PCL BL | MV PCL BH | MV PCL CL | MV PCL CH | MV PCH PCL | MV PCH PCH | MV PCH AL | MV PCH AH | MV PCH BL | MV PCH BH | MV PCH CL | MV PCH CH |
| 9x | MV AL PCL  | MV AL PCH  | MV AL AL   | MV AL AH  | MV AL BL  | MV AL BH  | MV AL CL  | MV AL CH  | MV AH PCL  | MV AH PCH  | MV AH AL  | MV AH AH  | MV AH BL  | MV AH BH  | MV AH CL  | MV AH CH  |
| Ax | MV BL PCL  | MV BL PCH  | MV BL AL   | MV BL AH  | MV BL BL  | MV BL BH  | MV BL CL  | MV BL CH  | MV BH PCL  | MV BH PCH  | MV BH AL  | MV BH AH  | MV BH BL  | MV BH BH  | MV BH CL  | MV BH CH  |
| Bx | MV CL PCL  | MV CL PCH  | MV CL AL   | MV CL AH  | MV CL BL  | MV CL BH  | MV CL CL  | MV CL CH  | MV CH PCL  | MV CH PCH  | MV CH AL  | MV CH AH  | MV CH BL  | MV CH BH  | MV CH CL  | MV CH CH  |
| Cx | LD PCL PC  | LD PCL A   | LD PCL B   | LD PCL C  | LD PCH PC | LD PCH A  | LD PCH B  | LD PCH C  | LD AL PC   | LD AL A    | LD AL B   | LD AL C   | LD AH PC  | LD AH A   | LD AH B   | LD AH C   |
| Dx | LD BL PC   | LD BL A    | LD BL B    | LD BL C   | LD BH PC  | LD BH A   | LD BH B   | LD BH C   | LD CL PC   | LD CL A    | LD CL B   | LD CL C   | LD CH PC  | LD CH A   | LD CH B   | LD CH C   |
| Ex | ST PCL PC  | ST PCL A   | ST PCL B   | ST PCL C  | ST PCH PC | ST PCH A  | ST PCH B  | ST PCH C  | ST AL PC   | ST AL A    | ST AL B   | ST AL C   | ST AH PC  | ST AH A   | ST AH B   | ST AH C   |
| Fx | ST BL PC   | ST BL A    | ST BL B    | ST BL C   | ST BH PC  | ST BH A   | ST BH B   | ST BH C   | ST CL PC   | ST CL A    | ST CL B   | ST CL C   | ST CH PC  | ST CH A   | ST CH B   | ST CH C   |