const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

pub fn RingBuffer(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        items: [size]T,
        head: usize = 0,
        writeIdx: usize = 0,
        full: bool = false,

        /// Initialize a new RingBuffer instance.
        /// The buffer is allocated on the stack, so no explicit deinit is needed.
        pub fn init() Self {
            return Self{ .items = undefined };
        }

        /// Set `position` to the next valid array position.
        /// If we are at the end of the array, `position` will start
        /// again at the begining.
        /// Head will always point to the oldest item in the buffer.
        fn updateTailPosition(self: *Self) void {
            assert(self.writeIdx <= size);
            self.writeIdx = (self.writeIdx + 1) % size;

            if (self.writeIdx == self.head and !self.full) self.full = true;

            if (!self.full) {
                assert(self.head == 0);
                return;
            }

            self.head = self.writeIdx;
        }

        /// Insert a new item into the ring buffer.
        /// If the buffer is full, the oldest item is overwritten.
        pub fn insert(self: *Self, item: T) void {
            self.items[self.writeIdx] = item;
            self.updateTailPosition();
        }

        /// Retrieve the element at a given index relative to the current head position.
        /// Returns `null` no element was inserted at given index position.
        /// `index` is not sanitized for out of bounds range.
        pub fn elementAt(self: Self, index: usize) ?T {
            if (index >= size) return self.items[index];
            if (self.head == 0 and self.writeIdx == 0 and !self.full) return null;
            if (!self.full and index >= self.writeIdx) return null;

            return self.items[(index + self.head) % size];
        }

        pub fn reset(self: *Self) void {
            self.items = undefined;
            self.head = 0;
            self.writeIdx = 0;
            self.full = false;
        }
    };
}

test "init" {
    const buffer = RingBuffer(i32, 3).init();

    try testing.expect(buffer.items.len == 3);
    try testing.expect(buffer.writeIdx == 0);
    try testing.expect(buffer.head == 0);
}

test "insert" {
    {
        // full buffer
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 1, 2, 3 }));
    }

    {
        // overriding oldest element
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 1, 2, 3 }));
        buffer.insert(0);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 2, 3 }));
        buffer.insert(1);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 1, 3 }));
        buffer.insert(2);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 0, 1, 2 }));
        buffer.insert(3);
        try testing.expect(std.mem.eql(i32, &buffer.items, &[3]i32{ 3, 1, 2 }));
    }
}

test "head" {
    {
        // head should move from pos 0 only when overriting ocurr
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        try testing.expect(buffer.head == 0);
        buffer.insert(2);
        try testing.expect(buffer.head == 0);
        buffer.insert(3);
        try testing.expect(buffer.head == 0);
    }

    {
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        buffer.insert(0);
        try testing.expect(buffer.head == 1);
        buffer.insert(1);
        try testing.expect(buffer.head == 2);
        buffer.insert(2);
        try testing.expect(buffer.head == 0);
        buffer.insert(3);
        try testing.expect(buffer.head == 1);
    }
}

test "retrieve elements" {
    {
        // with empty array should return null
        const buffer = RingBuffer(i32, 3).init();
        try testing.expect(buffer.elementAt(0) == null);
        try testing.expect(buffer.elementAt(1) == null);
        try testing.expect(buffer.elementAt(2) == null);
    }

    {
        // return null if given position is null
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(0);
        buffer.insert(1);
        try testing.expect(buffer.elementAt(2) == null);
    }

    {
        // element at position 0 should be the same as element at head position
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        try testing.expect(buffer.elementAt(0) == 1);
        buffer.insert(2);
        try testing.expect(buffer.elementAt(1) == 2);
        buffer.insert(3);
        try testing.expect(buffer.elementAt(2) == 3);
        buffer.insert(0);
        try testing.expect(buffer.elementAt(2) == 0);
    }
}
