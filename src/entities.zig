const std = @import("std");

pub const Empty = -1.11;
const Utils = @import("helper.zig");

pub const Game = struct {
    useMouse: bool = true,
    paused: bool = false,
    gameOver: bool = false,
    showPath: bool = false,
    showBody: bool = true,

    pub fn new() Game {
        return Game{};
    }
};

pub const Screen = struct {
    const _width: i16 = 400;
    const _height: i16 = 800;

    fps: f32 = 60,
    width: i16 = _width,
    height: i16 = _height,
    centerX: f32,
    centerY: f32,
    cellSize: f32,

    pub fn new() Screen {
        return Screen{
            .centerX = @divTrunc(_width, 2),
            .centerY = @divTrunc(_height, 2),
            .cellSize = @divTrunc(_width, 5),
        };
    }
};

pub const Snake = struct {
    const _radius: i8 = 10;
    const _radiusSquared: f32 = _radius * _radius;
    const _diameter: f32 = _radius * 2;
    const _tolerance: f32 = 0.025;
    const _len: usize = 1000;

    size: i16 = 10,
    radius: i8 = _radius,
    radiusSquared: f32 = _radiusSquared,
    diameter: f32 = _diameter,
    minDiameter: f32 = _diameter - _tolerance,
    maxDiameter: f32 = _diameter + _tolerance,
    step: f32 = 0.01,

    len: usize = _len,
    nodes: [_len]f32 = undefined,
    vecSize: usize = 2,

    pub fn new() Snake {
        return Snake{};
    }
};

pub const Path = struct {
    const _len: usize = 1000;

    /// Store positions as (x, y) vector
    positions: [_len]f32 = undefined,
    /// [Path.positions] length
    len: usize = _len,
    /// The number of elements in the vectorized data array [Path.positions].
    ///
    /// Represents the total count of elements stored in a contiguous memory block.
    /// Used for iterating over and processing the data efficiently.
    ///
    /// **Note:** DO NOT MUTATE this variable to avoid undefined behavior.
    vecSize: usize = 2,
    /// Minimum space between two positions in [Path.positions]
    resolution: f32 = 1,
    /// How much the cursor will increment when searching for a valid place
    /// for a new circle.
    step: f32 = 0.01,

    pub fn new() Path {
        return Path{};
    }
};

pub const Board = struct {
    const _len: usize = 1000;
    pub const fullSpeed: f32 = 180;

    /// Store blocks as (x, y, points) vector
    blocks: [_len]f32 = undefined,
    /// [Board.cells] length
    len: usize = _len,
    /// The number of elements in the vectorized data array [Board.cells].
    ///
    /// Represents the total count of elements stored in a contiguous memory block.
    /// Used for iterating over and processing the data efficiently.
    ///
    /// **Note:** DO NOT MUTATE this variable to avoid undefined behavior.
    vecSize: usize = 3,
    boardSpeed: f32 = fullSpeed,

    pub fn new() Board {
        return Board{};
    }

    pub fn deleteBlock(self: *Board, blockIndex: usize) !void {
        return try Utils.deleteVecSize3Element(blockIndex, &self.blocks, self.len);
    }
};
