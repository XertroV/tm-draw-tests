namespace MathX {


    shared bool Within(vec3 &in pos, vec3 &in min, vec3 &in max) {
        return pos.x >= min.x && pos.x <= max.x
            && pos.y >= min.y && pos.y <= max.y
            && pos.z >= min.z && pos.z <= max.z;
    }
    shared bool Within(nat3 &in pos, nat3 &in min, nat3 &in max) {
        return pos.x >= min.x && pos.x <= max.x
            && pos.y >= min.y && pos.y <= max.y
            && pos.z >= min.z && pos.z <= max.z;
    }
    shared bool Within(vec2 &in pos, vec4 &in rect) {
        return pos.x >= rect.x && pos.x < (rect.x + rect.z)
            && pos.y >= rect.y && pos.y < (rect.y + rect.w);
    }


    float[]@ Sin(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Sin(arr[i]);
        }
        return output;
    }

    float[]@ Cos(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Cos(arr[i]);
        }
        return output;
    }

    float[]@ Tan(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Tan(arr[i]);
        }
        return output;
    }

    float[]@ Asin(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Asin(arr[i]);
        }
        return output;
    }

    float[]@ Acos(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Acos(arr[i]);
        }
        return output;
    }

    float[]@ Atan(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Atan(arr[i]);
        }
        return output;
    }

    float[]@ Atan2(const float[] &in arr1, const float[] &in arr2, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::Atan2(arr1[i], arr2[i]);
        }
        return output;
    }

    float[]@ Sqrt(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Sqrt(arr[i]);
        }
        return output;
    }

    float[]@ Pow(const float[] &in arr, float power, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Pow(arr[i], power);
        }
        return output;
    }

    float[]@ Pow(const float[] &in arr, const float[] &in power, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Pow(arr[i], power[i]);
        }
        return output;
    }

    float[]@ Exp(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Exp(arr[i]);
        }
        return output;
    }

    float[]@ Log(const float[] &in arr, float base, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Log(arr[i]) / Math::Log(base);
        }
        return output;
    }

    float[]@ Log(const float[] &in arr, const float[] &in base, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Log(arr[i]) / Math::Log(base[i]);
        }
        return output;
    }

    float[]@ Ln(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Log(arr[i]);
        }
        return output;
    }

    float[]@ Log2(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Log(arr[i]) / Math::Log(2);
        }
        return output;
    }

    float[]@ Log10(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Log10(arr[i]);
        }
        return output;
    }

    float[]@ Abs(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Abs(arr[i]);
        }
        return output;
    }

    float[]@ Floor(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Floor(arr[i]);
        }
        return output;
    }

    float[]@ Ceil(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Ceil(arr[i]);
        }
        return output;
    }

    float[]@ Round(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Round(arr[i]);
        }
        return output;
    }

    float[]@ Round(const float[] &in arr, int dps, float[]@ output) {
        float factor = Math::Pow(10, dps);
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Round(arr[i], dps);
        }
        return output;
    }

    float[]@ Round(const float[] &in arr, const float[] &in dps, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Round(arr[i], int(dps[i]));
        }
        return output;
    }

    float[]@ ToDeg(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::ToDeg(arr[i]);
        }
        return output;
    }

    float[]@ ToRad(const float[] &in arr, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::ToRad(arr[i]);
        }
        return output;
    }

    float[]@ Min(const float[] &in arr1, const float[] &in arr2, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::Min(arr1[i], arr2[i]);
        }
        return output;
    }

    float[]@ Max(const float[] &in arr1, const float[] &in arr2, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::Max(arr1[i], arr2[i]);
        }
        return output;
    }

    float[]@ Clamp(const float[] &in arr, float min, float max, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Clamp(arr[i], min, max);
        }
        return output;
    }

    float[]@ Clamp(const float[] &in arr, const float[] &in min, const float[] &in max, float[]@ output) {
        output.Resize(arr.Length);
        for (uint i = 0; i < arr.Length; i++) {
            output[i] = Math::Clamp(arr[i], min[i], max[i]);
        }
        return output;
    }

    float[]@ Lerp(const float[] &in arr1, const float[] &in arr2, float t, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::Lerp(arr1[i], arr2[i], t);
        }
        return output;
    }

    float[]@ Lerp(const float[] &in arr1, const float[] &in arr2, const float[] &in t, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::Lerp(arr1[i], arr2[i], t[i]);
        }
        return output;
    }

    float[]@ InvLerp(const float[] &in arr1, const float[] &in arr2, const float[] &in arr3, float[]@ output) {
        output.Resize(arr1.Length);
        for (uint i = 0; i < arr1.Length; i++) {
            output[i] = Math::InvLerp(arr1[i], arr2[i], arr3[i]);
        }
        return output;
    }
}
