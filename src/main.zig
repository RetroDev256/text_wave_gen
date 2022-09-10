const os = @import("std").os;
const builtin = @import("builtin");

// compile time configuration constants
const banner = "Sinewave";
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
    const int_max: f128 = @intToFloat(f128, 65535);
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
    const osc_row_float: f128 = @intToFloat(f128, oscilation_rows);
    break :blk @floatToInt(i16, fp_div_float / osc_row_float);
};

fn write_all(buffer: []const u8) void {
    var len_written: usize = 0;
    while (len_written < buffer.len) {
        len_written += switch (builtin.os.tag) {
            .linux => blk: {
                const stdout = os.linux.STDOUT_FILENO;
                const segment: []const u8 = buffer[len_written..];
                const anylen_ptr: [*]const u8 = @ptrCast([*]const u8, segment);
                break :blk os.linux.write(stdout, anylen_ptr, segment.len);
            },
            else => @compileError("Unsupported OS."),
        };
    }
}

fn exit_success() noreturn {
    switch (builtin.os.tag) {
        .linux => os.linux.exit(0),
        else => @compileError("Unsupported OS."),
    }
}

pub export fn _start() noreturn {
    var line: i16 = 0;
    while (line < oscilation_rows) : (line += 1) {
        const scaled_osc: i16 = fposc(line * ctr_inc) * range;
        const offset: i16 = @divTrunc(scaled_osc, fp_div);
        var space: i16 = 0;
        while (space < offset) : (space += 1) {
            write_all(" ");
        }
        write_all(banner);
        write_all("\n");
    }
    exit_success();
}
