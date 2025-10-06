library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

use work.types.all;


entity neuron is
    generic(
        inputs : integer := 3
    );
    port(
        clk: in std_logic;
        reset: in std_logic;
        start_en : in std_logic; -- Start the calculations?
        input_i : in sfixed_bus_array(inputs - 1 downto 0);
        weights_i : in sfixed_bus_array(inputs downto 0); -- bias is here as well

        output_o : out sfixed_bus := (others => '0');
        done : out std_logic
    );
end entity neuron;


architecture rtl of neuron is
    component accumulator is
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
    end component accumulator;

    signal acc_output : sfixed_bus;
begin
    accumulator_inst: accumulator
     generic map(
        size => inputs
    )
     port map(
        clk => clk,
        rst => reset,
        values => input_i,
        weights => weights_i,
        input_en => start_en,
        result => acc_output,
        done_o => done
    );

    output_o <= acc_output when (acc_output >= 0 and done = '1') else to_sfixed_a(0);
end architecture rtl;
