const std = @import("std");

pub fn part1(file: std.fs.File) usize {
    const reports = read_file(file);

    var out: usize = 0;

    for (reports) |report| {
        if (is_safe1(report)) {
            out += 1;
        }
    }

    return out;
}

pub fn part2(file: std.fs.File) usize {
    const reports = read_file(file);

    var out: usize = 0;

    for (reports) |report| {
        if (is_safe2(report)) {
            out += 1;
        }
    }

    return out;
}

fn read_file(file: std.fs.File) [][]const i32 {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var reports = std.ArrayList([]i32).init(std.heap.page_allocator);

    var buf: [1024]u8 = undefined;
    while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch unreachable) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');

        var arr = std.ArrayList(i32).init(std.heap.page_allocator);

        while (it.next()) |elem| {
            arr.append(std.fmt.parseInt(i32, elem, 10) catch unreachable) catch unreachable;
        }

        reports.append(arr.items) catch unreachable;
    }

    return reports.items;
}

fn is_safe1(input: []const i32) bool {
    var increasing = true;
    var decreasing = true;
    var small_jumps = true;

    for (input[0..(input.len - 1)], input[1..]) |prev, next| {
        increasing = increasing and prev < next;
        decreasing = decreasing and prev > next;

        small_jumps = small_jumps and @abs(prev - next) <= 3;
    }

    std.debug.print("Input: {any}, increasing: {any}, decreasing: {any}, small jumps: {any}\n", .{ input, increasing, decreasing, small_jumps });

    return (increasing or decreasing) and small_jumps;
}

fn is_safe2(input: []const i32) bool {
    if (is_safe1(input)) {
        return true;
    }

    var al = std.ArrayList(i32).init(std.heap.page_allocator);
    defer al.deinit();

    for (0..input.len) |i| {
        al.clearAndFree();

        al.appendSlice(input[0..i]) catch unreachable;
        al.appendSlice(input[(i + 1)..]) catch unreachable;

        if (is_safe1(al.items)) {
            return true;
        }
    }

    return false;
}
