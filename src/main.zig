const std = @import("std");
const Helper = @import("helper.zig");
const print = std.debug.print;

const Thread = std.Thread;
const Mutex = std.Thread.Mutex;

const SnakeList = @import("snake.zig").List;
const Node = @import("snake.zig").Node;

const rl = @cImport({
    @cInclude("raylib.h");
});

const Color = rl.CLITERAL(rl.Color);

const tenMs = std.time.ns_per_us;
var lastTime: i64 = 0;

var useMouse: bool = false;
var paused: bool = false;
var gameOver = false;
const fps: f32 = 60;
const screenWidth = 400;
const screenHeight = 700;
const centerX = @divTrunc(screenWidth, 2);
const centerY = @divTrunc(screenHeight, 2);

const snakeVecSize = 2;
var snakeSize: i16 = 10;
const circleRadius = 10;
const circleSize = circleRadius * 2;
const margin: f16 = 4;
const leftScreenLimit = circleSize;
const rightScreenLimit = screenWidth - circleSize;
const visibleSnakeSizeLimit: usize = std.math.round((screenHeight / 2) / (circleSize + margin)) * snakeVecSize;
var visibleTail = visibleSnakeSizeLimit;
const speed: f32 = 1250;

var snake: SnakeList = undefined;

var snakeHeadX: f32 = centerX;
var snakeHeadY: f32 = centerY;
var direction: @Vector(2, f32) = undefined;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screenWidth, screenHeight, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(fps);

    const _x = [_]f32{ centerX, centerX, centerX };
    const _y = [_]f32{ centerY, centerY + circleSize, centerY + 2 * circleSize };
    snake = try SnakeList.init(std.heap.page_allocator, _x, _y);

    direction = @Vector(2, f32){ snakeHeadX, snakeHeadY };

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) paused = !paused;
        if (!paused and !gameOver) try update();
        try draw();
    }
}

fn update() anyerror!void {
    if (snakeSize <= 0) gameOver = true;
    const now = std.time.microTimestamp();
    if (now - lastTime < tenMs) return;

    const deltaTime = rl.GetFrameTime();

    // if (rl.IsKeyPressed(rl.KEY_M)) useMouse = !useMouse;

    try updateSnakePosition(deltaTime);
    lastTime = now;
}

fn updateSnakePosition(deltaTime: f32) !void {
    // get mouse position
    const mouse = rl.GetMousePosition();

    // limit mouse position to window boundaries
    var mouseX = std.math.clamp(mouse.x, circleRadius, screenWidth - circleRadius);
    var mouseY = std.math.clamp(mouse.y, circleRadius, centerY - circleRadius);

    // calculate mouse relative distance from snake head
    mouseX = mouse.x - snakeHeadX;
    mouseY = mouse.y - snakeHeadY;

    // calculate snake head direction vector
    const magnitude: f32 = std.math.sqrt(mouseX * mouseX + mouseY * mouseY);
    direction[0] = mouseX / magnitude;
    direction[1] = mouseY / magnitude;

    // position snake head
    snakeHeadX += direction[0] * speed * deltaTime;
}

fn draw() anyerror!void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(rl.BLACK);

    rl.DrawCircle(@intFromFloat(snakeHeadX), @intFromFloat(snakeHeadY), circleRadius, rl.RED);
    rl.DrawLine(@intFromFloat(snakeHeadX), @intFromFloat(snakeHeadY), @intFromFloat(-direction[0] * 100 + snakeHeadX), @intFromFloat(-direction[1] * 100 + snakeHeadY), rl.WHITE);

    if (gameOver) drawAtCenter("Game Over", 50, null);
    if (paused) drawAtCenter("paused", null, null);

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

fn drawAtCenter(text: [*c]const u8, size: ?usize, color: ?Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.MeasureText(text, @intCast(fontSize));
    const x = @divTrunc(screenWidth, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), @intFromFloat(screenHeight / 2), @intCast(fontSize), color orelse rl.WHITE);
}
