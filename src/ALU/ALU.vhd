-------------------------------------------------------------------------
-- ALU.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a mips ALU
--
-- REQUIRES: MIPS_types.vhd
-------------------------------------------------------------------------

-- library declaration
library IEEE;
use IEEE.std_logic_1164.all;

-- constants & types declaration
library work;
use work.MIPS_types.all;


entity ALU is
    port (
        iX1 : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        iX2 : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        iALUOp : in std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        oResult : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        oCout : out std_logic;
        oOverflow : out std_logic;
        oZero : out std_logic);
end ALU;

architecture mixed of control is

    component add_sub is
        port(
            iSubtract : in std_logic;
            iA	    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            iB	    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            oSum	: out std_logic_vector(DATA_WIDTH-1 downto 0);
            oCout 	: out std_logic;
            oCout2  : out std_logic);
    end component;

    component barrel_shifter is
        port(
            iLeft       : in std_logic;
            iArithmetic : in std_logic;
            iA          : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            iShamt      : in std_logic_vector(DATA_SELECT - 1 downto 0);
            oResult     : out std_logic_vector(DATA_WIDTH - 1 downto 0));
    end component;

signal s_subtract : std_logic;
signal s_add_sub_result : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal s_barrel_shifter_result : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal s_set_less_than_result : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal s_cout, s_cout2 : std_logic;

signal s_left_shift : std_logic;

signal s_overflow : std_logic;

begin

    -- Set parameters for ALU components
    s_subtract <= iALUOp(0);
    s_left_shift <= NOT iALUOP(1);
    s_arithmetic_shift <= iALUOP(0);
    
    add_sub_C: add_sub
    port map(
        iSubtract => s_subtract,
        iA	    => iX1,
        iB	    => iX2,
        oSum	=> s_add_sub_result,
        oCout 	=> s_cout,
        oCout2  => s_cout2);

    barrel_shifter_C: barrel_shifter
    port map(
        iA => iX1,
        iLeft => s_left_shift,
        iArithmetic => s_iArithmetic,
        iShamt => s_iShamt,
        oResult => s_barrel_shifter_result);


    
    -- Set overflow signal
    s_overflow <= s_cout XOR s_cout2;
    oOverflow <= s_overflow;
    
    -- Set less than result using Overflow detect and result from (a-b)
    s_set_less_than_result <= "000000000000000000000000000000" & (s_add_sub_result(DATA_WIDTH - 1) XOR s_overflow)

    -- Set carry out bit
    oCout <= s_cout;


    -- Select ALU result
    with iALUOP select
        oResult <=
            s_add_sub_result when "001-"
            iA AND iB when "0100",
            iA OR iB when "0101",
            iA XOR iB when "0111",
            iA NOR iB when "0110",
            s_barrel_shifter_result when "10--",
            s_set_less_than_result when "11--";
            -- sll when 1000
            -- srl when 1010
            -- sra when 1011
    
    -- Set result bit
    with oResult select
        oZero <=
            '1' when x"00000000",
            '0' when others;
      
end mixed;