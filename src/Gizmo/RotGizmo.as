// RotationTranslationGizmo@ testGizmo;

// array<vec3>@[] axisDragArrows = {
//     {vec3(.3, 0, 0), vec3(1, 0, 0), vec3(0.9, 0, 0.1), vec3(0.9, 0, -0.1), vec3(1, 0, 0), vec3(0.9, 0.1, 0), vec3(0.9, -0.1, 0), vec3(1, 0, 0)},
//     {vec3(0, .3, 0), vec3(0, 1, 0), vec3(0.1, 0.9, 0), vec3(-0.1, 0.9, 0), vec3(0, 1, 0), vec3(0, 0.9, 0.1), vec3(0, 0.9, -0.1), vec3(0, 1, 0)},
//     {vec3(0, 0, .3), vec3(0, 0, 1), vec3(0.1, 0, 0.9), vec3(-0.1, 0, 0.9), vec3(0, 0, 1), vec3(0, 0.1, 0.9), vec3(0, -0.1, 0.9), vec3(0, 0, 1)}
// };

// const int ARROW_SEGS = 14;
// const int CIRCLE_SEGMENTS = 256; // 64;
// vec3[] circleAroundY;
// vec3[] circleAroundX;
// vec3[] circleAroundZ;
// array<vec3>@[] circlesAroundXYZ;
// array<bool>[] circlesAroundIsNearSide;

// void InitCirclesAround() {
//     circleAroundY.Resize(CIRCLE_SEGMENTS);
//     circleAroundX.Resize(CIRCLE_SEGMENTS);
//     circleAroundZ.Resize(CIRCLE_SEGMENTS);
//     float dtheta = TAU / CIRCLE_SEGMENTS;
//     float theta = 0.;
//     for (int i = 0; i < CIRCLE_SEGMENTS; i++) {
//         circleAroundY[i] = vec3(Math::Cos(theta), 0, Math::Sin(theta));
//         circleAroundX[i] = vec3(0, Math::Cos(theta), Math::Sin(theta));
//         circleAroundZ[i] = vec3(Math::Cos(theta), Math::Sin(theta), 0);
//         theta += dtheta;
//     }
//     circlesAroundXYZ.RemoveRange(0, circlesAroundXYZ.Length);
//     circlesAroundXYZ.InsertLast(circleAroundX);
//     circlesAroundXYZ.InsertLast(circleAroundY);
//     circlesAroundXYZ.InsertLast(circleAroundZ);
//     //--
//     circlesAroundIsNearSide.RemoveRange(0, circlesAroundIsNearSide.Length);
//     for (int i = 0; i < 3; i++) {
//         circlesAroundIsNearSide.InsertLast(array<bool>(CIRCLE_SEGMENTS));
//     }
//     //--
//     if (axisDragArrows[0].Length < 10) {
//         for (int i = 0; i < 3; i++) {
//             auto snd = axisDragArrows[i][1];
//             for (float x = 0.9; x > 0.31; x -= 0.1) {
//                 axisDragArrows[i].InsertLast(snd * x);
//             }
//         }
//     }
// }

// vec4[] circleColors = {
//     vec4(1, 0, 0, 1),
//     vec4(0, 1, 0, 1),
//     vec4(0, 0, 1, 1)
// };

// const quat DEFAULT_QUAT = quat(0,0,0,1);

// float clickSensitivity = 400.;

// namespace Gizmo {
//     enum Mode {
//         Rotation,
//         Translation
//     }
// }

// class RotationTranslationGizmo {
//     // drawing gizmo
//     // click detection
//     // drag detection
//     // reading values out
//     // updating cursor
//     // clicking update

//     // quat rot = quat(0,0,0,1);
//     vec3 pos;
//     vec3 tmpPos;
//     mat4 rot = mat4::Identity();
//     mat4 tmpRot = mat4::Identity();
//     string name;
//     Gizmo::Mode mode = Gizmo::Mode::Rotation;

//     float stepDist = 0.25;
//     float stepRot = PI/32.;

//     RotationTranslationGizmo(const string &in name) {
//         this.name = name;
//         if (circleAroundX.Length == 0) {
//             InitCirclesAround();
//         }
//     }

//     RotationTranslationGizmo@ SetRotation(const mat4 &in r) {
//         rot = r;
//         return this;
//     }

//     RotationTranslationGizmo@ AddTmpRotation(Axis axis, float delta_theta) {
//         tmpRot = tmpRot * mat4::Rotate(delta_theta, AxisToVec(axis));
//         return this;
//     }

