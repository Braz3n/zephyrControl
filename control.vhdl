use work.controlConstants.all;
use work.registerConstants.all;
use work.fetchConstants.all;
use work.aluConstants.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlUnit is
    port (
        rst             : in std_logic;
        clk             : in std_logic;
        
        state           : out std_logic_vector (1 downto 0);

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
end controlUnit;

architecture rtl of controlUnit is
    type state_type is (init, prefetch, fetch, load, postload, execute, halt);
    signal stateMachine : state_type := init;
    signal postFetchState : state_type;
    
    signal halted : std_logic := '0';
begin
    stateOutputProcess : process (state) is
    begin
        if stateMachine = prefetch or stateMachine = fetch then
            state <= "00";
        elsif stateMachine = load or stateMachine = postload then
             state <= "01";
        elsif stateMachine = execute then
             state <= "10";
        else -- Halt or Init
             state <= "11";
        end if;
    end process;

    stateDecodeProcess : process (clk, stateMachine, fetchInstructionBus) is
    begin
--        if rising_edge(clk) then
            case stateMachine is
                -----------------
                -- FETCH STATES --
                -----------------
                when prefetch =>
                    -- ALU off
                    aluOpCode <= aluNOP;
                    -- Put program counter onto address bus and increment PC for the next instruction
                    regOpCode <= regWideOut;
                    regAddrBus <= regPC_slv;
                    regIncPC <= '1';
                    -- Read out address onto instruction bus
                    fetchOpCode <= fetchLDI;
                    fetchAddrBusLock <= '1';
                    
                when fetch =>
                    -- ALU off
                    aluOpCode <= aluNOP;
                    -- Put program counter onto address bus
                    regOpCode <= regWideOut;
                    regAddrBus <= regPC_slv;
                    regIncPC <= '0';
                    -- Read out address onto instruction bus
                    fetchOpCode <= fetchLDI;
                    fetchAddrBusLock <= '1';

                ----------------
                -- LOAD STATE --
                ----------------    
                when load =>
                    if fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpLDxY then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpLDLx then
                        -- Read out the next byte in memory and increment PC for the next instruction.
                        regOpCode <= regWideOut;
                        regAddrBus <= regPC_slv;
                        regIncPC <= '1';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlMoveOperandOpCodeWidth) = cpuOpMVxy then
                        -- Load the source register onto the data bus
                        if fetchInstructionBus(3) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(5 downto 4);
                        regIncPC <= '0';
                        -- Store data bus into ALU temp
                        aluOpCode <= aluLDT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSC then
                        -- Update PC if carry flag is set
                        if aluFlagBus(aluCarryFlagIndex) = '1' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCC then
                        -- Update PC if carry flag is cleared
                        if aluFlagBus(aluCarryFlagIndex) = '0' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSV then
                        -- Update PC if overflow flag is set
                        if aluFlagBus(aluOverflowFlagIndex) = '1' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCV then
                        -- Update PC if overflow flag is cleared
                        if aluFlagBus(aluOverflowFlagIndex) = '0' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSN then
                        -- Update PC if negative flag is set
                        if aluFlagBus(aluNegativeFlagIndex) = '1' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCN then
                        -- Update PC if negative flag is cleared
                        if aluFlagBus(aluNegativeFlagIndex) = '0' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSZ then
                        -- Update PC if zero flag is set
                        if aluFlagBus(aluZeroFlagIndex) = '1' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCZ then
                        -- Update PC if zero flag is cleared
                        if aluFlagBus(aluZeroFlagIndex) = '0' then
                            regOpCode <= regCpyToPC;
                        else
                            regOpCode <= regNOP;
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpWRQx then
                        -- Load target register to data bus, selecting the correct 8-bit register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        regIncPC <= '0';
                        -- ALU stores data bus to accumulator register
                        aluOpCode <= aluLDA;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpRDQx then
                        -- Save data bus value to target register, selecting the correct 8-bit register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        regIncPC <= '0';
                        -- ALU reads out accumulator register onto the data bus
                        aluOpCode <= aluRDA;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADDx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADCx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSUBx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSBBx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpANDx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpXORx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpORx  then
                        -- Load target register to data bus, selecting the correct 8-bit register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        regIncPC <= '0';
                        -- ALU stores data bus to accumulator temporary register
                        aluOpCode <= aluLDT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpHALT then
                        halted <= '1';
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU clears flag
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    else  -- This covers the NOP, HALT, NOTQ, INCQ, DECQ, LSLQ, LSRQ, ASRQ, RLCQ, RRCQ and SET/CLR cases.
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    end if;
                    
                --------------------
                -- POSTLOAD STATE --
                --------------------
                when postload =>
                    if fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpLDxY then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpLDLx then
                        -- Read out the next byte in memory.
                        regOpCode <= regWideOut;
                        regAddrBus <= regPC_slv;
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '1';
                    else
                        -- Read out the next byte in memory and increment PC for the next instruction.
                        regOpCode <= regNOP;
                        regAddrBus <= regPC_slv;
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    end if;

                -------------------
                -- EXECUTE STATE --
                -------------------
                when execute =>
                    if fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpLDxY then
                        -- Store the data bus into target 8-bit register
                        if fetchInstructionBus(2) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(4 downto 3);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit loads byte from memory to the data bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpLDLx then
                        -- Store the data bus into target 8-bit register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit loads byte from memory to the data bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        -- Register puts the byte of memory to be saved onto the data bus
                        if fetchInstructionBus(2) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(4 downto 3);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchSTD;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlMoveOperandOpCodeWidth) = cpuOpMVxy then
                        -- Write the data bus to the target register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluRDT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSC then
                        -- Update PC if carry flag is set
                        if aluFlagBus(aluCarryFlagIndex) = '1' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCC then
                        -- Update PC if carry flag is cleared
                        if aluFlagBus(aluCarryFlagIndex) = '0' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSV then
                        -- Update PC if overflow flag is set
                        if aluFlagBus(aluOverflowFlagIndex) = '1' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCV then
                        -- Update PC if overflow flag is cleared
                        if aluFlagBus(aluOverflowFlagIndex) = '0' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSN then
                        -- Update PC if negative flag is set
                        if aluFlagBus(aluNegativeFlagIndex) = '1' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCN then
                        -- Update PC if negative flag is cleared
                        if aluFlagBus(aluNegativeFlagIndex) = '0' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPSZ then
                        -- Update PC if zero flag is set
                        if aluFlagBus(aluZeroFlagIndex) = '1' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpJPCZ then
                        -- Update PC if zero flag is cleared
                        if aluFlagBus(aluZeroFlagIndex) = '0' then
                            regOpCode <= regWideOut;
                            -- Preload fetch unit with next address
                            fetchAddrBusLock <= '1';
                        else
                            regOpCode <= regNOP;
                            -- No change to the next address
                            fetchAddrBusLock <= '0';
                        end if;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth-1 downto 0);
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADDx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluADD;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADCx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluADC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSUBx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluSUB;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSBBx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluSBB;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpANDx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluAND;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpXORx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluXOR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpORx  then
                        -- Load target register to data bus, selecting the correct 8-bit register
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU stores data bus to accumulator temporary register
                        aluOpCode <= aluOR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpNOTQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU calculates the bitwise NOT of Q
                        aluOpCode <= aluNOT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpINCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU increments Q
                        aluOpCode <= aluINC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpDECQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU decrements Q
                        aluOpCode <= aluDEC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpLSLQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU executes shift operation
                        aluOpCode <= aluLSL;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpLSRQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU executes shift operation
                        aluOpCode <= aluLSR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpASRQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU executes shift operation
                        aluOpCode <= aluASR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpRLCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU executes rotation operation
                        aluOpCode <= aluRLC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpRRCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU executes rotation operation
                        aluOpCode <= aluRRC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETC then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU sets flag
                        aluOpCode <= aluSETC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRC then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU clears flag
                        aluOpCode <= aluCLRC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETV then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU sets flag
                        aluOpCode <= aluSETV;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRV then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU clears flag
                        aluOpCode <= aluCLRV;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETN then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU ALU sets flag
                        aluOpCode <= aluSETN;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRN then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU clears flag
                        aluOpCode <= aluCLRN;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    else  -- This covers the NOP, HALT, JPS/JPC, WRQ, and RDQ cases.
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        regIncPC <= '0';
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    end if;
                    
                ----------
                -- Halt --
                ---------- 
                when halt => 
                    -- Registers do nothing
                    regOpCode <= regNOP;
                    regAddrBus <= (others => '0');
                    regIncPC <= '1';
                    -- ALU does nothing
                    aluOpCode <= aluNOP;
                    -- Fetch Unit does nothing
                    fetchOpCode <= fetchNOP;
                    fetchAddrBusLock <= '0';
                    
                ----------
                -- Init --
                ---------- 
                when others =>
                    -- Registers do nothing
                    regOpCode <= regNOP;
                    regAddrBus <= (others => '0');
                    regIncPC <= '0';
                    -- ALU does nothing
                    aluOpCode <= aluNOP;
                    -- Fetch Unit does nothing
                    fetchOpCode <= fetchNOP;
                    fetchAddrBusLock <= '0';
            end case;
--        end if;
    end process;

    stateMachineProcess : process (clk, rst) is
    begin
        if rst then
            stateMachine <= init;
        elsif rising_edge(clk) then
            case stateMachine is
                when init =>
                    stateMachine <= prefetch;
                when prefetch =>
                    stateMachine <= fetch;
                when fetch =>
                    stateMachine <= load;
                when load =>
                    if fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpLDLx or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpLDxY or
                        fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        stateMachine <= postload;
                    else
                        stateMachine <= execute;
                    end if;
                when postload =>
                    stateMachine <= execute;
                when execute =>
                    if halted = '1' then
                        stateMachine <= halt;
                    else
                        stateMachine <= prefetch;
                    end if;
                when halt =>
                    null;
            end case;
        end if;
    end process;


end rtl;
