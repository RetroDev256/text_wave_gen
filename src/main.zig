const std = @import("std");
const linux = std.os.linux;

// compile time configuration constants
const banner = "Sinecraft";
const term_width = 80;
const oscilation_rows = 43;

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

// runtime functions for mathematics
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
    const osc_row_float: f128 = @intToFloat(f128, oscilation_rows);
    break :blk @floatToInt(i16, fp_div_float / osc_row_float);
};

pub export fn _start() noreturn {
    var line: i16 = 0;
    while (line < oscilation_rows) : (line += 1) {
        const scaled_osc: i16 = fposc(line * ctr_inc) * range;
        const offset: i16 = @divTrunc(scaled_osc, fp_div);
        var space: i16 = 0;
        while (space < offset) : (space += 1) {
            _ = linux.write(1, " ", 1);
        }
        _ = linux.write(1, banner, banner.len);
        _ = linux.write(1, "\n", 1);
        //_ = linux.nanosleep(&delay, null);
    }
    _ = linux.exit(0);
}
