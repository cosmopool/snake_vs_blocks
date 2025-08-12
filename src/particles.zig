const std = @import("std");
const rl = @import("raylib");

const Constants = @import("constants.zig");
const GameState = @import("game_state.zig").GameState;
const Vector = @import("vector.zig").Vector;

pub const vecSize: usize = 5;
pub const len: u16 = vecSize * 1000;
const acc_x: f32 = 0.0;
const acc_y: f32 = 0.5;

const ParticleIndexes = struct {
    index: usize,
    pos_x: usize,
    pos_y: usize,
    vel_x: usize,
    vel_y: usize,
    size: usize,
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

    return ParticleIndexes{
        .index = index,
        .pos_x = pos_x,
        .pos_y = pos_y,
        .vel_x = vel_x,
        .vel_y = vel_y,
        .size = size,
    };
}

fn createParticle(state: *GameState, quantity: usize) !void {
    var left = quantity;
    for (0..state.particleStatus.len - 1) |i| {
        if (left <= 0) break;
        const isParticleActive = state.particleStatus[i];
        if (isParticleActive) continue;

        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const snake_head_x: i32 = @intFromFloat(state.pathPositions[0]);
        const snake_head_y: i32 = @intFromFloat(state.pathPositions[1]);

        state.particles[idx.vel_x] = @as(f32, @floatFromInt(rl.getRandomValue(-20, 20))) * 0.1;
        state.particles[idx.vel_y] = @as(f32, @floatFromInt(rl.getRandomValue(-50, -20))) * 0.1;
        state.particles[idx.pos_x] = @as(f32, @floatFromInt(rl.getRandomValue((snake_head_x - 20) * 10, (snake_head_x + 20) * 10))) * 0.1;
        state.particles[idx.pos_y] = @floatFromInt(snake_head_y);
        state.particles[idx.size] = 5;

        state.particleStatus[i] = true;
        left -= 1;
    }
}

pub fn init(state: *GameState) void {
    for (0..state.particleStatus.len - 1) |i| {
        state.particleStatus[i] = false;
    }
}

pub fn update(state: *GameState) !void {
    if (state.isColliding) try createParticle(state, 5);

    for (0..state.particleStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len - vecSize);

        const isParticleActive = state.particleStatus[i];
        if (!isParticleActive) continue;

        // update velocity = velocity + acc
        state.particles[idx.vel_x] = state.particles[idx.vel_x] + acc_x;
        state.particles[idx.vel_y] = state.particles[idx.vel_y] + acc_y;
        // update position = position + velocity
        state.particles[idx.pos_x] = state.particles[idx.pos_x] + state.particles[idx.vel_x];
        state.particles[idx.pos_y] = state.particles[idx.pos_y] + state.particles[idx.vel_y];

        // reduce size 30% of the time
        if (state.random.uintLessThan(u16, 100) > 30) continue;
        state.particles[idx.size] = state.particles[idx.size] - 1;
        if (state.particles[idx.size] > 0) continue;
        state.particleStatus[i] = false;
    }
}

pub fn draw(state: *GameState) !void {
    for (0..state.particleStatus.len - 1) |i| {
        const idx = try getParticleIndexes(i);
        std.debug.assert(idx.index < len * vecSize);

        const isParticleActive = state.particleStatus[i];
        if (!isParticleActive) continue;

        const x: f32 = state.particles[idx.pos_x];
        const y: f32 = state.particles[idx.pos_y];
        const size: f32 = state.particles[idx.size];
        rl.drawCircle(@intFromFloat(x), @intFromFloat(y), size, .red);
    }
}
