const std = @import("std");
const rl = @import("raylib");

const Vector = @import("vector.zig").Vector;
const Constants = @import("constants.zig");
const Snake = @import("snake.zig");

pub const Collision = struct {
    isColliding: bool,
    isSideCollision: bool,
    distance: f32,
    closestX: f32,
};

pub fn limitVel(vel: f32, limit: f32) f32 {
    if (vel < 0) {
        return if (vel < -limit) -limit else vel;
    } else {
        return if (vel > limit) limit else vel;
    }
}

pub fn limitVelocity(dx: f32, dt: f32, limit: f32) f32 {
    if (dt == 0 or dx == 0) return 0;
    const vel: f32 = dx / dt;
    if (vel < 0) {
        return if (vel < -limit) -limit else vel;
    } else {
        return if (vel > limit) limit else vel;
    }
}

pub fn cosineInterpolation(y1: f32, y2: f32, mu: f32) f32 {
    var mu2: f32 = 0;
    mu2 = (1 - std.math.cos(mu * std.math.pi)) / 2;
    return (y1 * (1 - mu2) + y2 * mu2);
}

pub fn abs(num: anytype) @TypeOf(num) {
    if (std.math.sign(num) == -1) return num * -1;
    return num;
}

pub fn normalize(num: f32, minSet: f32, maxSet: f32, min: f32, max: f32) f32 {
    // fn normalize(num: anytype, min: anytype, max: anytype, n: anytype) @TypeOf(num) {
    // return ((num - minSet) / (maxSet - minSet)) * n;
    return ((num - minSet) / maxSet - minSet) * (max - min) + min;
}

pub fn checkCollision(x1: f32, y1: f32, x2: f32, y2: f32, size: f32) bool {
    const dx: f32 = x2 - x1;
    const dy: f32 = y2 - y1;
    const distance = std.math.sqrt(dx * dx + dy * dy);
    if (distance <= (size + size)) return true;
    return false;
}

/// Delete the element at [elementIndex] by shifting values past this point.
pub fn deleteVecSize3Element(elementIndex: usize, array: []f32) !void {
    const vecSize = 3;

    for (elementIndex..array.len - 1) |i| {
        const index = i * vecSize;
        if (index > array.len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const z = 2 + index;

        // check if this block and the next is empty
        if (array[x] == Constants.empty and array[y] == Constants.empty and
            array[x + vecSize] == Constants.empty and array[y + vecSize] == Constants.empty) break;
        std.debug.assert(array[x] != Constants.empty and array[y] != Constants.empty);

        array[x] = array[x + vecSize];
        array[y] = array[y + vecSize];
        array[z] = array[z + vecSize];

        // is this the last element?
        if (i < array.len - vecSize - 1) continue;

        array[x] = Constants.empty;
        array[y] = Constants.empty;
        array[z] = Constants.empty;
    }
}

/// Delete the element at [elementIndex] by shifting values past this point.
pub fn deleteVecSize4Element(elementIndex: usize, array: []f32, len: usize) !void {
    const vecSize = 4;

    for (elementIndex..len - 1) |i| {
        const index = i * vecSize;
        if (index > len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const z = 2 + index;
        const w = 3 + index;

        // check if this block and the next is empty
        if (array[x] == Constants.empty and array[y] == Constants.empty and
            array[x + vecSize] == Constants.empty and array[y + vecSize] == Constants.empty) break;
        std.debug.assert(array[x] != Constants.empty and array[y] != Constants.empty);

        array[x] = array[x + vecSize];
        array[y] = array[y + vecSize];
        array[z] = array[z + vecSize];
        array[w] = array[w + vecSize];

        // is this the last element?
        if (i < len - vecSize - 1) continue;

        array[x] = Constants.empty;
        array[y] = Constants.empty;
        array[z] = Constants.empty;
        array[w] = Constants.empty;
    }
}

pub fn checkCollisionWithBoxWithDistance(circle: Vector, block: Vector) Collision {
    const radius: f32 = Snake.radius;

    const blockLeft = block.x();
    const blockRight = blockLeft + Constants.screenCellSize;
    const blockTop = block.y();
    const blockBottom = blockTop + Constants.screenCellSize;

    // Find the closest point to the circle within the rectangle
    var closestX = std.math.clamp(circle.x(), blockLeft, blockRight);
    const closestY = std.math.clamp(circle.y(), blockTop, blockBottom);

    // Calculate the distance between the circle's center and this closest point
    var distanceX = circle.x() - closestX;
    const distanceY = circle.y() - closestY;
    if (distanceY > radius) return Collision{ .isColliding = false, .isSideCollision = false, .distance = distanceX, .closestX = closestX };

    // check if circle is inside the block
    const circleRight = circle.x() + radius;
    const circleLeft = circle.x() - radius;
    const circleTop = circle.y() + radius;
    if ((circleRight > blockLeft or circleLeft < blockRight) and circleTop < blockBottom) {
        const distanceToLeftSide = @abs(circle.x() - blockLeft);
        const distanceToRightSide = @abs(circle.x() - blockRight);
        if (distanceToLeftSide < distanceToRightSide) closestX = blockLeft else closestX = blockRight;
        distanceX = circle.x() - closestX;
    }

    // If the distance is less than the circle's radius, an intersection occurs
    const distanceSquared: f32 = (distanceX * distanceX) + (distanceY * distanceY);
    const collision = distanceSquared < radius * radius;
    const isSideCollision = collision and ((circle.y() + radius) < blockBottom);
    return Collision{ .isColliding = collision, .isSideCollision = isSideCollision, .distance = distanceX, .closestX = closestX };
}

pub fn checkIntersectionWithBlockSides(aStart: Vector, aEnd: Vector, block: Vector) bool {
    const topLeft = Vector.new(block.x(), block.y());
    const bottomLeft = Vector.new(block.x(), block.y() + Constants.screenCellSize);
    const topRight = Vector.new(block.x() + Constants.screenCellSize, block.y());
    const bottomRight = Vector.new(block.x() + Constants.screenCellSize, block.y() + Constants.screenCellSize);

    const leftSideIntersection = linesIntersect(aStart, aEnd, topLeft, bottomLeft);
    if (leftSideIntersection) return true;

    const rightSideIntersection = linesIntersect(aStart, aEnd, topRight, bottomRight);
    if (rightSideIntersection) return true;

    return false;
}

fn linesIntersect(a: Vector, b: Vector, c: Vector, d: Vector) bool {
    const line = (d.y() - c.y()) * (b.x() - a.x()) - (d.x() - c.x()) * (b.y() - a.y());

    // Lines are parallel
    if (line == 0) return false;

    const ua = ((d.x() - c.x()) * (a.y() - c.y()) - (d.y() - c.y()) * (a.x() - c.x())) / line;
    const ub = ((b.x() - a.x()) * (a.y() - c.y()) - (b.y() - a.y()) * (a.x() - c.x())) / line;

    const result = ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1;
    return result;
}

pub fn drawAtCenter(text: [:0]const u8, size: ?usize, color: ?rl.Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.measureText(text, @intCast(fontSize));
    const x = @divTrunc(Constants.screenWidth, 2) - @divTrunc(textSize, 2);
    rl.drawText(text, @intCast(x), Constants.screenCenterY, @intCast(fontSize), color orelse .white);
}
