RotationGizmo@ testGizmo;

const int CIRCLE_SEGMENTS = 256; // 64;
vec3[] circleAroundY;
vec3[] circleAroundX;
vec3[] circleAroundZ;
array<vec3>@[] circlesAroundXYZ;
array<bool>[] circlesAroundIsNearSide;

void InitCirclesAround() {
    circleAroundY.Resize(CIRCLE_SEGMENTS);
    circleAroundX.Resize(CIRCLE_SEGMENTS);
    circleAroundZ.Resize(CIRCLE_SEGMENTS);
    float dtheta = TAU / CIRCLE_SEGMENTS;
    float theta = 0.;
    for (int i = 0; i < CIRCLE_SEGMENTS; i++) {
        circleAroundY[i] = vec3(Math::Cos(theta), 0, Math::Sin(theta));
        circleAroundX[i] = vec3(0, Math::Cos(theta), Math::Sin(theta));
        circleAroundZ[i] = vec3(Math::Cos(theta), Math::Sin(theta), 0);
        theta += dtheta;
    }
    circlesAroundXYZ.RemoveRange(0, circlesAroundXYZ.Length);
    circlesAroundXYZ.InsertLast(circleAroundX);
    circlesAroundXYZ.InsertLast(circleAroundY);
    circlesAroundXYZ.InsertLast(circleAroundZ);
    //--
    circlesAroundIsNearSide.RemoveRange(0, circlesAroundIsNearSide.Length);
    for (int i = 0; i < 3; i++) {
        circlesAroundIsNearSide.InsertLast(array<bool>(CIRCLE_SEGMENTS));
    }
}

vec4[] circleColors = {
    vec4(1, 0, 0, 1),
    vec4(0, 1, 0, 1),
    vec4(0, 0, 1, 1)
};

const quat DEFAULT_QUAT = quat(0,0,0,1);

class RotationGizmo {
    // drawing gizmo
    // click detection
    // drag detection
    // reading values out
    // updating cursor
    // clicking update

    // quat rot = quat(0,0,0,1);
    mat4 rot = mat4::Rotate(0, UP);
    mat4 tmpRot = mat4::Rotate(0, UP);
    string name;

    RotationGizmo(const string &in name) {
        this.name = name;
        if (circleAroundX.Length == 0) {
            InitCirclesAround();
        }
    }

    RotationGizmo@ SetRotation(const mat4 &in r) {
        rot = r;
        return this;
    }

    RotationGizmo@ AddTmpRotation(Axis axis, float delta_theta) {
        tmpRot = tmpRot * mat4::Rotate(delta_theta, (rot * AxisToVec(axis)).xyz);
        return this;
    }

    RotationGizmo@ SetTmpRotation(Axis axis, float theta) {
        tmpRot = mat4::Rotate(theta, (rot * AxisToVec(axis)).xyz);
        return this;
    }

    RotationGizmo@ ApplyTmpRotation() {
        rot = rot * tmpRot;
        tmpRot = mat4::Identity();
        return this;
    }

    Axis lastClosestAxis = Axis::X;
    float lastClosestMouseDist = 1000000.;

    bool isMouseDown = false;
    uint mouseDownStart = 0;
    vec2 mouseDownPos;
    // the direction from center of circle to this point -- used to take dot product of drag delta to decide how much to rotate
    vec2 radialDir;

    vec2 mousePos;
    mat4 withTmpRot;
    vec3 worldPos;
    vec3 lastWorldPos;
    vec3 lastScreenPos;
    vec2 centerScreenPos;
    bool shouldDrawGizmo = true;

