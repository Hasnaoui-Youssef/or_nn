library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ieee;
use ieee.fixed_pkg.all;

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
--architecture rtl of accumulator is
--    type state is (idle, reg_input, sum, mult, done);
--    signal curr_state, next_state : state;
--    signal sum_sig : sfixed(2 * int_s - 1 downto -2 * frac_s) := (others => '0');
--    signal mul_sig : sfixed(2 * int_s - 1 downto -2 * frac_s) := (others => '0');
--    signal input_sig : sfixed_bus_array(size - 1 downto 0) := (others => (others => '0'));
--    signal weights_sig : sfixed_bus_array(size downto 0);
--    signal result_sig : sfixed_bus := (others => '0');
--    signal done_sig : std_logic := '0';
--    signal index : integer := 0;
--begin
--    weights_sig <= weights;
--
--    transition_fsm : process(curr_state, clk, rst) is
--
--    begin
--        if rising_edge(clk) then
--            if rst = '1' then
--                curr_state <= idle;
--            end if;
--            curr_state <= next_state;
--        end if;
--
--    end process transition_fsm;
--
--
--    rtl_fsm: process (curr_state, input_en, input_sig, values, input_en, weights_sig, mul_sig) is
--    begin
--        case curr_state is
--            when idle =>
--                done_sig <= '0';
--                if input_en = '1' then
--                    next_state <= reg_input;
--                else
--                    next_state <= idle;
--                end if;
--            when reg_input =>
--                input_sig <= values;
--                sum_sig <= resize(weights_sig(size),2 * int_s - 1, -2 * frac_s);
--                mul_sig <= (others => '0');
--                index <= size;
--                next_state <= mult;
--            when mult =>
--                if index = 0 then
--                    next_state <= done;
--                else
--                    mul_sig <= input_sig(index - 1) * weights_sig(index - 1);
--                    next_state <= sum;
--                end if;
--
--            when sum =>
--                index <= index - 1;
--                sum_sig <= sum_sig + mul_sig;
--                next_state <= mult;
--
--            when done =>
--                result_sig <= resize(sum_sig, int_s - 1, -frac_s);
--                done_sig <= '1';
--            when others =>
--                null;
--        end case;
--    end process rtl_fsm;
--
--    result <= result_sig;
--    done_o <= done_sig;
--end architecture rtl;
architecture rtl of accumulator is
    type state is (idle, reg_input, mult, sum, done);
    attribute enum_encoding : string;
    attribute enum_encoding of state : type is "000 001 010 011 100";

    -- accumulator width helpers
    constant acc_left  : integer := 2 * int_s - 1;  -- e.g. 31 when int_s=16
    constant acc_right : integer := -2 * frac_s;    -- e.g. -32 when frac_s=16

    -- internal registers (wide accumulator)
    signal curr_state : state := idle;
    signal sum_reg    : sfixed(acc_left downto acc_right) := (others => '0');
    signal mul_reg    : sfixed(acc_left downto acc_right) := (others => '0');
    signal index_reg  : integer := 0;

    signal debug_sum : std_logic_vector(63 downto 0);
    signal debug_mul : std_logic_vector(63 downto 0);
    -- outputs / status
    signal result_sig : sfixed_bus := (others => '0'); -- narrow output type (from package)
    signal done_sig   : std_logic := '0';

    -- next-state / next-values computed by comb. process
    signal next_state : state;
    signal next_sum   : sfixed(acc_left downto acc_right);
    signal next_mul   : sfixed(acc_left downto acc_right);
    signal next_index : integer;
    signal next_result: sfixed_bus;
    signal next_done  : std_logic;
begin
    debug_sum <= to_slv(sum_reg);
    debug_mul <= to_slv(mul_reg);

    ----------------------------------------------------------------------------
    -- Combinational: compute next-state & next-values (use variables!)
    ----------------------------------------------------------------------------
    comb_proc : process(curr_state, values, weights, sum_reg, mul_reg, index_reg, input_en)
        variable v_sum    : sfixed(acc_left downto acc_right);
        variable v_mul    : sfixed(acc_left downto acc_right);
        variable v_index  : integer;
        variable v_state  : state;
        variable v_done   : std_logic;
        variable v_result : sfixed_bus;
    begin
        -- defaults (copy current register state)
        v_state  := curr_state;
        v_sum    := sum_reg;
        v_mul    := mul_reg;
        v_index  := index_reg;
        v_done   := '0';
        v_result := (others => '0');

        case curr_state is
            when idle =>
                v_done := '0';
                if input_en = '1' then
                    v_state := reg_input;
                else
                    v_state := idle;
                end if;

            when reg_input =>
                -- initialize accumulator from highest weight (resize into wide acc)
                v_sum   := resize(weights(size), acc_left, acc_right);
                v_mul   := (others => '0');
                v_index := size;
                v_state := mult;

            when mult =>
                if v_index = 0 then
                    v_state := done;
                else
                    -- compute product and immediately resize it into the accumulator width
                    v_mul := resize(values(v_index - 1) * weights(v_index - 1),
                                    acc_left, acc_right);
                    v_state := sum;
                end if;

            when sum =>
                -- add the previously computed, already-resized mul to the (wide) sum
                -- we keep it in acc range; explicitly resize the sum-of-two to acc range
                v_sum := resize(v_sum + v_mul, acc_left, acc_right);
                v_index := v_index - 1;
                v_state := mult;

            when done =>
                -- present a narrow result and mark done
                v_result := resize(v_sum, int_s - 1, -frac_s);
                v_done := '1';
                v_state := idle; -- or keep 'done' if you prefer staying there

            when others =>
                null;
        end case;

        -- drive next signals
        next_state  <= v_state;
        next_sum    <= v_sum;
        next_mul    <= v_mul;
        next_index  <= v_index;
        next_result <= v_result;
        next_done   <= v_done;
    end process comb_proc;


    ----------------------------------------------------------------------------
    -- Clocked: update registers on rising edge
    ----------------------------------------------------------------------------
    clk_proc : process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                curr_state <= idle;
                sum_reg    <= (others => '0');
                mul_reg    <= (others => '0');
                index_reg  <= 0;
                result_sig <= (others => '0');
                done_sig   <= '0';
            else
                curr_state <= next_state;
                sum_reg    <= next_sum;
                mul_reg    <= next_mul;
                index_reg  <= next_index;
                -- result_sig is only meaningful when next_done = '1'
                result_sig <= next_result;
                done_sig   <= next_done;
            end if;
        end if;
    end process clk_proc;

    -- expose outputs
    result <= result_sig;
    done_o <= done_sig;

end architecture rtl;
