NSceneKinematicVis_SMgr@ Get_NSceneKinematicsVis_SMgr(CGameCtnApp@ app) {
    if (app.GameScene is null) return null;
    auto nod = Dev::GetOffsetNod(app.GameScene, 0x1A0);
    if (nod is null) return null;
    return Dev::ForceCast<NSceneKinematicVis_SMgr@>(nod).Get();
}

uint64 Get_NSceneKinematicsVis_SMgr_Ptr(CGameCtnApp@ app) {
    if (app.GameScene is null) return 0;
    auto ptr = Dev::GetOffsetUint64(app.GameScene, 0x1A0);
    return ptr;
}

D_NSceneKinematicVis_SMgr@ Get_D_NSceneKinematicVis_SMgr(CGameCtnApp@ app) {
    auto ptr = Get_NSceneKinematicsVis_SMgr_Ptr(app);
    if (Dev_PointerLooksBad(ptr)) return null;
    return D_NSceneKinematicVis_SMgr(ptr);
}

const uint16 O_SCENEVIS_KinematicsVis_SMgr = 0x1A0;

CachedAddrVal@ Get_NSceneKinematicsVis_SMgr_CAV(CGameCtnApp@ app) {
    if (app.GameScene is null) return null;
    auto gsAddr = Dev::GetOffsetUint64(app, O_APP_GAMESCENE);
    auto ptr = Dev::GetOffsetUint64(app.GameScene, O_SCENEVIS_KinematicsVis_SMgr);
    return CachedAddrVal(gsAddr + O_SCENEVIS_KinematicsVis_SMgr, ptr);
}