    void DrawCirclesManual(vec3 pos, float scale = 1.0) {
        camPos = Camera::GetCurrentPosition();
        mousePos = UI::GetMousePos();
        withTmpRot = (rot * tmpRot);
        float closestMouseDist = 1000000.;
        vec3 closestRotationPoint;
        Axis closestAxis;
        float tmpDist;
        float c2pLen2 = (pos - camPos).LengthSquared();
        shouldDrawGizmo = true || Camera::IsBehind(pos) || c2pLen2 < (scale * scale);
        if (!shouldDrawGizmo) {
            if (c2pLen2 < (scale * scale)) trace('c2pLen2 < (scale * scale)');
            else trace('Camera::IsBehind(pos)');
            return;
        }
        centerScreenPos = Camera::ToScreen(pos).xy;
        int segSkip = 4; // c2pLen2 > 40. ? 4 : 2;
        bool isNearSide = false;

        for (int c = 0; c < 3; c++) {
            bool thicken = lastClosestAxis == Axis(c) && lastClosestMouseDist < 200.;
            nvg::Reset();
            nvg::BeginPath();
            nvg::StrokeWidth(thicken ? 5 : 2);
            // nvg::Circle(mousePos, 5.);
            auto @circle = circlesAroundXYZ[c];
            auto col = circleColors[c];
            int i = 0;
            int imod;
            worldPos = (withTmpRot * circle[i]).xyz * scale + pos;
            if (Math::IsNaN(worldPos.LengthSquared())) {
                worldPos = circle[i] * scale + pos;
            }
            if (isMouseDown) {
                isNearSide = circlesAroundIsNearSide[c][0];
            } else {
                isNearSide = (worldPos - camPos).LengthSquared() < c2pLen2;
            }
            bool wasNearSide = isNearSide;
            nvg::StrokeColor(isNearSide ? col : col * 0.5);
            vec3 p1 = Camera::ToScreen(worldPos);
            nvg::MoveTo(p1.xy);
            for (i = 0; i <= CIRCLE_SEGMENTS; i += 4) {
                imod = i % CIRCLE_SEGMENTS;
                worldPos = (withTmpRot * circle[imod]).xyz * scale + pos;
                if (Math::IsNaN(worldPos.LengthSquared())) {
                    trace('worldPos is NaN');
                    trace('circle[imod]: ' + circle[imod].ToString());
                    // trace('withTmpRot: ' + withTmpRot.ToString());
                    // worldPos = circle[i] * scale + pos;
                    // tmpRot = quat(0,0,0,1);
                }
                if (isMouseDown) {
                    isNearSide = circlesAroundIsNearSide[c][imod];
                } else {
                    isNearSide = (worldPos - camPos).LengthSquared() < c2pLen2;
                    circlesAroundIsNearSide[c][imod] = isNearSide;
                }
                if (isNearSide != wasNearSide) {
                    nvg::Stroke();
                    nvg::ClosePath();
                    nvg::BeginPath();
                    nvg::StrokeColor(isNearSide ? col : col * 0.5);
                    nvg::MoveTo(p1.xy);
                }
                p1 = Camera::ToScreen(worldPos);
                try {
                    if (p1.z > 0) {
                        nvg::MoveTo(p1.xy);
                    } else {
                        nvg::LineTo(p1.xy);
                    }
                } catch {
                    trace('p1: ' + p1.ToString());
                    trace('worldPos: ' + worldPos.ToString());
                    trace('pos: ' + pos.ToString());
                    // trace('withTmpRot: ' + withTmpRot.ToString());
                }
                if (!isMouseDown && (tmpDist = (mousePos - p1.xy).LengthSquared()) <= closestMouseDist) {
                    closestMouseDist = tmpDist;
                    closestRotationPoint = worldPos;
                    closestAxis = Axis(c);
                    radialDir = (p1.xy - lastScreenPos.xy).Normalized();
                    // radialDir = vec2(radialDir.y, -radialDir.x);
                }
                wasNearSide = isNearSide;
                lastWorldPos = worldPos;
                lastScreenPos = p1;
            }
            nvg::Stroke();
            nvg::ClosePath();
        }
        if (!isMouseDown) {
            lastClosestAxis = closestAxis;
            lastClosestMouseDist = closestMouseDist;
            if (IsLMBPressed()) {
                isMouseDown = true;
                mouseDownStart = Time::Now;
                mouseDownPos = mousePos;
                // tmpRot = quat(0,0,0,1);
                tmpRot = mat4::Identity();
            }
        } else if (!IsLMBPressed()) {
            isMouseDown = false;
            ApplyTmpRotation();
        } else if (lastClosestMouseDist < 200.) {
            auto dd = UI::GetMouseDragDelta(UI::MouseButton::Left, 1);
            if (dd.LengthSquared() > 0.) {
                auto mag = Math::Dot(dd.Normalized(), radialDir) * dd.Length() / g_screen.y * TAU;
                trace('mag: ' + mag);
                if (IsShiftDown()) mag *= 0.1;
                if (!Math::IsNaN(mag)) {
                    SetTmpRotation(lastClosestAxis, mag);
                    // trace('lastClosestAxis: ' + tostring(lastClosestAxis) + '; dd: ' + ((dd.x + dd.y) / g_screen.y * TAU));
                    // trace('mag: ' + mag);
                }
                DrawRadialLine();
            }
        }
    }

    void DrawRadialLine() {
        nvg::Reset();
        nvg::BeginPath();
        nvg::StrokeColor(vec4(1, 1, 1, 1));
        nvg::StrokeWidth(2);
        nvg::MoveTo(mouseDownPos - radialDir * 10000.);
        nvg::LineTo(mouseDownPos + radialDir * 10000.);
        nvg::Stroke();
        nvg::ClosePath();
    }

    vec3 pos;
    vec3 camPos;
    vec4 pwrPos;
    mat4 camTranslate;
    mat4 camRotation;
    mat4 camTR;
    mat4 camPersp;
    mat4 camProj;

