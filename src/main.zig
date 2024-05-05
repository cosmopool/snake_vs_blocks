const std = @import("std");
const Helper = @import("helper.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;

const Vector2 = @import("vector.zig").Vector2;

const rl = @cImport({
    @cInclude("raylib.h");
});

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

const snakeVecSize = 2;
var snakeSize: i16 = 20;
const circleRadius = 10;
const circleDiameter = 20;
const circleSize = circleRadius * 2;
const margin: f16 = 4;
const leftScreenLimit = circleSize;
const rightScreenLimit = screenWidth - circleSize;
const visibleSnakeSizeLimit: usize = std.math.round((screenHeight / 2) / (circleSize + margin)) * snakeVecSize;
var visibleTail = visibleSnakeSizeLimit;
const speed: f32 = 200;

var snakeHeadX: f32 = centerX;
var snakeHeadY: f32 = centerY;
var direction = Vector2{ .x = centerX, .y = centerY };

const boardSpeed = 100;
const snakePathLen = 200;
var snakePathX: [snakePathLen]?f32 = undefined;
var snakePathY: [snakePathLen]?f32 = undefined;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(screenWidth, screenHeight, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(fps);

    snakePathX[0] = centerX;
    snakePathY[0] = centerY;

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
    try updateSnakePosition();
}

fn updateSnakePosition() !void {
    // limit mouse position to window boundaries
    const mouse = Vector2{
        .x = std.math.clamp(rl.GetMousePosition().x, circleRadius, screenWidth - circleRadius),
        .y = std.math.clamp(rl.GetMousePosition().y, circleRadius, centerY - circleRadius),
    };
    assert(mouse.x >= 0 and mouse.x <= screenWidth);
    assert(mouse.y >= 0 and mouse.y <= screenHeight);

    // calculate mouse relative distance from snake head
    const mouseDiff = Vector2{
        .x = mouse.x - snakeHeadX,
        .y = mouse.y - snakeHeadY,
    };

    // calculate snake head direction vector
    const magnitude: f32 = std.math.sqrt(mouseDiff.x * mouseDiff.x + mouseDiff.y * mouseDiff.y);
    const currentDirection = Vector2{
        .x = mouseDiff.x / magnitude,
        .y = mouseDiff.y / magnitude,
    };

    // if snake changed direction set a checkpoint in it's path
    if (didChangeDirection(&direction, &currentDirection)) {
        assert(direction.direction() != currentDirection.direction());
        addCheckpointInPath(.{ .x = snakeHeadX, .y = snakeHeadY });
    }
    direction = currentDirection;

    // update snake head position
    // snake.head.x += direction.x * 3000 * deltaTime;
    snakeHeadX = mouse.x;
    assert(snakeHeadX >= 0 and snakeHeadX <= screenWidth);
}

fn didChangeDirection(old: *const Vector2, current: *const Vector2) bool {
    return old.direction() != current.direction();
}

fn updateSnakePathPosition(deltaTime: f32) void {
    var i: i16 = snakePathLen - 1;
    while (i >= 0) : (i -= 1) {
        assert(i < snakePathLen);
        assert(i >= 0);

        const index: u16 = @abs(i);
        assert((snakePathX[index] != null and snakePathY[index] != null) or (snakePathX[index] == null and snakePathY[index] == null));
        const currentY = snakePathY[index] orelse continue;

        // update checkpoint position
        const newPositionY = currentY + (boardSpeed * deltaTime);
        if (newPositionY > screenHeight + 100) {
            snakePathX[index] = null;
            snakePathY[index] = null;
        } else {
            snakePathY[index] = newPositionY;
        }
        if (index == 0) break;
    }
}

fn addCheckpointInPath(checkpoint: Vector2) void {
    if (snakePathX[0] == null and snakePathY[0] == null) {
        snakePathX[0] = checkpoint.x;
        snakePathY[0] = checkpoint.y;
        return;
    }

    var i: i16 = snakePathLen - 1;
    while (i >= 0) : (i -= 1) {
        assert(i < snakePathLen);
        assert(i >= 0);

        const index: u16 = @abs(i);
        const currentX = snakePathX[index];
        const currentY = snakePathY[index];
        assert((currentX != null and currentY != null) or (currentX == null and currentY == null));
        if (currentX == null and currentY == null) continue;

        // shift values to the right
        if (index != snakePathLen - 1) {
            snakePathX[index + 1] = currentX;
            snakePathY[index + 1] = currentY;
        }

        // add new checkpoint values
        if (index == 0) {
            snakePathX[0] = checkpoint.x;
            snakePathY[0] = checkpoint.y;
        }
    }
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

fn drawCirclesBetween(start: *const Vector2, end: *const Vector2, remaningCircles: *i16) void {
    const path = start.directionVec(end);
    const distance = path.magnitude();
    const howManyFit = @ceil(distance / circleDiameter);
    const circle = path.normalize();

    for (0..@intFromFloat(howManyFit)) |i| {
        if (remaningCircles.* == 0) break;
        const n: f32 = @floatFromInt(i);
        const scale = circle.multiply(circleDiameter * n);
        const x = scale.x + start.x;
        const y = scale.y + start.y;
        if (y > screenHeight + 50) break;
        rl.DrawCircle(@intFromFloat(x), @intFromFloat(y), circleRadius, rl.RED);
        remaningCircles.* -= 1;
    }

    rl.DrawLine(
        @intFromFloat(start.x),
        @intFromFloat(start.y),
        @intFromFloat(end.x),
        @intFromFloat(end.y),
        rl.BLUE,
    );
}

fn drawSnake() !void {
    const endPosX = -direction.x * 100 + snakeHeadX;
    const endPosY = -direction.y * 100 + snakeHeadY;

    // direction vector
    rl.DrawLine(
        @intFromFloat(snakeHeadX),
        @intFromFloat(snakeHeadY),
        @intFromFloat(endPosX),
        @intFromFloat(endPosY),
        rl.WHITE,
    );
    drawBodyNodeAt(snakeHeadX, snakeHeadY);

    var remaningCircles: i16 = snakeSize;
    var idx: u16 = 0;
    while (idx < snakePathLen) : (idx += 1) {
        const pathX = snakePathX[idx] orelse break;
        const pathY = snakePathY[idx] orelse break;
        const currentNode = Vector2{ .x = pathX, .y = pathY };

        var prevNode: Vector2 = undefined;
        if (idx == 0) {
            // n = 1;
            prevNode = Vector2{ .x = snakeHeadX, .y = snakeHeadY };
        } else {
            // n = @floatFromInt(idx);
            prevNode = Vector2{
                .x = snakePathX[idx - 1] orelse break,
                .y = snakePathY[idx - 1] orelse break,
            };
        }

        drawCirclesBetween(&prevNode, &currentNode, &remaningCircles);
    }
}

fn drawAtCenter(text: [*c]const u8, size: ?usize, color: ?Color) void {
    const fontSize = size orelse 30;
    const textSize = rl.MeasureText(text, @intCast(fontSize));
    const x = @divTrunc(screenWidth, 2) - @divTrunc(textSize, 2);
    rl.DrawText(text, @intCast(x), @intFromFloat(screenHeight / 2), @intCast(fontSize), color orelse rl.WHITE);
}
