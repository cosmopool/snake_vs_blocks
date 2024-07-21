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
var Game = @import("entities.zig").Game.new();
const Screen = @import("entities.zig").Screen.new();
var Snake = @import("entities.zig").Snake.new();

const boardSpeed = 180;

const snakePathLen = 1000;
const snakePathVecSize = 2;
var snakePath: [snakePathLen]f32 = undefined;
const pathResolution: f32 = 3;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(Screen.width, Screen.height, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(Screen.fps);

    inline for (0..snakePathLen) |i| {
        const index = i * snakePathVecSize;
        if (index >= snakePathLen) break;
        const x = 0 + index;
        const y = 1 + index;
        snakePath[x] = Empty;
        snakePath[y] = Empty;
    }
    snakePath[0] = Screen.centerX;
    snakePath[1] = Screen.centerY;

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) Game.paused = !Game.paused;
        if (rl.IsKeyPressed(rl.KEY_D)) Game.showPath = !Game.showPath;
        if (rl.IsKeyPressed(rl.KEY_B)) Game.showBody = !Game.showBody;
        if (!Game.paused and !Game.gameOver) try update();
        try draw();
    }
}

fn update() anyerror!void {
    if (Snake.size <= 0) Game.gameOver = true;
    const deltaTime = rl.GetFrameTime();

    updateSnakePathPosition(deltaTime);
    try updateSnakePosition(deltaTime);
}

fn updateSnakePosition(deltaTime: f32) !void {
    _ = deltaTime; // autofix
    // limit mouse position to window boundaries
    const radius: f32 = @floatFromInt(Snake.radius);
    const screenWidthLimit: f32 = Screen.width - radius;
    const mouse = Vector.new(
        std.math.clamp(rl.GetMousePosition().x, radius, screenWidthLimit),
        Screen.centerY,
    );
    assert(mouse.x() >= 0 and mouse.x() <= Screen.width);
    assert(mouse.y() >= 0 and mouse.y() <= Screen.height);

    // last position in snakePath array
    const lastPathPos = Vector.new(snakePath[2], snakePath[3]);

    // create a new node in snakePath
    const distanceToLastPosition = mouse.distance(lastPathPos);
    if (distanceToLastPosition >= pathResolution) {
        addNodeInPath(mouse);
    }

    // update snake head position
    snakePath[0] = mouse.x();
    assert(snakePath[0] >= 0 and snakePath[0] <= Screen.width);
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
        if (newPositionY > Screen.height + 100) {
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

    if (Game.gameOver) drawAtCenter("GAME OVER", 50, null);
    if (Game.paused) drawAtCenter("PAUSED", null, null);

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

fn drawBodyNodeAt(x: f32, y: f32) void {
    rl.DrawCircle(@intFromFloat(x), @intFromFloat(y), @floatFromInt(Snake.radius), rl.RED);
}

fn drawSnake() !void {
    // draw head
    drawBodyNodeAt(snakePath[0], snakePath[1]);

    // draw body
    var lastBodyNodeUsed = Vector.new(0, 0);
    var remaningCircles: i16 = Snake.size;
    for (1..snakePathLen) |i| {
        const index = i * snakePathVecSize;
        if (index >= snakePathLen / snakePathVecSize) break;
        const x = 0 + index;
        const y = 1 + index;

        if (snakePath[x] == Empty and snakePath[y] == Empty) break;
        assert(snakePath[x] != Empty and snakePath[y] != Empty);

        const currentNode = Vector.new(snakePath[x], snakePath[y]);
        const prevNode = Vector.new(snakePath[x - snakePathVecSize], snakePath[y - snakePathVecSize]);

        if (Game.showPath) drawLineFrom(currentNode, prevNode);

        if (remaningCircles <= 0) continue;
        if (currentNode.distance(lastBodyNodeUsed) < Snake.diameter) continue;

        if (!Game.showBody) continue;
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
    const x = @divTrunc(Screen.width, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), Screen.centerY, @intCast(fontSize), color orelse rl.WHITE);
}
