const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

const rl = @cImport({
    @cInclude("raylib.h");
});

const ListError = error{ IndexOutOfBounds, Empty };

pub const Node = struct {
    next: ?*Node,
    prev: ?*Node,
    x: f32,
    y: f32,
};

pub const List = struct {
    head: *Node,
    tail: *Node,
    allocator: Allocator,
    len: usize = 0,

    pub fn init(allocator: Allocator, x: [3]f32, y: [3]f32) !List {
        std.debug.assert(x.len == y.len);
        const nodes = try allocator.alloc(*Node, x.len);
        defer allocator.free(nodes);

        const head = try createNode(allocator, x[0], y[0], null);
        nodes[0] = head;

        for (1..nodes.len) |i| {
            const prev = nodes[i - 1];
            const node = try createNode(allocator, x[i], y[i], prev);
            nodes[i] = node;
            prev.next = node;
        }

        return List{
            .head = head,
            .tail = nodes[nodes.len - 1],
            .allocator = allocator,
            .len = nodes.len,
        };
    }

    pub fn deinit(self: *List) void {
        var node: *Node = self.head;
        while (true) {
            const next = node.next orelse {
                self.allocator.destroy(node);
                break;
            };
            self.allocator.destroy(node);
            node = next;
        }
        // self.allocator.destroy(self);
    }

    fn createNode(allocator: Allocator, x: f32, y: f32, prev: ?*Node) !*Node {
        const node = try allocator.create(Node);
        errdefer allocator.destroy(node);
        node.* = Node{ .x = x, .y = y, .prev = prev, .next = null };
        return node;
    }

    pub fn add(self: *List, x: f32, y: f32) !void {
        const oldHead = self.head;
        const newHead = try self.allocator.create(Node);
        errdefer self.allocator.destroy(newHead);
        newHead.* = Node{ .next = oldHead, .prev = null, .x = x, .y = y };
        oldHead.prev = newHead;
        self.head = newHead;
        self.len += 1;
    }

    pub fn pop(self: *List) !void {
        const oldTail = self.tail;
        self.tail = oldTail.prev orelse return error.Empty;
        self.tail.next = null;
        self.len -= 1;
        self.allocator.destroy(oldTail);
    }

    pub fn popAfter(self: *List, this: *Node) !void {
        while (this != self.tail) try self.pop();
    }

    pub fn move(self: *List, x: f32, y: f32) !void {
        try pop(self);
        try add(self, x, y);
    }

    pub fn get(self: *List, index: usize) ListError!*Node {
        if (index >= self.len or index < 0) return ListError.IndexOutOfBounds;
        var i: usize = 0;
        var el: *Node = self.head;
        while (i < index) : (i += 1) {
            el = el.next orelse return ListError.Empty;
        }
        return el;
    }
};

test "get right element by index" {
    const arr = [_]f32{ 0, 0, 2, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const el = try list.get(2);
    try expect(el.x == 2);
    try expect(el.y == 2);
}

test "get last item of array by index" {
    const arr = [_]f32{ 0, 0, 0, 0, 2 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const el = try list.get(4);
    try expect(el.x == 2);
    try expect(el.y == 2);
}

test "get first item of array by index" {
    const arr = [_]f32{ 1, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const el = try list.get(0);
    try expect(el.x == 1);
    try expect(el.y == 1);
}

test "get error.OutOfBounds when accessing inexistent index" {
    const arr = [_]f32{ 0, 0, 0, 0, 2 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const el = list.get(5);
    try expect(el == error.IndexOutOfBounds);
}

test "pop should decrease len by 1" {
    const arr = [_]f32{ 0, 0, 0, 0, 2 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.pop();
    try expect(list.len == 4);
}

test "pop should remove last item" {
    const arr = [_]f32{ 0, 0, 0, 2, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try expect(list.tail.x == 0);
    try expect(list.tail.y == 0);
    try list.pop();
    try expect(list.tail.x == 2);
    try expect(list.tail.y == 2);
}

test "add should increase len by 1" {
    const arr = [_]f32{ 0, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.add(2, 2);
    try expect(list.len == 6);
}

test "add should add a new head" {
    const arr = [_]f32{ 0, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.add(2, 2);
    try expect(list.head.x == 2);
    try expect(list.head.y == 2);
}

test "add should move old head to second position" {
    const arr = [_]f32{ 2, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.add(0, 0);
    const el = try list.get(1);
    try expect(el.x == 2);
    try expect(el.y == 2);
}

test "after add, head.next should point to old head" {
    const arr = [_]f32{ 2, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.add(0, 0);
    const newHead = try list.get(0);
    const oldHead = try list.get(1);
    try expect(newHead.next == oldHead);
    // const oldHead = try list.get(1);
    // const node = &Node{ .prev = null, .next = null, .x = 0, .y = 0 };
    // try expect(oldHead.prev == node);
}

test "after add, oldHead.prev should point to head" {
    const arr = [_]f32{ 2, 0, 0, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    try list.add(0, 0);
    const newHead = try list.get(0);
    const oldHead = try list.get(1);
    try expect(oldHead.prev == newHead);
}

test "popAfter should stop at given node" {
    const arr = [_]f32{ 0, 0, 2, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const node = try list.get(2);
    try list.popAfter(node);
    try expect(list.tail == node);
}

test "popAfter should update list nodes len" {
    const arr = [_]f32{ 0, 0, 2, 0, 0 };
    var list = try List.init(std.testing.allocator, arr, arr);
    defer list.deinit();
    const node = try list.get(2);
    try list.popAfter(node);
    try expect(list.len == 3);
}
