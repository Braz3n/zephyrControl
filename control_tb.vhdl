use work.controlConstants.all;
use work.aluConstants.all;
use work.registerConstants.all;
use work.fetchConstants.all;

-- use std.env.finish;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--  A testbench has no ports.
entity control_tb is
end control_tb;
    
architecture behavioural of control_tb is
    --  Declaration of the component that will be instantiated.
    component controlUnit
    port (
        rst             : in std_logic;
        clk             : in std_logic;
        -- Register Signals
        regIncPC        : out std_logic;
        regOpCode       : out std_logic_vector (regOpCodeWidth-1 downto 0);
        regAddrBus      : out std_logic_vector (regAddrBusWidth-1 downto 0);
        -- ALU Signals
        aluFlagBus : in std_logic_vector (aluRegisterWidth-1 downto 0);
        aluOpCode : out std_logic_vector (aluOpCodeWidth-1 downto 0);
        -- Fetch Signals
        fetchInstructionBus  : in std_logic_vector(fetchInstructionWidth-1 downto 0);
        fetchOpCode : out std_logic_vector(fetchOpWidth-1 downto 0);
        fetchAddrBusLock : out std_logic
    );
    end component;

    --  Specifies which entity is bound with the component.
    for controlUnit_UUT: controlUnit use entity work.controlUnit;

    signal rst                  : std_logic;
    signal clk                  : std_logic;
    signal regIncPC             : std_logic;
    signal regOpCode            : std_logic_vector (regOpCodeWidth-1 downto 0);
    signal regAddrBus           : std_logic_vector (regAddrBusWidth-1 downto 0);
    signal aluFlagBus           : std_logic_vector (aluRegisterWidth-1 downto 0);
    signal aluOpCode            : std_logic_vector (aluOpCodeWidth-1 downto 0);
    signal fetchInstructionBus  : std_logic_vector(fetchInstructionWidth-1 downto 0);
    signal fetchOpCode          : std_logic_vector(fetchOpWidth-1 downto 0);
    signal fetchAddrBusLock     : std_logic;

