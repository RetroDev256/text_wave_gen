const std = @import("std");
const linux = std.os.linux;

// compile time configuration constants
const banner = "It will be great.";
const term_width = 80;
const osc_rows = 29;

// compile time constants
const range: i16 = blk: {
    if (banner.len >= term_width) {
        @compileError("The banner is too long!");
    }
    break :blk term_width - banner.len;
};
const fp_div: i16 = blk: {
    const range_float: f128 = @intToFloat(f128, range);
    const int_max: f128 = @intToFloat(f128, std.math.maxInt(i16));
    break :blk @floatToInt(i16, int_max / range_float);
};

// runtime functions for fixed point mathematics
fn fpabs(lhs: i16) i16 {
    return if (lhs < 0) -lhs else lhs;
}
fn fpmul(lhs: i16, rhs: i16) i16 {
    const mul: i32 = @intCast(i32, lhs) * @intCast(i32, rhs);
    return @intCast(i16, @divTrunc(mul, @intCast(i32, fp_div)));
}
fn fposc(lhs: i16) i16 {
    const shift_lhs: i16 = lhs - fp_div;
    const segmented: i16 = @mod(shift_lhs, fp_div * 2);
    const wrap_x: i16 = fpabs(segmented - fp_div);
    var squared: i16 = fpmul(wrap_x, wrap_x);
    var cubed: i16 = fpmul(squared, wrap_x);
    return 3 * squared - 2 * cubed;
}

// compile time constants used in _start()
const ctr_inc: i16 = blk: {
    const fp_div_float: f128 = @intToFloat(f128, fp_div) * 2.0;
    const osc_row_float: f128 = @intToFloat(f128, osc_rows);
    const alt_osc_flat: f128 = osc_row_float * 2.0;
    break :blk @floatToInt(i16, fp_div_float / alt_osc_flat);
};

pub export fn _start() noreturn {
    var buffer: [term_width]u8 = undefined;
    var line: i16 = 0;
    while (line < osc_rows) : (line += 1) {
        for (buffer) |*elem| elem.* = ' ';
        const scaled_osc: i16 = fposc(line * ctr_inc) * range;
        const off_a: usize = @intCast(usize, @divTrunc(scaled_osc, fp_div));
        const end_a: usize = off_a + banner.len;
        for (buffer[off_a..end_a]) |*elem, i| elem.* = banner[i];
        const off_b: usize = @intCast(usize, range) - off_a;
        const end_b: usize = off_b + banner.len;
        for (buffer[off_b..end_b]) |*elem, i| elem.* = banner[i];
        const written_len: usize = @maximum(end_a, end_b);
        _ = linux.write(1, @ptrCast([*]const u8, &buffer), written_len);
        _ = linux.write(1, "\n", 1);
    }
    _ = linux.exit(0);
}
