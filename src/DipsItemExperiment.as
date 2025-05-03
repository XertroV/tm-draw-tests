bool g_RunDipsItemExp = true;

void Render_DipsItemExperiment() {
    if (!g_RunDipsItemExp) return;
    if (UI::Begin("DipsItemExperiment", g_RunDipsItemExp)) {
        Draw_DipsItemExperiment_Main();
    }
    UI::End();
}

void Draw_DipsItemExperiment_Main() {
    Draw_Target_Params();
    UI::Separator();

    UI::Text("global_DT: " + Text::Format("%.4f", g_DT));
    UI::Text("LastGcDt3: " + Text::Format("%.4f", g_LastGcDt3));
    UI::Text("LastGcDt2: " + Text::Format("%.4f", g_LastGcDt2));
    UI::Text("LastGcDt1: " + Text::Format("%.4f", g_LastGcDt));

    auto kVis = Get_D_NSceneKinematicVis_SMgr(GetApp());
    if (kVis is null) {
        UI::Text("No Kinematics Vis manager");
        return;
    }
    auto nbConstraints = kVis.Constraints.Length;
    UI::Text("Constraints: " + nbConstraints);
    for (uint i = 0; i < nbConstraints; i++) {
        auto constraint = kVis.Constraints.GetSConstraint(i);
        if (constraint is null) continue;
        if (UI::TreeNode("Constraint " + (i + 1), i == 2 ? UI::TreeNodeFlags::DefaultOpen : UI::TreeNodeFlags::None)) {
            Draw_Constraint(i + 1, constraint);
            UI::TreePop();
        }
    }
}
void Draw_Constraint(uint i, D_NSceneKinematicVis_SConstraint@ constraint) {
    UI::Text("Constraint " + i + ": " + Text::FormatPointer(constraint.Ptr));
    if (UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::SetMouseCursor(UI::MouseCursor::Hand);
    }
    if (UI::IsItemClicked()) {
        SetClipboard(Text::FormatPointer(constraint.Ptr));
    }

    UI::Text("Pos: " + constraint.Pos.ToString());
    UI::Text("Signal.PosOff: " + constraint.Signal.PosOff.ToString());
    CopiableLabeledValue("constraint.Signal.ModelPtr", Text::FormatPointer(constraint.Signal.ModelPtr));
    // UI::Text("Class: " + Text::Format("0x%08X", constraint.hms_class_id));
    UI::Text("? Instance: " + constraint.hms_instance);
    UI::Text("Some ID: " + constraint.some_id);
    AddSimpleTooltip("Might be prefab mgr index");
}

DipsItemAnims@[] followers;

void DipsItemExperiment() {
    sleep(100);
    trace('DipsItemExperiment started');
    auto app = GetApp();
    while (true) {
        if (!g_RunDipsItemExp) {
            yield();
            continue;
        }
        // wait to enter playground
        while (app.RootMap is null || app.CurrentPlayground is null) yield();
        for (uint i = 0; i < 5; i++) {
            yield();
            if (app.RootMap is null || app.CurrentPlayground is null) continue;
        }
        // trace('Reflection::GetRefCount(app.RootMap): ' + Reflection::GetRefCount(app.RootMap));
        if (app.RootMap is null || app.CurrentPlayground is null || Reflection::GetRefCount(app.RootMap) <= 0) continue;


        auto mapId = app.RootMap.Id.Value;
        trace('DipsItemExperiment: running mapId: ' + mapId);
        followers.InsertLast(DipsItemAnims(app.RootMap, "Z_BF2\\DipsCollectable.Item.Gbx"));
        followers.InsertLast(DipsItemAnims(app.RootMap, "Z_BF2\\BF2_Crown.Item.Gbx", 1, NewCrownInMap).WithTarget(CalcTarget_Char));
        followers.InsertLast(DipsItemAnims(app.RootMap, "CoordinateMarker_Kin.Item.Gbx", 1, NewCoordHelperInMap).WithTarget(CalcTarget_Coord_Char));


        HookCamUpdate_CSmArenaClient_UpdateAsync.Apply();
        while (app.RootMap !is null && app.CurrentPlayground !is null && app.RootMap.Id.Value == mapId && g_RunDipsItemExp) {
            // _MostlyAfter_CSmArenaClient_UpdateAsync();
            yield();
        }

        trace('DipsItemExperiment: finished mapId');
        for (uint i = 0; i < followers.Length; i++) {
            if (followers[i] !is null) {
                followers[i].ResetWatchedConstraints();
            }
        }
        followers.RemoveRange(0, followers.Length);
        HookCamUpdate_CSmArenaClient_UpdateAsync.Unapply();
    }
}

