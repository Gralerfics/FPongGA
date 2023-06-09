library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.constants.all;
use work.types.all;


entity top_module_tb is
end entity;


architecture Behavioral of top_module_tb is
    component top_module is
        port (
            clk_sys, rst: in std_logic;
            spi_cs, spi_clk, spi_mosi: out std_logic;
            spi_miso: in std_logic;
            vgaout: out vga_t
        );
    end component;
    
    signal clk_sys, rst: std_logic;
    signal spi_cs, spi_clk, spi_mosi: std_logic;
    signal spi_miso: std_logic;
    signal vgaout: vga_t;
begin
    uut: top_module
        port map (
            clk_sys => clk_sys,
            rst => rst,
            spi_cs => spi_cs,
            spi_clk => spi_clk,
            spi_mosi => spi_mosi,
            spi_miso => spi_miso,
            vgaout => vgaout
        );
    
    clk_gen: process
    begin
        clk_sys <= '0';
        wait for 5 ns;
        clk_sys <= '1';
        wait for 5 ns;
    end process;

    rst <= '1', '0' after 200 ns;

    spi_miso <= '1';
end architecture;
