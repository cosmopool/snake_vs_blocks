const std = @import("std");
const math = @import("std").math;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

pub const Vector2 = struct {
    x: f32,
    y: f32,

    pub fn new(x: f32, y: f32) Vector2 {
        return Vector2{ .x = x, .y = y };
    }

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

    pub fn scale(self: *const Vector2, n: f32) Vector2 {
        const vec = @Vector(2, f32){ self.x, self.y } * @as(@Vector(2, f32), @splat(n));
        return Vector2{
            .x = vec[0],
            .y = vec[1],
        };
    }

    pub fn mul(self: *const Vector2, other: *const Vector2) Vector2 {
        const vec = @Vector(2, f32){ self.x, self.y } * @Vector(2, f32){ other.x, other.y };
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

    pub fn add(self: *const Vector2, other: Vector2) Vector2 {
        return Vector2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: *const Vector2, other: *const Vector2) Vector2 {
        return Vector2{
            .x = self.x - other.x,
            .y = self.y - other.y,
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

    pub fn dir(self: *const Vector2, other: *const Vector2) Vector2 {
        // const distance = self.distanceFrom(other);
        return Vector2{
            .x = (other.x - self.x),
            .y = (other.y - self.y),
        };
    }

    pub fn dot(self: *const Vector2, other: *const Vector2) f32 {
        const v1 = self.normalize();
        const v2 = other.normalize();
        return (v1.x * v2.x) + (v1.y + v2.y);
    }
};

/// Convert radians to degrees.
fn toDegrees(radians: anytype) @TypeOf(radians) {
    const T = @TypeOf(radians);

    if (@typeInfo(T) != .Float) {
        @compileError("Radians not implemented for " ++ @typeName(T));
    }

    return radians * (180.0 / math.pi);
}

pub const Vector = struct {
    const Vec2 = @Vector(2, f32);

    data: Vec2,

    pub fn x(self: *const Vector) f32 {
        return self.data[0];
    }

    pub fn y(self: *const Vector) f32 {
        return self.data[1];
    }

    pub fn new(vx: f32, vy: f32) Vector {
        return Vector{ .data = @Vector(2, f32){ vx, vy } };
    }

    pub fn sign(self: *const Vector) i8 {
        if (self.x() < 0) return -1;
        return 1;
    }

    /// Get direction of [x]
    pub fn direction(self: *const Vector) i8 {
        const n = self.data[0];
        if (n > 0 + 0) return 1;
        if (n < 0 - 0) return -1;
        return 0;
    }

    /// Construct new vector after multiplying each components by a given scalar
    pub fn scale(self: *const Vector, scalar: f32) Vector {
        const result = self.data * @as(Vec2, @splat(scalar));
        return .{ .data = result };
    }

    /// Substraction between two given vector.
    pub fn sub(self: *const Vector, other: Vector) Vector {
        const result = self.data - other.data;
        return .{ .data = result };
    }

    /// Addition betwen two given vector.
    pub fn add(self: *const Vector, other: Vector) Vector {
        const result = self.data + other.data;
        return .{ .data = result };
    }

    /// Component wise multiplication betwen two given vector.
    pub fn mul(self: *const Vector, other: Vector) Vector {
        const result = self.data * other.data;
        return .{ .data = result };
    }

    /// Component wise division betwen two given vector.
    pub fn div(self: *const Vector, other: Vector) Vector {
        const result = self.data / other.data;
        return .{ .data = result };
    }

    /// Return the dot product between two given vector.
    /// (x1 * x2) + (y1 * y2) + (z1 * z2) ...
    pub fn dot(self: *const Vector, other: Vector) f32 {
        return @reduce(.Add, self.data * other.data);
    }

    /// Return the length (magnitude) of given vector.
    /// √[x^2 + y^2 + z^2 ...]
    pub fn length(self: *const Vector) f32 {
        return @sqrt(self.dot(self.*));
    }

    /// Same as [lenght()]
    pub fn mag(self: *const Vector) f32 {
        return self.length();
    }

    /// Get a new vector with values normalized from 0 to 1
    pub fn normFrom(other: Vector) Vector {
        const l = other.length();
        if (l == 0) {
            return other;
        }
        const result: Vec2 = other.data / @as(Vec2, @splat(l));
        return .{ .data = result };
    }

    /// Construct new normalized vector from a given one.
    pub fn norm(self: *const Vector) Vector {
        return normFrom(self.*);
    }

    /// Return the angle (in degrees) between two vectors.
    pub fn getAngle(self: *const Vector, other: Vector) Vector {
        const dot_product = dot(self.norm(), other.norm());
        return toDegrees(math.acos(dot_product));
    }

    /// Linear interpolation between two vectors
    pub fn lerp(self: *const Vector, other: Vector, t: f32) Vector {
        const from = self.data;
        const to = other.data;

        const result = from + (to - from) * @as(Vec2, @splat(t));
        return .{ .data = result };
    }

    /// Return the distance between two points.
    /// √[(x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2 ...]
    pub fn distance(self: *const Vector, other: Vector) f32 {
        // return @sqrt(self.dot(self.sub(other)));
        return length(&self.sub(other));
    }
    ///
    /// Construct new vector after multiplying each components by a given scalar
    pub fn splat(scalar: f32) Vector {
        const result = @as(Vec2, @splat(scalar));
        return new(result[0], result[1]);
    }
};

test "divide by 2" {
    const vec = Vector{ .x = 2, .y = 2 };
    const res = vec.div(2);
    try expect(res.x() == 1);
    try expect(res.y() == 1);
}

test "divide by 4" {
    const vec = Vector{ .x = 2, .y = 2 };
    const res = vec.div(4);
    try expect(res.x() == 0.5);
    try expect(res.y() == 0.5);
}

test "multiply by 2" {
    const vec = Vector{ .x = 1, .y = 1 };
    const res = vec.mul(2);
    try expect(res.x() == 2);
    try expect(res.y() == 2);
}

test "multiply by 0" {
    const vec = Vector{ .x = 1, .y = 1 };
    const res = vec.mul(0);
    try expect(res.x() == 0);
    try expect(res.y() == 0);
}

test "multiply by negative" {
    const vec = Vector{ .x = 1, .y = 1 };
    const res = vec.mul(-1);
    try expect(res.x() == -1);
    try expect(res.y() == -1);
}

test "noralize (3, 4) should return magnitude 1" {
    const vec = Vector{ .x = 3, .y = 4 };
    try expect(vec.mag() != 1);

    const res = vec.norm();
    const mag = res.mag();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (1, 2) should return magnitude 1" {
    const vec = Vector{ .x = 1, .y = 2 };
    try expect(vec.mag() != 1);

    const res = vec.norm();
    const mag = res.mag();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (2, 2) should return magnitude 1" {
    const vec = Vector{ .x = 2, .y = 2 };
    try expect(vec.mag() != 1);

    const res = vec.norm();
    const mag = res.mag();
    try expect(mag > 0.99 and mag <= 1);
}

test "noralize (5, 5) should return magnitude 1" {
    const vec = Vector{ .x = 5, .y = 5 };
    try expect(vec.mag() != 1);

    const res = vec.norm();
    const mag = res.mag();
    try expect(mag > 0.99 and mag <= 1);
}
