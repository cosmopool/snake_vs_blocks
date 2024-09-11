const std = @import("std");

const Vector = @import("vector.zig").Vector;
var Snake = @import("entities.zig").Snake.new();
const Empty = @import("entities.zig").Empty;

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

pub fn checkCollisionWithBox(circle: Vector, box: Vector, boxSize: f32) bool {
    const radius: f32 = @floatFromInt(Snake.radius);

    // clamp(value, min, max) - limits value to the range min..max
    const boxLeft = box.x();
    const boxRight = boxLeft + boxSize;
    const boxTop = box.y();
    const boxBottom = box.y() + boxSize;

    // Find the closest point to the circle within the rectangle
    const closestX = std.math.clamp(circle.x(), boxLeft, boxRight);
    const closestY = std.math.clamp(circle.y(), boxTop, boxBottom);

    // Calculate the distance between the circle's center and this closest point
    const distanceX = circle.x() - closestX;
    const distanceY = circle.y() - closestY;

    if (distanceY > radius) return false;

    // If the distance is less than the circle's radius, an intersection occurs
    const distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);
    return distanceSquared < (radius * radius);
}

pub fn checkCollisionWithBoxWithDistance(circle: Vector, block: Vector, blockSize: f32) struct { isColliding: bool, isSideCollision: bool, distance: f32, closestX: f32 } {
    const radius: f32 = @floatFromInt(Snake.radius);

    // const blockLeft = if (sign >= 0) block.x() else 0;
    // const blockRight = if (sign >= 0) Screen.width else blockLeft + blockSize;
    const blockLeft = block.x();
    const blockRight = blockLeft + blockSize;
    const blockTop = block.y();
    const blockBottom = block.y() + blockSize;

    // Find the closest point to the circle within the rectangle
    // clamp(value, min, max) - limits value to the range min..max
    var closestX = std.math.clamp(circle.x(), blockLeft, blockRight);
    const closestY = std.math.clamp(circle.y(), blockTop, blockBottom);
    // if circle is inside the block
    if (circle.x() >= blockLeft and circle.x() <= blockRight) {
        const distanceToLeftSide = @abs(circle.x() - blockLeft);
        const distanceToRightSide = @abs(circle.x() - blockRight);
        if (distanceToLeftSide < distanceToRightSide) closestX = blockLeft else closestX = blockRight;
    }

    // Calculate the distance between the circle's center and this closest point
    const distanceX = circle.x() - closestX;
    const distanceY = circle.y() - closestY;
    // std.debug.print("dx: {d}, dy: {d}, cX: {d}, circleX: {d} circleY: {d}\n", .{ distanceX, distanceY, closestX, circle.x(), circle.y() });
    // std.debug.print("left: {d}, right: {d}\n", .{ blockLeft, blockRight });

    if (distanceY > radius) return .{ .isColliding = false, .isSideCollision = false, .distance = distanceX, .closestX = closestX };

    const distanceSquared: f32 = (distanceX * distanceX) + (distanceY * distanceY);

    // If the distance is less than the circle's radius, an intersection occurs
    const collision = distanceSquared < radius * radius;
    const isSideCollision = collision and ((circle.y() + radius) < blockBottom);
    return .{ .isColliding = collision, .isSideCollision = isSideCollision, .distance = distanceX, .closestX = closestX };
}

/// Delete the element at [elementIndex] by shifting values past this point.
pub fn deleteVecSize3Element(elementIndex: usize, array: []f32, len: usize) !void {
    const vecSize = 3;

    for (elementIndex..len - 1) |i| {
        const index = i * vecSize;
        if (index > len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const z = 2 + index;

        // check if this block and the next is empty
        if (array[x] == Empty and array[y] == Empty and
            array[x + vecSize] == Empty and array[y + vecSize] == Empty) break;
        std.debug.assert(array[x] != Empty and array[y] != Empty);

        array[x] = array[x + vecSize];
        array[y] = array[y + vecSize];
        array[z] = array[z + vecSize];

        // is this the last element?
        if (i < len - vecSize - 1) continue;

        array[x] = Empty;
        array[y] = Empty;
        array[z] = Empty;
    }
}

/// Check collision between circle and rectangle
/// From raylib
pub fn checkCollisionCircleRec(circle: Vector, rec: Vector, recSize: f32) bool {
    // const width = recSize;
    // const height = recSize;
    const halfSide: f32 = recSize / 2;

    const recCenterX: f32 = rec.x() + halfSide;
    const recCenterY: f32 = rec.y() + halfSide;

    const dx = @abs(circle.x() - recCenterX);
    const dy = @abs(circle.y() - recCenterY);

    if (dx > (halfSide + Snake.radius)) return false;
    if (dy > (halfSide + Snake.radius)) return false;

    if (dx <= (halfSide)) return true;
    if (dy <= (halfSide)) return true;

    const cornerDistanceSq = (dx - halfSide) * (dx - halfSide) + (dy - halfSide) * (dy - halfSide);
    // const cornerDistanceSq = std.math.pow(f32, dx - halfSide, dx - halfSide) + std.math.pow(f32, dy - halfSide, dy - halfSide);
    return (cornerDistanceSq <= (Snake.radius * Snake.radius));
}
