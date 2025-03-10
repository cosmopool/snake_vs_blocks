const std = @import("std");
const assert = std.debug.assert;
const rl = @import("raylib");

const Utils = @import("helper.zig");
const Board = @import("board.zig");
const Constants = @import("constants.zig");
const Vector = @import("vector.zig").Vector;
const GameState = @import("game_state.zig").GameState;

//--------------------------------------------------------------------------------------
// constants

const snakeRadius: i8 = 10;
const radiusSquared: f32 = snakeRadius * snakeRadius;
const diameter: f32 = snakeRadius * 2;
const minDiameter: f32 = diameter - tolerance;
const maxDiameter: f32 = diameter + tolerance;
const step: f32 = 0.01;
const tolerance: f32 = 0.025;
const mousePathSize = 800;
const mousePathVecSize = 2;
/// [Path.positions] length
pub const pathLen: usize = 1000;
/// The number of elements in the vectorized data array [Path.positions].
/// Represents the total count of elements stored in a contiguous memory block.
/// Used for iterating over and processing the data efficiently.
pub const pathVecSize: usize = 2;
/// Minimum space between two positions in [Path.positions]
pub const pathResolution: f32 = 1;
/// How much the cursor will increment when searching for a valid place
/// for a new circle.
pub const pathStep: f32 = 0.01;

// end constants
//--------------------------------------------------------------------------------------

pub fn init(state: *GameState) !void {
    // populate Path.pathPositions array
    state.pathPositions.insert(Constants.screenCenterX);
    state.pathPositions.insert(Constants.screenCenterY);
    for (pathLen..1) |i| {
        const index = i * pathVecSize;
        if (index >= pathLen) break;
        const x = 0 + index;
        const y = 1 + index;

        if ((@as(f32, @floatFromInt(i)) * diameter) + (1.5 * @as(f32, @floatFromInt(Constants.screenCenterY))) < Constants.screenHeight) {
            state.pathPositions.assignAt(x, Constants.screenCenterX);
            state.pathPositions.assignAt(y, @as(f32, @floatFromInt(i)) * diameter + Constants.screenCenterY);
        } else {
            _ = state.pathPositions.pop();
            _ = state.pathPositions.pop();
        }
    }
}

pub fn update(deltaTime: f32, state: *GameState) !void {
    try updateSnakePosition(deltaTime, state);
    updateSnakePathPosition(deltaTime, state);
}

