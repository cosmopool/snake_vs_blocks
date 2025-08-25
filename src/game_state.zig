const std = @import("std");
const Utils = @import("utils.zig");
const Constants = @import("constants.zig");
const Board = @import("board.zig");
const Snake = @import("snake.zig");
const Particles = @import("particles.zig");

pub const GameState = struct {
    useMouse: bool = true,
    paused: bool = false,
    gameOver: bool = false,
    showPath: bool = false,
    showBody: bool = true,
    godMode: bool = false,

    snakeSize: f32 = 100,

    /// Store positions as (x, y) vector
    pathPositions: [Snake.pathLen]f32 = undefined,

    /// Store blocks as (x, y, points) vector
    boardBlocks: [Board.len]f32 = undefined,
    boardSpeed: f32 = Board.fullSpeed,
    distanceFromLastBlock: u16 = 0,
    blockThatExploded: [2]f32 = undefined,

    // todo(kaio): set particle docstring
    /// Store particles as () vector
    particles: [Particles.len]f32 = undefined,
    particleStatus: [Particles.len / Particles.vecSize]bool = undefined,
    blockParticles: [Particles.len]f32 = undefined,
    blockParticleStatus: [Particles.len / Particles.vecSize]bool = undefined,

    isColliding: bool = false,

    random: std.Random = undefined,
};