// MARK: DipsItemAnims

funcdef CollectableItemInMap@ CreateItemInMapFunc(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item);
funcdef mat4 CalcTargetFunc();

class DipsItemAnims {
    CGameCtnChallenge@ map;
    string modelIdName;
    MemMutCheck@ memMutCheck;
    MwId modelId;

    bool itemModelRegistered = false;
    CollectableItemInMap@[] items;

    ConstraintWatcher@[] watchers;
    CreateItemInMapFunc@ createItemInMap = NewItemInMap;
    CalcTargetFunc@ calcTargetFunc = CalcTarget_Vehicle;


    DipsItemAnims(CGameCtnChallenge@ map, const string &in modelIdName, int limit = -1, CreateItemInMapFunc@ createItemInMap = null) {
        modelId.SetName(modelIdName);
        this.modelIdName = modelIdName;
        // modelId.Value = -1;
        @memMutCheck = MemMutCheck().GameScene();

        @this.map = map;
        map.MwAddRef();

        if (createItemInMap !is null) {
            @this.createItemInMap = createItemInMap;
        }

        startnew(CoroutineFunc(this.Init));
    }

    DipsItemAnims@ WithTarget(CalcTargetFunc@ func) {
        @this.calcTargetFunc = func;
        return this;
    }

    ~DipsItemAnims() {
        if (this.map !is null) {
            this.map.MwRelease();
            @this.map = null;
        }

        // maybe we are reloading plugin or leaving editor pg
        if (!memMutCheck.HasChanged()) {
            ResetWatchedConstraints();
        }
    }

    void Init() {
        // 1100 items in ~ 3ms on my pc (3x when comparing strings)
        // 300 items in ~ 1ms
        uint pauseLim = 300;
        uint plMinus1 = pauseLim - 1;
        uint i = 0;
        uint nbItemsInMap = map.AnchoredObjects.Length;

        if (modelId.Value == 0) {
            // find the first instance of the item model, save the id.Value
            for (; i < nbItemsInMap; i++) {
                if (map.AnchoredObjects[i].ItemModel.Name == modelIdName) {
                    modelId.Value = map.AnchoredObjects[i].ItemModel.Id.Value;
                    trace('DipsItemsAnims found initial item: ' + modelId.GetName());
                    break;
                }
                if (i % pauseLim == plMinus1) yield();
            }
        }

        // BenchmarkTestMwId();

        // loop through the rest of the items and register matching
        for (; i < nbItemsInMap; i++) {
            auto item = map.AnchoredObjects[i];
            if (item.ItemModel.Id.Value == modelId.Value) {
                RegisterItem(i, item);
                trace('DipsItemsAnims found item: ' + item.ItemModel.Name + " @ " + item.AbsolutePositionInMap.ToString());
            }
            if (i % pauseLim == plMinus1) yield();
        }

        Init_WatchKinematicVis();

        this.map.MwRelease();
        @this.map = null;
        trace('DipsItemsAnims: finished init');
    }


    void BenchmarkTestMwId() {
#if DEV
        // test 10k checks
        auto nbItemsInMap = map.AnchoredObjects.Length;
        auto jMax = Math::Max(1, 100000 / nbItemsInMap + 1);
        uint start = Time::Now;
        for (uint j = 0; j < jMax; j++) {
            for (uint i = 0; i < nbItemsInMap; i++) {
                if (map.AnchoredObjects[i].ItemModel.Id.Value == modelId.Value) {
                    auto item = map.AnchoredObjects[i];
                    trace('found: ' + item.ItemModel.Name + " @ " + item.AbsolutePositionInMap.ToString());
                    // RegisterItem(i, item);
                    // trace('DipsItemsAnims found item: ' + item.ItemModel.Name + " @ " + item.AbsolutePositionInMap.ToString());
                }
                // if (i % pauseLim == plMinus1) yield();
            }
        }
        uint end = Time::Now;
        float itemsPerMs = float(jMax * nbItemsInMap) / float(end - start);
        trace('\\$b8f\\$i BENCH - DipsItemsAnims: test took ' + (end - start) + ' ms for ' + (jMax*nbItemsInMap) + ' iterations -- ' + itemsPerMs + ' items/ms. NbItems: ' + nbItemsInMap);
        trace('\\$b8f\\$i BENCH - modelId.Value: ' + FmtUintHex(modelId.Value) + ' / name: ' + modelId.GetName());
#endif
    }


