const std = @import("std");

const Point = struct { x: i32, y: i32 };

fn add(p1: Point, p2: Point) Point {
    return .{ .x = p1.x + p2.x, .y = p1.y + p2.y };
}

fn eq(p1: Point, p2: Point) bool {
    return p1.x == p2.x and p1.y == p2.y;
}

pub fn part1(file: std.fs.File) !i32 {
    const map = try build_map(file);

    const offsets: []const Point = &.{
        // Cardinals
        .{ .x = 0, .y = 1 },
        .{ .x = 0, .y = -1 },
        .{ .x = 1, .y = 0 },
        .{ .x = -1, .y = 0 },

        // Diagonals
        .{ .x = 1, .y = 1 },
        .{ .x = 1, .y = -1 },
        .{ .x = -1, .y = 1 },
        .{ .x = -1, .y = -1 },
    };

    var out: i32 = 0;

    for (offsets) |offset| {
        for (map.get('X').?.items) |xs| {
            for (map.get('M').?.items) |ms| {
                if (!eq(ms, add(xs, offset))) {
                    continue;
                }

                for (map.get('A').?.items) |as| {
                    if (!eq(as, add(ms, offset))) {
                        continue;
                    }
                    for (map.get('S').?.items) |ss| {
                        if (!eq(ss, add(as, offset))) {
                            continue;
                        }
                        // This is a real XMAS
                        // std.debug.print("offset: {any}, x: {any}, m: {any}, a: {any}, s: {any}\n", .{ offset, xs, ms, as, ss });
                        out += 1;
                    }
                }
            }
        }
    }

    return out;
}

fn flip(p: Point) Point {
    return Point{ .x = -p.x, .y = -p.y };
}

fn has_none(haystack: []Point, target: Point) bool {
    for (haystack) |candidate| {
        if (eq(candidate, target)) {
            return false;
        }
    }
    return true;
}

pub fn part2(file: std.fs.File) !i32 {
    const map = try build_map(file);

    // Four options:
    // M_M    M_S    S_M    S_S
    // _A_    _A_    _A_    _A_
    // S_S    M_S    S_M    M_M
    // Pretty sure it doesn't do diagonals
    // They are in order, only encode M points as they force Ss
    const m_options: [4][2]Point = .{
        .{
            .{ .x = 1, .y = -1 },
            .{ .x = -1, .y = -1 },
        },
        .{
            .{ .x = 1, .y = 1 },
            .{ .x = 1, .y = -1 },
        },
        .{
            .{ .x = -1, .y = 1 },
            .{ .x = -1, .y = -1 },
        },
        .{
            .{ .x = 1, .y = 1 },
            .{ .x = -1, .y = 1 },
        },
    };

    var out: i32 = 0;

    const As = map.get('A').?.items;
    const Ms = map.get('M').?.items;
    const Ss = map.get('S').?.items;

    for (As) |a_pos| {
        for (m_options) |orientation| {
            const first_m = add(a_pos, orientation[0]);
            const first_s = add(a_pos, flip(orientation[0]));
            const second_m = add(a_pos, orientation[1]);
            const second_s = add(a_pos, flip(orientation[1]));

            if (has_none(Ms, first_m)) {
                continue;
            }

            if (has_none(Ms, second_m)) {
                continue;
            }

            if (has_none(Ss, first_s)) {
                continue;
            }

            if (has_none(Ss, second_s)) {
                continue;
            }

            // I don't think the same X can have multiples
            out += 1;
            break;
        }
    }

    return out;
}

fn build_map(file: std.fs.File) !std.AutoHashMap(u8, std.ArrayList(Point)) {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var map = std.AutoHashMap(u8, std.ArrayList(Point)).init(std.heap.page_allocator);
    var y: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // do something with line...
        for (line, 0..) |char, x| {
            if (std.mem.containsAtLeast(u8, "XMAS", 1, &[_]u8{char})) {
                const point = Point{ .x = @intCast(x), .y = @intCast(y) };

                if (map.getPtr(char)) |coords| {
                    try coords.append(point);
                    try map.put(char, coords.*);
                } else {
                    var al = std.ArrayList(Point).init(std.heap.page_allocator);
                    try al.append(point);
                    try map.put(char, al);
                }
            }
        }
        y += 1;
    }

    return map;
}

const assert_eq = std.testing.expectEqual;
test "Add and eq" {
    const point = Point{ .x = 1, .y = 2 };
    try assert_eq(point, point);

    const point2 = add(point, Point{ .x = 5, .y = 7 });
    try assert_eq(point2, Point{ .x = 6, .y = 9 });
}
