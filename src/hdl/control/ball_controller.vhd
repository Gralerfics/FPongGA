library IEEE;
use IEEE.std_logic_1164.all;

use work.types.all;
use work.constants.all;


entity ball_controller is
    port (
        clk, rst: in std_logic;
        p1_pos, p2_pos: in vec2i_t;
        current_ball_pos: out vec3i_t;
        score_1_out, score_2_out: out int
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

    constant UPDATE_FREQ: integer := 25;
    constant INIT_V: int := 180;
    constant V_MAX: int := 128;
    constant G: int := 12;

    signal ball_pulse: std_logic;
    signal ball_pos, ball_pos_next: vec3i_t;
    signal ball_v, ball_v_next: vec3i_t;
    signal from_who, from_who_next: std_logic; -- '0': 1, '1': 2
    signal score_1, score_1_next: int;
    signal score_2, score_2_next: int;
begin
    ball_freq_div: frequency_divider
        generic map (PERIOD => PPL_FREQ / UPDATE_FREQ)
        port map (
            clk => clk,
            rst => rst,
            en => '1',
            pulse => ball_pulse
        );

    process (clk, rst) is
    begin
        if rst = '1' then
            ball_pos <= (0, 0, NET_HEIGHT);
            ball_v <= (INIT_V, 0, 0);
            from_who <= '1';
            score_1 <= 0;
            score_2 <= 0;
        elsif rising_edge(clk) and ball_pulse = '1' then
            ball_pos <= ball_pos_next;
            ball_v <= ball_v_next;
            from_who <= from_who_next;
            score_1 <= score_1_next;
            score_2 <= score_2_next;
        end if;
    end process;

    process (all) is
        variable uv: vec2i_t;
    begin
        -- Defaults
        ball_pos_next <= ball_pos + ball_v * TABLE_LENGTH / UPDATE_FREQ / V_MAX / 3;
        ball_v_next <= (ball_v.x, ball_v.y, ball_v.z - G);
        from_who_next <= from_who;
        score_1_next <= score_1;
        score_2_next <= score_2;
        -- Touch the Paddle
        if ball_pos.x <= -PADDLE_DIST + BALL_RADIUS and ball_pos.x >= -PADDLE_DIST - BALL_RADIUS and ball_v.x < 0 then
            uv := vec2i_t'(-ball_pos.y, ball_pos.z) - p1_pos;
            if uv.x <= PADDLE_WIDTH / 2 + BALL_RADIUS and uv.x >= -PADDLE_WIDTH / 2 - BALL_RADIUS and uv.y <= PADDLE_HEIGHT / 2 + BALL_RADIUS and uv.y >= -PADDLE_HEIGHT / 2 - BALL_RADIUS then
                ball_pos_next.x <= -PADDLE_DIST + BALL_RADIUS;
                ball_v_next.x <= -ball_v.x;
                ball_v_next.y <= ball_v.y - uv.x * 3 / 2;
                ball_v_next.z <= (uv.y + 10) * 4 - G;
                from_who_next <= '0';
            end if;
        elsif ball_pos.x >= PADDLE_DIST - BALL_RADIUS and ball_pos.x <= PADDLE_DIST + BALL_RADIUS and ball_v.x > 0 then
            uv := vec2i_t'(ball_pos.y, ball_pos.z) - p2_pos;
            if uv.x <= PADDLE_WIDTH / 2 + BALL_RADIUS and uv.x >= -PADDLE_WIDTH / 2 - BALL_RADIUS and uv.y <= PADDLE_HEIGHT / 2 + BALL_RADIUS and uv.y >= -PADDLE_HEIGHT / 2 - BALL_RADIUS then
                ball_pos_next.x <= PADDLE_DIST - BALL_RADIUS;
                ball_v_next.x <= -ball_v.x;
                ball_v_next.y <= ball_v.y + uv.x * 3 / 2;
                ball_v_next.z <= (uv.y + 10) * 4 - G;
                from_who_next <= '1';
            end if;
        end if;
        -- Touch the Table
        if ball_pos.z <= BALL_RADIUS and ball_v.z < 0 and ball_pos.x >= -TABLE_LENGTH / 2 and ball_pos.x <= TABLE_LENGTH / 2 and ball_pos.y >= -TABLE_WIDTH / 2 and ball_pos.y <= TABLE_WIDTH / 2 then
            ball_pos_next.z <= BALL_RADIUS;
            ball_v_next.z <= -ball_v.z * 9 / 10 - G;
        end if;
        -- Lost
        if (ball_pos.x > PADDLE_DIST * 4 / 3) or (ball_pos.x < -PADDLE_DIST * 4 / 3) or (ball_pos.z < - NET_HEIGHT * 2) then
            ball_pos_next <= (0, 0, NET_HEIGHT);
            ball_v_next <= (INIT_V, 0, 0);
            from_who_next <= '1';
            if from_who = '0' then
                score_2_next <= score_2 + 1;
            else
                score_1_next <= score_1 + 1;
            end if;
        end if;
    end process;

    current_ball_pos <= ball_pos;
    score_1_out <= score_1;
    score_2_out <= score_2;
end architecture;
