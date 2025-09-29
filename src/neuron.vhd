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

begin
end architecture rtl;
