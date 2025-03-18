const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

pub fn RingBuffer(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        /// Not intended to be accessed by callers directly
        items: [size]T,

        /// The index of the oldest item
        head: usize = 0,

        /// The index to write the newest item
        writeIdx: usize = 0,

        /// Boolean that tracks buffer fullness
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

            assert(self.writeIdx >= 0);
            self.head = self.writeIdx;
        }

        /// Insert a new item into the ring buffer.
        /// If the buffer is full, the oldest item is overwritten.
        pub fn insert(self: *Self, item: T) void {
            if (self.writeIdx < 0) self.writeIdx = 0;
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

        pub fn assignAt(self: *Self, index: usize, value: T) void {
            if (index > size - 1) @panic("out of bounds");

            self.items[index] = value;
        }

        pub fn pop(self: *Self) ?T {
            if (self.writeIdx < 0) return null;
            if (self.writeIdx == 0 and !self.full) return null;

            // calculate tail
            const leftWriteIdxPos: isize = @as(isize, @intCast(self.writeIdx)) - 1;
            if (self.full and leftWriteIdxPos < 0) self.full = false;
            const tail: usize = @intCast(@mod(leftWriteIdxPos, size));

            // update element
            const element = self.items[tail];
            self.items[tail] = std.mem.zeroes(T);
            self.writeIdx = tail;
            return element;
        }

        /// Manually set the tail of this ring buffer
        /// This function always shrink the buffer.
        /// If targetIndex is < self.head, the tail will be set to self.head.
        pub fn setTail(self: *Self, targetIndex: usize) void {
            if (targetIndex >= size) return;
            if (targetIndex == self.writeIdx - 1) return;

            const index = if (targetIndex < self.head) self.head else targetIndex;
            if (self.full == true and index > self.writeIdx) self.full = false;
            self.writeIdx = (index + 1) % size;
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

    try testing.expectEqual(3, buffer.items.len);
    try testing.expectEqual(0, buffer.writeIdx);
    try testing.expectEqual(0, buffer.head);
}

test "insert" {
    {
        // full buffer
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        try testing.expectEqualSlices(i32, &[3]i32{ 1, 2, 3 }, &buffer.items);
    }

    {
        // overriding oldest element
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        try testing.expectEqualSlices(i32, &[3]i32{ 1, 2, 3 }, &buffer.items);
        buffer.insert(0);
        try testing.expectEqualSlices(i32, &[3]i32{ 0, 2, 3 }, &buffer.items);
        buffer.insert(1);
        try testing.expectEqualSlices(i32, &[3]i32{ 0, 1, 3 }, &buffer.items);
        buffer.insert(2);
        try testing.expectEqualSlices(i32, &[3]i32{ 0, 1, 2 }, &buffer.items);
        buffer.insert(3);
        try testing.expectEqualSlices(i32, &[3]i32{ 3, 1, 2 }, &buffer.items);
    }
}

test "pop" {
    {
        // full buffer
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        try testing.expectEqual(1, buffer.writeIdx);
        buffer.insert(2);
        try testing.expectEqual(2, buffer.writeIdx);
        buffer.insert(3);
        try testing.expectEqual(0, buffer.writeIdx);

        try testing.expectEqualSlices(i32, &[3]i32{ 1, 2, 3 }, &buffer.items);

        // checking poping values
        try testing.expectEqual(3, buffer.pop());
        try testing.expectEqual(2, buffer.writeIdx);
        try testing.expectEqual(2, buffer.pop());
        try testing.expectEqual(1, buffer.writeIdx);
        try testing.expectEqual(1, buffer.pop());
        try testing.expectEqual(0, buffer.writeIdx);

        // poping beyond buffer size
        try testing.expectEqual(null, buffer.pop());
        try testing.expectEqual(0, buffer.writeIdx);
        try testing.expectEqual(0, buffer.head);

        const s = std.math.maxInt(i32);
        try testing.expectEqualSlices(i32, &[3]i32{ s, s, s }, &buffer.items);
        try testing.expectEqual(0, buffer.writeIdx);
        try testing.expectEqual(0, buffer.head);
    }
}

test "head" {
    {
        // head should move from pos 0 only when overriting ocurr
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        try testing.expectEqual(0, buffer.head);
        buffer.insert(2);
        try testing.expectEqual(0, buffer.head);
        buffer.insert(3);
        try testing.expectEqual(0, buffer.head);
    }

    {
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        buffer.insert(0);
        try testing.expectEqual(1, buffer.head);
        buffer.insert(1);
        try testing.expectEqual(2, buffer.head);
        buffer.insert(2);
        try testing.expectEqual(0, buffer.head);
        buffer.insert(3);
        try testing.expectEqual(1, buffer.head);
    }
}

test "retrieve elements" {
    {
        // with empty array should return null
        const buffer = RingBuffer(i32, 3).init();
        try testing.expectEqual(null, buffer.elementAt(0));
        try testing.expectEqual(null, buffer.elementAt(1));
        try testing.expectEqual(null, buffer.elementAt(2));
    }

    {
        // return null if given position is null
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(0);
        buffer.insert(1);
        try testing.expectEqual(null, buffer.elementAt(2));
    }

    {
        // element at position 0 should be the same as element at head position
        var buffer = RingBuffer(i32, 3).init();
        buffer.insert(1);
        try testing.expectEqual(1, buffer.elementAt(0));
        buffer.insert(2);
        try testing.expectEqual(2, buffer.elementAt(1));
        buffer.insert(3);
        try testing.expectEqual(3, buffer.elementAt(2));
        buffer.insert(0);
        try testing.expectEqual(0, buffer.elementAt(2));
    }
}

test "setTail" {
    {
        // not full buffer
        var buffer = RingBuffer(i32, 7).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        buffer.insert(4);
        buffer.insert(5);
        buffer.insert(6);
        try testing.expectEqual(6, buffer.writeIdx);
        try testing.expectEqual(false, buffer.full);
        buffer.setTail(3);
        try testing.expectEqual(4, buffer.writeIdx);
        try testing.expectEqual(false, buffer.full);
    }

    {
        // full buffer
        var buffer = RingBuffer(i32, 7).init();
        buffer.insert(1);
        buffer.insert(2);
        buffer.insert(3);
        buffer.insert(4);
        buffer.insert(5);
        buffer.insert(6);
        buffer.insert(7);
        buffer.insert(8);
        buffer.insert(9);
        try testing.expectEqualSlices(i32, &[_]i32{ 8, 9, 3, 4, 5, 6, 7 }, &buffer.items);
        try testing.expectEqual(2, buffer.writeIdx);
        try testing.expectEqual(true, buffer.full);
        try testing.expectEqual(2, buffer.head);
        // should do nothing as tail is always writeIdx - 1
        buffer.setTail(1);
        try testing.expectEqual(2, buffer.writeIdx);
        try testing.expectEqual(true, buffer.full);
        try testing.expectEqual(2, buffer.head);
        // should update writeIdx and full
        buffer.setTail(5);
        try testing.expectEqual(6, buffer.writeIdx);
        try testing.expectEqual(false, buffer.full);
        try testing.expectEqual(2, buffer.head);
        // tail should never be less then head
        buffer.setTail(1);
        try testing.expectEqual(3, buffer.writeIdx);
        try testing.expectEqual(false, buffer.full);
        try testing.expectEqual(2, buffer.head);
    }
}

test "reset" {
    var buffer = RingBuffer(i32, 3).init();
    buffer.insert(1);
    buffer.insert(2);
    buffer.insert(3);
    buffer.insert(4);
    try testing.expectEqualSlices(i32, &[3]i32{ 4, 2, 3 }, &buffer.items);
    try testing.expectEqual(1, buffer.writeIdx);
    try testing.expectEqual(1, buffer.head);
    try testing.expectEqual(true, buffer.full);

    // reset restore default values
    buffer.reset();
    try testing.expectEqualSlices(i32, &[3]i32{ -1431655766, -1431655766, -1431655766 }, &buffer.items);
    try testing.expectEqual(0, buffer.writeIdx);
    try testing.expectEqual(0, buffer.head);
    try testing.expectEqual(false, buffer.full);

    // insert after reset does not break
    buffer.reset();
    buffer.insert(1);

    // pop after reset does not break
    buffer.reset();
    try testing.expectEqual(null, buffer.pop());
}
