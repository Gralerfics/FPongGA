library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.constants.all;
use work.types.all;


entity top_module is
    port (
        clk_sys, rst: in std_logic;
        spi_cs, spi_clk, spi_mosi: out std_logic;
        spi_miso: in std_logic;
        vgaout: out vga_t;
        anodes_n: out std_logic_vector(7 downto 0);
        segs_n: out std_logic_vector(0 to 7)
    );
end entity;


architecture Behavioral of top_module is
    component clk_vga_generator is
        port (
            clk_sys, reset: in std_logic;
            clk_vga, locked: out std_logic
        );
    end component;

    component vga_scanner is
        port (
            clk_vga, rst, enable: in std_logic;
            hsync_n, vsync_n: out std_logic;
            disp_buf_read_tick: out std_logic;
            disp_buf_read_addr: out std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
            pixel_valid: out std_logic
        );
    end component;

    component display_buffers is
        port (
            clk_write: in std_logic;
            en_write: in std_logic;
            we_write: in std_logic_vector(0 downto 0);
            addr_write: in std_logic_vector(16 downto 0);
            din_write: in std_logic_vector(11 downto 0);
            clk_read: in std_logic;
            en_read: in std_logic;
            addr_read: in std_logic_vector(16 downto 0);
            dout_read: out std_logic_vector(11 downto 0);
            clk_ppl, rst, enable: in std_logic;
            swap_sync: in std_logic
        );
    end component;

    component in_frame_state_register is
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
    end component;

    component clk_ppl_generator is
        port (
            clk_sys, reset: in std_logic;
            clk_ppl, locked: out std_logic
        );
    end component;

    component pipeline_entrance is
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
    end component;

    component pipeline_process is
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
    end component;

    component gamepad is
        port (
            clk, rst: in std_logic;
            spi_cs: out std_logic;
            spi_clk: out std_logic;
            spi_mosi: out std_logic;
            spi_miso: in std_logic;
            data_valid: out std_logic;
            data_out: out gamepad_data_t
        );
    end component;

    component ball_controller is
        port (
            clk, rst: in std_logic;
            p1_pos, p2_pos: in vec2i_t;
            current_ball_pos: out vec3i_t;
            score_1_out, score_2_out: out int
        );
    end component;

    component player_state_updater is
        port (
            clk, rst, enable: in std_logic;
            -- Paddles
            p1_lr_offset, p1_ud_offset, p2_lr_offset, p2_ud_offset: in int; -- -128 to 127
            current_p1_pos, current_p2_pos: out vec2i_t;
            -- Angle
            angle_lr_dir, angle_ud_dir: in int; -- -1 or 0 or 1, l and u is -1
            current_angle: out vec2i_t
        );
    end component;

    component seven_segments_display_driver is
        port (
            clk_sys, rst: in std_logic;
            nums: in bcd_array_t(7 downto 0);
            anodes_n: out std_logic_vector(7 downto 0);
            segs_n: out std_logic_vector(0 to 7)
        );
    end component;

    signal clk_vga, clk_vga_locked: std_logic;
    signal vga_enable: std_logic;
    signal vga_pixel_valid: std_logic;

    signal disp_buf_write_enable: std_logic;
    signal disp_buf_write_addr: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal disp_buf_write_data: std_logic_vector(11 downto 0);
    signal disp_buf_read_tick: std_logic;
    signal disp_buf_read_addr: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal disp_buf_read_data: std_logic_vector(11 downto 0);

    signal p1_pos, p2_pos: vec2i_t;
    signal angle: vec2i_t;
    signal ball_pos: vec3i_t;

    signal clk_ppl, clk_ppl_locked: std_logic;
    signal end_of_frame, is_preparing, pipeline_enable: std_logic;

    signal pixel_addr_in: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_in: vec3i_t;
    signal end_p_in: vec3i_t;
    signal color_rec_in: color_t;
    signal dist_rec_in: int;
    signal idx_in: int;
    signal shape_in: shape_t;

    signal pixel_addr_out: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0);
    signal start_p_out: vec3i_t;
    signal end_p_out: vec3i_t;
    signal next_color_rec_out: color_t;
    signal next_dist_rec_out: int;
    signal idx_out: int;
    signal next_shape_out: shape_t;    

    signal gp_data_valid: std_logic;
    signal gp_data_out: gamepad_data_t;

    signal current_ball_pos: vec3i_t;
    signal score_1, score_2: int;

    signal angle_lr_dir, angle_ud_dir: int;
    signal current_p1_pos, current_p2_pos: vec2i_t;
    signal current_angle: vec2i_t;

    signal bcd_nums: bcd_array_t(7 downto 0);
