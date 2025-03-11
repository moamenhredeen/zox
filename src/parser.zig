//! Parser
//! the problem i have right now is modeling the AST, that will be returned by the parser.
//! the idea was to use a `tagged union` wich represent all different node types (like
//! binary, unary, ...). each one of the types can contains an expression (it is recursive
//! data type). we can say, that this the OOP of moduling an AST.
//! there is multiple problems with this approach
//! - space ineffeciant: an array of tagged union means there will a LOT of padding
//! - using pointers: i'm not sure, if this will cause more cache misses
//! - currently i'm unable to get it to work
//! Although this approach has many problems, it it the most intuitive solution.
//! maybe i should implement the AST using recursive data types and later and can rebuild
//! it using a more data-oriented approach

const std = @import("std");
const tokenizer = @import("./tokenizer.zig");

const Literal = struct {
    value: u32,
};

const Unary = struct {
    operator: tokenizer.Token,
    expr: *Expr,
};

const Binary = struct {
    operator: tokenizer.Token,
    left_expr: *Expr,
    right_expr: *Expr,
};

const Grouping = struct {
    expr: *Expr,
};

/// Expression
pub const Expr = union(enum) {
    literal: Literal,
    unary: Unary,
    binary: Binary,
    grouping: Grouping,
};

pub fn serialize(expr: Expr) !void {
    const res = switch (expr) {
        .literal => |e| std.fmt.format("{}", e.value),
        .unary => |e| std.fmt.format("({s} {})", e.operator.lexeme, serialize(e.expr)),
        .binary => |e| std.fmt.format("({s} {s} {s})", e.operator.lexeme, serialize(e.left_expr), serialize(e.right_expr)),
        .grouping => |e| std.fmt.format("({})", serialize(e.expr)),
    };
    return res;
}

test "print ast" {
    const ast = Binary{
        .operator = .{ .line = 1, .lexeme = "-", .token_type = .MINUS },
        .left_expr = &Literal{ .value = 2 },
        .right_expr = &Literal{ .value = 2 },
    };

    std.testing.expectEqual(
        \\(- 2 2)
    , serialize(ast));
}
