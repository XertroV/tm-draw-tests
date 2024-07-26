// Game: XZY, Openplanet: XYZ
enum EulerOrder {
    XYZ,
    YXZ,
    ZXY,
    ZYX,
    YZX,
    XZY
}

vec3 EulerFromRotationMatrix(const mat4 &in mat, EulerOrder order = EulerOrder::XZY) {
    float m11 = mat.xx, m12 = mat.xy, m13 = mat.xz,
        m21 = mat.yx, m22 = mat.yy, m23 = mat.yz,
        m31 = mat.zx, m32 = mat.zy, m33 = mat.zz;
    float x, y, z;
    switch (order) {
        case EulerOrder::XYZ:
            y = Math::Asin(Math::Clamp(m13, -1.0, 1.0));
            if (Math::Abs(m13) < 0.9999999) {
                x = Math::Atan2(-m23, m33);
                z = Math::Atan2(-m12, m11);
            } else {
                x = Math::Atan2(m32, m22);
                z = 0;
            }
            return vec3(x, y, z) * -1.;
        case EulerOrder::YXZ:
            x = Math::Asin(-Math::Clamp(m23, -1.0, 1.0));
            if (Math::Abs(m23) < 0.9999999) {
                y = Math::Atan2(m13, m33);
                z = Math::Atan2(m21, m22);
            } else {
                y = Math::Atan2(-m31, m11);
                z = 0;
            }
            return vec3(x, y, z) * -1.;
        case EulerOrder::ZXY:
            x = Math::Asin(Math::Clamp(m32, -1.0, 1.0));
            if (Math::Abs(m32) < 0.9999999) {
                y = Math::Atan2(-m31, m33);
                z = Math::Atan2(-m12, m22);
            } else {
                y = 0;
                z = Math::Atan2(m21, m11);
            }
            return vec3(x, y, z) * -1.;
        case EulerOrder::ZYX:
            y = Math::Asin(-Math::Clamp(m31, -1.0, 1.0));
            if (Math::Abs(m31) < 0.9999999) {
                x = Math::Atan2(m32, m33);
                z = Math::Atan2(m21, m11);
            } else {
                x = 0;
                z = Math::Atan2(-m12, m22);
            }
            return vec3(x, y, z) * -1.;
        case EulerOrder::YZX:
            z = Math::Asin(Math::Clamp(m21, -1.0, 1.0));
            if (Math::Abs(m21) < 0.9999999) {
                x = Math::Atan2(-m23, m22);
                y = Math::Atan2(-m31, m11);
            } else {
                x = 0;
                y = Math::Atan2(m13, m33);
            }
            return vec3(x, y, z) * -1.;
        case EulerOrder::XZY:
            z = Math::Asin(-Math::Clamp(m12, -1.0, 1.0));
            if (Math::Abs(m12) < 0.9999999) {
                x = Math::Atan2(m32, m22);
                y = Math::Atan2(m13, m11);
            } else {
                x = Math::Atan2(-m23, m33);
                y = 0;
            }
            return vec3(x, y, z) * -1.;
        default:
            print("EulerFromRotationMatrix: Unknown Euler order: " + tostring(order));
            break;
    }
    return vec3(x, y, z);
}

mat4 EulerToRotationMatrix(vec3 pyr, EulerOrder order) {
    switch (order) {
        case EulerOrder::XYZ:
            return mat4::Rotate(pyr.z, BACKWARD) * mat4::Rotate(pyr.y, UP) * mat4::Rotate(pyr.x, RIGHT);
        case EulerOrder::YXZ:
            return mat4::Rotate(pyr.z, BACKWARD) * mat4::Rotate(pyr.x, RIGHT) * mat4::Rotate(pyr.y, UP);
        case EulerOrder::ZXY:
            return mat4::Rotate(pyr.y, UP) * mat4::Rotate(pyr.x, RIGHT) * mat4::Rotate(pyr.z, BACKWARD);
        case EulerOrder::ZYX:
            return mat4::Rotate(pyr.x, RIGHT) * mat4::Rotate(pyr.y, UP) * mat4::Rotate(pyr.z, BACKWARD);
        case EulerOrder::YZX:
            return mat4::Rotate(pyr.x, RIGHT) * mat4::Rotate(pyr.z, BACKWARD) * mat4::Rotate(pyr.y, UP);
        case EulerOrder::XZY:
            return mat4::Rotate(pyr.y, UP) * mat4::Rotate(pyr.z, BACKWARD) * mat4::Rotate(pyr.x, RIGHT);
        default:
            print("EulerToRotationMatrix: Unknown Euler order: " + tostring(order));
            break;
    }
    return mat4::Identity();
}

mat4 QuatToMat4(quat q) {
    return mat4::Rotate(q.Angle(), q.Axis());
}

