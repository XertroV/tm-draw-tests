string truncString(const string &in str, int len) {
    if (str.Length > len) {
        return str.SubStr(0, len) + "...";
    }
    return str;
}

string Mat3ToStr(const mat3 &in m) {
    string str = "< ";
    vec3 tmp;
    tmp.x = m.xx;
    tmp.y = m.xy;
    tmp.z = m.xz;
    str += tmp.ToString() + ", \n";
    tmp.x = m.yx;
    tmp.y = m.yy;
    tmp.z = m.yz;
    str += "  " + tmp.ToString() + ", \n";
    tmp.x = m.zx;
    tmp.y = m.zy;
    tmp.z = m.zz;
    str += "  " + tmp.ToString() + " >";
    return str;
}

string Mat4ToStr(const mat4 &in m) {
    string str = "< ";
    vec4 tmp;
    tmp.x = m.xx;
    tmp.y = m.xy;
    tmp.z = m.xz;
    tmp.w = m.xw;
    str += tmp.ToString() + ", \n";
    tmp.x = m.yx;
    tmp.y = m.yy;
    tmp.z = m.yz;
    tmp.w = m.yw;
    str += "  " + tmp.ToString() + ", \n";
    tmp.x = m.zx;
    tmp.y = m.zy;
    tmp.z = m.zz;
    tmp.w = m.zw;
    str += "  " + tmp.ToString() + ", \n";
    tmp.x = m.tx;
    tmp.y = m.ty;
    tmp.z = m.tz;
    tmp.w = m.tw;
    str += "  " + tmp.ToString() + " >";
    return str;
}
