library IEEE;
use IEEE.std_logic_1164.all;

use work.types.all;
use work.constants.all;


entity ball_controller is
    port (
        clk, rst: in std_logic;
        p1_pos, p2_pos: in vec2i_t;
        current_ball_pos: out vec3i_t
    );
end entity;


architecture Behavioral of ball_controller is
    component frequency_divider is
        generic (
            PERIOD: integer := 100000
        );
        port (
            clk, rst: in std_logic;
            en: in std_logic;
            pulse: out std_logic
        );
    end component;

    constant UPDATE_FREQ: integer := 5;
    constant V_MAX: int := 128;
    constant DELTA_T: int := TABLE_LENGTH / (2 * UPDATE_FREQ);

    signal ball_pulse: std_logic;
    signal ball_pos, ball_pos_next: vec3i_t;
    signal ball_v, ball_v_next: vec3i_t;
begin
    ball_freq_div: frequency_divider
        generic map (PERIOD => PPL_FREQ / UPDATE_FREQ)
        port map (
            clk => clk,
            rst => rst,
            en => '1',
            pulse => ball_pulse
        );

    process (clk, rst)
    begin
        if rst = '1' then
            ball_pos <= (0, 0, NET_HEIGHT);
            ball_v <= (0, 0, 0);
        elsif rising_edge(clk) and ball_pulse = '1' then
            ball_pos <= ball_pos_next;
            ball_v <= ball_v_next;
        end if;
    end process;

    ball_pos_next <= ball_pos + ball_v * DELTA_T / V_MAX;

    ball_v_next <= ball_v;

    current_ball_pos <= ball_pos;
end architecture;
