namespace NG {
    enum Mat3Val0Type {
        Zero = 0,
        Identity = 1,
    }

    enum Mat3Val1Type {
        Scale = 2,
        Rotate = 3,
    }

    enum Mat3Val2Type {
        Scale = 2,
        Translate = 4,
        // Shear = 5,
    }

    enum Mat3Func1 {
        Transpose = 7,
        Inverse = 8,
    }
}
