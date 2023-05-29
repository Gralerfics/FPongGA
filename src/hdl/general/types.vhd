library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package types is
    -- radix
    constant DISP_RAM_ADDR_RADIX: natural := 17;
    constant INT_RADIX: natural := 23;

    -- int
    subtype int is integer range -2 ** (INT_RADIX - 1) to 2 ** (INT_RADIX - 1) - 1;

    -- vec2i_t
    type vec2i_t is record
        x: int;
        y: int;
    end record;
    function "+"(v1, v2: vec2i_t) return vec2i_t;
    function "-"(v1, v2: vec2i_t) return vec2i_t;

    -- vec3i_t
    type vec3i_t is record
        x: int;
        y: int;
        z: int;
    end record;
    function "+"(v1, v2: vec3i_t) return vec3i_t;
    function "-"(v1, v2: vec3i_t) return vec3i_t;
    function "*"(v: vec3i_t; s: int) return vec3i_t;
    function "/"(v: vec3i_t; s: int) return vec3i_t;
    function length_2(v: vec3i_t) return int;
    function length_mht(v: vec3i_t) return int;
    function cross(v1, v2: vec3i_t) return vec3i_t;
    function dot(v1, v2: vec3i_t) return int;

    -- color
    subtype color_int is integer; -- range 0 to 65535;    -- 0 to 255, but to prevent overflow when blending
    type color_t is record
        r: int;
        g: int;
        b: int;
    end record;
    function to_color(data: std_logic_vector(23 downto 0)) return color_t;

    -- direction
    subtype dir_t is integer range 0 to 3; -- 0: x, 1: y, 2: z, 3: invalid

    -- shape
    type shape_t is record
        o: vec3i_t;
        axis: dir_t;
        r1: int;
        r2: int;
        color: color_t;
    end record;

    -- vga
    type vga_color_t is record  -- 0 to 15
        r: std_logic_vector(3 downto 0);
        g: std_logic_vector(3 downto 0);
        b: std_logic_vector(3 downto 0);
    end record;

    type vga_t is record
        hsync_n, vsync_n: std_logic;
        color: vga_color_t;
    end record;

    -- gamepad
    type gamepad_data_t is record
        id: std_logic_vector(7 downto 0);
        f_select, L3, R3, f_start, up, right, down, left: std_logic;
        L2, R2, L1, R1, triangle, circle, cross, square: std_logic;
        pss_rx, pss_ry, pss_lx, pss_ly: integer;
    end record;
    constant PSS_RES: int := 256;
    constant PSS_MIDDLE: int := 128;
    constant PSS_DEADZONE_RADIUS: int := 2;

    -- bcd
    subtype bcd_t is std_logic_vector(3 downto 0);
    type bcd_array_t is array (natural range <>) of bcd_t;
end package;


package body types is
    function "+"(v1, v2: vec2i_t) return vec2i_t is
    begin
        return vec2i_t'(v1.x + v2.x, v1.y + v2.y);
    end function;

    function "-"(v1, v2: vec2i_t) return vec2i_t is
    begin
        return vec2i_t'(v1.x - v2.x, v1.y - v2.y);
    end function;

    function "+"(v1, v2: vec3i_t) return vec3i_t is
    begin
        return vec3i_t'(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
    end function;

    function "-"(v1, v2: vec3i_t) return vec3i_t is
    begin
        return vec3i_t'(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
    end function;

    function "*"(v: vec3i_t; s: int) return vec3i_t is
    begin
        return vec3i_t'(v.x * s, v.y * s, v.z * s);
    end function;

    function "/"(v: vec3i_t; s: int) return vec3i_t is
    begin
        return vec3i_t'(v.x / s, v.y / s, v.z / s);
    end function;

    function length_2(v: vec3i_t) return int is
    begin
        return v.x * v.x + v.y * v.y + v.z * v.z;
    end function;

    function length_mht(v: vec3i_t) return int is
    begin
        return abs(v.x) + abs(v.y) + abs(v.z);
    end function;

    function cross(v1, v2: vec3i_t) return vec3i_t is
    begin
        return vec3i_t'(
            v1.y * v2.z - v1.z * v2.y,
            v1.z * v2.x - v1.x * v2.z,
            v1.x * v2.y - v1.y * v2.x
        );
    end function;

    function dot(v1, v2: vec3i_t) return int is
    begin
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    end function;

    function to_color(data: std_logic_vector(23 downto 0)) return color_t is
    begin
        return color_t'(
            to_integer(unsigned(data(23 downto 16))),
            to_integer(unsigned(data(15 downto 8))),
            to_integer(unsigned(data(7 downto 0)))
        );
    end function;
end package body;
