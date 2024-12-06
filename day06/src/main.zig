const std = @import("std");
const root = @import("./root.zig");

pub fn main() !void {
    const file = std.fs.cwd().openFile("input/puzzle.txt", .{}) catch unreachable;
    defer file.close();
    const out1 = root.part1(file);
    std.debug.print("Part 1: {any}\n", .{out1});

    file.seekTo(0) catch unreachable;
    const out2 = root.path2_path_traverse(file);
    std.debug.print("Part 2: {any}\n", .{out2});
}

test "part1 example" {
    const file = std.fs.cwd().openFile("input/example.txt", .{}) catch unreachable;
    defer file.close();
    const out = root.part1(file);
    try std.testing.expectEqual(41, out);
}

test "part2 example path" {
    const file = std.fs.cwd().openFile("input/example.txt", .{}) catch unreachable;
    defer file.close();
    const out = root.path2_path_traverse(file);
    try std.testing.expectEqual(6, out);
}

test "part2 example brute" {
    const file = std.fs.cwd().openFile("input/example.txt", .{}) catch unreachable;
    defer file.close();
    const out = root.part2_brute(file);
    try std.testing.expectEqual(6, out);
}
