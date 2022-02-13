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
        ( -- rst  regOpCode     regAddrBus  aluFlagBus    aluOpCode     fetchInstructionBus     fetchOpCode fetchAddrBusLock
            ('1', regWideOut,   "00",       "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- Fetch State
            ('0', regWideOut,   "00",       "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- Fetch State
            ('0', regWideOut,   "00",       "00000000",   aluNOP,       "11001000",             fetchNOP,   '1'), -- Load State (LDALB - load reg AL from address in PC) 
            ('0', regHalfInL,   "01",       "00000000",   aluNOP,       "11001000",             fetchLDD,   '0'), -- Execute State
            ('0', regIncPC,     "00",       "00000000",   aluNOP,       "11001000",             fetchNOP,   '0'), -- Increment State

            ('0', regWideOut,   "00",       "00000000",   aluNOP,       "--------",             fetchLDI,   '1'), -- Fetch State
            ('0', regHalfOutL,  "11",       "00000000",   aluLDA,       "00100110",             fetchNOP,   '0'), -- Load State (MVCLQ - load CL into Q) 
            ('0', regNOP,       "00",       "00000000",   aluNOP,       "00100110",             fetchNOP,   '0'), -- Execute State
            ('0', regIncPC,     "00",       "00000000",   aluNOP,       "00100110",             fetchNOP,   '0')  -- Increment State

        );
    begin

        for i in test_pattern'range loop
            -- Set input signals
            rst <= test_pattern(i).rst;
            aluFlagBus <= test_pattern(i).aluFlagBus;
            fetchInstructionBus <= test_pattern(i).fetchInstructionBus;
            
            wait for 20 ns;

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