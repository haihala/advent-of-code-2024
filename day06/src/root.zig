const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,
};

fn turn(coord: Vec2) Vec2 {
    const new_x = -coord.y;
    const new_y = coord.x;

    return Vec2{ .x = new_x, .y = new_y };
}

fn eq(a: Vec2, b: Vec2) bool {
    return a.x == b.x and a.y == b.y;
}

fn in_bounds(pos: Vec2, bounds: Vec2) bool {
    if (pos.x < 0) return false;
    if (pos.y < 0) return false;
    if (pos.x >= bounds.x) return false;
    if (pos.y >= bounds.y) return false;
    return true;
}

fn add(p1: Vec2, p2: Vec2) Vec2 {
    return .{ .x = p1.x + p2.x, .y = p1.y + p2.y };
}
fn sub(p1: Vec2, p2: Vec2) Vec2 {
    return .{ .x = p1.x - p2.x, .y = p1.y - p2.y };
}

const Puzzle = struct {
    obstacles: std.ArrayList(Vec2),
    guard_pos: Vec2,
    guard_facing: Vec2,
    bounds: Vec2,
};

// Unused
fn debug_draw(puzzle: Puzzle, explored: std.AutoHashMap(Vec2, u8)) void {
    std.debug.print("Map:\n", .{});
    for (0..@intCast(puzzle.bounds.y)) |y| {
        for (0..@intCast(puzzle.bounds.x)) |x| {
            const point = Vec2{ .x = @intCast(x), .y = @intCast(y) };

            var is_obstacle = false;
            for (puzzle.obstacles.items) |obs| {
                if (eq(obs, point)) {
                    is_obstacle = true;
                    break;
                }
            }

            if (is_obstacle) {
                std.debug.print("#", .{});
                continue;
            }

            if (eq(puzzle.guard_pos, point)) {
                if (puzzle.guard_facing.y == -1) {
                    std.debug.print("^", .{});
                }
                if (puzzle.guard_facing.y == 1) {
                    std.debug.print("v", .{});
                }
                if (puzzle.guard_facing.x == 1) {
                    std.debug.print(">", .{});
                }
                if (puzzle.guard_facing.x == -1) {
                    std.debug.print("<", .{});
                }

                continue;
            }

            const in_explored = explored.getKey(point) != null;
            if (in_explored) {
                std.debug.print("X", .{});
                continue;
            }

            // Empty, unexplored space
            std.debug.print(".", .{});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n\n", .{});
}

pub fn part1(file: std.fs.File) !i32 {
    const puzzle = try read_input(file);
    var pos = puzzle.guard_pos;
    var facing = puzzle.guard_facing;
    // There doesn't seem to be a hashset, so use a hashmap with meaningless values
    var explored = std.AutoHashMap(Vec2, u8).init(std.heap.page_allocator);

    while (in_bounds(pos, puzzle.bounds)) {
        try explored.put(pos, 0);
        const target = add(pos, facing);

        var bump = false;
        for (puzzle.obstacles.items) |obstacle| {
            if (eq(obstacle, target)) {
                // Collision
                bump = true;
                break;
            }
        }

        if (bump) {
            facing = turn(facing);
        } else {
            pos = target;
        }
    }

    return @intCast(explored.count());
}

pub fn part2_brute(file: std.fs.File) !i32 {
    const puzzle = try read_input(file);
    var pos = puzzle.guard_pos;
    var facing = puzzle.guard_facing;
    // There doesn't seem to be a hashset, so use a hashmap with meaningless values
    var explored = std.AutoHashMap(Vec2, u8).init(std.heap.page_allocator);

    while (in_bounds(pos, puzzle.bounds)) {
        try explored.put(pos, 0);
        const target = add(pos, facing);

        var bump = false;
        for (puzzle.obstacles.items) |obstacle| {
            if (eq(obstacle, target)) {
                // Collision
                bump = true;
                break;
            }
        }

        if (bump) {
            facing = turn(facing);
        } else {
            pos = target;
        }
    }

    var out: i32 = 0;
    // Block needs to go into one of the squares the guard actually explores
    var key_iter = explored.keyIterator();
    while (key_iter.next()) |to_block| {
        var new_obstacles = try puzzle.obstacles.clone();
        defer new_obstacles.deinit();
        try new_obstacles.append(to_block.*);

        const sub_puzzle = Puzzle{
            .bounds = puzzle.bounds,
            .guard_pos = puzzle.guard_pos,
            .guard_facing = puzzle.guard_facing,
            .obstacles = new_obstacles,
        };

        if (try is_loop(sub_puzzle)) {
            out += 1;
        }
    }

    return out;
}

// This is an optimized approach to brute forcing it
// Runs in about a third of the time the mega brute one does.
// Still the wrong solution
pub fn part2_path_traverse(file: std.fs.File) !i32 {
    const puzzle = try read_input(file);
    var pos = puzzle.guard_pos;
    var facing = puzzle.guard_facing;
    // There doesn't seem to be a hashset, so use a hashmap with meaningless values
    var explored = std.AutoHashMap(Vec2, u8).init(std.heap.page_allocator);

    var loops: i32 = 0;
    while (in_bounds(pos, puzzle.bounds)) {
        if (explored.getKey(pos) == null) {
            // Unexplored, add a block, move back, simulate
            var new_obstacles = try puzzle.obstacles.clone();
            defer new_obstacles.deinit();
            try new_obstacles.append(pos);

            const sub_puzzle = Puzzle{
                .bounds = puzzle.bounds,
                .guard_pos = sub(pos, facing),
                .guard_facing = facing,
                .obstacles = new_obstacles,
            };

            if (try is_loop(sub_puzzle)) {
                loops += 1;
            }
        }

        try explored.put(pos, 0);
        const target = add(pos, facing);

        var bump = false;
        for (puzzle.obstacles.items) |obstacle| {
            if (eq(obstacle, target)) {
                // Collision
                bump = true;
                break;
            }
        }

        if (bump) {
            facing = turn(facing);
        } else {
            pos = target;
        }
    }

    return loops;
}
fn is_loop(puzzle: Puzzle) !bool {
    var pos = puzzle.guard_pos;
    var facing = puzzle.guard_facing;
    var explored = std.AutoHashMap(Vec2, std.ArrayList(Vec2)).init(std.heap.page_allocator);
    defer {
        var it = explored.valueIterator();
        while (it.next()) |dirs| {
            dirs.deinit();
        }
        explored.deinit();
    }

    while (in_bounds(pos, puzzle.bounds)) {
        if (explored.getPtr(pos)) |dirs| {
            for (dirs.items) |dir| {
                // Same point, same facing = loop
                if (eq(dir, facing)) {
                    return true;
                }
            }

            // Not a loop yet
            try dirs.append(facing);
        } else {
            var dirs = std.ArrayList(Vec2).init(std.heap.page_allocator);
            try dirs.append(facing);
            try explored.put(pos, dirs);
        }

        const target = add(pos, facing);

        var bump = false;
        for (puzzle.obstacles.items) |obstacle| {
            if (eq(obstacle, target)) {
                // Collision
                bump = true;
                break;
            }
        }

        if (bump) {
            facing = turn(facing);
        } else {
            pos = target;
        }
    }

    return false;
}

fn read_input(file: std.fs.File) !Puzzle {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var obstacles = std.ArrayList(Vec2).init(std.heap.page_allocator);
    var guard_pos: Vec2 = undefined;
    var guard_facing: Vec2 = undefined;

    var y: i32 = 0;
    var max_x: i32 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // All lines are the same size right?
        max_x = @intCast(line.len);
        for (line, 0..) |char, x| {
            if (char == '.') {
                continue;
            }

            const pos = Vec2{ .x = @intCast(x), .y = y };
            if (char == '#') {
                try obstacles.append(pos);
                continue;
            }

            // Otherwise it's the guard
            guard_pos = pos;
            switch (char) {
                '^' => {
                    guard_facing = .{ .x = 0, .y = -1 };
                },
                'v' => {
                    guard_facing = .{ .x = 0, .y = 1 };
                },
                '>' => {
                    guard_facing = .{ .x = 1, .y = 0 };
                },
                '<' => {
                    guard_facing = .{ .x = -1, .y = 0 };
                },
                else => unreachable,
            }
        }
        y += 1;
    }

    return Puzzle{ .obstacles = obstacles, .guard_facing = guard_facing, .guard_pos = guard_pos, .bounds = .{ .x = max_x, .y = y } };
}
