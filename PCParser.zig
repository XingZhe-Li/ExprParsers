// This Source File is made for Parser 2

const std = @import("std");
const Token = @import("Lexer.zig").Token;
const TokenReader = @import("Lexer.zig").TokenReader;

fn getPrecedence(token: Token) u64 {
    switch (token.tktype) {
        .ADD, .SUB => return 1,
        .MUL, .DIV => return 2,
        .POWER => return 3,
        else => return 0,
    }
}

fn isRightCombined(token: Token) bool {
    if (token.tktype == .POWER) return true;
    return false;
}

fn entry(src: []const u8) i64 {
    var tokenReader = TokenReader.new(src);
    return parse(&tokenReader, 1);
}

fn add(x: i64, y: i64) i64 {
    return x + y;
}

fn sub(x: i64, y: i64) i64 {
    return x - y;
}

fn mul(x: i64, y: i64) i64 {
    return x * y;
}

fn div(x: i64, y: i64) i64 {
    return @divExact(x, y);
}

fn pow(x: i64, y: i64) i64 {
    return std.math.powi(i64, x, y) catch {
        std.debug.print("power failed {} ^ {}", .{ x, y });
        std.process.exit(1);
    };
}

fn getFunc(token: Token) *const fn (i64, i64) i64 {
    return switch (token.tktype) {
        .ADD => add,
        .SUB => sub,
        .MUL => mul,
        .DIV => div,
        .POWER => pow,
        else => unreachable,
    };
}

fn parse(tokenReader: *TokenReader, precedence: u64) i64 {
    if (tokenReader.current_token() == null) {
        std.debug.print("expecting expr but met EOF", .{});
        std.process.exit(1);
    }
    const token = tokenReader.current_token().?;
    var lhs: i64 = 0;
    if (token.tktype == .LPAR) {
        tokenReader.next();
        lhs = parse(tokenReader, 1);
        if (tokenReader.current_token() == null) {
            std.debug.print("expecting .RPAR but met EOF", .{});
            std.process.exit(1);
        } else if (tokenReader.current_token().?.tktype != .RPAR) {
            std.debug.print("expecting .RPAR but met {}", .{tokenReader.current_token().?.tktype});
            std.process.exit(1);
        }
        tokenReader.next();
    } else if (token.tktype == .INT) {
        lhs = @as(i64, @intCast(token.value));
        tokenReader.next();
    } else if (token.tktype != .ADD and token.tktype != .SUB) {
        std.debug.print("expecting expr but met {}", .{token.tktype});
        std.process.exit(1);
    }

    while (true) {
        if (tokenReader.current_token() == null) {
            return lhs;
        }
        const opToken = tokenReader.current_token().?;
        const prec = getPrecedence(opToken);
        if (prec == 0) {
            std.debug.print("expecting operator but met {}", .{opToken.tktype});
            std.process.exit(1);
        }
        if (prec < precedence) {
            return lhs;
        }
        const isRight = isRightCombined(opToken);
        const nextPrec = if (isRight) prec else prec + 1;
        tokenReader.next();
        const rhs = parse(tokenReader, nextPrec);
        lhs = getFunc(opToken)(lhs, rhs);
    }
}

pub fn main() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
    const src = std.mem.trim(u8, bare_line, "\r");

    try stdout.print("{d}", .{entry(src)});
    try stdout.flush();
}
