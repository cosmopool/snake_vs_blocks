const std = @import("std");
const rl = @import("raylib");

const Constants = @import("constants.zig");
const GameState = @import("game_state.zig").GameState;
const Vector = @import("vector.zig").Vector;

const math = std.math;

pub const vecSize: usize = 5;
pub const len: u16 = vecSize * 1000;

pub fn init(state: *GameState) void {
    for (0..state.snakeParticlesStatus.len - 1) |i| {
        state.snakeParticlesStatus[i] = false;
        state.blockParticleStatus[i] = false;
    }
}

pub fn update(deltaTime: f32, state: *GameState) !void {
    try createSnakeParticle(state, 2);
    try createBlockParticle(state, 30);
    try updateSnakeParticles(deltaTime, state);
    try updateBlockParticles(deltaTime, state);
}

pub fn draw(state: *GameState) !void {
    try drawSnakeParticles(state);
    try drawBlockParticles(state);
}

const ParticleIndexes = struct {
    index: usize,
    pos_x: usize,
    pos_y: usize,
    vel_x: usize,
    vel_y: usize,
    size: usize,
    acc_x: usize,
    acc_y: usize,
};

fn getParticleIndexes(i: usize) !ParticleIndexes {
    std.debug.assert(i < len);
    const index = i * vecSize;
    std.debug.assert(index < len);
    const pos_x = index + 0;
    const pos_y = index + 1;
    const vel_x = index + 2;
    const vel_y = index + 3;
    const size = index + 4;
    const acc_x = index + 5;
    const acc_y = index + 6;

    return ParticleIndexes{
        .index = index,
        .pos_x = pos_x,
        .pos_y = pos_y,
        .vel_x = vel_x,
        .vel_y = vel_y,
        .size = size,
        .acc_x = acc_x,
        .acc_y = acc_y,
    };
}

fn createSnakeParticle(state: *GameState, quantity: usize) !void {
    if (!state.isColliding) return;

    var left = quantity;
    for (0..state.snakeParticlesStatus.len - 1) |i| {
        if (left <= 0) break;
        const isParticleActive = state.snakeParticlesStatus[i];
        if (isParticleActive) continue;

        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const snake_head_x: i32 = @intFromFloat(state.pathPositions[0]);
        const snake_head_y: i32 = @intFromFloat(state.pathPositions[1]);

        // TODO(kaio): better to use state.random to generate numbers?
        state.snakeParticles[idx.vel_x] = @as(f32, @floatFromInt(rl.getRandomValue(-20, 20))) * 0.1;
        state.snakeParticles[idx.vel_y] = @as(f32, @floatFromInt(rl.getRandomValue(-50, -20))) * 0.1;
        state.snakeParticles[idx.pos_x] = @as(f32, @floatFromInt(rl.getRandomValue((snake_head_x - 20) * 10, (snake_head_x + 20) * 10))) * 0.1;
        state.snakeParticles[idx.pos_y] = @floatFromInt(snake_head_y);
        state.snakeParticles[idx.size] = 5;

        state.snakeParticlesStatus[i] = true;
        left -= 1;
    }
}

fn createBlockParticle(state: *GameState, quantity: usize) !void {
    if (state.blockThatExploded[0] == 0 and state.blockThatExploded[1] == 0) return;

    var left = quantity;
    for (0..state.blockParticleStatus.len - 1) |i| {
        if (left <= 0) break;
        const isParticleActive = state.blockParticleStatus[i];
        if (isParticleActive) continue;

        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const x = state.blockThatExploded[0];
        const y = state.blockThatExploded[1];

        const radius: f32 = @floatFromInt(rl.getRandomValue(10, 30));
        const t: f32 = @floatFromInt(rl.getRandomValue(0, 360));
        const particle_x = radius * math.cos(t);
        const particle_y = radius * math.sin(t);

        // TODO(kaio): better to use state.random to generate numbers?
        state.blockParticles[idx.vel_x] = particle_x * 0.5;
        state.blockParticles[idx.vel_y] = particle_y * 0.5;
        state.blockParticles[idx.pos_x] = particle_x + Constants.screenCellSize / 2 + x;
        state.blockParticles[idx.pos_y] = particle_y + Constants.screenCellSize / 2 + y;
        state.blockParticles[idx.size] = 3;
        state.blockParticles[idx.acc_x] = particle_x * 0.2;
        state.blockParticles[idx.acc_y] = particle_y * 0.2;

        state.blockParticleStatus[i] = true;
        left -= 1;
    }

    state.blockThatExploded[0] = 0;
    state.blockThatExploded[1] = 0;
}

pub fn updateSnakeParticles(deltaTime: f32, state: *GameState) !void {
    const acc_x: f32 = 0.0;
    const acc_y: f32 = 0.5;
    _ = deltaTime;

    for (0..state.snakeParticlesStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const isParticleActive = state.snakeParticlesStatus[i];
        if (!isParticleActive) continue;

        // update velocity = velocity + acc
        state.snakeParticles[idx.vel_x] += acc_x;
        state.snakeParticles[idx.vel_y] += acc_y;
        // update position = position + velocity
        state.snakeParticles[idx.pos_x] += state.snakeParticles[idx.vel_x];
        state.snakeParticles[idx.pos_y] += state.snakeParticles[idx.vel_y];

        // reduce size 30% of the time
        if (state.random.uintLessThan(u16, 100) > 30) continue;
        state.snakeParticles[idx.size] -= 1;
        if (state.snakeParticles[idx.size] > 0) continue;
        state.snakeParticlesStatus[i] = false;
    }
}

pub fn updateBlockParticles(deltaTime: f32, state: *GameState) !void {
    for (0..state.blockParticleStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const isParticleActive = state.blockParticleStatus[i];
        if (!isParticleActive) continue;

        // update velocity = velocity + acc
        state.blockParticles[idx.vel_x] *= 0.9;
        state.blockParticles[idx.vel_y] *= 0.9;
        // update position = position + velocity
        state.blockParticles[idx.pos_x] += state.blockParticles[idx.vel_x];
        state.blockParticles[idx.pos_y] += state.blockParticles[idx.vel_y] + (state.boardSpeed * deltaTime);

        // reduce size 30% of the time
        if (state.random.uintLessThan(u16, 100) > 30) continue;
        state.blockParticles[idx.size] -= 1;
        if (state.blockParticles[idx.size] > 0) continue;
        state.blockParticleStatus[i] = false;
    }
}

pub fn drawSnakeParticles(state: *GameState) !void {
    for (0..state.snakeParticlesStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len * vecSize);

        const isParticleActive = state.snakeParticlesStatus[i];
        if (!isParticleActive) continue;

        const x: f32 = state.snakeParticles[idx.pos_x];
        const y: f32 = state.snakeParticles[idx.pos_y];
        const size: f32 = state.snakeParticles[idx.size];
        rl.drawCircle(@intFromFloat(x), @intFromFloat(y), size, .red);
    }
}

pub fn drawBlockParticles(state: *GameState) !void {
    for (0..state.blockParticleStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len * vecSize);

        const isParticleActive = state.blockParticleStatus[i];
        if (!isParticleActive) continue;

        const x: f32 = state.blockParticles[idx.pos_x];
        const y: f32 = state.blockParticles[idx.pos_y];
        const size: f32 = state.blockParticles[idx.size];
        rl.drawCircle(@intFromFloat(x), @intFromFloat(y), size, .green);
    }
}
