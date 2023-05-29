library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.constants.all;
use work.types.all;


entity pipeline_process is
    port (
        clk_ppl, rst, enable: in std_logic;
        -- Data In
        p1_pos, p2_pos: in vec2i_t;
        ball_pos: in vec3i_t;
        -- Input Interface
        pixel_addr_in: in std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
        start_p_in: in vec3i_t;
        end_p_in: in vec3i_t;
        color_rec_in: in color_t;
        dist_rec_in: in int;
        idx_in: in int;
        shape_in: in shape_t;
        -- Output Interface
        pixel_addr_out: out std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
        start_p_out: out vec3i_t;
        end_p_out: out vec3i_t;
        next_color_rec_out: out color_t;
        next_dist_rec_out: out int;
        idx_out: out int;
        next_shape_out: out shape_t
    );
end entity;


architecture Behavioral of pipeline_process is
    -- component divider_gen is
    --     port (
    --         -- aclk: in std_logic;
    --         s_axis_divisor_tvalid: in std_logic;
    --         s_axis_divisor_tdata: in std_logic_vector(23 downto 0);
    --         s_axis_dividend_tvalid: in std_logic;
    --         s_axis_dividend_tdata: in std_logic_vector(23 downto 0);
    --         m_axis_dout_tvalid: out std_logic;
    --         m_axis_dout_tdata: out std_logic_vector(47 downto 0)
    --     );
    -- end component;

    component sqrt_gen is
        port (
            s_axis_cartesian_tvalid: in std_logic;
            s_axis_cartesian_tdata: in std_logic_vector(31 downto 0);
            m_axis_dout_tvalid: out std_logic;
            m_axis_dout_tdata: out std_logic_vector(23 downto 0)
        );
    end component;

    -- Stage 0
    signal pixel_addr_0, pixel_addr_0_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_0, start_p_0_next: vec3i_t;
    signal end_p_0, end_p_0_next: vec3i_t;
    signal color_rec_0, color_rec_0_next: color_t;
    signal dist_rec_0, dist_rec_0_next: int;
    signal idx_0, idx_0_next: int;
    signal shape_0, shape_0_next: shape_t;

    -- Stage 1
    signal pixel_addr_1, pixel_addr_1_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_1, start_p_1_next: vec3i_t;
    signal end_p_1, end_p_1_next: vec3i_t;
    signal idx_1, idx_1_next: int;
    signal color_rec_1, color_rec_1_next: color_t;
    signal dist_rec_1, dist_rec_1_next: int;
    signal shape_1, shape_1_next: shape_t;
    signal AB_1, AB_1_next: vec3i_t;
    signal AO_1, AO_1_next: vec3i_t;

    -- Stage 2
    signal pixel_addr_2, pixel_addr_2_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_2, start_p_2_next: vec3i_t;
    signal end_p_2, end_p_2_next: vec3i_t;
    signal idx_2, idx_2_next: int;
    signal color_rec_2, color_rec_2_next: color_t;
    signal dist_rec_2, dist_rec_2_next: int;
    signal shape_2, shape_2_next: shape_t;
    signal AB_2, AB_2_next: vec3i_t;
    signal AB_len_2, AB_len_2_next: int;
    signal AB_len2_raw_2: std_logic_vector(31 downto 0);
    signal AB_len_raw_2: std_logic_vector(23 downto 0);
    signal ABdotAO_2, ABdotAO_2_next: int;
    signal AO_len2_2, AO_len2_2_next: int;
    signal ABmAO_yx_2, ABmAO_yx_2_next: int;
    signal ABmAO_zx_2, ABmAO_zx_2_next: int;
    signal ABmAO_xy_2, ABmAO_xy_2_next: int;
    signal ABmAO_zy_2, ABmAO_zy_2_next: int;
    signal ABmAO_xz_2, ABmAO_xz_2_next: int;
    signal ABmAO_yz_2, ABmAO_yz_2_next: int;
    signal AO_mht_2, AO_mht_2_next: int;

    -- Stage 3
    signal pixel_addr_3, pixel_addr_3_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_3, start_p_3_next: vec3i_t;
    signal end_p_3, end_p_3_next: vec3i_t;
    signal idx_3, idx_3_next: int;
    signal color_rec_3, color_rec_3_next: color_t;
    signal dist_rec_3, dist_rec_3_next: int;
    signal shape_3, shape_3_next: shape_t;
    signal AB_3, AB_3_next: vec3i_t;
    signal D_len_3, D_len_3_next: int;
    signal AO_len2_3, AO_len2_3_next: int;
    signal m_div_AB_yx_3, m_div_AB_yx_3_next: int;
    signal m_div_AB_zx_3, m_div_AB_zx_3_next: int;
    signal m_div_AB_xy_3, m_div_AB_xy_3_next: int;
    signal m_div_AB_zy_3, m_div_AB_zy_3_next: int;
    signal m_div_AB_xz_3, m_div_AB_xz_3_next: int;
    signal m_div_AB_yz_3, m_div_AB_yz_3_next: int;
    signal AO_mht_3, AO_mht_3_next: int;

    -- Stage 4
    signal pixel_addr_4, pixel_addr_4_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_4, start_p_4_next: vec3i_t;
    signal end_p_4, end_p_4_next: vec3i_t;
    signal idx_4, idx_4_next: int;
    signal color_rec_4, color_rec_4_next: color_t;
    signal dist_rec_4, dist_rec_4_next: int;
    signal shape_4, shape_4_next: shape_t;
    signal Odist2_4, Odist2_4_next: int;
    signal hit_p_4, hit_p_4_next: vec3i_t;
    signal AO_mht_4, AO_mht_4_next: int;

    signal hit_p_x_4, hit_p_y_4, hit_p_z_4: vec3i_t;

    -- Stage 5
    signal pixel_addr_5, pixel_addr_5_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_5, start_p_5_next: vec3i_t;
    signal end_p_5, end_p_5_next: vec3i_t;
    signal idx_5, idx_5_next: int;
    signal color_rec_5, color_rec_5_next: color_t;
    signal dist_rec_5, dist_rec_5_next: int;
    signal shape_5, shape_5_next: shape_t;
    signal is_in_ball_5, is_in_ball_5_next: std_logic;
    signal AO_mht_5, AO_mht_5_next: int;
    signal AH_mht_5, AH_mht_5_next: int;
    signal is_in_area_5, is_in_area_5_next: std_logic;

    -- Stage 6
    signal pixel_addr_6, pixel_addr_6_next: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_6, start_p_6_next: vec3i_t;
    signal end_p_6, end_p_6_next: vec3i_t;
    signal idx_6, idx_6_next: int;
    signal next_shape_6, next_shape_6_next: shape_t;
    signal next_color_rec_6, next_color_rec_6_next: color_t;
    signal next_dist_rec_6, next_dist_rec_6_next: int;

    signal p1_pos_tovec3, p2_pos_tovec3: vec3i_t;
    signal update_6: std_logic;
