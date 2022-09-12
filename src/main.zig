const std = @import("std");
const linux = std.os.linux;

// compile time configuration constants
const banner = "Wave";
const term_width = 80;
const osc_rows = 40;

// compile time constants
const range: u16 = blk: {
    if (banner.len >= term_width) {
        @compileError("The banner is too long!");
    }
    break :blk term_width - banner.len;
};
const fp_div: u16 = blk: {
    const range_float: f128 = @intToFloat(f128, range);
    const int_max: u16 = std.math.maxInt(u16);
    const int_max_float: f128 = @intToFloat(f128, int_max);
    break :blk @floatToInt(u16, int_max_float / range_float);
};

// compile time constant used in _start() - increment for full wave
const ctr_inc: u16 = blk: {
    const fp_div_float: f128 = @intToFloat(f128, fp_div) * 2.0;
    const osc_row_float: f128 = @intToFloat(f128, osc_rows);
    const ctr_inc_calc: f128 = fp_div_float / osc_row_float;
    break :blk @floatToInt(u16, @round(ctr_inc_calc));
};

// runtime functions for fixed point mathematics
fn fpnorm(lhs: u16) u16 {
    const dd_iv: u16 = fp_div * 2;
    const wrap: u16 = lhs % dd_iv;
    return if (lhs > fp_div) dd_iv - wrap else wrap;
}
fn fpmul(lhs: u16, rhs: u16) u16 {
    const mul: u32 = @intCast(u32, lhs) * @intCast(u32, rhs);
    return @intCast(u16, mul / fp_div);
}
fn fposc(lhs: u16) u16 {
    var squared: u16 = fpmul(lhs, lhs);
    return 3 * squared - 2 * fpmul(squared, lhs);
}

pub export fn _start() noreturn {
    var spaces: [range]u8 = undefined;
    for (spaces) |*space| space.* = ' ';
    var line: u16 = 0;
    while (line < osc_rows) : (line += 1) {
        const ctr: u16 = line * ctr_inc;
        const scaled_osc: u16 = fposc(fpnorm(ctr)) * range;
        const offset: usize = @intCast(usize, scaled_osc / fp_div);
        _ = linux.write(1, @ptrCast([*]const u8, &spaces), offset);
        _ = linux.write(1, banner, banner.len);
        _ = linux.write(1, "\n", 1);
    }
    _ = linux.exit(0);
}
