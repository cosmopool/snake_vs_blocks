const std = @import("std");
const Helper = @import("helper.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

const rl = @cImport({
    @cInclude("raylib.h");
});

const Vec2 = @import("vector.zig").Vector2;
const Vector2 = @Vector(2, f32);
const Vector = @import("vector.zig").Vector;

const Empty = 0;

const allocator = std.heap.page_allocator;

const Color = rl.CLITERAL(rl.Color);

var useMouse: bool = false;
var paused: bool = false;
var gameOver = false;
const fps: f32 = 60;
const screenWidth = 400;
const screenHeight = 700;
const centerX = @divTrunc(screenWidth, 2);
const centerY = @divTrunc(screenHeight, 2);

var snakeSize: i16 = 20;
const circleRadius = 10;
const circleDiameter = circleRadius * 2;
const margin: f16 = 4;
const speed: f32 = 200;
const boardSpeed = 100;

var lastPathNodeDirection: i8 = 0;

const snakePathLen = 400;
const snakePathVecSize = 2;
var snakePath: [snakePathLen]f32 = undefined;

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

    // calculate mouse relative distance from snake head
    const mouseDiff = mouse.sub(Vector.new(snakePath[0], snakePath[1])).norm();

    // calculate snake head direction vector
    const diffDirection = mouseDiff.direction();

    // if snake changed direction set a checkpoint in it's path
    if (lastPathNodeDirection != diffDirection) {
        addNodeInPath(mouse);
        lastPathNodeDirection = diffDirection;
    }

    // update snake head position
    snakePath[0] = mouse.x();
    // snakeHead.x += currentDirection.x() * 3000 * deltaTime;
    assert(snakePath[0] >= 0 and snakePath[0] <= screenWidth);
}

fn didChangeDirection(old: *const Vector, current: *const Vector) bool {
    return old.direction() != current.direction();
}

