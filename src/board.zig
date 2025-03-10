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

// end constants
//--------------------------------------------------------------------------------------

pub fn init(state: *GameState) !void {
    // for (0..len) |i| {
    //     const index = i * vecSize;
    //     if (index >= len - vecSize) break;
    //     const x = 0 + index;
    //     const y = 1 + index;
    //     const points = 2 + index;
    //
    //     state.boardBlocks[x] = Constants.empty;
    //     state.boardBlocks[y] = Constants.empty;
    //     state.boardBlocks[points] = Constants.empty;
    // }

    state.boardBlocks.insert(2 * Constants.screenCellSize);
    state.boardBlocks.insert(0);
    state.boardBlocks.insert(5);

    state.boardBlocks.insert(1 * Constants.screenCellSize);
    state.boardBlocks.insert(0);
    state.boardBlocks.insert(3);

    state.boardBlocks.insert(2 * Constants.screenCellSize);
    state.boardBlocks.insert(0);
    state.boardBlocks.insert(4);

    state.boardBlocks.insert(3 * Constants.screenCellSize);
    state.boardBlocks.insert(0);
    state.boardBlocks.insert(6);
}

fn deleteBlock(self: *GameState, blockIndex: usize) !void {
    return try Utils.deleteVecSize3Element(blockIndex, &self.boardBlocks, len);
}

pub fn update(deltaTime: f32, state: *GameState) !void {
    for (0..len) |i| {
        const index = i * vecSize;
        if (index > len - vecSize) break;
        const x = 0 + index;
        const y = 1 + index;
        const points = 2 + index;

        if (state.boardBlocks.elementAt(x) == null and state.boardBlocks.elementAt(y) == null) break;
        assert(state.boardBlocks.elementAt(x) != null and state.boardBlocks.elementAt(y) != null);

        // update element position
        const newPositionY = state.boardBlocks.elementAt(y) + (state.boardSpeed * deltaTime);
        // remove element if not visible anymore or has 0 points
        if (newPositionY > Constants.screenHeight + 100 or state.boardBlocks.elementAt(points) <= 0) {
            try deleteBlock(state, i);
            continue;
        }

        state.boardBlocks.assignAt(y, newPositionY);
    }
}

pub fn draw(state: *GameState) !void {
    for (0..len) |i| {
        const index = i * vecSize;
        if (index >= len / vecSize) break;

        const x = state.boardBlocks.elementAt(0 + index);
        const y = state.boardBlocks.elementAt(1 + index);
        const points = state.boardBlocks.elementAt(2 + index);

        // the path beyond this point is all empty, no need to check
        if (x == null and y == null and points == null) break;
        assert(x != null and y != null and points != null);

        const rec: rl.Rectangle = .{
            .x = x,
            .y = y,
            .width = Constants.screenCellSize,
            .height = Constants.screenCellSize,
        };
        rl.drawRectangleRounded(rec, 0.2, 0, .blue);

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