    void RegisterItem(uint ix, CGameCtnAnchoredObject@ item) {
        RegisterItemModel(item.ItemModel);
        items.InsertLast(createItemInMap(ix, items.Length, item));
    }

    void RegisterItemModel(CGameItemModel@ model) {
        if (model is null) throw('DipsItemsAnims model is null');
        if (itemModelRegistered) return;
        itemModelRegistered = true;

        auto prefab = cast<CPlugPrefab>(model.EntityModel);
        if (prefab is null) {
            warn('DipsItemsAnims prefab is null');
            return;
        }

        auto nbEnts = prefab.Ents.Length;
        for (uint i = 0; i < nbEnts; i++) {
            auto kc = cast<NPlugDyna_SKinematicConstraint>(prefab.Ents[i].Model);
            if (kc is null) continue;
            RegisterKinematicConstraint(kc);
        }
    }

    uint64[] kcPointers;

    void RegisterKinematicConstraint(NPlugDyna_SKinematicConstraint@ kc) {
        // get ptr
        auto ptr = Dev_GetPointerForNod(kc);
        kcPointers.InsertLast(ptr);
        trace('DipsItemsAnims found kc: ' + Text::FormatPointer(ptr));
    }

    void Init_WatchKinematicVis() {
        auto app = GetApp();
        auto kVis = Get_D_NSceneKinematicVis_SMgr(app);
        if (kVis is null) {
            warn('DipsItemsAnims no KinematicVis');
            return;
        }

        auto cav = Get_NSceneKinematicsVis_SMgr_CAV(app);
        memMutCheck.PushPair(cav);
        if (kVis.Ptr != cav.value) {
            warn('DipsItemsAnims kVis pointer mismatch');
        }

        for (uint i = 0; i < kVis.Constraints.Length; i++) {
            auto constraint = kVis.Constraints.GetSConstraint(i);
            if (!HasKCPtr(constraint.Signal.ModelPtr)) continue;
            AddKinVisConstraint(constraint);
        }
    }

    // has kinematic constraint ptr
    bool HasKCPtr(uint64 ptr) {
        return kcPointers.Find(ptr) > -1;
    }

    // MARK: watchers

    void AddKinVisConstraint(D_NSceneKinematicVis_SConstraint@ constraint) {
        auto kcPtr = constraint.Signal.ModelPtr;
        if (kcPtr == 0) throw("DipsItemsAnims: constraint.Signal.ModelPtr is null");
        bool isPrimary = kcPtr == kcPointers[0];
        // watch
        auto itemInMap = FindItemInMap(constraint);
        watchers.InsertLast(ConstraintWatcher(constraint, isPrimary, itemInMap));
    }

    void ResetWatchedConstraints() {
        for (uint i = 0; i < watchers.Length; i++) {
            watchers[i].Reset();
        }
        watchers.RemoveRange(0, watchers.Length);
    }

    CollectableItemInMap@ FindItemInMap(D_NSceneKinematicVis_SConstraint@ constraint) {
        for (uint i = 0; i < items.Length; i++) {
            if ((items[i].pos - constraint.Pos).LengthSquared() < 1.0) {
                return items[i];
            }
        }
        return null;
    }

    bool goneBad = false;
    void Update(float dt) {
        if (goneBad || memMutCheck.HasChanged()) {
            if (!goneBad) trace('DipsItemsAnims: memMutCheck failed');
            goneBad = true;
            return;
        }

        auto target = this.calcTargetFunc();
        auto targetPos = Mat4_GetPos(target);
        for (uint i = 0; i < watchers.Length; i++) {
            // set rotation before pos because it includes a pos
            watchers[i].SetLoc(target);
            watchers[i].MoveTowardsTargetPos(targetPos, dt);
        }
        // trace('DipsItemsAnims: Updated ' + watchers.Length + ' constraints');
    }
}

// MARK: ItemInMap

CollectableItemInMap@ NewItemInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
    return CollectableItemInMap(ix, dipsIx, item);
}

CollectableItemInMap@ NewCrownInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
    return CrownItemInMap(ix, dipsIx, item);
}

CollectableItemInMap@ NewCoordHelperInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
    return CoordItemInMap(ix, dipsIx, item);
}

class CollectableItemInMap {
    vec3 pos;
    // index in AnchoredObjects
    uint ix;
    // index in DipsItemAnims::items
    uint dipsIx;

    CollectableItemInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
        pos = item.AbsolutePositionInMap;
        this.ix = ix;
        this.dipsIx = dipsIx;
    }

    vec3 MoveTowardsTargetPos(vec3 lastPos, vec3 target, float dt) {
        // constraint.Pos = lastPos = SmoothFollow(target, lastPos, dt, 1);
        // auto priorPos = lastPos;
        return SmoothFollow(lastPos, target, dt, 12.0);
    }
}

class CrownItemInMap : CollectableItemInMap {
    CrownItemInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
        super(ix, dipsIx, item);
    }

    vec3 MoveTowardsTargetPos(vec3 lastPos, vec3 target, float dt) override {
        return target;
    }
}

class CoordItemInMap : CollectableItemInMap {
    CoordItemInMap(uint ix, uint dipsIx, CGameCtnAnchoredObject@ item) {
        super(ix, dipsIx, item);
    }

    vec3 MoveTowardsTargetPos(vec3 lastPos, vec3 target, float dt) override {
        return target;
    }
}

// MARK: ConstraintWatcher

class ConstraintWatcher {
    D_NSceneKinematicVis_SConstraint@ constraint;
    CollectableItemInMap@ itemInMap;
    // if we have multiple KCs then the first one is treated as the main one and the others are like extra bits like orbiting stars or something
    bool isPrimary;
    vec3 origPos;
    vec3 lastPos;

    ConstraintWatcher(D_NSceneKinematicVis_SConstraint@ constraint, bool isPrimary, CollectableItemInMap@ itemInMap) {
        @this.constraint = constraint;
        @this.itemInMap = itemInMap;
        this.isPrimary = isPrimary;
        this.lastPos = this.origPos = constraint.Pos;

        if (isPrimary) {
            trace('ConstraintWatcher for Primary KC created: ' + origPos.ToString() + " / addr: " + Text::FormatPointer(constraint.Ptr));
        }
        if (itemInMap is null) {
            warn('ConstraintWatcher: itemInMap is null');
        }
    }

    void MoveTowardsTargetPos(vec3 target, float dt) {
        lastPos = itemInMap.MoveTowardsTargetPos(lastPos, target, dt);
        constraint.Pos = lastPos;
        // // constraint.Pos = lastPos = SmoothFollow(target, lastPos, dt, 1);
        // // auto priorPos = lastPos;
        // lastPos = SmoothFollow(lastPos, target, dt, 12.0);
        // // trace('ConstraintWatcher: from -> to ' + priorPos.ToString() + " -> " + target.ToString() + " @ dt = " + dt + " ms; next = " + lastPos.ToString());
        // constraint.Pos = lastPos;
        // // constraint.Pos = lastPos = target;
    }

    void SetLoc(const mat4 &in rot) {
        constraint.Loc = iso4(rot);
    }

    void Reset() {
        constraint.Pos = lastPos = origPos;
    }
}



// decayRate in [1, 25]
vec3 SmoothFollow(vec3 current, vec3 target, float dt, float decayRate = 8.0) {
    return target + (current - target) * Math::Clamp(Math::Exp(decayRate * dt * -1.0), 0.0, 1.0);
}


// MARK: MemMutCheck

const uint16 O_APP_GAMESCENE = GetOffset("CGameCtnApp", "GameScene");

class MemMutCheck {
    CachedAddrVal[] ptrsToValues;

    MemMutCheck() {
        auto app = GetApp();
        auto appPtr = Dev_GetPointerForNod(app);
        auto appVTable = Dev::GetOffsetUint64(app, 0);
        PushPair(appPtr, appVTable);
    }

    // Add app.GameScene as something to check
    MemMutCheck@ GameScene() {
        // auto app = GetApp();
        // auto appAddr = Dev_GetPointerForNod(app);
        auto appAddr = ptrsToValues[0].addr;
        auto appGSAddr = appAddr + O_APP_GAMESCENE;
        auto gsPtr = Dev::ReadUInt64(appGSAddr);
        return PushPair(appGSAddr, gsPtr);
    }

    MemMutCheck@ PushPair(uint64 ptr, uint64 value) {
        if (ptr == 0) return null;
        ptrsToValues.InsertLast(CachedAddrVal(ptr, value));
        return this;
    }

    MemMutCheck@ PushPair(CachedAddrVal@ cav) {
        ptrsToValues.InsertLast(cav);
        return this;
    }

    // Indicates it's unsafe to access memory under this
    bool HasChanged() {
        for (uint i = 0; i < ptrsToValues.Length; i++) {
            if (ptrsToValues[i].IsChanged()) return true;
        }
        return false;
    }
}

class CachedAddrVal {
    uint64 addr;
    uint64 value;

