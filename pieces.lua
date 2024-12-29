local tetrominoes = {
    {
        color = {1, 0, 0},
        rotations = {
            {{1, 1, 1, 1}},
            {{1}, {1}, {1}, {1}}
        }
    },
    {
        color = {0, 1, 0},
        rotations = {
            {{0, 1, 1}, {1, 1, 0}},
            {{1, 0}, {1, 1}, {0, 1}}
        }
    },
    {
        color = {0, 0, 1},
        rotations = {
            {{1, 1, 0}, {0, 1, 1}},
            {{0, 1}, {1, 1}, {1, 0}}
        }
    },
    {
        color = {1, 1, 0},
        rotations = {
            {{1, 1}, {1, 1}}
        }
    }
}

return tetrominoes

