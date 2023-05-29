library IEEE;
use IEEE.std_logic_1164.all;

use work.types.all;
use work.constants.all;


entity player_state_updater is
    port (
        clk, rst, enable: in std_logic;
        -- Paddles
        p1_lr_offset, p1_ud_offset, p2_lr_offset, p2_ud_offset: in int; -- -128 to 127
        current_p1_pos, current_p2_pos: out vec2i_t;
        -- Angle
        angle_lr_dir, angle_ud_dir: in int; -- -1 or 0 or 1, l and u is -1
        current_angle: out vec2i_t
    );
end entity;


architecture Behavioral of player_state_updater is
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

    component inventory_register is
        port (
            clk, rst, enable: in std_logic;
            last_item, next_item: in std_logic;
            current_item: out int
        );
    end component;

    constant BTN_UPDATE_FREQ: integer := 20;
    constant CONT_UPDATE_FREQ: integer := 20;

    signal btn_pulse: std_logic;
    signal ctrl_pulse: std_logic;

    signal current_p1_pos_reg, current_p1_pos_next: vec2i_t;
    signal current_p2_pos_reg, current_p2_pos_next: vec2i_t;
    signal current_angle_reg, current_angle_next: vec2i_t;
begin
    ctrl_freq_div: frequency_divider
        generic map (
            PERIOD => PPL_FREQ / CONT_UPDATE_FREQ
        )
        port map (
            clk => clk,
            rst => rst,
            en => enable,
            pulse => ctrl_pulse
        );
    
    btn_freq_div: frequency_divider
        generic map (
            PERIOD => PPL_FREQ / BTN_UPDATE_FREQ
        )
        port map (
            clk => clk,
            rst => rst,
            en => enable,
            pulse => btn_pulse
        );
    
    process (clk, rst) is
    begin
        if rst = '1' then
            current_p1_pos_reg <= vec2i_t'(0, NET_HEIGHT);
            current_p2_pos_reg <= vec2i_t'(0, NET_HEIGHT);
            current_angle_reg <= (-ANGLE_QUARTER, ANGLE_HALF / 3);
        elsif rising_edge(clk) then
            if ctrl_pulse = '1' then
                current_p1_pos_reg <= current_p1_pos_next;
                current_p2_pos_reg <= current_p2_pos_next;
            end if;
            if btn_pulse = '1' then
                current_angle_reg <= current_angle_next;
            end if;
        end if;
    end process;

    process (clk, rst) is
    begin
        current_p1_pos_next.x <= current_p1_pos_reg.x + p1_lr_offset * PADDLE_STEP / PSS_MIDDLE;
        current_p1_pos_next.y <= current_p1_pos_reg.y - p1_ud_offset * PADDLE_STEP / PSS_MIDDLE;
        current_p2_pos_next.x <= current_p2_pos_reg.x + p2_lr_offset * PADDLE_STEP / PSS_MIDDLE;
        current_p2_pos_next.y <= current_p2_pos_reg.y - p2_ud_offset * PADDLE_STEP / PSS_MIDDLE;
        current_angle_next.x <= current_angle.x + angle_lr_dir * ANGLE_STEP;
        current_angle_next.y <= current_angle.y - angle_ud_dir * ANGLE_STEP;
    end process;
    current_p1_pos <= current_p1_pos_reg;
    current_p2_pos <= current_p2_pos_reg;
    current_angle <= current_angle_reg;
end architecture;
