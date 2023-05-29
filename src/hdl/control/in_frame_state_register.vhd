library IEEE;
use IEEE.std_logic_1164.all;

use work.types.all;


-- This module is only used to avoid update the pose infomation during one frame.
entity in_frame_state_register is
    port (
        clk, rst: in std_logic;
        update_sync: in std_logic;
        p1_pos_in, p2_pos_in: in vec2i_t;
        angle_in: in vec2i_t;
        ball_pos_in: in vec3i_t;
        p1_pos, p2_pos: out vec2i_t;
        angle: out vec2i_t;
        ball_pos: out vec3i_t
    );
end entity;


architecture Behavioral of in_frame_state_register is
    signal p1_pos_reg, p1_pos_next: vec2i_t;
    signal p2_pos_reg, p2_pos_next: vec2i_t;
    signal angle_reg, angle_next: vec2i_t;
    signal ball_pos_reg, ball_pos_next: vec3i_t;
begin
    process (clk, rst) is
    begin
        if rst = '1' then
            p1_pos_reg <= p1_pos_in;
            p2_pos_reg <= p2_pos_in;
            angle_reg <= angle_in;
            ball_pos_reg <= ball_pos_in;
        elsif rising_edge(clk) then
            p1_pos_reg <= p1_pos_next;
            p2_pos_reg <= p2_pos_next;
            angle_reg <= angle_next;
            ball_pos_reg <= ball_pos_next;
        end if;
    end process;
    
    p1_pos_next <= p1_pos_in when update_sync = '1' else p1_pos_reg;
    p2_pos_next <= p2_pos_in when update_sync = '1' else p2_pos_reg;
    angle_next <= angle_in when update_sync = '1' else angle_reg;
    ball_pos_next <= ball_pos_in when update_sync = '1' else ball_pos_reg;
    
    p1_pos <= p1_pos_reg;
    p2_pos <= p2_pos_reg;
    angle <= angle_reg;
    ball_pos <= ball_pos_reg;
end architecture;
