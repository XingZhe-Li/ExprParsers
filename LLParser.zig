// This Source File is made for Parser 3

// please learn to induce a LL state table first

// Expr   -> Term Expr'
// Expr'  -> + Term Expr'  | null
// Term   -> Factor Term'
// Term'  -> * Factor Term' | null
// Factor -> Power Factor'
// Factor'-> ^ Power Factor' | null
// Power  -> (Expr) | Numbers

// Apparently what's aforementioned can be implemented in a RDParser fashion.

// Induce this from bottom (Numbers) to top (Expr)
// pay attention to LHS & elements that can be null
// e refers to epsilon (exists when an element is nullable)

// First Sets
// Expr    = {(} + Numbers
// Expr'   = {+} + {e}
// Term    = {(} + Numbers
// Term'   = {*} + {e}
// Factor  = {(} + Numbers
// Factor' = {^} + {e}
// Power   = {(} + Numbers
// Numbers = '0'..='9'

// Induce this from top (Expr) to bottom (Numbers)
// pay attention to what's following in RHS, and if it's nullable.
// also pay attention to the rear elements in a production.
// follow set should be including end symbol: $
// Under most circumstances , we'd add one more production: S' -> S$
// this end symbol is introduced for better error detection: 3 + 1 ( 2 $
// without the $ symbol, the production may assume it's correct after consuming "3 + 1"

// Follow Sets
// Expr    = {)$}
// Expr'   = {)$}
// Term    = {+)$}
// Term'   = {+)$}
// Factor  = {+)*$}
// Factor' = {+)*$}
// Power   = {^+)*$}
// Numbers = {^+)*$}

const std = @import("std");
const Token = @import("Lexer.zig").Token;
const TokenReader = @import("Lexer.zig").TokenReader;

// let's ignore $ , and replace it with "all match" (when stack is empty , the input should be all parsed , vice versa).

const Action = enum { ADD, SUB, MUL, DIV, POW };

const Production = enum { Expr, Expr2, Term, Term2, Factor, Factor2, Power, Numbers, OpToken, PAR };

const State = union(enum) {
    action: Action,
    prod: Production,
};

fn Stack(comptime element_type: type) type {
    const max_size: comptime_int = 1024;
    return struct {
        stack: [max_size]element_type = undefined,
        ptr: usize = max_size,

        fn push(self: *@This(), element: element_type) void {
            self.ptr -= 1;
            self.stack[self.ptr] = element;
        }
        fn pop(self: *@This()) ?element_type {
            if (self.ptr == max_size) {
                return null;
            }
            self.ptr += 1;
            return self.stack[self.ptr - 1];
        }
        fn top(self: *@This()) ?element_type {
            if (self.ptr == max_size) {
                return null;
            }
            return self.stack[self.ptr];
        }
        fn ntop(self: *@This(), n: usize) ?element_type {
            if (self.ptr + n >= max_size) {
                return null;
            }
            return self.stack[self.ptr + n];
        }
        fn size(self: *@This()) usize {
            return max_size - self.ptr;
        }
    };
}

