const std = @import("std");
const math = std.math;
const print = std.debug.print;

const rl = @cImport({
    @cInclude("raylib.h");
});

var useMouse: bool = false;
var paused: bool = false;
var gameOver = false;
const fps: f32 = 60;
const frameTime: f32 = 1 / fps;
const screenWidth = 400;
const screenHeight = 700;
const movementSpeed = 500;

const snakeVecSize = 2;
var snakeSize: i16 = 5;
var snake: [100]f32 = undefined;
var snakeOldPos: [100]f32 = undefined;
const circleRadius = 10;
const circleSize = circleRadius * 2;
const margin: f16 = 4;
const leftScreenLimit = circleSize;
const rightScreenLimit = screenWidth - circleSize;
const visibleSnakeSizeLimit: usize = std.math.round((screenHeight / 2) / (circleSize + margin)) * snakeVecSize;
var visibleTail = visibleSnakeSizeLimit;
const maxVel = 1000;

const SnakeHead = struct {
    x: *f32 = &snake[0],
    y: *f32 = &snake[1],
};
const head = SnakeHead{};

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screenWidth, screenHeight, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(fps);

    try Snake.init();

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) paused = !paused;
        if (!paused and !gameOver) try update();
        try draw();
    }
}

fn update() anyerror!void {
    const deltaTime = rl.GetFrameTime();
    if (snakeSize <= 0) {
        gameOver = true;
        return;
    }

    if (rl.IsKeyPressed(rl.KEY_M)) useMouse = !useMouse;

    try Snake.updatePosition(deltaTime);
}

fn draw() anyerror!void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(rl.BLACK);

    try Snake.draw();

    if (gameOver) drawAtCenter("Game Over", 50, null);
    if (paused) drawAtCenter("paused", null, null);

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

const Color = rl.CLITERAL(rl.Color);

fn drawAtCenter(text: [*c]const u8, size: ?usize, color: ?Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.MeasureText(text, @intCast(fontSize));
    const x = @divTrunc(screenWidth, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), @intFromFloat(screenHeight / 2), @intCast(fontSize), color orelse rl.WHITE);
}

const Snake = struct {
    inline fn init() !void {
        const size: usize = @intCast(snakeSize);
        for (0..size) |i| {
            const index = i * snakeVecSize;
            const x = 0 + index;
            const y = 1 + index;
            snake[x] = screenWidth / 2;
            snake[y] = if (index > 0) snake[index - 1] + circleRadius * 2 else screenHeight / 2;
            snakeOldPos[x] = snake[x];
            snakeOldPos[y] = snake[y];
        }
    }

    fn updatePosition(deltaTime: f32) !void {
        _ = deltaTime;
    }

    fn draw() !void {
        for (0..visibleTail) |i| {
            const index = i * snakeVecSize;
            const x = 0 + index;
            const y = 1 + index;
            rl.DrawCircle(@intFromFloat(snake[x]), @intFromFloat(snake[y]), circleRadius, rl.RED);
        }
        // rl.DrawText(rl.TextFormat("%i", .{snakeSize}), @intFromFloat(head.x.* + 2), @intFromFloat(head.y.* - 20), fontSize, rl.WHITE);
    }

    fn checkCollision(x1: f32, y1: f32, x2: f32, y2: f32, size: f32) bool {
        const dx: f32 = x2 - x1;
        const dy: f32 = y2 - y1;
        const distance = std.math.sqrt(dx * dx + dy * dy);
        if (distance <= (size + size)) return true;
        return false;
    }
};

fn abs(num: anytype) @TypeOf(num) {
    if (std.math.sign(num) == -1) return num * -1;
    return num;
}

fn normalize(num: f32, min: f32, max: f32, n: f32) f32 {
    return ((num - min) / (max - min)) * n;
}

fn limitVelocity(dx: f32, dt: f32, limit: f32) f32 {
    if (dt == 0 or dx == 0) return 0;
    const vel: f32 = dx / dt;
    if (vel < 0) {
        return if (vel < -limit) -limit else vel;
    } else {
        return if (vel > limit) limit else vel;
    }
}

fn cosineInterpolation(y1: f32, y2: f32, mu: f32) f32 {
    var mu2: f32 = 0;
    mu2 = (1 - std.math.cos(mu * std.math.pi)) / 2;
    return (y1 * (1 - mu2) + y2 * mu2);
}

var posMutex = Mutex{};
fn physics() noreturn {
    while (true) {
        // while (!posMutex.tryLock()) snake.len;
        // posMutex.unlock();
        std.time.sleep(std.time.ns_per_ms * 10);
    }
}
