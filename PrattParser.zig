// Pratt Parser , this is source for parser 6
// A Classic Parser for expressions , simple structure with only 2 stack
//

const std = @import("std");
const Token = @import("Lexer.zig").Token;
const TokenType = @import("Lexer.zig").TokenType;
const TokenReader = @import("Lexer.zig").TokenReader;

const Operator = enum { ADD, SUB, MUL, DIV, POW, LPAR, RPAR };

fn Stack(element_type: type) type {
    const capacity: comptime_int = 1024;
    return struct {
        ptr: usize = capacity,
        data: [capacity]element_type = undefined,

        fn push(self: *@This(), item: element_type) void {
            self.ptr -= 1;
            self.data[self.ptr] = item;
        }

        fn top(self: *@This()) ?element_type {
            if (self.ptr == capacity) {
                return null;
            }
            return self.data[self.ptr];
        }

        fn ntop(self: *@This(), n: usize) ?element_type {
            if (self.ptr + n >= capacity) {
                return null;
            }
            return self.data[self.ptr + n];
        }

        fn pop(self: *@This()) ?element_type {
            if (self.ptr == capacity) {
                return null;
            }
            self.ptr += 1;
            return self.data[self.ptr - 1];
        }

        fn size(self: *@This()) usize {
            return capacity - self.ptr;
        }
    };
}

fn isRightCombined(op: Operator) bool {
    return switch (op) {
        .POW => true,
        else => false,
    };
}

fn priorityTable(op: Operator) usize {
    return switch (op) {
        .RPAR => 0,
        .ADD, .SUB => 1,
        .MUL, .DIV => 2,
        .POW => 3,
        .LPAR => 4,
    };
}

fn stackSizeCheck(comptime etype: type, stack: *Stack(etype), size: usize) void {
    if (stack.size() < size) {
        std.debug.print("the number of operators does not match that of operands", .{});
        std.process.exit(1);
    }
}

fn processStack(operandsStack: *Stack(i64), operatorStack: *Stack(Operator)) void {
    const onTopOperator = operatorStack.pop();
    if (onTopOperator == null) return;
    const topOperator = onTopOperator.?;

    const priority = priorityTable(topOperator);
    const isRight = isRightCombined(topOperator);

    while (true) {
        if (operatorStack.top() == null) break;
        const nextOpreator = operatorStack.top().?;

        const nextPriority = priorityTable(nextOpreator);
        if (nextPriority == 4) {
            if (priority == 0) {
                _ = operatorStack.pop();
                return;
            } else {
                break;
            }
        } else if (priority <= nextPriority) {
            if (priority == nextPriority and isRight) {
                break;
            }

            _ = operatorStack.pop();
            stackSizeCheck(i64, operandsStack, 2);
            const x = operandsStack.pop().?;
            const y = operandsStack.pop().?;
            var z: i64 = undefined;
            switch (nextOpreator) {
                .ADD => z = x + y,
                .SUB => z = y - x,
                .MUL => z = x * y,
                .DIV => z = @divExact(y, x),
                .POW => z = std.math.powi(i64, y, x) catch {
                    std.debug.print("power failed", .{});
                    std.process.exit(1);
                },
                else => unreachable,
            }
            operandsStack.push(z);
        } else {
            break;
        }
    }

    operatorStack.push(topOperator);
}

fn parse(tokenReader: *TokenReader) i64 {
    var oprandsStack = Stack(i64){};
    var operatorStack = Stack(Operator){};

    operatorStack.push(.LPAR);

    while (tokenReader.current_token()) |token| {
        switch (token.tktype) {
            .INT => {
                oprandsStack.push(@as(i64, @intCast(token.value)));
            },
            .ADD => operatorStack.push(.ADD),
            .SUB => operatorStack.push(.SUB),
            .MUL => operatorStack.push(.MUL),
            .DIV => operatorStack.push(.DIV),
            .POWER => operatorStack.push(.POW),
            .LPAR => operatorStack.push(.LPAR),
            .RPAR => operatorStack.push(.RPAR),
        }
        processStack(&oprandsStack, &operatorStack);
        tokenReader.next();

        // // for debug purpose
        // for (0..oprandsStack.size()) |idx| {
        //     std.debug.print("{},", .{oprandsStack.ntop(idx).?});
        // }
        // std.debug.print("\n", .{});

        // for (0..operatorStack.size()) |idx| {
        //     std.debug.print("{},", .{operatorStack.ntop(idx).?});
        // }
        // std.debug.print("\n", .{});
    }
    operatorStack.push(.RPAR);
    processStack(&oprandsStack, &operatorStack);

    if (operatorStack.size() != 0 or oprandsStack.size() != 1) {
        std.debug.print("your expression is not complete!", .{});
        std.process.exit(1);
    }
    return oprandsStack.top().?;
}

fn entry(src: []const u8) i64 {
    var tokenReader = TokenReader.new(src);
    return parse(&tokenReader);
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