fn table(prod: Production, tokenReader: *TokenReader, parseStack: *Stack(State), evalStack: *Stack(i64)) void {
    // manually built transition table
    // since Zig does not has a table that's similar to that in Python
    const topToken = tokenReader.current_token();
    switch (prod) {
        .Expr => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .LPAR, .INT => {
                        parseStack.push(State{ .prod = .Expr2 });
                        parseStack.push(State{ .prod = .Term });
                    },
                    else => {
                        std.debug.print("expecting ( or .INT but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting ( or .INT but met null", .{});
                std.process.exit(1);
            }
        },
        .Expr2 => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .ADD, .SUB => {
                        parseStack.push(State{ .prod = .Expr2 });
                        switch (unwrap_topToken.tktype) {
                            .ADD => {
                                parseStack.push(State{ .action = .ADD });
                            },
                            .SUB => {
                                parseStack.push(State{ .action = .SUB });
                            },
                            else => unreachable,
                        }
                        parseStack.push(State{ .prod = .Term });
                        parseStack.push(State{ .prod = .OpToken });
                    },
                    .RPAR => {
                        return;
                    },
                    else => {
                        std.debug.print("expecting expr\' but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                return;
            }
        },
        .Factor => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .LPAR, .INT => {
                        parseStack.push(State{ .prod = .Factor2 });
                        parseStack.push(State{ .prod = .Power });
                    },
                    else => {
                        std.debug.print("expecting ( or .INT but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting Factor but met null", .{});
                std.process.exit(1);
            }
        },
        .Factor2 => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .POWER => {
                        // right-combined
                        parseStack.push(State{ .action = .POW });
                        parseStack.push(State{ .prod = .Factor2 });
                        parseStack.push(State{ .prod = .Power });
                        parseStack.push(State{ .prod = .OpToken });
                    },
                    .ADD, .RPAR, .MUL => {
                        return;
                    },
                    else => {
                        std.debug.print("expecting factor\' but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                return;
            }
        },
        .Term => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .LPAR, .INT => {
                        parseStack.push(State{ .prod = .Term2 });
                        parseStack.push(State{ .prod = .Factor });
                    },
                    else => {
                        std.debug.print("expecting ( or .INT but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting Term but met null", .{});
                std.process.exit(1);
            }
        },
        .Term2 => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .MUL, .DIV => {
                        parseStack.push(State{ .prod = .Term2 });
                        switch (unwrap_topToken.tktype) {
                            .MUL => {
                                parseStack.push(State{ .action = .MUL });
                            },
                            .DIV => {
                                parseStack.push(State{ .action = .DIV });
                            },
                            else => unreachable,
                        }
                        parseStack.push(State{ .prod = .Factor });
                        parseStack.push(State{ .prod = .OpToken });
                    },
                    .ADD, .RPAR => {
                        return;
                    },
                    else => {
                        std.debug.print("expecting term\' but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                return;
            }
        },
        .Power => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .LPAR => {
                        parseStack.push(State{ .prod = .PAR });
                        parseStack.push(State{ .prod = .Expr });
                        parseStack.push(State{ .prod = .PAR });
                    },
                    .INT => {
                        parseStack.push(State{ .prod = .Numbers });
                    },
                    else => {
                        std.debug.print("expecting .RPAR or .INT but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting power but met null", .{});
                std.process.exit(1);
            }
        },
        .Numbers => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .INT => {
                        evalStack.push(@as(i64, @intCast(unwrap_topToken.value)));
                        tokenReader.next();
                    },
                    else => {
                        std.debug.print("expecting .INT but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting number but met null", .{});
                std.process.exit(1);
            }
        },
        .OpToken => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .ADD, .SUB, .MUL, .DIV, .POWER => {
                        tokenReader.next();
                        return;
                    },
                    else => {
                        std.debug.print("expecting OpToken but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting number but met null", .{});
                std.process.exit(1);
            }
        },
        .PAR => {
            if (topToken) |unwrap_topToken| {
                switch (unwrap_topToken.tktype) {
                    .LPAR, .RPAR => {
                        tokenReader.next();
                        return;
                    },
                    else => {
                        std.debug.print("expecting PAR but met {}", .{unwrap_topToken.tktype});
                        std.process.exit(1);
                    },
                }
            } else {
                std.debug.print("expecting PAR but met null", .{});
                std.process.exit(1);
            }
        },
    }
}

fn action(act: Action, evalStack: *Stack(i64)) void {
    const x = evalStack.pop().?;
    const y = evalStack.pop().?;
    switch (act) {
        .ADD => {
            evalStack.push(x + y);
        },
        .SUB => {
            evalStack.push(y - x);
        },
        .MUL => {
            evalStack.push(x * y);
        },
        .DIV => {
            evalStack.push(@divExact(y, x));
        },
        .POW => {
            evalStack.push(std.math.powi(i64, y, x) catch {
                std.debug.print("power failed", .{});
                std.process.exit(1);
            });
        },
    }
}

fn parse(tokenReader: *TokenReader) i64 {
    var parseStack = Stack(State){};
    var evalStack = Stack(i64){};
    parseStack.push(State{ .prod = .Expr });

    while (parseStack.size() != 0) {
        const top = parseStack.pop();
        if (top == null) {
            std.debug.print("parseStack error, met empty when popping element!", .{});
            std.process.exit(1);
        }
        switch (top.?) {
            .action => |act| {
                action(act, &evalStack);
            },
            .prod => |prod| {
                table(prod, tokenReader, &parseStack, &evalStack);
            },
        }

        // Check out the process
        // for (0..parseStack.size()) |idx| {
        //     std.debug.print("{},", .{parseStack.ntop(idx).?});
        // }
        // std.debug.print("\n", .{});

        // for (0..evalStack.size()) |idx| {
        //     std.debug.print("{},", .{evalStack.ntop(idx).?});
        // }
        // std.debug.print("\n", .{});
    }

    if (tokenReader.current_token() != null or evalStack.size() != 1) {
        std.debug.print("evaluatation failed, mismatched length!", .{});
        std.process.exit(1);
    }

    return evalStack.top().?;
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
