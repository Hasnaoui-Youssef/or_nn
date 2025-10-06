library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;
use ieee.numeric_std.all;

use work.types.all;

entity neuron_tb is
end entity neuron_tb;

architecture tb of neuron_tb is
    component neuron is
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
    end component neuron;
    constant half_p : time := 5 ns;
    constant inputs : integer := 2;


    signal clk : std_logic := '0';
    signal reset : std_logic := '0';

    signal start_en : std_logic := '0';

    signal input_i : sfixed_bus_array(inputs - 1 downto 0);
    signal weights_i : sfixed_bus_array(inputs downto 0) := (to_sfixed_a(10), to_sfixed_a(20), to_sfixed_a(30));

    signal output_o : sfixed_bus;
    signal output_done : std_logic;

    signal input_r : real_array(inputs - 1 downto 0);
    signal weights_r : real_array(inputs downto 0);
    signal output_r : real;
begin
    neuron_inst: neuron
     generic map(
        inputs => inputs
    )
     port map(
        clk => clk,
        reset => reset,
        start_en => start_en,
        input_i => input_i,
        weights_i => weights_i,
        output_o => output_o,
        done => output_done
    );
    clk <= not clk after half_p;
    input_r <= to_real(input_i);
    weights_r <= to_real(weights_i);
    output_r <= to_real(output_o);


    input_i <= ( (to_sfixed_a(0)), to_sfixed_a(20));
    start_en <= '0', '1' after 15 ns, '0' after 30 ns;
end architecture tb;
