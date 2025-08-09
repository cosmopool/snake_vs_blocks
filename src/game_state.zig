const std = @import("std");
const Utils = @import("helper.zig");
const Constants = @import("constants.zig");
const Board = @import("board.zig");
const Snake = @import("snake.zig");

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
    boardBlocks: [Board.len]f32 = undefined,
    boardSpeed: f32 = Board.fullSpeed,
    distanceFromLastBlock: u16 = 0,

    random: std.Random = undefined,
};
