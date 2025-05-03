
mat4 CalcTarget_Vehicle() {
    auto app = GetApp();
    vec3 targetPos;
    float dt = g_DT * 0.001;
    auto camSysFakeNod = Dev::GetOffsetNod(app, O_APP_GAMESCENE + 0x10);
    if (camSysFakeNod !is null) {
        // dt = Dev::GetOffsetFloat(camSysFakeNod, 0x30);
        dt = Dev::GetOffsetFloat(app.GameScene, 0xD08);
    }

    CSceneVehicleVis@ vis = VehicleState::GetSingularVis(app.GameScene);
    if (vis is null) return mat4::Identity();
    return mat4(Dev::GetOffsetIso4(vis.AsyncState, 0x2C));
}

[Setting hidden]
vec3 headOffsetFromVehicle = vec3(0, 0.9701, -0.1601);
[Setting hidden]
vec3 headOffsetPos = vec3(0);
[Setting hidden]
vec3 coordOffsetPos = vec3(0);
[Setting hidden]
float CharHeadTopNeckOffset = 0.116;
vec2 lastPitchRoll;
[Setting hidden]
bool S_SillyCrown = true;


mat4 CalcTarget_Vehicle_Head() {
    auto v = CalcTarget_Vehicle();
    auto pos = Mat4_GetPos(v);
    auto r = mat4::Translate(pos * -1.) * v;
    vec3 offset = headOffsetFromVehicle; //vec3(0, 0.9701, -0.1601);
    offset = (mat4::Inverse(r) * offset).xyz;
    return mat4::Translate(offset) * mat4::Translate(pos) * r;
}

uint _countN = 0;

mat4 CalcTarget_Char() {
    _countN++;

    auto app = GetApp();
    auto charVisMgr = Get_D_NSceneCharVis_SMgr(app);
    auto charVis = charVisMgr.CharViss.GetDSceneCharVis(0);

    auto r = mat4(Dev::ReadIso4(charVis.pLoc));
    r = mat4::Translate(Mat4_GetPos(r) * -1.) * r;
    auto invR = mat4::Inverse(r);

    if (Math::IsNaN(CharHeadTopNeckOffset)) {
        warn("CharHeadTopNeckOffset is NaN");
        CharHeadTopNeckOffset = 0.116;
    }
    auto head = vec3(0, CharHeadTopNeckOffset, 0);
    // if (_countN % 10 == 0) trace('head: ' + head.ToString());
    // head = (invR * head).xyz;
    auto rotQ = charVis.RotRef;
    // if (_countN % 10 == 0) trace("rotQ: " + rotQ.ToString());
    auto rot = mat4(quatToRotMat3x3(rotQ));
    // head = (rotQ * head);
    // if (_countN % 10 == 0)  trace("rotQ * h: " + (rotQ * head).ToString());
    mat4 tiltRot = getHeadTiltRot(app, charVis);
    mat4 tiltRotInv = mat4::Inverse(tiltRot);
    head = (tiltRotInv * head).xyz;
    if (S_SillyCrown) tiltRot = tiltRotInv;

    // auto neck = vec3(0, 0.9701 - CharHeadTopNeckOffset, -0.1) + head;
    auto neck = vec3(0, 0.8701 - CharHeadTopNeckOffset, -0.1401) + head;
    neck = (invR * neck).xyz;

    // auto m = mat4::Translate(charVis.Pos + neck) * r * tiltRot;
    auto m = mat4::Translate(neck) * mat4::Translate(charVis.Pos) * tiltRot * r;
    // auto m = ;
    return m;
}

mat4 getHeadTiltRot(CGameCtnApp@ app, DSceneCharVis@ charVis) {
    auto animMgr = Get_DSceneAnim_SMgr(app);
    if (animMgr is null) return mat4::Identity();
    auto inst = animMgr.FindInstanceFromInputNodAddr(charVis.State_Addr);
    if (inst is null) return mat4::Identity();
    auto jd = inst.JointDynamic;
    if (jd is null) { return mat4::Identity(); }
    auto pitch = inst.JointDynamic.HeadPitch;
    auto roll = inst.JointDynamic.HeadRoll;
    if (Math::Abs(pitch) < 0.0001) pitch = 0;
    if (Math::Abs(roll) < 0.0001) roll = 0;
    lastPitchRoll = vec2(pitch, roll);
    // if (S_SillyCrown) {
    //     pitch = -pitch;
    //     roll = -roll;
    // }
    auto headRot = mat4::Rotate(pitch, LEFT) * mat4::Rotate(roll, FORWARD);
    return headRot;
}

mat4 CalcTarget_Coord_Vehicle() {
    auto v = CalcTarget_Vehicle();
    auto pos = Mat4_GetPos(v);
    auto r = mat4::Translate(pos * -1.) * v;
    vec3 offset = coordOffsetPos;
    offset = (mat4::Inverse(r) * offset).xyz;
    return mat4::Translate(offset) * mat4::Translate(pos) * r;
}

