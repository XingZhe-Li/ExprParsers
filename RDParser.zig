// This Source File is made for Parser 1

const std = @import("std");
const Token = @import("Lexer.zig").Token;
const TokenReader = @import("Lexer.zig").TokenReader;

pub fn entry(src: []const u8) i64 {
    var tokenReader = TokenReader.new(src);
    return parse_expr(&tokenReader);
}

// Expr   -> Term   '+' Expr  | Term
// Term   -> Factor '*' Term | Factor
// Factor -> Power  '^' Factor               // this is right-combined
// Power  -> (Expr) | Number

fn parse_power(tokenReader: *TokenReader) i64 {
    if (tokenReader.current_token() == null) {
        std.debug.print("expecting a power but met EOF", .{});
        std.process.exit(1);
    }
    var token = tokenReader.current_token().?;
    var result: i64 = 0;
    if (token.tktype == .LPAR) {
        tokenReader.next();
        result = parse_expr(tokenReader);
        if (tokenReader.current_token() == null) {
            std.debug.print("expecting an .RPAR but met EOF", .{});
            std.process.exit(1);
        }
        token = tokenReader.current_token().?;
        if (token.tktype != .RPAR) {
            std.debug.print("expecting an .RPAR but met {}", .{token.tktype});
            std.process.exit(1);
        }
        tokenReader.next();
    } else if (token.tktype == .INT) {
        result = @as(i64, @intCast(token.value));
        tokenReader.next();
    } else {
        std.debug.print("expecting a power but met {}", .{token.tktype});
        std.process.exit(1);
    }
    return result;
}

fn parse_factor(tokenReader: *TokenReader) i64 {
    if (tokenReader.current_token() == null) {
        std.debug.print("expecting a factor but met EOF", .{});
        std.process.exit(1);
    }
    const power = parse_power(tokenReader);
    if (tokenReader.current_token() == null) {
        return power;
    }
    const token = tokenReader.current_token().?;
    if (token.tktype == .POWER) {
        tokenReader.next();
        return std.math.powi(i64, power, parse_factor(tokenReader)) catch {
            std.debug.print("power failed", .{});
            std.process.exit(1);
        };
    } else {
        return power;
    }
}

fn parse_term(tokenReader: *TokenReader) i64 {
    if (tokenReader.current_token() == null) {
        std.debug.print("expecting an term but met EOF", .{});
        std.process.exit(1);
    }
    var result: i64 = 1;
    var token = tokenReader.current_token().?;
    var last_mul = true;
    while (true) {
        if (last_mul) {
            result *= parse_factor(tokenReader);
        } else {
            const factor = parse_factor(tokenReader);
            if (factor == 0) {
                std.debug.print("division by zero error!", .{});
                std.process.exit(1);
            }
            result = @divTrunc(result, factor);
        }
        if (tokenReader.current_token() == null) {
            return result;
        }
        token = tokenReader.current_token().?;
        if (token.tktype == .MUL) {
            last_mul = true;
            tokenReader.next();
        } else if (token.tktype == .DIV) {
            last_mul = false;
            tokenReader.next();
        } else {
            return result;
        }
    }
}

fn parse_expr(tokenReader: *TokenReader) i64 {
    if (tokenReader.current_token() == null) {
        std.debug.print("expecting an expr but met EOF", .{});
        std.process.exit(1);
    }
    var last_pos: bool = true;
    var result: i64 = 0;
    var token = tokenReader.current_token().?;
    if (token.tktype == .ADD) {
        last_pos = true;
        tokenReader.next();
    } else if (token.tktype == .SUB) {
        last_pos = false;
        tokenReader.next();
    }
    while (true) {
        if (last_pos) {
            result += parse_term(tokenReader);
        } else {
            result -= parse_term(tokenReader);
        }
        if (tokenReader.current_token() == null) {
            return result;
        }
        token = tokenReader.current_token().?;
        if (token.tktype == .ADD) {
            last_pos = true;
        } else if (token.tktype == .SUB) {
            last_pos = false;
        } else {
            return result;
        }
        tokenReader.next();
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
