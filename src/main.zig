const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;
const rl = @cImport({
    @cInclude("raylib.h");
});

const Vector = @import("vector.zig").Vector;
const Utils = @import("helper.zig");

const Empty = @import("entities.zig").Empty;
const Color = rl.CLITERAL(rl.Color);
const Screen = @import("entities.zig").Screen.new();
var Game = @import("entities.zig").Game.new();
var Snake = @import("entities.zig").Snake.new();

var boardFullSpeed: f32 = 180;

var frames: usize = 0;
const nodesLen: usize = 3;
var nodesX: [nodesLen]f32 = undefined;
var nodesY: [nodesLen]f32 = undefined;

const mousePathSize = 200;
var mousePathX = RingBuffer(f32, mousePathSize).init();
var mousePathY = RingBuffer(f32, mousePathSize).init();

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(Screen.width, Screen.height, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(Screen.fps);

    for (0..nodesLen - 1) |i| {
        nodesX[i] = Screen.centerX;
        nodesY[i] = @as(f32, @floatFromInt(i)) * Snake.diameter + Screen.centerY;
        // std.debug.print("x: {d}, y: {d}\n", .{ nodesX[i], nodesY[i] });
    }
    // std.debug.print("\n", .{});

    // fix for first position
    rl.SetMousePosition(Screen.centerX, Screen.centerX);

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) Game.paused = !Game.paused;
        if (rl.IsKeyPressed(rl.KEY_D)) Game.showPath = !Game.showPath;
        if (rl.IsKeyPressed(rl.KEY_B)) Game.showBody = !Game.showBody;
        if (rl.IsKeyPressed(rl.KEY_V)) {
            if (boardFullSpeed == 180) {
                boardFullSpeed = 0;
            } else {
                boardFullSpeed = 180;
            }
        }
        if (!Game.paused and !Game.gameOver) try update();
        try draw();
    }
}

fn update() anyerror!void {
    // if (frames > 1) return;
    if (Snake.size < 0) Game.gameOver = true;
    const deltaTime = rl.GetFrameTime();

    try updateSnakePosition(deltaTime);
    try updateSnakeNodes();
    try updateMousePath();
    // frames += 1;
}

fn updateMousePath() !void {
    if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) return;

    const mousePos = rl.GetMousePosition();
    if (mousePos.y < Screen.centerY) {
        mousePathX.reset();
        mousePathY.reset();
        return;
    }
    mousePathX.insert(mousePos.x);
    mousePathY.insert(mousePos.y);
}

fn drawMousePath() !void {
    for (0..mousePathSize) |idx| {
        const x = mousePathX.elementAt(idx) orelse break;
        const y = mousePathY.elementAt(idx) orelse break;
        rl.DrawCircle(
            @intFromFloat(x),
            @intFromFloat(y),
            2,
            rl.YELLOW,
        );
    }
}

fn updateSnakeNodes() !void {
    for (1..nodesLen - 1) |i| {
        assert(i != 0);

        if (nodesX[i] == Empty and nodesY[i] == Empty) break;
        assert(nodesX[i] != Empty and nodesY[i] != Empty);

        const node = Vector.new(nodesX[i], nodesY[i]);
        const anchor = Vector.new(nodesX[i - 1], nodesY[i - 1]);

        // const factor = @as(f32, @floatFromInt(Snake.radius)) / anchor.distance(node);
        // const distance = Vector.new(
        //     nodesX[i - 1] - nodesX[i],
        //     nodesY[i - 1] - nodesY[i],
        // );
        const newPosition = anchor.sub(node).norm().scale(Snake.diameter);
        // const newPosition = node.scale(factor);
        rl.DrawLine(
            @intFromFloat(node.x()),
            @intFromFloat(node.y()),
            @intFromFloat(newPosition.x() + Screen.centerX),
            @intFromFloat(newPosition.y() + Screen.centerY),
            rl.BLUE,
        );
        nodesX[i] = newPosition.x() + Screen.centerX;
        nodesY[i] = @as(f32, @floatFromInt(i)) * Snake.diameter + Screen.centerY + newPosition.y();
        // std.debug.print("x: {d}, y: {d}\n", .{ newPosition.x(), newPosition.y() });

        // const h = std.math.hypot(nodesX[i], nodesY[i]);
        // const factor: f32 = Snake.diameter / h;
        // std.debug.print("factor: {d}\n", .{factor});
        // const valX: f32 = nodesX[i] * factor;
        // const valY: f32 = nodesY[i] * factor;
        // // const valX: f32 = Snake.diameter * (nodesX[i] / h);
        // // const valY: f32 = Snake.diameter * (nodesY[i] / h);
        // nodesX[i] = valX + Screen.centerX;
        // nodesY[i] = @as(f32, @floatFromInt(i)) * @as(f32, @floatFromInt(Snake.radius)) + Screen.centerY + valY;
        // std.debug.print("x: {d}, y: {d}\n", .{ valX, valY });

        // std.debug.print("\n", .{});
    }
}

fn updateSnakePosition(deltaTime: f32) !void {
    // current head position
    const lastPosition = Vector.new(nodesX[0], nodesY[0]);

    // limit mouse position to window boundaries
    const radius: f32 = @floatFromInt(Snake.radius);
    const screenWidthLimit: f32 = Screen.width - radius;

    // get mouse X position
    const mouseX = std.math.clamp(rl.GetMousePosition().x, radius, screenWidthLimit);
    assert(mouseX >= 0 and mouseX <= Screen.width);

    // calculate new position
    var newPosition = Vector.new(
        std.math.lerp(lastPosition.x(), mouseX, deltaTime * 10),
        Screen.centerY,
    );
    assert(newPosition.x() >= 0 and newPosition.x() <= Screen.width);

    // update snake head position
    nodesX[0] = newPosition.x();
}

fn draw() anyerror!void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(rl.BLACK);

    try drawSnake();
    try drawMousePath();

    if (Game.gameOver) drawAtCenter("GAME OVER", 50, null);
    if (Game.paused) drawAtCenter("PAUSED", null, null);

    rl.DrawFPS(rl.GetScreenWidth() - 95, 10);
}

fn drawBodyNodeAt(x: f32, y: f32) void {
    rl.DrawCircle(@intFromFloat(x), @intFromFloat(y), @floatFromInt(Snake.radius), rl.RED);
}

fn drawSnake() !void {
    var pointsText: [2]u8 = undefined;
    _ = try std.fmt.bufPrint(&pointsText, "{d}", .{Snake.size});

    rl.DrawText(
        &pointsText,
        @intFromFloat(nodesX[0] + 15),
        @intFromFloat(nodesY[0] - 15),
        10,
        rl.WHITE,
    );

    for (0..nodesLen - 1) |i| {
        if (nodesX[i] == Empty and nodesY[i] == Empty) break;
        assert(nodesX[i] != Empty and nodesY[i] != Empty);

        drawBodyNodeAt(nodesX[i], nodesY[i]);
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
