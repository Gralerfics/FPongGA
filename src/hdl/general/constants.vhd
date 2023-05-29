library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.types.all;


package constants is
    -- display constants. (dimension divided by 2)
        constant H_SYNC_PULSE: int := 96;
        constant H_BACK_PORCH: int := 48;
        constant H_ACTIVE: int := 640;
        constant H_FRONT_PORCH: int := 16;
        constant H_LINE_PERIOD: int := H_SYNC_PULSE + H_BACK_PORCH + H_ACTIVE + H_FRONT_PORCH;
        constant H_REAL: int := H_ACTIVE / 2;
        constant V_SYNC_PULSE: int := 2;
        constant V_BACK_PORCH: int := 33;
        constant V_ACTIVE: int := 480;
        constant V_FRONT_PORCH: int := 10;
        constant V_FRAME_PERIOD: int := V_SYNC_PULSE + V_BACK_PORCH + V_ACTIVE + V_FRONT_PORCH;
        constant V_REAL: int := V_ACTIVE / 2;

    -- math constants.
        constant ANGLE_RADIUS: int := 225;
        constant ANGLE_EIGHTH: int := 158;
        constant ANGLE_QUARTER: int := ANGLE_EIGHTH * 2 + 1;
        constant ANGLE_HALF: int := ANGLE_EIGHTH * 4 + 2;
        constant ANGLE_MODULO: int := ANGLE_EIGHTH * 8 + 4;
    
    -- object constants.
        constant SCALE_FAC: int := 1;
        constant TABLE_LENGTH: int := 260 * SCALE_FAC;
        constant TABLE_WIDTH: int := 145 * SCALE_FAC;
        constant BALL_RADIUS: int := 4 * SCALE_FAC;
        constant PADDLE_WIDTH: int := 46 * SCALE_FAC;
        constant PADDLE_HEIGHT: int := 32 * SCALE_FAC;
        constant NET_HEIGHT: int := 32 * SCALE_FAC;
        constant TABLE_COLOR: color_t := color_t'(255, 197, 131);
        constant BALL_COLOR: color_t := color_t'(255, 255, 255);
        constant PADDLE1_COLOR: color_t := color_t'(247, 123, 93);
        constant PADDLE2_COLOR: color_t := color_t'(153, 183, 244);
        constant NET_COLOR: color_t := color_t'(220, 130, 0);
        constant OBJ_NUM: int := 5;
        constant NO_DIST: int := 3000000;
        constant SKY_DIST: int := 2000000;
        constant SKY_COLOR: color_t := color_t'(160, 224, 240);

        constant TABLE: shape_t := shape_t'((0, 0, 0), 2, TABLE_LENGTH / 2, TABLE_WIDTH / 2, TABLE_COLOR);
        constant NET: shape_t := shape_t'((0, 0, NET_HEIGHT / 2), 0, TABLE_WIDTH / 2, NET_HEIGHT / 2, NET_COLOR);

    -- viewport constants.
        constant LOOKAT_REL_FAC: int := SCALE_FAC * 3;
        constant EOF_ADDR: std_logic_vector(DISP_RAM_ADDR_RADIX - 1 downto 0) := std_logic_vector(to_unsigned(H_REAL * V_REAL - 1, DISP_RAM_ADDR_RADIX));                   -- "10010101111111111"

    -- control constants.
        constant PADDLE_STEP: int := 2;
        constant ANGLE_STEP: int := 8;

    -- time constants.
        constant PPL_FREQ: integer := 8000000;
end package;