//     RotationTranslationGizmo@ AddTmpTranslation(const vec3 &in t) {
//         tmpPos = tmpPos + t;
//         return this;
//     }

//     RotationTranslationGizmo@ SetTmpRotation(Axis axis, float theta) {
//         tmpRot = mat4::Rotate(theta, AxisToVec(axis));
//         return this;
//     }

//     RotationTranslationGizmo@ SetTmpTranslation(const vec3 &in t) {
//         tmpPos = t;
//         return this;
//     }

//     RotationTranslationGizmo@ ApplyTmpRotation() {
//         rot = rot * tmpRot;
//         tmpRot = mat4::Identity();
//         return this;
//     }

//     RotationTranslationGizmo@ ApplyTmpTranslation() {
//         pos = pos + tmpPos;
//         tmpPos = vec3();
//         return this;
//     }

//     Axis lastClosestAxis = Axis::X;
//     float lastClosestMouseDist = 1000000.;

//     bool isMouseDown = false;
//     uint mouseDownStart = 0;
//     vec2 mouseDownPos;
//     // the direction from center of circle to this point -- used to take dot product of drag delta to decide how much to rotate
//     vec2 radialDir;

//     vec2 mousePos;
//     mat4 withTmpRot;
//     vec3 worldPos;
//     vec3 lastWorldPos;
//     vec3 lastScreenPos;
//     vec2 centerScreenPos;
//     bool shouldDrawGizmo = true;

//     bool _isCtrlDown = false;
//     bool _wasCtrlDown = false;
//     bool _ctrlPressed = false;

//     void DrawCirclesManual(vec3 pos, float scale = 2.0) {
//         camPos = Camera::GetCurrentPosition();
//         mousePos = UI::GetMousePos();
//         float closestMouseDist = 1000000.;
//         vec3 closestRotationPoint;
//         Axis closestAxis;
//         withTmpRot = (rot * tmpRot);
//         float c2pLen2 = (pos - camPos).LengthSquared();
//         float c2pLen = (pos - camPos).Length();
//         shouldDrawGizmo = true || Camera::IsBehind(pos) || c2pLen < scale;
//         if (!shouldDrawGizmo) {
//             if (c2pLen < scale) trace('c2pLen < scale');
//             else trace('Camera::IsBehind(pos)');
//             return;
//         }

//         _wasCtrlDown = _isCtrlDown;
//         _isCtrlDown = IsCtrlDown();
//         _ctrlPressed = _wasCtrlDown != _isCtrlDown && _isCtrlDown;

//         float tmpDist;
//         centerScreenPos = Camera::ToScreen(pos).xy;
//         bool isRotMode = mode == Gizmo::Mode::Rotation;
//         int segSkip =  isRotMode ? 4 : 1; // c2pLen2 > 40. ? 4 : 2;
//         bool isNearSide = false;

//         int segments = isRotMode ? CIRCLE_SEGMENTS : ARROW_SEGS;

//         vec2 translateRadialDir;
//         bool mouseInClickRange = lastClosestMouseDist < clickSensitivity;

