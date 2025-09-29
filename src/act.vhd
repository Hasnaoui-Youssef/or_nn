library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

use work.types.all;


entity act_fn is
    port(
        input_i : in sfixed_bus;
        output_o : out sfixed_bus := (others => '0')
    );
end entity act_fn;

architecture relu of act_fn is
begin
    output_o <= input_i when input_i >= 0 else to_sfixed_a(0);
end architecture relu;
