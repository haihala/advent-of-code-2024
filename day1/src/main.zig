const std = @import("std");
const root = @import("./root.zig");

pub fn main() !void {
    const out1 = try root.part1("input/puzzle.txt");
    std.debug.print("Part 1: {any}\n", .{out1});
    const out2 = try root.part2("input/puzzle.txt");
    std.debug.print("Part 2: {any}\n", .{out2});
}

test "part1 example" {
    const out = try root.part1("input/example.txt");
    try std.testing.expectEqual(11, out);
}

test "part2 example" {
    const out = try root.part2("input/example.txt");
    try std.testing.expectEqual(31, out);
}