begin
    -- Component instantiation.
    controlUnit_UUT : controlUnit port map 
    (
        rst => rst,
        clk => clk,
        regIncPC => regIncPC,
        regOpCode => regOpCode,
        regAddrBus => regAddrBus,
        aluFlagBus => aluFlagBus,
        aluOpCode => aluOpCode,
        fetchInstructionBus => fetchInstructionBus,
        fetchOpCode => fetchOpCode,
        fetchAddrBusLock => fetchAddrBusLock
    );

    -- Clock process.
    process 
    begin 
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;

    -- Actual working process block.
    process
        type test_pattern_type is record
            rst                  : std_logic;
            regIncPC             : std_logic;
            regOpCode            : std_logic_vector (regOpCodeWidth-1 downto 0);
            regAddrBus           : std_logic_vector (regAddrBusWidth-1 downto 0);
            aluFlagBus           : std_logic_vector (aluRegisterWidth-1 downto 0);
            aluOpCode            : std_logic_vector (aluOpCodeWidth-1 downto 0);
            fetchInstructionBus  : std_logic_vector(fetchInstructionWidth-1 downto 0);
            fetchOpCode          : std_logic_vector(fetchOpWidth-1 downto 0);
            fetchAddrBusLock     : std_logic;
        end record;
        
        type test_pattern_array is array (natural range <>) of test_pattern_type;
        
        constant test_pattern : test_pattern_array :=
        ( -- rst  regIncPC  regOpCode     regAddrBus  aluFlagBus    aluOpCode     fetchInstructionBus     fetchOpCode fetchAddrBusLock
            -- Reset the control unit
            ('1',   '1',    regWideOut,     "00",     "00000001",   aluNOP,       "--------",             fetchLDI,   '1'), -- 00 - Fetch State
            
            -- LD AL B (LDLxY) - load reg AL from address in B
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 01 - Fetch State 
            ('0',   '0',    regWideOut,     "10",     "00000000",   aluNOP,       "11001010",             fetchLDD,   '1'), -- 02 - Load State  
            ('0',   '0',    regHalfInL,     "01",     "00000000",   aluNOP,       "11001010",             fetchLDD,   '1'), -- 03 - Execute State
            
            -- LDL AH 0x55 (LDLx) - load literal into AH
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 04 - Fetch State 
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "00001011",             fetchNOP,   '1'), -- 05 - Load State  
            ('0',   '0',    regHalfInH,     "01",     "00000000",   aluNOP,       "00001011",             fetchLDD,   '1'), -- 06 - Execute State

            -- ST CH A (STxY) - Store reg AL into address in A
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 07 - Fetch State 
            ('0',   '0',    regWideOut,     "01",     "00000000",   aluNOP,       "11111101",             fetchNOP,   '1'), -- 08 - Load State  
            ('0',   '0',    regHalfOutH,    "11",     "00000000",   aluNOP,       "11111101",             fetchSTD,   '1'), -- 09 - Execute State

            -- MV AL CH (MVxy) - Copy value in AL into CH
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 10 - Fetch State 
            ('0',   '0',    regHalfOutL,    "01",     "00000000",   aluLDT,       "10010111",             fetchNOP,   '0'), -- 11 - Load State  
            ('0',   '0',    regHalfInH,     "11",     "00000000",   aluRDT,       "10010111",             fetchNOP,   '0'), -- 12 - Execute State

            -- JPSC A (JPSC) - Jump if carry flag is set
            ('0',   '1',    regWideOut,     "00",     "00000010",   aluNOP,       "--------",             fetchLDI,   '1'), -- 13 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000010",   aluNOP,       "00010001",             fetchNOP,   '0'), -- 14 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000010",   aluNOP,       "00010001",             fetchNOP,   '0'), -- 15 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 16 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000000",   aluNOP,       "00010001",             fetchNOP,   '0'), -- 17 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00010001",             fetchNOP,   '0'), -- 18 - Execute State

            -- JPCC A (JPCC) - Jump if carry flag is clear
            ('0',   '1',    regWideOut,     "00",     "00000010",   aluNOP,       "--------",             fetchLDI,   '1'), -- 19 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000010",   aluNOP,       "00010101",             fetchNOP,   '0'), -- 20 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000010",   aluNOP,       "00010101",             fetchNOP,   '0'), -- 21 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 22 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000000",   aluNOP,       "00010101",             fetchNOP,   '0'), -- 23 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00010101",             fetchNOP,   '0'), -- 24 - Execute State

            -- JPSV A (JPSV) - Jump if overflow flag is set
            ('0',   '1',    regWideOut,     "00",     "00000100",   aluNOP,       "--------",             fetchLDI,   '1'), -- 25 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000100",   aluNOP,       "00011001",             fetchNOP,   '0'), -- 26 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000100",   aluNOP,       "00011001",             fetchNOP,   '0'), -- 27 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 28 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000000",   aluNOP,       "00011001",             fetchNOP,   '0'), -- 29 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00011001",             fetchNOP,   '0'), -- 30 - Execute State

            -- JPCV A (JPCV) - Jump if overflow flag is clear
            ('0',   '1',    regWideOut,     "00",     "00000100",   aluNOP,       "--------",             fetchLDI,   '1'), -- 31 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000100",   aluNOP,       "00011101",             fetchNOP,   '0'), -- 32 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000100",   aluNOP,       "00011101",             fetchNOP,   '0'), -- 33 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 34 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000000",   aluNOP,       "00011101",             fetchNOP,   '0'), -- 35 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00011101",             fetchNOP,   '0'), -- 36 - Execute State

            -- JPSN A (JPSN) - Jump if negative flag is set
            ('0',   '1',    regWideOut,     "00",     "00001000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 37 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00001000",   aluNOP,       "00100001",             fetchNOP,   '0'), -- 38 - Load State  
            ('0',   '0',    regNOP,         "00",     "00001000",   aluNOP,       "00100001",             fetchNOP,   '0'), -- 39 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 40 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000000",   aluNOP,       "00100001",             fetchNOP,   '0'), -- 41 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00100001",             fetchNOP,   '0'), -- 42 - Execute State

            -- JPCN A (JPCN) - Jump if negative flag is clear
            ('0',   '1',    regWideOut,     "00",     "00001000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 43 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00001000",   aluNOP,       "00100101",             fetchNOP,   '0'), -- 44 - Load State  
            ('0',   '0',    regNOP,         "00",     "00001000",   aluNOP,       "00100101",             fetchNOP,   '0'), -- 45 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 46 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000000",   aluNOP,       "00100101",             fetchNOP,   '0'), -- 47 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00100101",             fetchNOP,   '0'), -- 48 - Execute State

            -- JPSZ A (JPSZ) - Jump if zero flag is set
            ('0',   '1',    regWideOut,     "00",     "00000001",   aluNOP,       "--------",             fetchLDI,   '1'), -- 49 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000001",   aluNOP,       "00101001",             fetchNOP,   '0'), -- 50 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000001",   aluNOP,       "00101001",             fetchNOP,   '0'), -- 51 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 52 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000000",   aluNOP,       "00101001",             fetchNOP,   '0'), -- 53 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00101001",             fetchNOP,   '0'), -- 54 - Execute State

            -- JPCZ A (JPCZ) - Jump if zero flag is clear
            ('0',   '1',    regWideOut,     "00",     "00000001",   aluNOP,       "--------",             fetchLDI,   '1'), -- 55 - Fetch State 
            ('0',   '0',    regNOP,         "01",     "00000001",   aluNOP,       "00101101",             fetchNOP,   '0'), -- 56 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000001",   aluNOP,       "00101101",             fetchNOP,   '0'), -- 57 - Execute State
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 58 - Fetch State 
            ('0',   '0',    regCpyToPC,     "01",     "00000000",   aluNOP,       "00101101",             fetchNOP,   '0'), -- 59 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00101101",             fetchNOP,   '0'), -- 60 - Execute State
            
            -- WRQ CL - load CL into Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 61 - Fetch State 
            ('0',   '0',    regHalfOutL,    "11",     "00000000",   aluLDA,       "01110110",             fetchNOP,   '0'), -- 62 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01110110",             fetchNOP,   '0'), -- 63 - Execute State

            -- RDQ PCL - load PCL from Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 64 - Fetch State 
            ('0',   '0',    regHalfInL,     "00",     "00000000",   aluRDA,       "01111000",             fetchNOP,   '0'), -- 65 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01111000",             fetchNOP,   '0'), -- 66 - Execute State

            -- ADD PCH - Add PCH to Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 67 - Fetch State 
            ('0',   '0',    regHalfOutH,    "00",     "00000000",   aluLDT,       "00110001",             fetchNOP,   '0'), -- 68 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluADD,       "00110001",             fetchNOP,   '0'), -- 69 - Execute State

            -- ADC PCH - Add with carry PCH to Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 70 - Fetch State 
            ('0',   '0',    regHalfOutH,    "00",     "00000000",   aluLDT,       "00111001",             fetchNOP,   '0'), -- 71 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluADC,       "00111001",             fetchNOP,   '0'), -- 72 - Execute State

            -- SUB PCH - Sub PCH from Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 73 - Fetch State 
            ('0',   '0',    regHalfOutH,    "00",     "00000000",   aluLDT,       "01000001",             fetchNOP,   '0'), -- 74 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluSUB,       "01000001",             fetchNOP,   '0'), -- 75 - Execute State

            -- SBB PCH - Sub with borrow PCH from Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 76 - Fetch State 
            ('0',   '0',    regHalfOutH,    "00",     "00000000",   aluLDT,       "01001001",             fetchNOP,   '0'), -- 77 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluSBB,       "01001001",             fetchNOP,   '0'), -- 78 - Execute State

            -- AND BL - Bitwise AND BL with Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 79 - Fetch State 
            ('0',   '0',    regHalfOutL,    "10",     "00000000",   aluLDT,       "01010100",             fetchNOP,   '0'), -- 80 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluAND,       "01010100",             fetchNOP,   '0'), -- 81 - Execute State

            -- OR BH - Bitwise OR BH with Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 82 - Fetch State 
            ('0',   '0',    regHalfOutH,    "10",     "00000000",   aluLDT,       "01011101",             fetchNOP,   '0'), -- 83 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluOR,        "01011101",             fetchNOP,   '0'), -- 84 - Execute State

            -- XOR BH - Bitwise XOR CL with Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 85 - Fetch State 
            ('0',   '0',    regHalfOutL,    "11",     "00000000",   aluLDT,       "01101110",             fetchNOP,   '0'), -- 86 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluXOR,       "01101110",             fetchNOP,   '0'), -- 87 - Execute State

            -- NOTQ - Bitwise NOT Q
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 88 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100101",             fetchNOP,   '0'), -- 89 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOT,       "01100101",             fetchNOP,   '0'), -- 90 - Execute State

            -- INCQ - Increment value of Q by 1
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 91 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100110",             fetchNOP,   '0'), -- 92 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluINC,       "01100110",             fetchNOP,   '0'), -- 93 - Execute State

            -- DECQ - Decrement value of Q by 1
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 94 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100111",             fetchNOP,   '0'), -- 95 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluDEC,       "01100111",             fetchNOP,   '0'), -- 96 - Execute State

            -- LSLQ - Logical shift left Q by 1
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 97 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100000",             fetchNOP,   '0'), -- 98 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluLSL,       "01100000",             fetchNOP,   '0'), -- 99 - Execute State

            -- LSRQ - Logical shift right Q by 1
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 100 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100001",             fetchNOP,   '0'), -- 101 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluLSR,       "01100001",             fetchNOP,   '0'), -- 102 - Execute State

            -- ASRQ - Arithmetic shift right Q by 1
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 103 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100010",             fetchNOP,   '0'), -- 104 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluASR,       "01100010",             fetchNOP,   '0'), -- 105 - Execute State

            -- RLCQ - Rotate Q left through carry
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 106 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100011",             fetchNOP,   '0'), -- 107 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluRLC,       "01100011",             fetchNOP,   '0'), -- 108 - Execute State

            -- RRCQ - Rotate Q right through carry
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 109 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "01100100",             fetchNOP,   '0'), -- 110 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluRRC,       "01100100",             fetchNOP,   '0'), -- 111 - Execute State

            -- SETC - Set carry flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 112 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000010",             fetchNOP,   '0'), -- 113 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluSETC,      "00000010",             fetchNOP,   '0'), -- 114 - Execute State

            -- CLRC - Clear carry flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 115 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000011",             fetchNOP,   '0'), -- 116 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluCLRC,      "00000011",             fetchNOP,   '0'), -- 117 - Execute State

            -- SETV - Set overflow flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 118 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000100",             fetchNOP,   '0'), -- 119 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluSETV,      "00000100",             fetchNOP,   '0'), -- 120 - Execute State

            -- CLRV - Clear overflow flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 121 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000101",             fetchNOP,   '0'), -- 122 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluCLRV,      "00000101",             fetchNOP,   '0'), -- 123 - Execute State

            -- SETN - Set negative flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 124 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000110",             fetchNOP,   '0'), -- 125 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluSETN,      "00000110",             fetchNOP,   '0'), -- 126 - Execute State

            -- CLRN - Clear negative flag
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 127 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000111",             fetchNOP,   '0'), -- 128 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluCLRN,      "00000111",             fetchNOP,   '0'), -- 129 - Execute State

            -- NOP - No Operation - Only PC is incremented
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 130 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000000",             fetchNOP,   '0'), -- 131 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000000",             fetchNOP,   '0'), -- 132 - Execute State

            -- HALT - CPU is halted until reset
            ('0',   '1',    regWideOut,     "00",     "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- 133 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 134 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 135 - Execute State
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 136 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 137 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 138 - Execute State
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 139 - Fetch State 
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0'), -- 140 - Load State  
            ('0',   '0',    regNOP,         "00",     "00000000",   aluNOP,       "00000001",             fetchNOP,   '0')  -- 141 - Execute State
        );
    begin

        for i in test_pattern'range loop
            -- Set input signals
            rst <= test_pattern(i).rst;
            aluFlagBus <= test_pattern(i).aluFlagBus;
            fetchInstructionBus <= test_pattern(i).fetchInstructionBus;
            
            wait for 20 ns;

            assert regIncPC = test_pattern(i).regIncPC
                report "Bad 'regIncPC' value " & to_string(regIncPC) & 
                        ", expected " & to_string(test_pattern(i).regIncPC) &
                        " at test pattern index " & integer'image(i) severity error;

            assert regOpCode = test_pattern(i).regOpCode
                report "Bad 'regOpCode' value " & to_string(regOpCode) & 
                        ", expected " & to_string(test_pattern(i).regOpCode) &
                        " at test pattern index " & integer'image(i) severity error;
                        
            assert regAddrBus = test_pattern(i).regAddrBus
                report "Bad 'regAddrBus' value " & to_string(regAddrBus) & 
                        ", expected " & to_string(test_pattern(i).regAddrBus) & 
                        " at test pattern index " & integer'image(i) severity error;

            assert aluOpCode = test_pattern(i).aluOpCode
                report "Bad 'aluOpCode' value " & to_string(aluOpCode) & 
                        ", expected " & to_string(test_pattern(i).aluOpCode) & 
                        " at test pattern index " & integer'image(i) severity error;

            assert fetchOpCode = test_pattern(i).fetchOpCode
                report "Bad 'fetchOpCode' value " & to_string(fetchOpCode) & 
                        ", expected " & to_string(test_pattern(i).fetchOpCode) & 
                        " at test pattern index " & integer'image(i) severity error;
                    
            assert fetchAddrBusLock = test_pattern(i).fetchAddrBusLock
                report "Bad 'fetchAddrBusLock' value " & to_string(fetchAddrBusLock) & 
                        ", expected " & to_string(test_pattern(i).fetchAddrBusLock) & 
                        " at test pattern index " & integer'image(i) severity error;
        end loop;

        assert false report "End Of Test - All Tests Successful!" severity note;
        wait;
    end process;

end behavioural;