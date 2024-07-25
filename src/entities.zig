pub const Empty = -1.11;

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
    const _height: i16 = 800;

    fps: f32 = 60,
    width: i16 = _width,
    height: i16 = _height,
    centerX: f32,
    centerY: f32,
    cellSize: f32,

    pub fn new() Screen {
        return Screen{
            .centerX = @divTrunc(_width, 2),
            .centerY = @divTrunc(_height, 2),
            .cellSize = @divTrunc(_width, 5),
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
    const _len: usize = 1000;

    /// Store positions as (x, y) vector
    positions: [_len]f32 = undefined,
    /// [Path.positions] length
    len: usize = _len,
    /// The number of elements in the vectorized data array [Path.positions].
    ///
    /// Represents the total count of elements stored in a contiguous memory block.
    /// Used for iterating over and processing the data efficiently.
    ///
    /// **Note:** DO NOT MUTATE this variable to avoid undefined behavior.
    vecSize: usize = 2,
    /// Minimum space between two positions in [Path.positions]
    resolution: f32 = 1,
    /// How much the cursor will increment when searching for a valid place
    /// for a new circle.
    step: f32 = 0.01,

    pub fn new() Path {
        return Path{};
    }
};

pub const Board = struct {
    const _len: usize = 1000;

    /// Store blocks as (x, y, points) vector
    blocks: [_len]f32 = undefined,
    /// Store food as (x, y, points) vector
    foods: [_len]f32 = undefined,
    /// Store food as (x, y, length) vector
    walls: [_len]f32 = undefined,
    /// [Board.cells] length
    len: usize = _len,
    /// The number of elements in the vectorized data array [Board.cells].
    ///
    /// Represents the total count of elements stored in a contiguous memory block.
    /// Used for iterating over and processing the data efficiently.
    ///
    /// **Note:** DO NOT MUTATE this variable to avoid undefined behavior.
    vecSize: usize = 3,

    pub fn new() Board {
        return Board{};
    }
};
