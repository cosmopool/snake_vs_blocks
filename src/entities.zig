pub const Game = struct {
    useMouse: bool = true,
    paused: bool = false,
    gameOver: bool = false,
    showPath: bool = false,
    showBody: bool = true,
    boardSpeed: f32 = 180,

    pub fn new() Game {
        return Game{};
    }
};

pub const Screen = struct {
    const _width: i16 = 400;
    const _height: i16 = 700;

    fps: f32 = 60,
    width: i16 = _width,
    height: i16 = _height,
    centerX: f32,
    centerY: f32,

    pub fn new() Screen {
        return Screen{
            .centerX = @divTrunc(_width, 2),
            .centerY = @divTrunc(_height, 2),
        };
    }
};

pub const Snake = struct {
    const _radius: i8 = 10;
    const _diameter: f32 = _radius * 2;
    const _tolerance: f32 = 0.025;

    size: i16 = 5,
    radius: i8 = _radius,
    diameter: f32 = _diameter,
    minDiameter: f32 = _diameter - _tolerance,
    maxDiameter: f32 = _diameter + _tolerance,
    step: f32 = 0.01,

    pub fn new() Snake {
        return Snake{};
    }
};

pub const Path = struct {
    pub const _len: usize = 1000;

    positions: [_len]f32 = undefined,
    len: usize = _len,
    vecSize: usize = 2,
    resolution: f32 = 1,
    step: f32 = 0.01,

    pub fn new() Path {
        return Path{};
    }
};