void FindRotOrder() {
    uint[] count = array<uint>(6);
    for (uint i = 0; i < 20; i++) {
        auto e = RandEuler();
        auto mXYZ = EulerToRotationMatrix(e, EulerOrder::XYZ);
        auto mYXZ = EulerToRotationMatrix(e, EulerOrder::YXZ);
        auto mZXY = EulerToRotationMatrix(e, EulerOrder::ZXY);
        auto mZYX = EulerToRotationMatrix(e, EulerOrder::ZYX);
        auto mYZX = EulerToRotationMatrix(e, EulerOrder::YZX);
        auto mXZY = EulerToRotationMatrix(e, EulerOrder::XZY);
        auto mOpenplanet = QuatToMat4(quat(e));
        auto eXYZ = EulerFromRotationMatrix(mXYZ /*mXYZ*/, EulerOrder::XYZ);
        auto eYXZ = EulerFromRotationMatrix(mYXZ /*mYXZ*/, EulerOrder::YXZ);
        auto eZXY = EulerFromRotationMatrix(mZXY /*mZXY*/, EulerOrder::ZXY);
        auto eZYX = EulerFromRotationMatrix(mZYX /*mZYX*/, EulerOrder::ZYX);
        auto eYZX = EulerFromRotationMatrix(mYZX /*mYZX*/, EulerOrder::YZX);
        auto eXZY = EulerFromRotationMatrix(mXZY /*mXZY*/, EulerOrder::XZY);
        vec3 compareTarget = e;
        if (AnglesVeryClose(compareTarget, eXYZ)) count[uint(EulerOrder::XYZ)]++;
        else {
            print("Euler: " + e.ToString());
            print("eXYZ: " + eXYZ.ToString());
        }
        if (AnglesVeryClose(compareTarget, eYXZ)) count[uint(EulerOrder::YXZ)]++;
        else {
            print("Euler: " + e.ToString());
            print("eYXZ: " + eYXZ.ToString());
        }
        if (AnglesVeryClose(compareTarget, eZXY)) count[uint(EulerOrder::ZXY)]++;
        else {
            print("Euler: " + e.ToString());
            print("eZXY: " + eZXY.ToString());
        }
        if (AnglesVeryClose(compareTarget, eZYX)) count[uint(EulerOrder::ZYX)]++;
        else {
            print("Euler: " + e.ToString());
            print("eZYX: " + eZYX.ToString());
        }
        if (AnglesVeryClose(compareTarget, eYZX)) count[uint(EulerOrder::YZX)]++;
        else {
            print("Euler: " + e.ToString());
            print("eYZX: " + eYZX.ToString());
        }
        if (AnglesVeryClose(compareTarget, eXZY)) count[uint(EulerOrder::XZY)]++;
        else {
            print("Euler: " + e.ToString());
            print("eXZY: " + eXZY.ToString());
        }
    }
    print("Results:");
    for (uint i = 0; i < 6; i++) {
        print("Order " + tostring(EulerOrder(i)) + ": " + count[i]);
    }
}


float Rand01() {
    return Math::Rand(0.0, 1.0);
}

float RandM1To1() {
    return Math::Rand(-1.0, 1.0);
}

vec2 RandVec2Norm() {
    return vec2(RandM1To1(), RandM1To1()).Normalized();
}

vec3 RandVec3() {
    return vec3(RandM1To1(), RandM1To1(), RandM1To1());
}

vec3 RandVec3Norm() {
    return vec3(RandM1To1(), RandM1To1(), RandM1To1()).Normalized();
}

vec3 RandEuler() {
    return vec3(Rand01() * TAU - PI, Rand01() * TAU - PI, Rand01() * TAU - PI) * .5;
}

bool AnglesVeryClose(const quat &in q1, const quat &in q2, bool allowConjugate = false) {
    auto dot = Math::Abs(q1.x*q2.x + q1.y*q2.y + q1.z*q2.z + q1.w*q2.w);
    // technically, the angles are only the same if the quaternions are the same, but sometimes the game will give us the conjugate (e.g., circle cps seem to have this happen)
    // example: i tell it to place at PYR 0,180,90, but it places 180,0,90
    // idk, adding < 0.0001 fixes it, though.
    return dot > 0.9999 || (allowConjugate && dot < 0.0001);
}

bool AnglesVeryClose(const vec3 &in a, const vec3 &in b) {
    return AnglesVeryClose(quat(a), quat(b), true);
    // return Math::Abs(a.x - b.x) < 0.0001 && Math::Abs(a.y - b.y) < 0.0001 && Math::Abs(a.z - b.z) < 0.0001;
}

Meta::PluginCoroutine@ _findRotOrder = startnew(FindRotOrder);