    CachedAddrVal() {}

    CachedAddrVal(uint64 ptr, uint64 value) {
        this.addr = ptr;
        this.value = value;
        if (ptr == 0) {
            warn("CachedPtrVal: ptr is null");
            throw("CachedPtrVal: ptr is null");
        }
    }

    bool IsChanged() {
        if (addr == 0) return true;
        auto newValue = Dev::ReadUInt64(addr);
        return newValue != value;
    }
}



// MARK: Hook

/*
hook location: before position of SConstraints are read under some calls from CSmArenaClient::UpdateAsync

Trackmania.exe.text+6E1BDA - 66 0F7F 4D C0         - movdqa [rbp-40],xmm1
Trackmania.exe.text+6E1BDF - E8 8C35FFFF           - call Trackmania.exe.text+6D5170 {
    this call reads constraint pos (vehicle state pos at 0x15C updated a few hundred bytes above)
}
Trackmania.exe.text+6E1BE4 - 40 38 B3 A8000000     - cmp [rbx+000000A8],sil
Trackmania.exe.text+6E1BEB - 8B C6                 - mov eax,esi
Trackmania.exe.text+6E1BED - 0F95 C0               - setne al
Trackmania.exe.text+6E1BF0 - 89 83 A4010000        - mov [rbx+000001A4],eax
Trackmania.exe.text+6E1BF6 - 8B 43 3C              - mov eax,[rbx+3C]
Trackmania.exe.text+6E1BF9 - 89 83 A8010000        - mov [rbx+000001A8],eax


66 0F 7F 4D C0 E8 8C 35 FF FF 40 38 B3 A8 00 00 00 8B C6 0F 95 C0 89 83 A4 01 00 00 8B 43 3C 89 83 A8 01 00 00
66 0F 7F 4D ?? E8 ?? ?? ?? ?? 40 38 B3 A8 00 00 00 8B C6 0F 95 C0 89 83 A4 01 00 00 8B 43 ?? 89 83 A8 01 00 00

unique: 66 0F 7F 4D ?? E8 ?? ?? ?? ?? 40 38 B3 ?? 00 00 00
*/




HookHelper@ HookCamUpdate_CSmArenaClient_UpdateAsync = HookHelper(
    "66 0F 7F 4D ?? E8 ?? ?? ?? ?? 40 38 B3 A8 00 00 00",
    0x0, 0x0, "_MostlyAfter_CSmArenaClient_UpdateAsync", Dev::PushRegisters::SSE, true
);

void _MostlyAfter_CSmArenaClient_UpdateAsync() {
    if (followers is null) return;
    if (followers.Length == 0) return;

    for (uint i = 0; i < followers.Length; i++) {
        followers[i].Update(g_DT);
    }

    auto app = GetApp();
    vec3 targetPos;
    float dt = g_DT * 0.001;
    auto camSysFakeNod = Dev::GetOffsetNod(app, O_APP_GAMESCENE + 0x10);
    if (camSysFakeNod !is null) {
        // dt = Dev::GetOffsetFloat(camSysFakeNod, 0x30);
        dt = Dev::GetOffsetFloat(app.GameScene, 0xD08);
    }

    CSceneVehicleVis@ vis = VehicleState::GetSingularVis(app.GameScene);

    if (vis !is null) {
        targetPos = vis.AsyncState.Position + UP * 1.0;
    } else {
        iso4 camLoc = Camera::GetCurrent().Location;
        if (camSysFakeNod !is null) {
            // camLoc = Dev::GetOffsetIso4(camSysFakeNod, 0x578);
            camLoc = Dev::GetOffsetIso4(camSysFakeNod, 0x268);
            auto m = camLoc;
            auto camPos = vec3(m.tx, m.ty, m.tz);
            auto camDir  = vec3(m.xz, m.yz, m.zz);
            targetPos = camPos + camDir * 64.0 * 0.1;
        }
    }
    g_LastGcDt3 = g_LastGcDt2;
    g_LastGcDt2 = g_LastGcDt;
    g_LastGcDt = dt * 1000.0;
    for (uint i = 0; i < followers.Length; i++) {
        followers[i].Update(dt);
    }
}

// CalcTarget functions


// MARK: misc

string FmtUintHex(uint v) {
    return Text::Format("0x%08x", v);
}

vec3 Iso4_GetPos(const iso4 &in iso) {
    return vec3(iso.tx, iso.ty, iso.tz);
}

vec3 Mat4_GetPos(const mat4 &in m) {
    return vec3(m.tx, m.ty, m.tz);
}
