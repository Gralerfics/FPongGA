library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.constants.all;
use work.types.all;


entity pipeline_entrance is
    port (
        clk_ppl, rst, enable: in std_logic;
        p_angle: in vec2i_t;
        is_preparing, is_eof: out std_logic;
        -- Pipeline Final States
        pixel_addr_pplout: in std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
        start_p_pplout: in vec3i_t;
        end_p_pplout: in vec3i_t;
        next_color_rec_pplout: in color_t;
        next_dist_rec_pplout: in int;
        idx_pplout: in int;
        next_shape_pplout: in shape_t;
        -- Pipeline Entrances
        pixel_addr: out std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
        start_p: out vec3i_t;
        end_p: out vec3i_t;
        color_rec: out color_t;
        dist_rec: out int;
        idx: out int;
        shape: out shape_t
    );
end entity;


architecture Behavioral of pipeline_entrance is
    component viewport_scanner is
        port (
            clk_ppl, rst, enable: in std_logic;
            fragment_uv: out vec2i_t
        );
    end component;

    component viewport_params is
        port (
            p_angle: in vec2i_t;
            p_pos, vp_origin, vp_u, vp_v: out vec3i_t
        );
    end component;

    type state_t is (BEFORE_PREPARE, PREPARING, RUNNING);

    constant PREPARE_CYCLES: int := 4;

    signal state, state_next: state_t;
    signal prepare_cnt, prepare_cnt_next: int;
    signal is_next_pixel: std_logic;
    signal is_eof_i, is_preparing_i: std_logic;
    signal vps_enable: std_logic;
    signal fragment_uv: vec2i_t;
    signal p_pos, vp_origin, vp_u, vp_v, vp_target: vec3i_t;
begin
    -- State Machine
    process (clk_ppl, rst) is
    begin
        if rst = '1' then
            state <= BEFORE_PREPARE;
            prepare_cnt <= 0;
        elsif rising_edge(clk_ppl) then
            state <= state_next;
            prepare_cnt <= prepare_cnt_next;
        end if;
    end process;

    is_next_pixel <= '1' when idx_pplout = OBJ_NUM - 1 else '0';

    is_eof_i <= '1' when pixel_addr_pplout = EOF_ADDR and is_next_pixel = '1' else '0';
    is_eof <= is_eof_i;

    is_preparing_i <= '1' when state /= RUNNING else '0';
    is_preparing <= is_preparing_i;

    process (state, prepare_cnt, is_eof_i) is
    begin
        state_next <= state;
        prepare_cnt_next <= prepare_cnt;
        case state is
            when BEFORE_PREPARE =>
                state_next <= PREPARING;
                prepare_cnt_next <= 0;
            when PREPARING =>
                if prepare_cnt = PREPARE_CYCLES - 1 then
                    state_next <= RUNNING;
                end if;
                prepare_cnt_next <= prepare_cnt + 1;
            when RUNNING =>
                if is_eof_i = '1' then
                    state_next <= BEFORE_PREPARE;
                end if;
                prepare_cnt_next <= 0;
        end case;
    end process;

    -- Viewport
    vp_scan: viewport_scanner
        port map (
            clk_ppl => clk_ppl,
            rst => rst,
            enable => vps_enable,
            fragment_uv => fragment_uv
        );
    vps_enable <= '1' when (is_next_pixel = '1') and (is_preparing_i = '0') else '0';
    
    vp_param: viewport_params
        port map (
            p_angle => p_angle,
            p_pos => p_pos,
            vp_origin => vp_origin,
            vp_u => vp_u,
            vp_v => vp_v
        );
    vp_target <= vp_origin + vp_u * fragment_uv.x * LOOKAT_REL_FAC / ANGLE_RADIUS - vp_v * fragment_uv.y * LOOKAT_REL_FAC / ANGLE_RADIUS; -- update when p_state updates, i.e., when preparing.

    -- Output Multiplexer
    pixel_addr <= pixel_addr_pplout when is_next_pixel = '0' else std_logic_vector(to_unsigned(fragment_uv.y * H_REAL + fragment_uv.x, DISP_RAM_ADDR_RADIX));
    start_p <= start_p_pplout when is_next_pixel = '0' else p_pos;
    end_p <= end_p_pplout when is_next_pixel = '0' else vp_target;
    color_rec <= next_color_rec_pplout when is_next_pixel = '0' else SKY_COLOR;
    dist_rec <= next_dist_rec_pplout when is_next_pixel = '0' else SKY_DIST;
    idx <= idx_pplout + 1 when is_next_pixel = '0' else 0;
    shape <= next_shape_pplout when is_next_pixel = '0' else TABLE;
end architecture;
