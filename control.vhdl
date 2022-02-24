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
end controlUnit;

architecture rtl of controlUnit is
    type state_type is (fetch, load, execute, increment, halt);
    signal stateMachine : state_type := fetch;

    signal nextState : std_logic;
begin
    stateDecodeProcess : process (clk) is
    begin
        if rising_edge(clk) then
            case stateMachine is
                -----------------
                -- FETCH STATE --
                -----------------
                when fetch =>
                    -- ALU off
                    aluOpCode <= aluNOP;
                    -- Put program counter onto address bus
                    regOpCode <= regWideOut;
                    regAddrBus <= regPC_slv;
                    -- Read out address onto instruction bus
                    fetchOpCode <= fetchLDI;
                    fetchAddrBusLock <= '1';
                    -- Move to the next state
                    nextState <= '1';

                ----------------
                -- LOAD STATE --
                ----------------    
                when load =>
                    if fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpLDxY then
                        -- First put the target 16-bit register onto the address bus
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpLDLx then
                        -- Increment the PC register to get the address of the next byte in memory
                        regOpCode <= regIncPC;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(1 downto 0);
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlMoveOperandOpCodeWidth) = cpuOpMVxy then
                        -- Load the source register onto the data bus
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
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
                        -- ALU stores data bus to accumulator temporary register
                        aluOpCode <= aluLDT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    else  -- This covers the NOP, HALT, NOTQ, INCQ, DECQ, LSLQ, LSRQ, ASRQ, RLCQ, RRCQ and SET/CLR cases.
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
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
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit loads byte from memory to the data bus
                        fetchOpCode <= fetchLDD;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlAddrOperandOpCodeWidth) = cpuOpLDLx then
                        -- First put the target 16-bit register onto the address bus
                        regOpCode <= regWideOut;
                        regAddrBus <= fetchInstructionBus(regAddrBusWidth downto 0);
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlLdStOperandOpCodeWidth) = cpuOpSTxY then
                        -- Register puts the byte of memory to be saved onto the data bus
                        if fetchInstructionBus(2) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(4 downto 3);
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing other than latch the address bus
                        fetchOpCode <= fetchSTD;
                        fetchAddrBusLock <= '1';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlMoveOperandOpCodeWidth) = cpuOpMVxy then
                        -- Register puts the byte of memory to be saved onto the data bus
                        if fetchInstructionBus(3) = '1' then
                            regOpCode <= regHalfInH;
                        else
                            regOpCode <= regHalfInL;
                        end if;
                        regAddrBus <= fetchInstructionBus(5 downto 4);
                        -- ALU does nothing
                        aluOpCode <= aluRDT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';    
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADDx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluADD;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpADCx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluADC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSUBx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluSUB;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpSBBx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluSBB;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpANDx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluAND;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpXORx then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluXOR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlDataOperandOpCodeWidth) = cpuOpORx  then
                        -- Load target register to data bus, selecting the correct 8-bit register
                        if fetchInstructionBus(0) = '1' then
                            regOpCode <= regHalfOutH;
                        else
                            regOpCode <= regHalfOutL;
                        end if;
                        regAddrBus <= fetchInstructionBus(2 downto 1);
                        -- ALU stores data bus to accumulator temporary register
                        aluOpCode <= aluOR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpNOTQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluNOT;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpINCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluINC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpDECQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluDEC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpLSLQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluLSL;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpLSRQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluLSR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpASRQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluASR;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpRLCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluRLC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpRRCQ then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluRRC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETC then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluSETC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRC then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluCLRC;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETV then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluSETV;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRV then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluCLRV;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpSETN then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluSETN;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    elsif fetchInstructionBus(fetchInstructionWidth-1 downto fetchInstructionWidth-controlZeroOperandOpCodeWidth) = cpuOpCLRN then
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluCLRN;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    else  -- This covers the NOP, HALT, JPS/JPC, WRQ, and RDQ cases.
                        -- Registers do nothing
                        regOpCode <= regNOP;
                        regAddrBus <= (others => '0');
                        -- ALU does nothing
                        aluOpCode <= aluNOP;
                        -- Fetch Unit does nothing
                        fetchOpCode <= fetchNOP;
                        fetchAddrBusLock <= '0';
                    end if;

                ---------------
                -- Increment --
                ---------------
                when increment =>
                    -- Registers do nothing
                    regOpCode <= regIncPC;
                    regAddrBus <= (others => '0');
                    -- ALU does nothing
                    aluOpCode <= aluNOP;
                    -- Fetch Unit does nothing
                    fetchOpCode <= fetchNOP;
                    fetchAddrBusLock <= '0'; 
            end case;
        end if;
    end process;

    stateMachineProcess : process (clk, rst, nextState) is
    begin
        if rst then
            stateMachine <= fetch;
        elsif rising_edge(clk) then
            case stateMachine is
                when fetch =>
                    if nextState <= '1' then
                        stateMachine <= load;
                    end if;
                when load =>
                    if nextState <= '1' then
                        stateMachine <= execute;
                    end if;
                when execute =>
                    if nextState <= '1' then
                        stateMachine <= increment;
                    end if;
                when increment =>
                    if nextState <= '1' then
                        stateMachine <= fetch;
                    end if;
            end case;
            nextState <= '0';
        end if;
    end process;


end rtl;
