const std = @import("std");
const math = std.math;
const print = std.debug.print;
const List = @import("snake.zig").List;
const Node = @import("snake.zig").Node;
const rl = @cImport({
    @cInclude("raylib.h");
});

var useMouse: bool = false;
var paused: bool = false;
var gameOver = false;
const fps = 60;
const fontSize = 10;
const screenWidth = 400;
const screenHeight = 700;
const movementSpeed = 500;
// const columns = 5;
// const cellSize: f32 = screenWidth / columns;
// const rectSize: f32 = cellSize - 1;
// const rows = std.math.round(screenHeight / cellSize);

const snakeVecSize = 2;
const circleRadius = 10;
const circleSize = circleRadius * 2;
const margin: f16 = 4;
// const leftScreenLimit = circleSize;
// const rightScreenLimit = screenWidth - circleSize;
var snakeSize: i16 = 5;
const visibleSnakeSizeLimit: usize = std.math.round((screenHeight / 2) / (circleSize + margin)) * snakeVecSize;
var visibleTail = visibleSnakeSizeLimit;
var snake: List = undefined;

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

    if (gameOver) {
        rl.DrawText("Game Over", @intFromFloat(0), @intFromFloat(screenHeight / 2), 50, rl.WHITE);
    }

    try Snake.draw();

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

const Snake = struct {
    inline fn init() !void {
        const size: usize = @intCast(snakeSize);
        var snakeX: [5]f32 = undefined;
        var snakeY: [5]f32 = undefined;
        for (0..size) |i| {
            snakeX[i] = screenWidth / 2;
            snakeY[i] = if (i > 0) snakeY[i - 1] + circleRadius * 2 else screenHeight / 2;
        }
        snake = try List.init(std.heap.page_allocator, snakeX, snakeY);
    }

    fn updatePosition(deltaTime: f32) !void {
        visibleTail = if (snakeSize > visibleSnakeSizeLimit) visibleSnakeSizeLimit else @intCast(snakeSize);
        var newX = snake.head.x;
        const newY = snake.head.y;

        if (useMouse) {
            newX = @floatFromInt(rl.GetMouseX());
        } else {
            if (rl.IsKeyDown(rl.KEY_LEFT)) {
                newX -= 1 * movementSpeed * deltaTime;
            } else if (rl.IsKeyDown(rl.KEY_RIGHT)) {
                newX += 1 * movementSpeed * deltaTime;
            }
        }

        snake.head.x = math.clamp(snake.head.x, 0 + circleRadius, screenWidth - circleRadius);

        // if (newX != snake.head.x or newY != snake.head.y) try snake.move(newX, newY);
        const deltaX = snake.head.x - newX;
        const deltaY = snake.head.y - newY;
        if (abs(deltaX) >= circleSize or abs(deltaY) >= circleSize) try snake.move(newX, newY);
    }

    fn draw() !void {
        for (0..snake.len) |i| {
            const node = try snake.get(i);
            rl.DrawCircle(@intFromFloat(node.x), @intFromFloat(node.y), circleRadius, rl.RED);
        }
        // rl.DrawText(rl.TextFormat("%i", .{snakeSize}), @intFromFloat(snake.head.x + 2), @intFromFloat(snake.head.y - 20), fontSize, rl.WHITE);
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
