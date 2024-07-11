class RotationGizmo {
    // drawing gizmo
    // click detection
    // drag detection
    // reading values out
    // updating cursor
    // clicking update

    quat rot = quat(0, 0, 0, 1);
    quat tmpRot = quat(0, 0, 0, 1);
    string name;

    RotationGizmo(const string &in name) {
        this.name = name;
    }

    RotationGizmo@ SetRotation(const quat &in r) {
        rot = r;
        return this;
    }

    RotationGizmo@ AddTmpRotation(Axis axis, float delta_theta) {
        tmpRot *= quat(AxisToVec(axis), delta_theta);
    }

    RotationGizmo@ ApplyTmpRotation() {
        rot *= tmpRot;
        tmpRot = quat(0, 0, 0, 1);
    }

    void DrawUIWindow() {
        // 10 meters in front of camera
        vec3 pos = Camera::GetProjectionMatrix() * vec3(0, 0, -10);
        DrawElipseControl(pos, rot);
        DrawElipseControl(pos, rot * ROT_Q_AROUND_UP);
        DrawElipseControl(pos, rot * ROT_Q_AROUND_FWD);
        UX::PushInvisibleWindowStyle();
        if (UI::Begin("###rgz"+name)) {
            vec2 wp = UI::GetWindowPos() / g_scale;
            UI::Text("test window");
            UI::Text("pos: " + pos.ToString());
            UI::Text("rot: " + rot.ToString());
        }
        UI::End();
        UX::PopInvisibleWindowStyle();
    }

    void DrawElipseControl(vec2 winPos, const quat &in rot) {

    }

    void DrawProjectedCircle(vec3 &in pos, quat&in rot, float scale = 1.0) {
        // Mat4_GetEllipseData
        // world -> translate only
        // local -> rotate only
        auto pwr = Camera::GetProjectionMatrix() * mat4::Translate(pos) * mat4::Rotate(rot.Angle(), rot.Axis());
        vec3 rrt;
        Mat4_GetEllipseData(pwr, rrt, scale);
        nvg::Reset();
        nvg::Rotate(rrt.z);
        nvg::BeginPath();
        nvg::StrokeColor(vec4(1, 1, 1, 1));
        nvg::StrokeWidth(2);
        nvg::Ellipse(vec2(pwr.tx, pwr.ty), rrt.x, rrt.y);
        nvg::Stroke();
        nvg::ClosePath();
    }
}

const quat ROT_Q_AROUND_UP = quat(UP, HALF_PI);
const quat ROT_Q_AROUND_FWD = quat(FORWARD, HALF_PI);


void Mat4_GetEllipseData(const mat4 &in m, vec3 &out r1_r2_theta, float scale = 1.0) {
    auto c1 = vec2(m.xx, m.xy);
    auto c2 = vec2(m.yx, m.yy);
    auto c1Len = c1.Length();
    auto c2Len = c2.Length();
    vec2 c;
    // swap .y = c{1,2}Len to rotate by 90deg
    if (c1Len < c2Len) {
        c = c2;
        r1_r2_theta.y = c2Len;
    } else {
        c = c1;
        r1_r2_theta.y = c1Len;
    }
    r1_r2_theta.z = Math::Atan2(c.y, c.x);
    r1_r2_theta.x = scale;
    r1_r2_theta.y *= scale;
}


namespace UX {
    void PushInvisibleWindowStyle() {
        UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::TitleBg, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::TitleBgActive, vec4(0, 0, 0, 0));
    }

    void PopInvisibleWindowStyle() {
        UI::PopStyleColor(4);
    }
}
