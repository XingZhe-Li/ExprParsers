pub const TokenType = enum { ADD, SUB, MUL, DIV, LPAR, RPAR, INT, POWER };

pub const Token = struct { tktype: TokenType, value: u64 = 0 };

pub const Lexer = struct {
    src: []const u8,
    ptr: usize,
    fn current_u8(self: *@This()) ?u8 {
        if (self.ptr >= self.src.len) {
            return null;
        }
        return self.src[self.ptr];
    }
    fn next(self: *@This()) void {
        self.ptr += 1;
    }
    fn token(self: *@This()) ?Token {
        while (self.current_u8()) |head| {
            switch (head) {
                '0'...'9' => {
                    var result: u64 = 0;
                    while (self.current_u8()) |char| {
                        if (char < '0' or char > '9') break;
                        result = 10 * result + (char - '0');
                        self.next();
                    }
                    return Token{ .tktype = .INT, .value = result };
                },
                '+' => {
                    self.next();
                    return Token{ .tktype = .ADD };
                },
                '-' => {
                    self.next();
                    return Token{ .tktype = .SUB };
                },
                '*' => {
                    self.next();
                    return Token{ .tktype = .MUL };
                },
                '/' => {
                    self.next();
                    return Token{ .tktype = .DIV };
                },
                '(' => {
                    self.next();
                    return Token{ .tktype = .LPAR };
                },
                ')' => {
                    self.next();
                    return Token{ .tktype = .RPAR };
                },
                '^' => {
                    self.next();
                    return Token{ .tktype = .POWER };
                },
                else => {
                    self.next();
                    continue;
                },
            }
        }
        return null;
    }
};

const std = @import("std");

pub const TokenReader = struct {
    lexer: Lexer,
    token_buf: ?Token = null,
    pub fn current_token(self: *@This()) ?Token {
        return self.token_buf;
    }
    pub fn next(self: *@This()) void {
        self.token_buf = self.lexer.token();
    }
    pub fn new(src: []const u8) TokenReader {
        var tokenReader = TokenReader{ .lexer = Lexer{ .ptr = 0, .src = src } };
        tokenReader.next();
        return tokenReader;
    }
};
