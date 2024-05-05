const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

pub const Vector2 = struct {
    x: f32,
    y: f32,

    pub fn sign(self: *const Vector2) i8 {
        if (self.x < 0) return -1;
        return 1;
    }

    /// Get direction of [x]
    pub fn direction(self: *const Vector2) i8 {
        if (self.x > 0) return 1;
        if (self.x < 0) return -1;
        return 0;
    }

    pub fn magnitude(self: *const Vector2) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }

    pub fn multiply(self: *const Vector2, n: f32) Vector2 {
        const vec = @Vector(2, f32){ self.x, self.y } * @as(@Vector(2, f32), @splat(n));
        return Vector2{
            .x = vec[0],
            .y = vec[1],
        };
    }

    pub fn divide(self: *const Vector2, n: f32) Vector2 {
        const vec = @Vector(2, f32){ self.x, self.y } * @as(@Vector(2, f32), @splat(1 / n));
        return Vector2{
            .x = vec[0],
            .y = vec[1],
        };
    }

    pub fn sum(self: *const Vector2, other: *const Vector2) Vector2 {
        return Vector2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn normalize(self: *const Vector2) Vector2 {
        return self.divide(self.magnitude());
    }

    pub fn distanceFrom(self: *const Vector2, other: *const Vector2) f32 {
        const x: f32 = other.x - self.x;
        const y: f32 = other.y - self.y;
        return std.math.sqrt(x * x + y * y);
    }

    pub fn directionVec(self: *const Vector2, other: *const Vector2) Vector2 {
        // const distance = self.distanceFrom(other);
        return Vector2{
            .x = (other.x - self.x),
            .y = (other.y - self.y),
        };
    }
};

test "divide by 2" {
    const vec = Vector2{ .x = 2, .y = 2 };
    const res = vec.divide(2);
    try expect(res.x == 1);
    try expect(res.y == 1);
}

test "divide by 4" {
    const vec = Vector2{ .x = 2, .y = 2 };
    const res = vec.divide(4);
    try expect(res.x == 0.5);
    try expect(res.y == 0.5);
}

test "multiply by 2" {
    const vec = Vector2{ .x = 1, .y = 1 };
    const res = vec.multiply(2);
    try expect(res.x == 2);
    try expect(res.y == 2);
}

test "multiply by 0" {
    const vec = Vector2{ .x = 1, .y = 1 };
    const res = vec.multiply(0);
    try expect(res.x == 0);
    try expect(res.y == 0);
}

test "multiply by negative" {
    const vec = Vector2{ .x = 1, .y = 1 };
    const res = vec.multiply(-1);
    try expect(res.x == -1);
    try expect(res.y == -1);
}

test "noralize (3, 4) should return magnitude 1" {
    const vec = Vector2{ .x = 3, .y = 4 };
    try expect(vec.magnitude() != 1);

    const res = vec.normalize();
    const mag = res.magnitude();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (1, 2) should return magnitude 1" {
    const vec = Vector2{ .x = 1, .y = 2 };
    try expect(vec.magnitude() != 1);

    const res = vec.normalize();
    const mag = res.magnitude();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (2, 2) should return magnitude 1" {
    const vec = Vector2{ .x = 2, .y = 2 };
    try expect(vec.magnitude() != 1);

    const res = vec.normalize();
    const mag = res.magnitude();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (5, 5) should return magnitude 1" {
    const vec = Vector2{ .x = 5, .y = 5 };
    try expect(vec.magnitude() != 1);

    const res = vec.normalize();
    const mag = res.magnitude();
    try expect(mag > 0.99 and mag <= 1);
}
