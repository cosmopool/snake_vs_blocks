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
const Screen = @import("entities.zig").Screen.new();
var Game = @import("entities.zig").Game.new();
var Snake = @import("entities.zig").Snake.new();
var Path = @import("entities.zig").Path.new();

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    rl.InitWindow(Screen.width, Screen.height, "hello world!");
    defer rl.CloseWindow();
    rl.SetTargetFPS(Screen.fps);

    for (0..Path.len) |i| {
        const index = i * Path.vecSize;
        if (index >= Path.len) break;
        const x = 0 + index;
        const y = 1 + index;
        Path.positions[x] = Empty;
        Path.positions[y] = Empty;
    }
    Path.positions[0] = Screen.centerX;
    Path.positions[1] = Screen.centerY;

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

    // last position in Path.path array
    const lastPathPos = Vector.new(Path.positions[2], Path.positions[3]);

    // create a new node in Path.path
    const distanceToLastPosition = mouse.distance(lastPathPos);
    if (distanceToLastPosition >= Path.resolution) {
        addNodeInPath(mouse);
    }

    // update snake head position
    Path.positions[0] = mouse.x();
    assert(Path.positions[0] >= 0 and Path.positions[0] <= Screen.width);
}

fn updateSnakePathPosition(deltaTime: f32) void {
    for (0..Path.len) |i| {
        if (i == 0) continue;
        const index = i * Path.vecSize;
        if (index > Path.len) break;
        const x = 0 + index;
        const y = 1 + index;

        if (Path.positions[x] == Empty and Path.positions[y] == Empty) break;
        assert(Path.positions[x] != Empty and Path.positions[y] != Empty);

        // update checkpoint position
        const newPositionY = Path.positions[y] + (Game.boardSpeed * deltaTime);
        if (newPositionY > Screen.height + 100) {
            Path.positions[x] = Empty;
            Path.positions[y] = Empty;
        } else {
            Path.positions[y] = newPositionY;
        }
    }
}

fn addNodeInPath(newNode: Vector) void {
    var i: usize = Path.len / Path.vecSize;
    while (i > 1) : (i -= Path.vecSize) {
        if (i >= Path.len / Path.vecSize) continue;
        const x = 0 + i;
        const y = 1 + i;

        if (Path.positions[x] == Empty and Path.positions[y] == Empty) continue;
        assert(Path.positions[x] != Empty and Path.positions[y] != Empty);

        // shift values to the right
        Path.positions[x + 2] = Path.positions[x];
        Path.positions[y + 2] = Path.positions[y];
    }

    // add new checkpoint values
    Path.positions[2] = newNode.x();
    Path.positions[3] = newNode.y();
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
    drawBodyNodeAt(Path.positions[0], Path.positions[1]);

    // draw body
    var lastBodyNodeUsed = Vector.new(0, 0);
    var remaningCircles: i16 = Snake.size;
    for (1..Path.len) |i| {
        const index = i * Path.vecSize;
        if (index >= Path.len / Path.vecSize) break;
        const x = 0 + index;
        const y = 1 + index;

        if (Path.positions[x] == Empty and Path.positions[y] == Empty) break;
        assert(Path.positions[x] != Empty and Path.positions[y] != Empty);

        const currentNode = Vector.new(Path.positions[x], Path.positions[y]);
        const prevNode = Vector.new(Path.positions[x - Path.vecSize], Path.positions[y - Path.vecSize]);

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
