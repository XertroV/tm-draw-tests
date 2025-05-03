// todo: get offsets better
const uint16 O_SCENEVIS_KinematicsVis_SMgr = 0x1A0;
const uint16 O_SCENEVIS_CharVis_SMgr = 0x78;
const uint16 O_SCENEVIS_SceneAnim_SMgr = 0xC0;

NSceneKinematicVis_SMgr@ Get_NSceneKinematicsVis_SMgr(CGameCtnApp@ app) {
	if (app.GameScene is null) return null;
	auto nod = Dev::GetOffsetNod(app.GameScene, O_SCENEVIS_KinematicsVis_SMgr);
	if (nod is null) return null;
	return Dev::ForceCast<NSceneKinematicVis_SMgr@>(nod).Get();
}

uint64 Get_NSceneKinematicsVis_SMgr_Ptr(CGameCtnApp@ app) {
	if (app.GameScene is null) return 0;
	auto ptr = Dev::GetOffsetUint64(app.GameScene, O_SCENEVIS_KinematicsVis_SMgr);
	return ptr;
}

D_NSceneKinematicVis_SMgr@ Get_D_NSceneKinematicVis_SMgr(CGameCtnApp@ app) {
	auto ptr = Get_NSceneKinematicsVis_SMgr_Ptr(app);
	if (Dev_PointerLooksBad(ptr)) return null;
	return D_NSceneKinematicVis_SMgr(ptr);
}

CachedAddrVal@ Get_NSceneKinematicsVis_SMgr_CAV(CGameCtnApp@ app) {
	if (app.GameScene is null) return null;
	auto gsAddr = Dev::GetOffsetUint64(app, O_APP_GAMESCENE);
	auto ptr = Dev::GetOffsetUint64(app.GameScene, O_SCENEVIS_KinematicsVis_SMgr);
	return CachedAddrVal(gsAddr + O_SCENEVIS_KinematicsVis_SMgr, ptr);
}

uint64 Get_NSceneCharVis_SMgr_Ptr(CGameCtnApp@ app) {
	if (app.GameScene is null) return 0;
	auto ptr = Dev::GetOffsetUint64(app.GameScene, O_SCENEVIS_CharVis_SMgr);
	return ptr;
}

DSceneCharVis_SMgr@ Get_D_NSceneCharVis_SMgr(CGameCtnApp@ app) {
	auto ptr = Get_NSceneCharVis_SMgr_Ptr(app);
	if (Dev_PointerLooksBad(ptr)) return null;
	return DSceneCharVis_SMgr(ptr);
}

// DSceneAnim_SMgr

uint64 Get_DSceneAnim_SMgr_Ptr(CGameCtnApp@ app) {
	if (app.GameScene is null) return 0;
	auto ptr = Dev::GetOffsetUint64(app.GameScene, O_SCENEVIS_SceneAnim_SMgr);
	return ptr;
}

DSceneAnim_SMgr2@ Get_DSceneAnim_SMgr(CGameCtnApp@ app) {
	auto ptr = Get_DSceneAnim_SMgr_Ptr(app);
	if (ptr == 0) return null;
	return DSceneAnim_SMgr2(ptr);
}

NSceneAnim_SMgr@ Get_NSceneAnim_SMgr(CGameCtnApp@ app) {
	if (app.GameScene is null) return null;
	auto nod = Dev::GetOffsetNod(app.GameScene, O_SCENEVIS_SceneAnim_SMgr);
	if (nod is null) return null;
	return Dev::ForceCast<NSceneAnim_SMgr@>(nod).Get();
}

class DSceneAnim_SMgr2 : DSceneAnim_SMgr {
	DSceneAnim_SMgr2(uint64 ptr) { super(ptr); }
	DSModelInst@ FindInstanceFromInputNodAddr(uint64 addr) {
		auto insts = this.ModelInsts;
		auto nbInsts = insts.Length;
		for (uint i = 0; i < nbInsts; ++i) {
			auto inst = insts.GetDSModelInst(i);
			if (inst.Input_Contexts0_NodAddr == addr) {
				return inst;
			}
		}
		return null;
	}
}