mat4 CalcTarget_Coord_Char() {
    auto app = GetApp();
    auto charVisMgr = Get_D_NSceneCharVis_SMgr(app);
    auto charVis = charVisMgr.CharViss.GetDSceneCharVis(0);
    auto m = mat4(Dev::ReadIso4(charVis.pLoc));
    auto r = mat4::Translate(Mat4_GetPos(m) * -1.) * m;

    vec3 offset = coordOffsetPos;
    offset = (mat4::Inverse(r) * offset).xyz;

    return mat4::Translate(offset) * m;
}

mat4 CalcTarget_Vehicle_Dir5() {
    auto v = CalcTarget_Vehicle();
    auto pos = Mat4_GetPos(v);
    auto r = mat4::Translate(pos * -1.) * v;
    vec3 offset = vec3(0, 0, 5.0);
    offset = (mat4::Inverse(r) * offset).xyz;
    return mat4::Translate(offset) * mat4::Translate(pos) * r;
}

void Draw_Target_Params() {
    UI::Text("lastPitchRoll: " + lastPitchRoll.ToString());
    if (followers.Length < 2) return;
    if (UI::TreeNode("Vehicle Tail")) {
        headOffsetFromVehicle.x = UI::InputFloat("Tail Offset X", headOffsetFromVehicle.x, 0.05, 0.2);
        headOffsetFromVehicle.y = UI::InputFloat("Tail Offset Y", headOffsetFromVehicle.y, 0.05, 0.2);
        headOffsetFromVehicle.z = UI::InputFloat("Tail Offset Z", headOffsetFromVehicle.z, 0.05, 0.2);
        UI::TreePop();
    }
    if (UI::TreeNode("Char Head")) {
        S_SillyCrown = UI::Checkbox("Silly Crown", S_SillyCrown);
        headOffsetPos.x = UI::InputFloat("Head Offset X", headOffsetPos.x, 0.01, 0.05);
        headOffsetPos.y = UI::InputFloat("Head Offset Y", headOffsetPos.y, 0.01, 0.05);
        headOffsetPos.z = UI::InputFloat("Head Offset Z", headOffsetPos.z, 0.01, 0.05);
        if (UI::Button("TF: Vechile + Head")) {
            followers[1].WithTarget(CalcTarget_Vehicle_Head);
        }
        if (UI::Button("TF: Char")) {
            followers[1].WithTarget(CalcTarget_Char);
        }
        UI::TreePop();
    }

    if (UI::TreeNode("Coord Helper")) {
        coordOffsetPos.x = UI::InputFloat("Coord Offset X", coordOffsetPos.x, 0.05, 0.25);
        coordOffsetPos.y = UI::InputFloat("Coord Offset Y", coordOffsetPos.y, 0.05, 0.25);
        coordOffsetPos.z = UI::InputFloat("Coord Offset Z", coordOffsetPos.z, 0.05, 0.25);
        if (UI::Button("TF: Vechile + Head##1")) {
            followers[2].WithTarget(CalcTarget_Vehicle_Head);
        }
        if (UI::Button("TF: Char##1")) {
            followers[2].WithTarget(CalcTarget_Char);
        }
        if (UI::Button("TF: Vehicle+Coord##1")) {
            followers[2].WithTarget(CalcTarget_Coord_Vehicle);
        }
        if (UI::Button("TF: Char+Coord##1")) {
            followers[2].WithTarget(CalcTarget_Coord_Char);
        }
        if (UI::Button("TF: Vehicle+Dir*5##1")) {
            followers[2].WithTarget(CalcTarget_Vehicle_Dir5);
        }
        UI::TreePop();
    }
}


















// from E++ -- modified to use openplanet quats
mat3 quatToRotMat3x3(const quat &in q) {
    float fVar1, fVar2, fVar3, fVar4, fVar5, fVar6, fVar7, fVar8;
    fVar1 = q.x; // f0
    fVar2 = q.w; // f3
    fVar6 = fVar2 + fVar2;
    fVar3 = q.y; // f1
    fVar4 = q.z; // f2
    fVar5 = fVar4 + fVar4;
    fVar8 = fVar1 * (fVar3 + fVar3);
    fVar7 = 1.0 - fVar3 * (fVar3 + fVar3);
    auto v1 = vec3(
        (1.0 - fVar4 * fVar5) - fVar2 * fVar6,
        (fVar3 * fVar5 - fVar1 * fVar6), // outMat3x3Rot[1]
        (fVar3 * fVar6 + fVar1 * fVar5)  // outMat3x3Rot[2]
    );
    auto v2 = vec3(
        fVar3 * fVar5 + fVar1 * fVar6, // outMat3x3Rot[3]
        fVar7 - fVar2 * fVar6, // outMat3x3Rot[4]
        fVar4 * fVar6 - fVar8  // outMat3x3Rot[5]
    );
    auto v3 = vec3(
        fVar3 * fVar6 - fVar1 * fVar5, // outMat3x3Rot[6]
        fVar4 * fVar6 + fVar8, // outMat3x3Rot[7]
        fVar7 - fVar4 * fVar5  // outMat3x3Rot[8]
    );
    return mat3(v1, v2, v3);
}
