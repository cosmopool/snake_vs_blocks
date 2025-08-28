const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const rl = @import("raylib");

const Snake = @import("snake.zig");
const Board = @import("board.zig");
const Particles = @import("particles.zig");
const Utils = @import("utils.zig");
const Constants = @import("constants.zig");

const Vector = @import("vector.zig").Vector;
const GameState = @import("game_state.zig").GameState;

pub fn main() !void {
    //--------------------------------------------------------------------------------------
    // Initialization
    rl.setConfigFlags(rl.ConfigFlags{ .vsync_hint = true });
    rl.initWindow(Constants.screenWidth, Constants.screenHeight, "hello world!");
    rl.setTargetFPS(Constants.fps);

    var state = GameState{};

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    state.random = prng.random();

    try Board.init(&state);
    try Snake.init(&state);
    Particles.init(&state);
    //--------------------------------------------------------------------------------------

    // fix for first position
    rl.setMousePosition(Constants.screenCenterX, Constants.screenCenterY);

    //--------------------------------------------------------------------------------------
    // Game loop
    while (!rl.windowShouldClose()) {
        handleInput(&state);
        try update(&state);
        try draw(&state);
    }
    //--------------------------------------------------------------------------------------

    //--------------------------------------------------------------------------------------
    // De-Initialization
    rl.closeWindow();
    //--------------------------------------------------------------------------------------
}

fn handleInput(state: *GameState) void {
    if (rl.isKeyPressed(.space)) state.paused = !state.paused;
    if (rl.isKeyPressed(.d)) state.showPath = !state.showPath;
    if (rl.isKeyPressed(.b)) state.showBody = !state.showBody;
    if (rl.isKeyPressed(.g)) state.godMode = !state.godMode;
    if (rl.isKeyPressed(.v)) {
        if (state.boardSpeed == Board.fullSpeed) {
            state.boardSpeed = 0;
        } else {
            state.boardSpeed = Board.fullSpeed;
        }
    }
}

fn update(state: *GameState) anyerror!void {
    if (state.paused or state.gameOver) return;
    if (state.snakeSize < 0) state.gameOver = true;

    const deltaTime = rl.getFrameTime();

    try Board.update(deltaTime, state);
    try Snake.update(deltaTime, state);
    try Particles.update(deltaTime, state);
}

fn draw(state: *GameState) anyerror!void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(.black);

    try Board.draw(state);
    try Snake.draw(state);
    try Particles.draw(state);

    if (state.gameOver) Utils.drawAtCenter("GAME OVER", 50, null);
    if (state.paused) Utils.drawAtCenter("PAUSED", null, null);

    rl.drawFPS(rl.getScreenWidth() - 95, 10);
}
