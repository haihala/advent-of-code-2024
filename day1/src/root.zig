const std = @import("std");

const FileError = error{ Opening, Reading, NaN, Oom };

pub fn part1(path: []const u8) FileError!usize {
    const file = std.fs.cwd().openFile(path, .{}) catch return FileError.Opening;
    defer file.close();

    const pairs = try read_file(file);

    const left = pairs[0];
    const right = pairs[1];

    std.mem.sort(i32, left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right, {}, comptime std.sort.asc(i32));

    var out: usize = 0;

    for (left, right) |l, r| {
        out += @abs(l - r);
    }

    return out;
}

pub fn part2(path: []const u8) FileError!usize {
    const file = std.fs.cwd().openFile(path, .{}) catch return FileError.Opening;
    defer file.close();

    const pairs = try read_file(file);
    const left = pairs[0];
    const right = pairs[1];

    var map = std.AutoHashMap(i32, i32).init(
        std.heap.page_allocator,
    );
    defer map.deinit();
    for (right) |r| {
        const value = map.get(r) orelse 0;
        map.put(r, value + 1) catch return FileError.Oom;
    }

    var out: usize = 0;

    for (left) |num| {
        const rcount = map.get(num) orelse continue;
        out += @abs(num * rcount);
    }

    return out;
}

fn read_file(file: std.fs.File) FileError![2][]i32 {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var left = std.ArrayList(i32).init(std.heap.page_allocator);
    var right = std.ArrayList(i32).init(std.heap.page_allocator);

    var buf: [1024]u8 = undefined;
    while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch return FileError.Reading) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');

        var first: []const u8 = "";
        var last: []const u8 = undefined;

        while (it.next()) |elem| {
            if (first.len == 0) {
                first = elem;
            }

            last = elem;
        }

        const pl = std.fmt.parseInt(i32, first, 10) catch return FileError.NaN;
        const pr = std.fmt.parseInt(i32, last, 10) catch return FileError.NaN;

        left.append(pl) catch return FileError.Oom;
        right.append(pr) catch return FileError.Oom;
    }

    return .{ left.items, right.items };
}