fn updateSnakePosition(deltaTime: f32, state: *GameState) !void {
    // current head position
    const lastPosition = Vector.new(state.pathPositions[0], state.pathPositions[1]);

    // limit mouse position to window boundaries
    const radius: f32 = @floatFromInt(snakeRadius);
    const screenWidthLimit: f32 = Constants.screenWidth - radius;

    // get mouse X position
    const mouseX = std.math.clamp(rl.getMousePosition().x, radius, screenWidthLimit);
    assert(mouseX >= 0 and mouseX <= Constants.screenWidth);

    // calculate new position
    var newPosition = Vector.new(
        std.math.lerp(lastPosition.x(), mouseX, deltaTime * 10),
        Constants.screenCenterY,
    );
    assert(newPosition.x() >= 0 and newPosition.x() <= Constants.screenWidth);

    // check if is coliding
    var col: Utils.Collision = undefined;
    var blockIndex: usize = 0;
    var collisionBlock: Vector = undefined;
    var newPositionCrossesBlock: bool = false;
    for (0..Board.len) |i| {
        blockIndex = i;
        const index = i * Board.vecSize;
        if (index >= Board.len - Board.vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        collisionBlock = Vector.new(state.boardBlocks.elementAt(x), state.boardBlocks.elementAt(y));
        if (collisionBlock.x() == Constants.empty and collisionBlock.y() == Constants.empty) break;

        col = Utils.checkCollisionWithBoxWithDistance(newPosition, collisionBlock, snakeRadius);
        if (col.isColliding) break;

        newPositionCrossesBlock = Utils.checkIntersectionWithBlockSides(lastPosition, newPosition, collisionBlock);
        if (newPositionCrossesBlock) break;
    }

    // lock snake position at closest block side and prevent to get inside the block
    if (col.isSideCollision and @abs(col.distance) < radius) {
        if (col.closestX > collisionBlock.x() + Constants.screenCellSize / 2) {
            newPosition.data[0] = collisionBlock.x() + Constants.screenCellSize + radius;
        } else {
            newPosition.data[0] = collisionBlock.x() - radius;
        }
    } else if (newPositionCrossesBlock) {
        // prevent snake to teleport to other side of the block
        newPosition = lastPosition;
    }

    if (col.isColliding and !col.isSideCollision) {
        state.boardSpeed = 0;

        const points = 2 + (blockIndex * Board.vecSize);
        if (state.boardBlocks[points] > 0) {
            state.snakeSize -= 1;
            state.boardBlocks[points] -= 1;
        }
    } else {
        state.boardSpeed = Board.fullSpeed;
    }

    // create a new node in Path if newPosition is in a valid distance from
    // previous node position in Path
    const prevPathNode = Vector.new(state.pathPositions.elementAt(1), state.pathPositions.elementAt(2));
    const distanceToLastPosition = newPosition.distance(prevPathNode);
    if (distanceToLastPosition >= pathResolution) {
        addPositionInPath(newPosition, state);
    }

    // update snake head position
    state.pathPositions.assignAt(0, newPosition.x());
}

/// Moves the snake's path downward by the current [Board.boardSpeed].
///
/// Increments the y-coordinate of each position in [Path.pathPositions]
/// by [Board.boardSpeed].
///
/// The first position in Path represents the snake's head and is managed by
/// the [updateSnakePosition] function.
fn updateSnakePathPosition(deltaTime: f32, state: *GameState) void {
    for (0..pathLen) |i| {
        if (i == 0) continue;
        const index = i * pathVecSize;
        if (index > pathLen) break;
        const x = 0 + index;
        const y = 1 + index;

        if (state.pathPositions.elementAt(x) == Constants.empty and state.pathPositions.elementAt(y) == Constants.empty) break;
        assert(state.pathPositions.elementAt(x) != Constants.empty and state.pathPositions.elementAt(y) != Constants.empty);

        // update checkpoint position
        const newPositionY = state.pathPositions.elementAt(y) + (state.boardSpeed * deltaTime);
        if (newPositionY > Constants.screenHeight + 100) {
            state.pathPositions.pop();
            state.pathPositions.pop();
        } else {
            state.pathPositions.assignAt(y, newPositionY);
        }
    }
}

/// Add the given [position] as the first node in [Path.pathPositions].
///
/// Start by shifting all positions to the right (discard the last if not empty)
/// and finishes adding [position] "x" and "y" at index "0" and "1".
fn addPositionInPath(position: Vector, state: *GameState) void {
    var i: usize = pathLen / pathVecSize;
    while (i > 1) : (i -= pathVecSize) {
        if (i >= pathLen / pathVecSize) continue;
        const x = 0 + i;
        const y = 1 + i;

        if (state.pathPositions[x] == Constants.empty and state.pathPositions[y] == Constants.empty) continue;
        assert(state.pathPositions[x] != Constants.empty and state.pathPositions[y] != Constants.empty);

        // shift values to the right
        state.pathPositions[x + 2] = state.pathPositions[x];
        state.pathPositions[y + 2] = state.pathPositions[y];
    }

    // add new position values
    state.pathPositions[2] = position.x();
    state.pathPositions[3] = position.y();
}

fn drawBodyNodeAt(x: f32, y: f32) void {
    rl.drawCircle(@intFromFloat(x), @intFromFloat(y), @floatFromInt(snakeRadius), .red);
}

fn drawLineFrom(start: Vector, end: Vector) void {
    return rl.drawLine(
        @intFromFloat(start.x()),
        @intFromFloat(start.y()),
        @intFromFloat(end.x()),
        @intFromFloat(end.y()),
        .blue,
    );
}

pub fn draw(state: *GameState) !void {
    var pointsText: [20]u8 = undefined;
    const formattedText = try std.fmt.bufPrint(&pointsText, "{d}", .{state.snakeSize});
    pointsText[formattedText.len] = 0;

    rl.drawText(
        pointsText[0..formattedText.len :0],
        @intFromFloat(state.pathPositions[0] + 15),
        @intFromFloat(state.pathPositions[1] - 15),
        10,
        .white,
    );

    // draw head
    drawBodyNodeAt(state.pathPositions[0], state.pathPositions[1]);

    // draw circles between path nodes
    var lastCircle = Vector.new(state.pathPositions[0], state.pathPositions[1]);
    var remaningCircles: i16 = state.snakeSize;
    for (1..pathLen) |i| {
        const index = i * pathVecSize;
        if (index >= pathLen / pathVecSize) break;
        const x = 0 + index;
        const y = 1 + index;

        // the path beyond this point is all empty, no need to check
        if (state.pathPositions[x] == Constants.empty and state.pathPositions[y] == Constants.empty) break;
        assert(state.pathPositions[x] != Constants.empty and state.pathPositions[y] != Constants.empty);

        const end = Vector.new(state.pathPositions[x], state.pathPositions[y]);
        const start = Vector.new(state.pathPositions[x - pathVecSize], state.pathPositions[y - pathVecSize]);

        if (state.showPath) drawLineFrom(start, end);
        if (!state.showBody) continue;
        if (remaningCircles <= 0) continue;

        assert(start.distance(lastCircle) <= minDiameter);

        var cursor = start;
        var circleIdx = state.snakeSize - remaningCircles;
        var t: f32 = 0;
        // add as many circles that fit in this line segment
        while (end.distance(lastCircle) >= minDiameter and remaningCircles > 0) {
            // using the line equation = (x, y) = (x1, y1) + t * ((x2, y2) - (x1, y1))
            // to find a valid point for a new circle incrementing "t" by Path.step
            while (t <= 1) : (t += pathStep) {
                const distance = cursor.distance(lastCircle);
                if (distance >= minDiameter and distance <= maxDiameter) break;
                if (distance > maxDiameter) break;

                cursor = Vector.new(
                    start.x() + t * (end.x() - start.x()),
                    start.y() + t * (end.y() - start.y()),
                );
            }

            if (lastCircle.x() == cursor.x() and lastCircle.y() == cursor.y()) break;
            assert(lastCircle.x() != cursor.x() or lastCircle.y() != cursor.y());

            drawBodyNodeAt(cursor.x(), cursor.y());
            lastCircle = cursor;
            remaningCircles -= 1;
            circleIdx = state.snakeSize - remaningCircles;
        }
    }
}