begin
    -- Display Controller
        clk_vga_gen: clk_vga_generator
            port map (
                clk_sys => clk_sys,
                reset => rst,
                clk_vga => clk_vga,
                locked => clk_vga_locked
            );
        vga_enable <= clk_vga_locked;
        
        vga_scan: vga_scanner
            port map (
                clk_vga => clk_vga,
                rst => rst,
                enable => vga_enable,
                hsync_n => vgaout.hsync_n,
                vsync_n => vgaout.vsync_n,
                disp_buf_read_tick => disp_buf_read_tick,
                disp_buf_read_addr => disp_buf_read_addr,
                pixel_valid => vga_pixel_valid
            );

        disp_bufs: display_buffers
            port map (
                clk_write => not clk_ppl,
                en_write => disp_buf_write_enable,
                we_write => "1",
                addr_write => disp_buf_write_addr,
                din_write => disp_buf_write_data,
                clk_read => disp_buf_read_tick,
                en_read => '1',
                addr_read => disp_buf_read_addr,
                dout_read => disp_buf_read_data,
                clk_ppl => clk_ppl,
                rst => rst,
                enable => clk_ppl_locked,
                swap_sync => end_of_frame
            );
        vgaout.color.r <= disp_buf_read_data(11 downto 8) when vga_pixel_valid = '1' else "0000";
        vgaout.color.g <= disp_buf_read_data(7 downto 4) when vga_pixel_valid = '1' else "0000";
        vgaout.color.b <= disp_buf_read_data(3 downto 0) when vga_pixel_valid = '1' else "0000";

        disp_buf_write_enable <= '1' when idx_out = OBJ_NUM - 1 else '0';
        disp_buf_write_addr <= pixel_addr_out;
        disp_buf_write_data <= std_logic_vector(to_unsigned(next_color_rec_out.r / 16, 4)) & std_logic_vector(to_unsigned(next_color_rec_out.g / 16, 4)) & std_logic_vector(to_unsigned(next_color_rec_out.b / 16, 4));
    
    -- In-frame State Update
        if_state: in_frame_state_register
            port map (
                clk => clk_ppl,
                rst => rst,
                update_sync => end_of_frame,
                p1_pos_in => current_p1_pos,
                p2_pos_in => current_p2_pos,
                angle_in => current_angle,
                ball_pos_in => current_ball_pos,
                p1_pos => p1_pos,
                p2_pos => p2_pos,
                angle => angle,
                ball_pos => ball_pos
            );

    -- Pipeline
        clk_ppl_gen: clk_ppl_generator
            port map (
                clk_sys => clk_sys,
                reset => rst,
                clk_ppl => clk_ppl,
                locked => clk_ppl_locked
            );
        pipeline_enable <= clk_ppl_locked;
        
        ppl_enter: pipeline_entrance
            port map (
                clk_ppl => clk_ppl,
                rst => rst,
                enable => clk_ppl_locked,
                p_angle => angle,
                is_preparing => is_preparing,
                is_eof => end_of_frame,
                -- Pipeline Final States
                pixel_addr_pplout => pixel_addr_out,
                start_p_pplout => start_p_out,
                end_p_pplout => end_p_out,
                next_color_rec_pplout => next_color_rec_out,
                next_dist_rec_pplout => next_dist_rec_out,
                idx_pplout => idx_out,
                next_shape_pplout => next_shape_out,
                -- Pipeline Entrances
                pixel_addr => pixel_addr_in,
                start_p => start_p_in,
                end_p => end_p_in,
                color_rec => color_rec_in,
                dist_rec => dist_rec_in,
                idx => idx_in,
                shape => shape_in
            );
        
        ppl_proc: pipeline_process
            port map (
                clk_ppl => clk_ppl,
                rst => rst,
                enable => pipeline_enable,
                -- Data In
                p1_pos => p1_pos,
                p2_pos => p2_pos,
                ball_pos => ball_pos,
                -- Input Interface
                pixel_addr_in => pixel_addr_in,
                start_p_in => start_p_in,
                end_p_in => end_p_in,
                color_rec_in => color_rec_in,
                dist_rec_in => dist_rec_in,
                idx_in => idx_in,
                shape_in => shape_in,
                -- Input Interface
                pixel_addr_out => pixel_addr_out,
                start_p_out => start_p_out,
                end_p_out => end_p_out,
                next_color_rec_out => next_color_rec_out,
                next_dist_rec_out => next_dist_rec_out,
                idx_out => idx_out,
                next_shape_out => next_shape_out
            );

    -- Controlling
        ball_state: ball_controller
            port map (
                clk => clk_ppl,
                rst => rst,
                p1_pos => p1_pos,
                p2_pos => p2_pos,
                current_ball_pos => current_ball_pos,
                score_1_out => score_1,
                score_2_out => score_2
            );

        p_update: player_state_updater
            port map (
                clk => clk_ppl,
                rst => rst,
                enable => gp_data_valid,
                -- Paddles
                p1_lr_offset => gp_data_out.pss_lx,
                p1_ud_offset => gp_data_out.pss_ly,
                p2_lr_offset => gp_data_out.pss_rx,
                p2_ud_offset => gp_data_out.pss_ry,
                current_p1_pos => current_p1_pos,
                current_p2_pos => current_p2_pos,
                -- Angle
                angle_lr_dir => angle_lr_dir,
                angle_ud_dir => angle_ud_dir,
                current_angle => current_angle
            );
        angle_lr_dir <= -1 when gp_data_out.left = '1' else 1 when gp_data_out.right = '1' else 0;
        angle_ud_dir <= -1 when gp_data_out.up = '1' else 1 when gp_data_out.down = '1' else 0;

    -- Peripherals
        gp_ps2: gamepad
            port map (
                clk => clk_sys,
                rst => rst,
                spi_cs => spi_cs,
                spi_clk => spi_clk,
                spi_mosi => spi_mosi,
                spi_miso => spi_miso,
                data_valid => gp_data_valid,
                data_out => gp_data_out
            );
        
        seven_segs_driver: seven_segments_display_driver port map (clk_sys => clk_sys, rst => rst, nums => bcd_nums, anodes_n => anodes_n, segs_n => segs_n);
        bcd_nums(7) <= std_logic_vector(to_unsigned(score_1 / 1000 mod 10, 4));
        bcd_nums(6) <= std_logic_vector(to_unsigned(score_1 / 100 mod 10, 4));
        bcd_nums(5) <= std_logic_vector(to_unsigned(score_1 / 10 mod 10, 4));
        bcd_nums(4) <= std_logic_vector(to_unsigned(score_1 mod 10, 4));
        bcd_nums(3) <= std_logic_vector(to_unsigned(score_2 / 1000 mod 10, 4));
        bcd_nums(2) <= std_logic_vector(to_unsigned(score_2 / 100 mod 10, 4));
        bcd_nums(1) <= std_logic_vector(to_unsigned(score_2 / 10 mod 10, 4));
        bcd_nums(0) <= std_logic_vector(to_unsigned(score_2 mod 10, 4));
end architecture;