//         for (int c = 0; c < 3; c++) {
//             bool thicken = lastClosestAxis == Axis(c) && mouseInClickRange;
//             float colAdd = thicken ? 0.2 : 0.;
//             nvg::Reset();
//             nvg::LineCap(nvg::LineCapType::Round);
//             nvg::LineJoin(nvg::LineCapType::Round);
//             nvg::BeginPath();
//             nvg::StrokeWidth(thicken ? 5 : 2);
//             // nvg::Circle(mousePos, 5.);
//             auto @circle = isRotMode ? circlesAroundXYZ[c] : axisDragArrows[c];
//             auto col = circleColors[c];
//             auto col2 = col * vec4(.67, .67, .67, .5);
//             int i = 0;
//             int imod;
//             worldPos = (withTmpRot * circle[i]).xyz * scale + pos + tmpPos;
//             if (Math::IsNaN(worldPos.LengthSquared())) {
//                 worldPos = circle[i] * scale + pos + tmpPos;
//             }
//             if (isMouseDown) {
//                 isNearSide = circlesAroundIsNearSide[c][0];
//             } else {
//                 isNearSide = (worldPos - camPos).LengthSquared() < c2pLen2;
//             }
//             bool wasNearSide = isNearSide;
//             nvg::StrokeColor((isNearSide ? col : col2) + colAdd);
//             vec3 p1 = Camera::ToScreen(worldPos);
//             nvg::MoveTo(p1.xy);
//             translateRadialDir = centerScreenPos - p1.xy;
//             for (i = 0; i <= segments; i += segSkip) {
//                 imod = i % segments;
//                 worldPos = (withTmpRot * circle[imod]).xyz * scale + pos + tmpPos;
//                 // trace('imod: ' + imod);
//                 if (isMouseDown) {
//                     isNearSide = circlesAroundIsNearSide[c][imod];
//                 } else {
//                     isNearSide = (worldPos - camPos).LengthSquared() < c2pLen2;
//                     circlesAroundIsNearSide[c][imod] = isNearSide;
//                 }
//                 if (isNearSide != wasNearSide) {
//                     nvg::Stroke();
//                     nvg::ClosePath();
//                     nvg::BeginPath();
//                     nvg::StrokeColor((isNearSide ? col : col2) + colAdd);
//                     nvg::MoveTo(p1.xy);
//                 }
//                 p1 = Camera::ToScreen(worldPos);
//                 if (p1.z > 0) {
//                     nvg::MoveTo(p1.xy);
//                 } else {
//                     nvg::LineTo(p1.xy);
//                 }
//                 if (!isMouseDown && (tmpDist = (mousePos - p1.xy).LengthSquared()) <= closestMouseDist) {
//                     closestMouseDist = tmpDist;
//                     closestRotationPoint = worldPos;
//                     closestAxis = Axis(c);
//                     radialDir = isRotMode ? (p1.xy - lastScreenPos.xy).Normalized() : translateRadialDir.Normalized();
//                 }
//                 wasNearSide = isNearSide;
//                 lastWorldPos = worldPos;
//                 lastScreenPos = p1;
//             }
//             nvg::Stroke();
//             nvg::ClosePath();
//         }
//         if (!isMouseDown) {
//             lastClosestAxis = closestAxis;
//             lastClosestMouseDist = closestMouseDist;
//             if (IsAltDown()) {
//                 // do nothing: camera inputs
//             } if (IsLMBPressed()) {
//                 isMouseDown = true;
//                 mouseDownStart = Time::Now;
//                 mouseDownPos = mousePos;
//                 ResetTmp();
//             } else if (UI::IsMouseClicked(UI::MouseButton::Right) && mouseInClickRange) {
//                 mode = isRotMode ? Gizmo::Mode::Translation : Gizmo::Mode::Rotation;
//                 ResetTmp();
//             }
//         } else if (!IsLMBPressed()) {
//             isMouseDown = false;
//             ApplyTmpRotation();
//             ApplyTmpTranslation();
//         } else if (mouseInClickRange) {
//             bool skipSetLastDD = false;
//             if (_ctrlPressed) ResetTmp();
//             dragDelta = UI::GetMouseDragDelta(UI::MouseButton::Left, 1);
//             auto ddd = dragDelta - lastDragDelta;
//             if (ddd.LengthSquared() > 0.) {
//                 auto mag = Math::Dot(ddd.Normalized(), radialDir) * ddd.Length() / g_screen.y * TAU * -1.;
//                 // trace('mag: ' + mag);
//                 if (IsShiftDown()) mag *= 0.1;
//                 if (!Math::IsNaN(mag)) {
//                     if (isRotMode) {
//                         d = mag;
//                         if (_isCtrlDown) d = d - d % stepRot;
//                         if (d == 0.) skipSetLastDD = true;
//                         else AddTmpRotation(lastClosestAxis, d);
//                     } else {
//                         d = mag * c2pLen * 0.2;
//                         if (_isCtrlDown) d = d - d % stepDist;
//                         if (d == 0.) skipSetLastDD = true;
//                         else AddTmpTranslation((rot * AxisToVec(lastClosestAxis)).xyz * d * (lastClosestAxis == Axis::Y ? 1 : -1));
//                     }
//                     // SetTmpRotation(lastClosestAxis, mag);
//                     // trace('lastClosestAxis: ' + tostring(lastClosestAxis) + '; dd: ' + ((dd.x + dd.y) / g_screen.y * TAU));
//                     // trace('mag: ' + mag);
//                 } else {
//                     // warn('mag is NaN');
//                 }
//             }
//             DrawRadialLine();
//             if (!skipSetLastDD) lastDragDelta = dragDelta;
//         }
//     }

//     void ResetTmp() {
//         tmpRot = mat4::Identity();
//         tmpPos = vec3();
//         lastDragDelta = vec2();
//     }

