library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ieee08;
use ieee08.fixed_pkg.all;

use work.types.all;

entity accumulator is
    generic(
        size : integer := 3
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        values : in  sfixed_bus_array(size - 1 downto 0);
        weights : in sfixed_bus_array(size downto 0);
        input_en : in std_logic;
        result : out sfixed_bus;
        done_o : out std_logic
    );
end entity accumulator;


-- The accumulator should be a higher level abstraction
-- Following the multiplier model but not limited to multiples of 2
-- For a basic design we will implement the basic multiplication before having our own multiplier design
architecture rtl of accumulator is
    type state is (idle, reg_input, sum, mult, done);
    signal curr_state, next_state : state;
    signal sum_sig : sfixed(int_s - 1 downto -frac_s) := (others => '0');
    signal mul_sig : sfixed(2 * int_s - 1 downto -2 * frac_s) := (others => '0');
    signal input_sig : sfixed_bus_array(size - 1 downto 0) := (others => (others => '0'));
    signal weights_sig : sfixed_bus_array(size downto 0) := weights;
    signal result_sig : sfixed_bus := (others => '0');
    signal done_sig : std_logic := '0';
    signal index : integer := 0;
begin

    transition_fsm : process(curr_state, clk, rst) is

    begin
        if rising_edge(clk) then
            if rst = '1' then
                curr_state <= idle;
            end if;
            curr_state <= next_state;
        end if;

    end process transition_fsm;


    rtl_fsm: process (curr_state, input_en, input_sig, values, input_en, weights_sig, mul_sig) is
    begin
        case curr_state is
            when idle =>
                done_sig <= '0';
                if input_en = '1' then
                    next_state <= reg_input;
                else
                    next_state <= idle;
                end if;
            when reg_input =>
                input_sig <= values;
                sum_sig <= resize(weights_sig(size), int_s, -frac_s);
                mul_sig <= (others => '0');
                index <= size;
                next_state <= mult;
            when mult =>
                if index = 0 then
                    next_state <= done;
                else
                    mul_sig <= input_sig(index - 1) * weights_sig(index - 1);
                    next_state <= sum;
                end if;

            when sum =>
                index <= index - 1;
                sum_sig <= resize(sum_sig, int_s - 1, -frac_s) + resize(mul_sig, int_s - 1, -frac_s);
                next_state <= mult;

            when done =>
                result_sig <= sum_sig;
                done_sig <= '1';
            when others =>
                null;
        end case;
    end process rtl_fsm;

    result <= result_sig;
    done_o <= done_sig;
end architecture rtl;
