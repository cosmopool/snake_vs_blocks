const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const rl = @cImport({
    @cInclude("raylib.h");
});

const Vector = @import("vector.zig").Vector;

const Empty = 0;

const Color = rl.CLITERAL(rl.Color);

var useMouse: bool = false;
var paused: bool = false;
var gameOver = false;
var showPath = false;
var showBody = false;
const fps: f32 = 60;
const screenWidth = 400;
const screenHeight = 700;
const centerX = @divTrunc(screenWidth, 2);
const centerY = @divTrunc(screenHeight, 2);

var snakeSize: i16 = 20;
const circleRadius = 10;
const circleDiameter = circleRadius * 2;
const margin: f16 = 4;
const boardSpeed = 180;

const snakePathLen = 1000;
const snakePathVecSize = 2;
var snakePath: [snakePathLen]f32 = undefined;
const pathResolution: f32 = 3;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screenWidth, screenHeight, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(fps);

    inline for (0..snakePathLen) |i| {
        const index = i * snakePathVecSize;
        if (index >= snakePathLen) break;
        const x = 0 + index;
        const y = 1 + index;
        snakePath[x] = Empty;
        snakePath[y] = Empty;
    }
    snakePath[0] = centerX;
    snakePath[1] = centerY;

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) paused = !paused;
        if (rl.IsKeyPressed(rl.KEY_D)) showPath = !showPath;
        if (rl.IsKeyPressed(rl.KEY_B)) showBody = !showBody;
        if (!paused and !gameOver) try update();
        try draw();
    }
}

fn update() anyerror!void {
    if (snakeSize <= 0) gameOver = true;
    const deltaTime = rl.GetFrameTime();

    updateSnakePathPosition(deltaTime);
    try updateSnakePosition(deltaTime);
}

fn updateSnakePosition(deltaTime: f32) !void {
    _ = deltaTime; // autofix
    // limit mouse position to window boundaries
    const mouse = Vector.new(
        std.math.clamp(rl.GetMousePosition().x, circleRadius, screenWidth - circleRadius),
        centerY,
    );
    assert(mouse.x() >= 0 and mouse.x() <= screenWidth);
    assert(mouse.y() >= 0 and mouse.y() <= screenHeight);

    // last position in snakePath array
    const lastPathPos = Vector.new(snakePath[2], snakePath[3]);

    // create a new node in snakePath
    const distanceToLastPosition = mouse.distance(lastPathPos);
    if (distanceToLastPosition >= pathResolution) {
        addNodeInPath(mouse);
    }

    // update snake head position
    snakePath[0] = mouse.x();
    assert(snakePath[0] >= 0 and snakePath[0] <= screenWidth);
}

fn updateSnakePathPosition(deltaTime: f32) void {
    for (0..snakePathLen) |i| {
        if (i == 0) continue;
        const index = i * snakePathVecSize;
        if (index > snakePathLen) break;
        const x = 0 + index;
        const y = 1 + index;

        if (snakePath[x] == Empty and snakePath[y] == Empty) break;
        assert(snakePath[x] != Empty and snakePath[y] != Empty);

        // update checkpoint position
        const newPositionY = snakePath[y] + (boardSpeed * deltaTime);
        if (newPositionY > screenHeight + 100) {
            snakePath[x] = Empty;
            snakePath[y] = Empty;
        } else {
            snakePath[y] = newPositionY;
        }
    }
}

fn addNodeInPath(newNode: Vector) void {
    var i: usize = snakePathLen / snakePathVecSize;
    while (i > 1) : (i -= snakePathVecSize) {
        if (i >= snakePathLen / snakePathVecSize) continue;
        const x = 0 + i;
        const y = 1 + i;

        if (snakePath[x] == Empty and snakePath[y] == Empty) continue;
        assert(snakePath[x] != Empty and snakePath[y] != Empty);

        // shift values to the right
        snakePath[x + 2] = snakePath[x];
        snakePath[y + 2] = snakePath[y];
    }

    // add new checkpoint values
    snakePath[2] = newNode.x();
    snakePath[3] = newNode.y();
}

fn draw() anyerror!void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(rl.BLACK);

    try drawSnake();

    if (gameOver) drawAtCenter("GAME OVER", 50, null);
    if (paused) drawAtCenter("PAUSED", null, null);

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

fn drawBodyNodeAt(x: f32, y: f32) void {
    rl.DrawCircle(@intFromFloat(x), @intFromFloat(y), circleRadius, rl.RED);
}

fn drawSnake() !void {
    // draw head
    drawBodyNodeAt(snakePath[0], snakePath[1]);

    // draw body
    var lastBodyNodeUsed = Vector.new(0, 0);
    var remaningCircles: i16 = snakeSize;
    for (1..snakePathLen) |i| {
        const index = i * snakePathVecSize;
        if (index >= snakePathLen / snakePathVecSize) break;
        const x = 0 + index;
        const y = 1 + index;

        if (snakePath[x] == Empty and snakePath[y] == Empty) break;
        assert(snakePath[x] != Empty and snakePath[y] != Empty);

        const currentNode = Vector.new(snakePath[x], snakePath[y]);
        const prevNode = Vector.new(snakePath[x - snakePathVecSize], snakePath[y - snakePathVecSize]);

        if (showPath) drawLineFrom(currentNode, prevNode);

        if (remaningCircles <= 0) continue;
        if (currentNode.distance(lastBodyNodeUsed) < circleDiameter) continue;

        if (!showBody) continue;
        drawBodyNodeAt(currentNode.x(), currentNode.y());
        lastBodyNodeUsed = currentNode;
        remaningCircles -= 1;
    }
}

fn drawLineFrom(start: Vector, end: Vector) void {
    return rl.DrawLine(
        @intFromFloat(start.x()),
        @intFromFloat(start.y()),
        @intFromFloat(end.x()),
        @intFromFloat(end.y()),
        rl.BLUE,
    );
}

fn drawAtCenter(text: [*c]const u8, size: ?usize, color: ?Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.MeasureText(text, @intCast(fontSize));
    const x = @divTrunc(screenWidth, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), @intFromFloat(screenHeight / 2), @intCast(fontSize), color orelse rl.WHITE);
}
