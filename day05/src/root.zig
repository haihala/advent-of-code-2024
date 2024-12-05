const std = @import("std");

const Puzzle = struct {
    rules: std.AutoHashMap(i32, [2]std.ArrayList(i32)),
    updates: std.ArrayList([]i32),
};

pub fn part1(file: std.fs.File) !i32 {
    const puzzle = try read_input(file);

    var out: i32 = 0;
    for (puzzle.updates.items) |update| {
        if (valid_order(update, puzzle.rules)) {
            out += update[update.len / 2];
        }
    }

    return out;
}

pub fn part2(file: std.fs.File) !i32 {
    const puzzle = try read_input(file);

    var out: i32 = 0;
    for (puzzle.updates.items) |update| {
        if (!valid_order(update, puzzle.rules)) {
            out += try reordered_value(update, puzzle.rules);
        }
    }

    return out;
}

fn reordered_value(
    update: []i32,
    rules: std.AutoHashMap(i32, [2]std.ArrayList(i32)),
) !i32 {
    var build = std.ArrayList(i32).init(std.heap.page_allocator);
    defer build.deinit();

    while (build.items.len != update.len) {
        for (update) |candidate| {
            if (std.mem.containsAtLeast(i32, build.items, 1, &[_]i32{candidate})) {
                // Number already in there, skip
                continue;
            }

            const must_be_before = rules.get(candidate).?[0];

            var all_in = true;
            for (must_be_before.items) |requirement| {
                const value_in_update = std.mem.containsAtLeast(i32, update, 1, &[_]i32{requirement});
                if (!value_in_update) {
                    continue;
                }

                const already_in = std.mem.containsAtLeast(i32, build.items, 1, &[_]i32{requirement});
                if (!already_in) {
                    all_in = false;
                    break;
                }
            }

            if (all_in) {
                try build.append(candidate);
            }
        }
    }

    return build.items[build.items.len / 2];
}

fn valid_order(
    update: []i32,
    rules: std.AutoHashMap(i32, [2]std.ArrayList(i32)),
) bool {
    for (update, 0..) |num, index| {
        const rule = rules.get(num);
        if (rule == null) {
            // No rules for this number, everything goes
            continue;
        }

        const before = update[0..index];
        const after = update[index + 1 ..];

        const must_be_before = rule.?[0];
        const must_be_after = rule.?[1];

        for (must_be_after.items) |after_requirement| {
            if (std.mem.containsAtLeast(i32, before, 1, &[_]i32{after_requirement})) {
                // There is an illegal page
                return false;
            }
        }

        for (must_be_before.items) |before_requirement| {
            if (std.mem.containsAtLeast(i32, after, 1, &[_]i32{before_requirement})) {
                // There is an illegal page
                return false;
            }
        }
    }

    return true;
}

fn read_input(file: std.fs.File) !Puzzle {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var rules = std.AutoHashMap(i32, [2]std.ArrayList(i32)).init(std.heap.page_allocator);
    var updates = std.ArrayList([]i32).init(std.heap.page_allocator);

    var in_rule_block = true;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            // Empty line between blocks
            in_rule_block = false;
            continue;
        }

        if (in_rule_block) {
            var nums = std.ArrayList(i32).init(std.heap.page_allocator);
            var chunks = std.mem.split(u8, line, "|");
            while (chunks.next()) |chunk| {
                const num = try std.fmt.parseInt(i32, chunk, 10);
                try nums.append(num);
            }
            try std.testing.expect(nums.items.len == 2);

            if (rules.getPtr(nums.items[0])) |first| {
                try first[1].append(nums.items[1]);
            } else {
                var afters = std.ArrayList(i32).init(std.heap.page_allocator);
                try afters.append(nums.items[1]);

                try rules.put(nums.items[0], .{
                    std.ArrayList(i32).init(std.heap.page_allocator),
                    afters,
                });
            }

            if (rules.getPtr(nums.items[1])) |second| {
                try second[0].append(nums.items[0]);
            } else {
                var befores = std.ArrayList(i32).init(std.heap.page_allocator);
                try befores.append(nums.items[0]);

                try rules.put(nums.items[1], .{
                    befores,
                    std.ArrayList(i32).init(std.heap.page_allocator),
                });
            }
        } else {
            var nums = std.ArrayList(i32).init(std.heap.page_allocator);
            var chunks = std.mem.split(u8, line, ",");
            while (chunks.next()) |chunk| {
                const num = try std.fmt.parseInt(i32, chunk, 10);
                try nums.append(num);
            }

            try updates.append(nums.items);
        }
    }

    return Puzzle{ .rules = rules, .updates = updates };
}