fn updateSnakePathPosition(deltaTime: f32) void {
    for (0..snakePathLen) |i| {
        if (i == 0) continue;
        const index = i * snakePathVecSize;
        if (index > snakePathLen) break;
        const x = 0 + index;
        const y = 1 + index;

        assert((snakePath[x] != Empty and snakePath[y] != Empty) or (snakePath[x] == Empty and snakePath[y] == Empty));
        if (snakePath[x] == Empty and snakePath[y] == Empty) break;

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
        assert((snakePath[x] != Empty and snakePath[y] != Empty) or (snakePath[x] == Empty and snakePath[y] == Empty));
        if (snakePath[x] == Empty and snakePath[y] == Empty) continue;

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

fn drawCirclesBetween(start: *const Vector, end: *const Vector, remaningCircles: *i16) void {
    const path = end.sub(start.*);
    const distance = path.length();
    const howManyFit = @ceil(distance / circleDiameter);
    const circle = path.norm();

    for (0..@intFromFloat(howManyFit)) |i| {
        if (remaningCircles.* == 0) break;
        const n: f32 = @floatFromInt(i);
        const scale = circle.scale(circleDiameter * n);
        const x = scale.x() + start.x();
        const y = scale.y() + start.y();
        if (y > screenHeight + 50) break;
        rl.DrawCircle(@intFromFloat(x), @intFromFloat(y), circleRadius, rl.RED);
        remaningCircles.* -= 1;
    }

    rl.DrawLine(
        @intFromFloat(start.x()),
        @intFromFloat(start.y()),
        @intFromFloat(end.x()),
        @intFromFloat(end.y()),
        rl.BLUE,
    );
}

fn getT(p0: *const Vector2, p1: *const Vector2, t: f32, alpha: f32) f32 {
    const d = p1.* - p0.*;
    const a = d[0] * d[0] + d[1] * d[1];
    const b = std.math.pow(f32, a, alpha * 0.5);
    return b + t;
}

fn catmullRom(p0: *const Vector2, p1: *const Vector2, p2: *const Vector2, p3: *const Vector2, t: f32, alpha: f32) Vector2 {
    // assert(t >= 0 and t <= 1);
    assert(alpha >= 0 and alpha <= 1);

    const t0: f32 = 0.0;
    const t1 = getT(p0, p1, t0, alpha);
    const t2 = getT(p1, p2, t1, alpha);
    const t3 = getT(p2, p3, t2, alpha);
    const tt = std.math.lerp(t1, t2, t);

    if (0.0 == t1) {
        return p1.*;
    }

    const A1 = @as(Vector2, @splat((t1 - tt) / (t1 - t0))) * p0.* + @as(Vector2, @splat((tt - t0) / (t1 - t0))) * p1.*;
    const A2 = @as(Vector2, @splat((t2 - tt) / (t2 - t1))) * p1.* + @as(Vector2, @splat((tt - t1) / (t2 - t1))) * p2.*;
    const A3 = @as(Vector2, @splat((t3 - tt) / (t3 - t2))) * p2.* + @as(Vector2, @splat((tt - t2) / (t3 - t2))) * p3.*;
    const B1 = @as(Vector2, @splat((t2 - tt) / (t2 - t0))) * A1 + @as(Vector2, @splat((tt - t0) / (t2 - t0))) * A2;
    const B2 = @as(Vector2, @splat((t3 - tt) / (t3 - t1))) * A2 + @as(Vector2, @splat((tt - t1) / (t3 - t1))) * A3;
    const C = @as(Vector2, @splat((t2 - tt) / (t2 - t1))) * B1 + @as(Vector2, @splat((tt - t1) / (t2 - t1))) * B2;

    return C;
}

fn drawSnake() !void {
    // draw head
    drawBodyNodeAt(snakePath[0], snakePath[1]);

    // draw body
    var remaningCircles: i16 = snakeSize;
    for (1..snakePathLen) |i| {
        const index = i * snakePathVecSize;
        if (index >= snakePathLen / snakePathVecSize) break;
        const x = 0 + index;
        const y = 1 + index;

        assert((snakePath[x] != Empty and snakePath[y] != Empty) or (snakePath[x] == Empty and snakePath[y] == Empty));
        if (snakePath[x] == Empty and snakePath[y] == Empty) break;

        const currentNode = Vector.new(snakePath[x], snakePath[y]);
        const prevNode = Vector.new(snakePath[x - snakePathVecSize], snakePath[y - snakePathVecSize]);

        drawCirclesBetween(&prevNode, &currentNode, &remaningCircles);

        rl.DrawLine(
            @intFromFloat(prevNode.x()),
            @intFromFloat(prevNode.y()),
            @intFromFloat(currentNode.x()),
            @intFromFloat(currentNode.y()),
            rl.BLUE,
        );

        const p0 = @Vector(2, f32){ prevNode.x(), prevNode.y() };
        const p1 = @Vector(2, f32){ currentNode.x(), currentNode.y() };
        const p2 = @Vector(2, f32){ snakePath[x + snakePathVecSize * 1], snakePath[y + snakePathVecSize * 2] };
        const p3 = @Vector(2, f32){ snakePath[x + snakePathVecSize * 2], snakePath[y + snakePathVecSize * 2] };

        // var i: f32 = 0;
        // while (i <= 1.0) : (i += 0.01) {
        const cat = catmullRom(&p0, &p1, &p2, &p3, @floatFromInt(index), 0.5);
        if (std.math.isNan(cat[0]) or std.math.isNan(cat[1])) break;
        rl.DrawCircle(@intFromFloat(cat[0]), @intFromFloat(cat[1]), circleRadius, rl.YELLOW);
        // }
    }
}

fn drawAtCenter(text: [*c]const u8, size: ?usize, color: ?Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.MeasureText(text, @intCast(fontSize));
    const x = @divTrunc(screenWidth, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), @intFromFloat(screenHeight / 2), @intCast(fontSize), color orelse rl.WHITE);
}