begin
    process (clk_ppl, rst) is
    begin
        if rst = '1' then
            -- Stage 0
            pixel_addr_0 <= (others => '0');
            start_p_0 <= (others => 0);
            end_p_0 <= (others => 0);
            color_rec_0 <= (others => 0);
            dist_rec_0 <= 0;
            idx_0 <= OBJ_NUM - 1;
            shape_0 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));

            -- Stage 1
            pixel_addr_1 <= (others => '0');
            start_p_1 <= (others => 0);
            end_p_1 <= (others => 0);
            color_rec_1 <= (others => 0);
            dist_rec_1 <= 0;
            idx_1 <= OBJ_NUM - 1;
            shape_1 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            AB_1 <= (0, 0, 0);
            AO_1 <= (0, 0, 0);

            -- Stage 2
            pixel_addr_2 <= (others => '0');
            start_p_2 <= (others => 0);
            end_p_2 <= (others => 0);
            idx_2 <= OBJ_NUM - 1;
            color_rec_2 <= (others => 0);
            dist_rec_2 <= 0;
            shape_2 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            AB_2 <= (0, 0, 0);
            AB_len_2 <= 0;
            ABdotAO_2 <= 0;
            AO_len2_2 <= 0;
            ABmAO_yx_2 <= 0;
            ABmAO_zx_2 <= 0;
            ABmAO_xy_2 <= 0;
            ABmAO_zy_2 <= 0;
            ABmAO_xz_2 <= 0;
            ABmAO_yz_2 <= 0;
            AO_mht_2 <= 0;

            -- Stage 3
            pixel_addr_3 <= (others => '0');
            start_p_3 <= (others => 0);
            end_p_3 <= (others => 0);
            idx_3 <= OBJ_NUM - 1;
            color_rec_3 <= (others => 0);
            dist_rec_3 <= 0;
            shape_3 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            AB_3 <= (0, 0, 0);
            D_len_3 <= 0;
            AO_len2_3 <= 0;
            m_div_AB_yx_3 <= 0;
            m_div_AB_zx_3 <= 0;
            m_div_AB_xy_3 <= 0;
            m_div_AB_zy_3 <= 0;
            m_div_AB_xz_3 <= 0;
            m_div_AB_yz_3 <= 0;
            AO_mht_3 <= 0;


            -- Stage 4
            pixel_addr_4 <= (others => '0');
            start_p_4 <= (others => 0);
            end_p_4 <= (others => 0);
            idx_4 <= OBJ_NUM - 1;
            color_rec_4 <= (others => 0);
            dist_rec_4 <= 0;
            shape_4 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            Odist2_4 <= 0;
            hit_p_4 <= (0, 0, 0);
            AO_mht_4 <= 0;

            -- Stage 5
            pixel_addr_5 <= (others => '0');
            start_p_5 <= (others => 0);
            end_p_5 <= (others => 0);
            idx_5 <= OBJ_NUM - 1;
            color_rec_5 <= (others => 0);
            dist_rec_5 <= 0;
            shape_5 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            is_in_ball_5 <= '0';
            AO_mht_5 <= 0;
            AH_mht_5 <= 0;
            is_in_area_5 <= '0';

            -- Stage 6
            pixel_addr_6 <= (others => '0');
            start_p_6 <= (others => 0);
            end_p_6 <= (others => 0);
            idx_6 <= OBJ_NUM - 1;
            next_shape_6 <= ((0, 0, 0), 0, 0, 0, (0, 0, 0));
            next_color_rec_6 <= (others => 0);
            next_dist_rec_6 <= 0;
        elsif rising_edge(clk_ppl) and enable = '1' then
            -- Stage 0
            pixel_addr_0 <= pixel_addr_0_next;
            start_p_0 <= start_p_0_next;
            end_p_0 <= end_p_0_next;
            color_rec_0 <= color_rec_0_next;
            dist_rec_0 <= dist_rec_0_next;
            idx_0 <= idx_0_next;
            shape_0 <= shape_0_next;

            -- Stage 1
            pixel_addr_1 <= pixel_addr_1_next;
            start_p_1 <= start_p_1_next;
            end_p_1 <= end_p_1_next;
            idx_1 <= idx_1_next;
            color_rec_1 <= color_rec_1_next;
            dist_rec_1 <= dist_rec_1_next;
            shape_1 <= shape_1_next;
            AB_1 <= AB_1_next;
            AO_1 <= AO_1_next;

            -- Stage 2
            pixel_addr_2 <= pixel_addr_2_next;
            start_p_2 <= start_p_2_next;
            end_p_2 <= end_p_2_next;
            idx_2 <= idx_2_next;
            color_rec_2 <= color_rec_2_next;
            dist_rec_2 <= dist_rec_2_next;
            shape_2 <= shape_2_next;
            AB_2 <= AB_2_next;
            AB_len_2 <= AB_len_2_next;
            ABdotAO_2 <= ABdotAO_2_next;
            AO_len2_2 <= AO_len2_2_next;
            ABmAO_yx_2 <= ABmAO_yx_2_next;
            ABmAO_zx_2 <= ABmAO_zx_2_next;
            ABmAO_xy_2 <= ABmAO_xy_2_next;
            ABmAO_zy_2 <= ABmAO_zy_2_next;
            ABmAO_xz_2 <= ABmAO_xz_2_next;
            ABmAO_yz_2 <= ABmAO_yz_2_next;
            AO_mht_2 <= AO_mht_2_next;

            -- Stage 3
            pixel_addr_3 <= pixel_addr_3_next;
            start_p_3 <= start_p_3_next;
            end_p_3 <= end_p_3_next;
            idx_3 <= idx_3_next;
            color_rec_3 <= color_rec_3_next;
            dist_rec_3 <= dist_rec_3_next;
            shape_3 <= shape_3_next;
            AB_3 <= AB_3_next;
            D_len_3 <= D_len_3_next;
            AO_len2_3 <= AO_len2_3_next;
            m_div_AB_yx_3 <= m_div_AB_yx_3_next;
            m_div_AB_zx_3 <= m_div_AB_zx_3_next;
            m_div_AB_xy_3 <= m_div_AB_xy_3_next;
            m_div_AB_zy_3 <= m_div_AB_zy_3_next;
            m_div_AB_xz_3 <= m_div_AB_xz_3_next;
            m_div_AB_yz_3 <= m_div_AB_yz_3_next;
            AO_mht_3 <= AO_mht_3_next;

            -- Stage 4
            pixel_addr_4 <= pixel_addr_4_next;
            start_p_4 <= start_p_4_next;
            end_p_4 <= end_p_4_next;
            idx_4 <= idx_4_next;
            color_rec_4 <= color_rec_4_next;
            dist_rec_4 <= dist_rec_4_next;
            shape_4 <= shape_4_next;
            Odist2_4 <= Odist2_4_next;
            hit_p_4 <= hit_p_4_next;
            AO_mht_4 <= AO_mht_4_next;

            -- Stage 5
            pixel_addr_5 <= pixel_addr_5_next;
            start_p_5 <= start_p_5_next;
            end_p_5 <= end_p_5_next;
            idx_5 <= idx_5_next;
            color_rec_5 <= color_rec_5_next;
            dist_rec_5 <= dist_rec_5_next;
            shape_5 <= shape_5_next;
            is_in_ball_5 <= is_in_ball_5_next;
            AO_mht_5 <= AO_mht_5_next;
            AH_mht_5 <= AH_mht_5_next;
            is_in_area_5 <= is_in_area_5_next;

            -- Stage 6
            pixel_addr_6 <= pixel_addr_6_next;
            start_p_6 <= start_p_6_next;
            end_p_6 <= end_p_6_next;
            idx_6 <= idx_6_next;
            next_shape_6 <= next_shape_6_next;
            next_color_rec_6 <= next_color_rec_6_next;
            next_dist_rec_6 <= next_dist_rec_6_next;
        end if;
    end process;

    -- Stage 0
    pixel_addr_0_next <= pixel_addr_in;
    start_p_0_next <= start_p_in;
    end_p_0_next <= end_p_in;
    color_rec_0_next <= color_rec_in;
    dist_rec_0_next <= dist_rec_in;
    idx_0_next <= idx_in;
    shape_0_next <= shape_in;

    -- Stage 1
    pixel_addr_1_next <= pixel_addr_0;
    start_p_1_next <= start_p_0;
    end_p_1_next <= end_p_0;
    idx_1_next <= idx_0;
    color_rec_1_next <= color_rec_0;
    dist_rec_1_next <= dist_rec_0;
    shape_1_next <= shape_0;
    AB_1_next <= end_p_0 - start_p_0;
    AO_1_next <= shape_0.o - start_p_0;

    -- Stage 2
    pixel_addr_2_next <= pixel_addr_1;
    start_p_2_next <= start_p_1;
    end_p_2_next <= end_p_1;
    idx_2_next <= idx_1;
    color_rec_2_next <= color_rec_1;
    dist_rec_2_next <= dist_rec_1;
    shape_2_next <= shape_1;
    AB_2_next <= AB_1;
    AB_len_2_next <= to_integer(unsigned(AB_len_raw_2));
    AB_len2_raw_2 <= std_logic_vector(to_unsigned(length_2(AB_1), 32));
    sqrt_AB_len2: sqrt_gen
        port map (
            s_axis_cartesian_tvalid => '1',
            s_axis_cartesian_tdata => AB_len2_raw_2,
            m_axis_dout_tvalid => open,
            m_axis_dout_tdata => AB_len_raw_2
        );
    ABdotAO_2_next <= dot(AB_1, AO_1);
    AO_len2_2_next <= length_2(AO_1);
    ABmAO_yx_2_next <= AB_1.y * AO_1.x;
    ABmAO_zx_2_next <= AB_1.z * AO_1.x;
    ABmAO_xy_2_next <= AB_1.x * AO_1.y;
    ABmAO_zy_2_next <= AB_1.z * AO_1.y;
    ABmAO_xz_2_next <= AB_1.x * AO_1.z;
    ABmAO_yz_2_next <= AB_1.y * AO_1.z;
    AO_mht_2_next <= length_mht(AO_1);

    -- Stage 3
    pixel_addr_3_next <= pixel_addr_2;
    start_p_3_next <= start_p_2;
    end_p_3_next <= end_p_2;
    idx_3_next <= idx_2;
    color_rec_3_next <= color_rec_2;
    dist_rec_3_next <= dist_rec_2;
    shape_3_next <= shape_2;
    AB_3_next <= AB_2;
    D_len_3_next <= ABdotAO_2 / AB_len_2;
    AO_len2_3_next <= AO_len2_2;
    m_div_AB_yx_3_next <= ABmAO_yx_2 / AB_2.x when AB_2.x /= 0 else NO_DIST;
    m_div_AB_zx_3_next <= ABmAO_zx_2 / AB_2.x when AB_2.x /= 0 else NO_DIST;
    m_div_AB_xy_3_next <= ABmAO_xy_2 / AB_2.y when AB_2.y /= 0 else NO_DIST;
    m_div_AB_zy_3_next <= ABmAO_zy_2 / AB_2.y when AB_2.y /= 0 else NO_DIST;
    m_div_AB_xz_3_next <= ABmAO_xz_2 / AB_2.z when AB_2.z /= 0 else NO_DIST;
    m_div_AB_yz_3_next <= ABmAO_yz_2 / AB_2.z when AB_2.z /= 0 else NO_DIST;
    AO_mht_3_next <= AO_mht_2;

    -- Stage 4
    pixel_addr_4_next <= pixel_addr_3;
    start_p_4_next <= start_p_3;
    end_p_4_next <= end_p_3;
    idx_4_next <= idx_3;
    color_rec_4_next <= color_rec_3;
    dist_rec_4_next <= dist_rec_3;
    shape_4_next <= shape_3;
    Odist2_4_next <= AO_len2_3 - (D_len_3 * D_len_3);
    hit_p_4_next <=
        hit_p_x_4 when shape_3.axis = 0 else
        hit_p_y_4 when shape_3.axis = 1 else
        hit_p_z_4 when shape_3.axis = 2 else
        (NO_DIST, NO_DIST, NO_DIST);
    AO_mht_4_next <= AO_mht_3;

    hit_p_x_4 <=
        (shape_3.o.x, start_p_3.y + m_div_AB_yx_3, start_p_3.z + m_div_AB_zx_3) when AB_3.x /= 0 else
        start_p_3 when start_p_3.x = shape_3.o.x else
        (NO_DIST, NO_DIST, NO_DIST);
    hit_p_y_4 <=
        (start_p_3.x + m_div_AB_xy_3, shape_3.o.y, start_p_3.z + m_div_AB_zy_3) when AB_3.y /= 0 else
        start_p_3 when start_p_3.y = shape_3.o.y else
        (NO_DIST, NO_DIST, NO_DIST);
    hit_p_z_4 <=
        (start_p_3.x + m_div_AB_xz_3, start_p_3.y + m_div_AB_yz_3, shape_3.o.z) when AB_3.z /= 0 else
        start_p_3 when start_p_3.z = shape_3.o.z else
        (NO_DIST, NO_DIST, NO_DIST);

    -- Stage 5
    pixel_addr_5_next <= pixel_addr_4;
    start_p_5_next <= start_p_4;
    end_p_5_next <= end_p_4;
    idx_5_next <= idx_4;
    color_rec_5_next <= color_rec_4;
    dist_rec_5_next <= dist_rec_4;
    shape_5_next <= shape_4;
    is_in_ball_5_next <= '1' when Odist2_4 <= shape_4.r1 * shape_4.r1 else '0'; -- is_in_ball_5_next <= '0';
    AO_mht_5_next <= AO_mht_4;
    AH_mht_5_next <= length_mht(hit_p_4 - start_p_4);
    is_in_area_5_next <= '1' when
        (shape_4.axis = 0 and hit_p_4.y >= shape_4.o.y - shape_4.r1 and hit_p_4.y <= shape_4.o.y + shape_4.r1 and hit_p_4.z >= shape_4.o.z - shape_4.r2 and hit_p_4.z <= shape_4.o.z + shape_4.r2) or
        (shape_4.axis = 1 and hit_p_4.x >= shape_4.o.x - shape_4.r2 and hit_p_4.x <= shape_4.o.x + shape_4.r2 and hit_p_4.z >= shape_4.o.z - shape_4.r1 and hit_p_4.z <= shape_4.o.z + shape_4.r1) or
        (shape_4.axis = 2 and hit_p_4.x >= shape_4.o.x - shape_4.r1 and hit_p_4.x <= shape_4.o.x + shape_4.r1 and hit_p_4.y >= shape_4.o.y - shape_4.r2 and hit_p_4.y <= shape_4.o.y + shape_4.r2) else '0';

    -- Stage 6
    pixel_addr_6_next <= pixel_addr_5;
    start_p_6_next <= start_p_5;
    end_p_6_next <= end_p_5;
    idx_6_next <= idx_5;
    next_shape_6_next <=
        NET when idx_5 = 0 else
        shape_t'(p1_pos_tovec3, 0, PADDLE_WIDTH / 2, PADDLE_HEIGHT / 2, PADDLE1_COLOR) when idx_5 = 1 else
        shape_t'(p2_pos_tovec3, 0, PADDLE_WIDTH / 2, PADDLE_HEIGHT / 2, PADDLE2_COLOR) when idx_5 = 2 else
        shape_t'(ball_pos, 3, BALL_RADIUS, BALL_RADIUS, BALL_COLOR) when idx_5 = 3 else
        TABLE; -- when idx_5 = 4
    next_color_rec_6_next <= shape_5.color when update_6 = '1' else color_rec_5;
    next_dist_rec_6_next <=
        AO_mht_5 when update_6 = '1' and shape_5.axis = 3 else
        AH_mht_5 when update_6 = '1' and shape_5.axis /= 3 else
        dist_rec_5;

    p1_pos_tovec3 <= vec3i_t'(-TABLE_LENGTH / 2 - PADDLE_HEIGHT, -p1_pos.x, p1_pos.y);
    p2_pos_tovec3 <= vec3i_t'(TABLE_LENGTH / 2 + PADDLE_HEIGHT, p2_pos.x, p2_pos.y);
    update_6 <= '1' when (shape_5.axis = 3 and is_in_ball_5 = '1' and AO_mht_5 < dist_rec_5) or (shape_5.axis /= 3 and is_in_area_5 = '1' and AH_mht_5 < dist_rec_5) else '0';

    -- Outputs
    pixel_addr_out <= pixel_addr_6;
    start_p_out <= start_p_6;
    end_p_out <= end_p_6;
    idx_out <= idx_6;
    next_shape_out <= next_shape_6;
    next_color_rec_out <= next_color_rec_6;
    next_dist_rec_out <= next_dist_rec_6;
end architecture;