//     void DrawRadialLine() {
//         nvg::Reset();
//         nvg::BeginPath();
//         // nvg::StrokeColor(vec4(1, 1, 1, 1));
//         nvg::StrokeWidth(2);
//         vec2 start = mouseDownPos - radialDir * g_screen.y * .5;
//         vec2 end = mouseDownPos + radialDir * g_screen.y * .5;
//         nvg::MoveTo(start);
//         nvg::LineTo(mouseDownPos);
//         nvg::StrokePaint(nvg::LinearGradient(start, mouseDownPos, vec4(1, 1, 1, 0), vec4(1, 1, 1, 1)));
//         nvg::Stroke();
//         nvg::ClosePath();
//         nvg::BeginPath();
//         nvg::MoveTo(mouseDownPos);
//         nvg::LineTo(end);
//         nvg::StrokePaint(nvg::LinearGradient(end, mouseDownPos, vec4(1, 1, 1, 0), vec4(1, 1, 1, 1)));
//         nvg::Stroke();
//         nvg::ClosePath();
//     }

//     vec2 dragDelta;
//     vec2 lastDragDelta;

//     vec3 camPos;
//     vec4 pwrPos;
//     mat4 camTranslate;
//     mat4 camRotation;
//     mat4 camTR;
//     mat4 camPersp;
//     mat4 camProj;

//     void DrawAll() {
//         auto cam = Camera::GetCurrent();
//         if (cam is null) return;
//         auto camLoc = mat4(cam.Location);
//         camPos = vec3(camLoc.tx, camLoc.ty, camLoc.tz);

// #if DEV
//         if (pos.LengthSquared() == 0) {
//             pos = camPos - vec3(4.);
//             try {
//                 auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
//                 pos = editor.OrbitalCameraControl.m_TargetedPosition;
//             } catch {}
//         }
// #endif

//         DrawCirclesManual(pos);
//         DrawWindow();
//     }

//     void DrawWindow() {
//         // UX::PushInvisibleWindowStyle();
//         if (UI::Begin("###rgz"+name)) {
//             vec2 wp = UI::GetWindowPos() / g_scale;
//             UI::Text("test window");
//             UI::Text("cam pos: " + camPos.ToString());
//             UI::Text("pos pos: " + pos.ToString());
//             UI::Text("center pos" + centerScreenPos.ToString());
//             UI::Text("mouse pos: " + mousePos.ToString());
//             UI::Text("last mouse pos: " + lastScreenPos.ToString());
//             UI::Text("last closest axis: " + tostring(lastClosestAxis));
//             UI::Text("last closest mouse dist: " + lastClosestMouseDist);
//             UI::Text("isMouseDown: " + isMouseDown);
//             UI::Text("IsShiftDown(): " + IsShiftDown());
//             UI::Text("IsCtrlDown(): " + IsCtrlDown());
//             UI::Text("IsAltDown(): " + IsAltDown());
//             // UI::Text("rot: " + rot.ToString());
//             // UI::Text("tmpRot: " + tmpRot.ToString());
//             // UI::Text("withTmpRot: " + withTmpRot.ToString());
//             UI::Text("radialDir: " + radialDir.ToString());
//             UI::Text("shouldDrawGizmo: " + shouldDrawGizmo);
//         }
//         UI::End();
//         // UX::PopInvisibleWindowStyle();
//     }

//     float d;
// }

// const quat ROT_Q_AROUND_UP = quat(UP, HALF_PI);
// const quat ROT_Q_AROUND_FWD = quat(FORWARD, HALF_PI);


// void Mat4_GetEllipseData(const mat4 &in m, vec3 &out r1_r2_theta, float scale = 1.0) {
//     auto c1 = vec2(m.xx, m.yx);
//     auto c2 = vec2(m.xy, m.yy);
//     auto c1Len = c1.Length();
//     auto c2Len = c2.Length();
//     vec2 c;
//     if (c1Len < c2Len) {
//         c = c2;
//         r1_r2_theta.y = c1Len;
//     } else {
//         c = c1;
//         r1_r2_theta.y = c2Len;
//     }
//     r1_r2_theta.x = scale;
//     r1_r2_theta.y *= scale;
//     r1_r2_theta.z = Math::Atan2(c.y, c.x);
// }


// namespace UX {
//     void PushInvisibleWindowStyle() {
//         UI::PushStyleColor(UI::Col::WindowBg, vec4(0, 0, 0, 0));
//         UI::PushStyleColor(UI::Col::Border, vec4(0, 0, 0, 0));
//         UI::PushStyleColor(UI::Col::TitleBg, vec4(0, 0, 0, 0));
//         UI::PushStyleColor(UI::Col::TitleBgActive, vec4(0, 0, 0, 0));
//     }

//     void PopInvisibleWindowStyle() {
//         UI::PopStyleColor(4);
//     }
// }
