const std = @import("std");

pub fn part1(file: std.fs.File) !i32 {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var bytes = std.ArrayList(u8).init(std.heap.page_allocator);
    const stat = try file.stat();
    try in_stream.readAllArrayList(&bytes, stat.size);

    var collector = std.ArrayList(u8).init(std.heap.page_allocator);
    defer collector.deinit();

    var out: i32 = 0;
    for (bytes.items) |char| {
        switch (char) {
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '0',
            'm',
            'u',
            'l',
            '(',
            ',',
            => {
                try collector.append(char);
            },
            ')' => {
                const base = std.mem.indexOf(u8, collector.items, "mul") orelse 0;
                const data = collector.items[base..];

                std.debug.print("collector: {s}\n", .{collector.items});

                if (data.len < 7) {
                    collector.clearAndFree();
                    continue;
                }

                if (!std.mem.eql(u8, data[0..4], "mul(")) {
                    collector.clearAndFree();
                    continue;
                }

                const ci = std.mem.indexOf(u8, data, ",");
                if (ci == null) {
                    collector.clearAndFree();
                    continue;
                }

                const split = ci.?;

                const a = try std.fmt.parseInt(i32, data[4..split], 10);
                const b = try std.fmt.parseInt(i32, data[split + 1 ..], 10);

                std.debug.print("a: {any}, b: {any}\n", .{ a, b });
                out += a * b;
                collector.clearAndFree();
                continue;
            },
            else => {
                collector.clearAndFree();
            },
        }
    }

    return out;
}

pub fn part2(file: std.fs.File) !i32 {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var bytes = std.ArrayList(u8).init(std.heap.page_allocator);
    const stat = try file.stat();
    try in_stream.readAllArrayList(&bytes, stat.size);

    var out: i32 = 0;
    var cursor: usize = 0;
    var do_mode = true;

    while (cursor < stat.size) {
        const win = bytes.items[cursor..];
        if (win.len < 7) {
            break;
        }

        if (std.mem.eql(u8, win[0..4], "mul(")) {
            cursor += 4;
            const inner = win[4..];
            const comma_index = std.mem.indexOf(u8, inner, ",");
            if (comma_index) |ci| {
                const paren_index = std.mem.indexOf(u8, inner[ci..], ")");

                if (paren_index) |pi| {
                    std.debug.print("ci: {any}, pi: {any}, inner: {s}", .{ ci, pi, inner });
                    const a = std.fmt.parseInt(i32, inner[0..ci], 10) catch continue;
                    const b = std.fmt.parseInt(i32, inner[ci + 1 .. ci + pi], 10) catch continue;

                    if (do_mode) {
                        out += a * b;
                    }
                    cursor += ci + pi;
                }
            }
        } else if (std.mem.eql(u8, win[0..4], "do()")) {
            do_mode = true;
            cursor += 4;
        } else if (std.mem.eql(u8, win[0..7], "don't()")) {
            do_mode = false;
            cursor += 7;
        } else {
            cursor += 1;
        }
    }
    return out;
}