    void DrawAll() {

        // pos = (camTR * (BACKWARD * 10.)).xyz;
        auto cam = Camera::GetCurrent();
        if (cam is null) return;
        auto camLoc = mat4(cam.Location);
        camPos = vec3(camLoc.tx, camLoc.ty, camLoc.tz);
        float c_scale = 10.;

        if (pos.LengthSquared() == 0) {
            pos = camPos - vec3(4.);
            try {
                auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
                pos = editor.OrbitalCameraControl.m_TargetedPosition;
            } catch {}
        }

        DrawCirclesManual(pos);
        DrawWindow();


		camTranslate = mat4::Translate(camPos);
		camRotation = mat4::Inverse(mat4::Inverse(camTranslate) * mat4(camLoc));
        camTR = (camTranslate * camRotation);
        camPersp = mat4::Perspective(cam.Fov, cam.Width_Height, cam.NearZ, cam.FarZ);
        camProj = camPersp * mat4::Inverse(camTR);



        // DrawProjectedCircle(pos, rot, c_scale);
        // DrawProjectedCircle(pos, rot * ROT_Q_AROUND_UP, c_scale);
        // DrawProjectedCircle(pos, rot * ROT_Q_AROUND_FWD, c_scale);

        pwrPos = vec4(pwr.tx, pwr.ty, pwr.tz, pwr.tw);
    }

    void DrawWindow() {
        // UX::PushInvisibleWindowStyle();
        if (UI::Begin("###rgz"+name)) {
            vec2 wp = UI::GetWindowPos() / g_scale;
            UI::Text("test window");
            UI::Text("cam pos: " + camPos.ToString());
            UI::Text("pos pos: " + pos.ToString());
            UI::Text("center pos" + centerScreenPos.ToString());
            UI::Text("mouse pos: " + mousePos.ToString());
            UI::Text("last mouse pos: " + lastScreenPos.ToString());
            UI::Text("last closest axis: " + tostring(lastClosestAxis));
            UI::Text("last closest mouse dist: " + lastClosestMouseDist);
            UI::Text("isMouseDown: " + isMouseDown);
            // UI::Text("rot: " + rot.ToString());
            // UI::Text("tmpRot: " + tmpRot.ToString());
            // UI::Text("withTmpRot: " + withTmpRot.ToString());
            UI::Text("radialDir: " + radialDir.ToString());
            UI::Text("shouldDrawGizmo: " + shouldDrawGizmo);
        }
        UI::End();
        // UX::PopInvisibleWindowStyle();
    }

    mat4 qRot = mat4::Identity();
    mat4 wr = mat4::Identity();
    mat4 pwr = mat4::Identity();
    vec3 screenPos = vec3();
    vec3 rrt;
    float d;

    void DrawProjectedCircle(vec3 &in pos, quat&in rot, float scale = 1.0) {
        // Mat4_GetEllipseData
        // world -> translate only
        // local -> rotate only
        auto cam = Camera::GetCurrent();
        d = (Camera::GetCurrentPosition() - pos).Length();
        auto persp = mat4::Perspective(cam.Fov, cam.Width_Height, cam.NearZ, cam.FarZ);
        qRot = mat4::Rotate(rot.Angle(), rot.Axis());
        pwr = camProj * mat4::Inverse(qRot);
        // wr = mat4::Translate(pos) * qRot;
        // pwr = persp * wr;
        screenPos = Camera::ToScreen(pos);
        Mat4_GetEllipseData(pwr, rrt, scale / d * 100.);
        nvg::Reset();
        nvg::BeginPath();
        nvg::StrokeColor(vec4(1, 1, 1, 1));
        nvg::StrokeWidth(2);
        // nvg::Ellipse(screenPos.xy, rrt.x, rrt.y);
        // nvg::Circle(screenPos.xy, rrt.x * .5);
        nvg::Translate(screenPos.xy);
        nvg::Rotate(rrt.z);
        nvg::Ellipse(vec2(), rrt.x, rrt.y);
        nvg::Stroke();
        nvg::ClosePath();
    }
}

const quat ROT_Q_AROUND_UP = quat(UP, HALF_PI);
const quat ROT_Q_AROUND_FWD = quat(FORWARD, HALF_PI);


void Mat4_GetEllipseData(const mat4 &in m, vec3 &out r1_r2_theta, float scale = 1.0) {
    auto c1 = vec2(m.xx, m.yx);
    auto c2 = vec2(m.xy, m.yy);
    auto c1Len = c1.Length();
    auto c2Len = c2.Length();
    vec2 c;
    if (c1Len < c2Len) {
        c = c2;
        r1_r2_theta.y = c1Len;
    } else {
        c = c1;
        r1_r2_theta.y = c2Len;
    }
    r1_r2_theta.x = scale;
    r1_r2_theta.y *= scale;
    r1_r2_theta.z = Math::Atan2(c.y, c.x);
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
