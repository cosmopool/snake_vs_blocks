const std = @import("std");
const Utils = @import("helper.zig");
const Constants = @import("constants.zig");
const Board = @import("board.zig");
const Snake = @import("snake.zig");
const RingBuffer = @import("ring_buffer.zig").RingBuffer;

pub const GameState = struct {
    useMouse: bool = true,
    paused: bool = false,
    gameOver: bool = false,
    showPath: bool = false,
    showBody: bool = true,

    snakeSize: i16 = 10,

    /// Store positions as (x, y) vector
    pathPositions: [Snake.pathLen]f32 = undefined,

    /// Store blocks as (x, y, points) vector
    boardBlocks: RingBuffer(f32, Board.len),
    boardSpeed: f32 = Board.fullSpeed,
};
