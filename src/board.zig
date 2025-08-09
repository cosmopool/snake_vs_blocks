const std = @import("std");
const assert = std.debug.assert;
const rl = @import("raylib");

const Utils = @import("helper.zig");
const GameState = @import("game_state.zig").GameState;
const Constants = @import("constants.zig");

//--------------------------------------------------------------------------------------
// constants

pub const fullSpeed: f32 = 180;
/// [Board.cells] length
pub const len: usize = 1000;
/// The number of elements in the vectorized data array [Board.cells].
///
/// Represents the total count of elements stored in a contiguous memory block.
/// Used for iterating over and processing the data efficiently.
pub const vecSize: usize = 3;

var spawnRule = [_]u8{ 1, 1, 1, 1, 2, 2, 2, 5, 5, 5 };

// end constants
//--------------------------------------------------------------------------------------

pub fn init(state: *GameState) !void {
    state.random.shuffleWithIndex(u8, &spawnRule, usize);

    for (0..len) |i| {
        const index = i * vecSize;
        if (index >= len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const points = 2 + index;

        state.boardBlocks[x] = Constants.empty;
        state.boardBlocks[y] = Constants.empty;
        state.boardBlocks[points] = Constants.empty;
    }

    state.boardBlocks[0] = 2 * Constants.screenCellSize;
    state.boardBlocks[1] = 0;
    state.boardBlocks[2] = 5;

    state.boardBlocks[3] = 1 * Constants.screenCellSize;
    state.boardBlocks[4] = 0;
    state.boardBlocks[5] = 3;

    state.boardBlocks[6] = 2 * Constants.screenCellSize;
    state.boardBlocks[7] = 0;
    state.boardBlocks[8] = 4;

    state.boardBlocks[9] = 3 * Constants.screenCellSize;
    state.boardBlocks[10] = 0;
    state.boardBlocks[11] = 6;
}

pub fn update(deltaTime: f32, state: *GameState) !void {
    state.distanceFromLastBlock += @intFromFloat(state.boardSpeed);
    try spawnBlocks(&state.random, state);
    try updateBlocksPosition(deltaTime, state);
}

fn updateBlocksPosition(deltaTime: f32, state: *GameState) !void {
    for (0..len) |i| {
        const index = i * vecSize;
        if (index > len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const points = 2 + index;

        if (state.boardBlocks[x] == Constants.empty and state.boardBlocks[y] == Constants.empty) break;
        assert(state.boardBlocks[x] != Constants.empty and state.boardBlocks[y] != Constants.empty);

        // update element position
        const newPositionY = state.boardBlocks[y] + (state.boardSpeed * deltaTime);
        // remove element if not visible anymore or has 0 points
        if (newPositionY > Constants.screenHeight + 100 or state.boardBlocks[points] <= 0) {
            try Utils.deleteVecSize3Element(i, &state.boardBlocks);
            continue;
        }

        state.boardBlocks[y] = newPositionY;
    }
}

fn spawnBlocks(rand: *const std.Random, state: *GameState) !void {
    const distance: u16 = if (rand.boolean()) 10000 else 20000;

    if (state.distanceFromLastBlock < distance) return;
    state.distanceFromLastBlock = 0;

    const quantityIndex: u8 = rand.intRangeAtMost(u8, 0, spawnRule.len - 1);
    const quantityToSpawn: u8 = spawnRule[quantityIndex];

    if (quantityToSpawn == 0) return;

    // find empty idx in blocks array
    // check if this index has [quantity] positions Constants.empty to place new blocks
    var haveTheSpaceNecessary: bool = true;
    var startPlacingAtIdx: usize = 0;
    for (startPlacingAtIdx..len) |i| {
        const index = i * vecSize;
        assert(index < state.boardBlocks.len);
        if (index >= len / vecSize) break;

        if (i - startPlacingAtIdx >= quantityToSpawn) {
            haveTheSpaceNecessary = true;
            break;
        }

        if (state.boardBlocks[0 + index] != Constants.empty and state.boardBlocks[1 + index] != Constants.empty) {
            startPlacingAtIdx = i + 1;
        }
    }

    if (!haveTheSpaceNecessary) return;

    var quantityRemaning = quantityToSpawn;
    for (startPlacingAtIdx..startPlacingAtIdx + quantityToSpawn) |h| {
        assert(quantityRemaning >= 0);
        quantityRemaning -= 1;
        const index: usize = h * vecSize;
        assert(index < state.boardBlocks.len);
        if (index >= len / vecSize) break;

        const x: usize = 0 + index;
        const y: usize = 1 + index;
        const points: usize = 2 + index;

        var position: f32 = @floatFromInt(quantityRemaning);
        if (quantityToSpawn == 1) position = @floatFromInt(rand.intRangeAtMost(u8, 1, 5));
        if (quantityToSpawn == 2) {
            if (quantityRemaning == 1) position = @floatFromInt(rand.intRangeAtMost(u8, 0, 2));
            if (quantityRemaning == 0) position = @floatFromInt(rand.intRangeAtMost(u8, 3, 4));
        }

        state.boardBlocks[x] = position * Constants.screenCellSize;
        state.boardBlocks[y] = -Constants.screenCellSize;
        state.boardBlocks[points] = @floatFromInt(rand.intRangeAtMost(u8, 1, 50));
    }
}

pub fn draw(state: *GameState) !void {
    for (0..len) |i| {
        const index = i * vecSize;
        if (index >= len / vecSize) break;

        const x = state.boardBlocks[0 + index];
        const y = state.boardBlocks[1 + index];
        const points = state.boardBlocks[2 + index];

        // the path beyond this point is all empty, no need to check
        if (x == Constants.empty and y == Constants.empty and points == Constants.empty) break;
        assert(x != Constants.empty and y != Constants.empty and points != Constants.empty);

        const rec: rl.Rectangle = .{
            .x = x,
            .y = y,
            .width = Constants.screenCellSize,
            .height = Constants.screenCellSize,
        };
        rl.drawRectangleRounded(rec, 0.2, 0, generateColorForGivingBlockPoint(points));

        var pointsText: [20]u8 = undefined;
        const formattedText = try std.fmt.bufPrint(&pointsText, "{d:0.0}", .{points});
        // Add null terminator explicitly
        pointsText[formattedText.len] = 0;

        const fontSize = 20;
        const textSize = rl.measureText(pointsText[0..formattedText.len :0], @intCast(fontSize));
        const textX = x + (Constants.screenCellSize / 2) - @as(f32, @floatFromInt(@divTrunc(textSize, 2)));
        const textY = y + (Constants.screenCellSize / 2) - (fontSize / 2);
        rl.drawText(pointsText[0..formattedText.len :0], @intFromFloat(textX), @intFromFloat(textY), fontSize, .white);
    }
}

fn generateColorForGivingBlockPoint(n: f32) rl.Color {
    assert(n >= 0 and n <= 50);
    const clampedValue = @max(1, @min(50, n));
    const t: f32 = (clampedValue - 1) / (50 - 1);

    var minR: f32 = 98;
    var minG: f32 = 224;
    var minB: f32 = 225;
    var maxR: f32 = 0;
    var maxG: f32 = 0;
    var maxB: f32 = 0;

    if (n >= 0 and n <= 10) {
        maxR = 71;
        maxG = 255;
        maxB = 151;
    } else if (n <= 20) {
        minR = 71;
        minG = 255;
        minB = 151;

        maxR = 8;
        maxG = 233;
        maxB = 0;
    } else if (n <= 30) {
        minR = 8;
        minG = 233;
        minB = 0;

        maxR = 194;
        maxG = 233;
        maxB = 0;
    } else if (n <= 40) {
        minR = 194;
        minG = 233;
        minB = 0;

        maxR = 233;
        maxG = 155;
        maxB = 0;
    } else if (n <= 50) {
        minR = 233;
        minG = 155;
        minB = 0;

        maxR = 233;
        maxG = 23;
        maxB = 0;
    }

    const r: u8 = @intFromFloat(std.math.lerp(minR, maxR, t));
    const g: u8 = @intFromFloat(std.math.lerp(minG, maxG, t));
    const b: u8 = @intFromFloat(std.math.lerp(minB, maxB, t));

    return rl.Color{ .r = r, .g = g, .b = b, .a = 255 };
}
