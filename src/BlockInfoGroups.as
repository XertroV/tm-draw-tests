#if FALSE

namespace BlockInfoGroups {
    void Run() {
        auto app = GetApp();
        auto stadium = app.GlobalCatalog.Chapters[3];
        auto collection = cast<CGameCtnCollection>(Fids::Preload(stadium.CollectionFid));
        auto blockInfoGs = cast<CGameBlockInfoGroups>(Fids::Preload(cast<CSystemFidFile>(collection.FidBlockInfoGroups)));
        auto itemPlaceGs = cast<NPlugItemPlacement_SGroups>(collection.ItemPlacementGroups);
        for (uint i = 0; i < blockInfoGs.Groups.Length; i++) {
            auto @group = blockInfoGs.Groups[i];
            print("# BIGroup: " + group.GroupId.GetName());
            for (uint j = 0; j < group.BlockIds.Length; j++) {
                print("- g: " + j + " | " + group.BlockIds[j].GetName());
            }
        }
        print("# Item Placements");
        for (uint i = 0; i < itemPlaceGs.IdGroups.Length; i++) {
            auto group = itemPlaceGs.IdGroups[i];
            print("- g: " + group.Name.GetName());
        }
        for (uint i = 0; i < itemPlaceGs.SizeGroups.Length; i++) {
            auto sg = itemPlaceGs.SizeGroups[i];
            print("- sg: " + sg.Name.GetName() + " | " + sg.Size.ToString());
        }
        print("-------------------");
        print("-------------------");
        print("-------------------");
        print("-------------------");
        // RunGetPillarsAndReplacements();
    }


    void RunGetPillarsAndReplacements() {
        auto t = Thing();
        t.RunTest();
    }
}

class Thing : WithGetPillarsAndReplacements {
    Thing() {}
}

/// draft work

mixin class WithGetPillarsAndReplacements {
    void RunTest() {
        InitializePillarNames();
    }

    uint[] pillarNames;
    uint[] replacePillarNames;

    private void AddPillarName(uint nameId, uint replacementId) {
        pillarNames.InsertLast(nameId);
        replacePillarNames.InsertLast(replacementId);
    }

    private void AddPillarName(uint nameId, const string &in replacement) {
        pillarNames.InsertLast(nameId);
        replacePillarNames.InsertLast(GetMwId(replacement));
    }

    private void AddPillarName(const string &in name, const string &in replacement) {
        pillarNames.InsertLast(GetMwId(name));
        replacePillarNames.InsertLast(GetMwId(replacement));
    }

    protected void InitializePillarNames() {
        if (pillarNames.Length > 0) return;
        CGameCtnBlockInfoClassic@ bi;
        auto pillars = GetPillarBlockInfos();
        for (uint i = 0; i < pillars.Length; i++) {
            @bi = pillars[i];
            uint replacement = CalcPillarReplacement(bi.Name);
            AddPillarName(bi.Id.Value, replacement);
            print("Pillar: " + bi.Name + " | " + GetMwIdName(replacement));
        }
    }

    uint CalcPillarReplacement(const string &in name) {
        if (!name.EndsWith("Pillar")) {
            warn("Name does not end with 'Pillar': " + name);
        }
        string decoWallName = name.SubStr(0, name.Length - 6);
        auto fid = Fids::GetGame("GameData/Stadium/GameCtnBlockInfo/GameCtnBlockInfoClassic/" + decoWallName + ".EDClassic.Gbx");
        if (fid is null) {
            warn("No replacement found for: " + name);
            return 0xFFFFFFFF;
        }
        return GetMwId(decoWallName);
    }

    CGameCtnBlockInfoClassic@[]@ GetPillarBlockInfos() {
        auto folder = Fids::GetGameFolder("GameData/Stadium/GameCtnBlockInfo/GameCtnBlockInfoPillar");
        CGameCtnBlockInfoClassic@[] ret;
        for (uint i = 0; i < folder.Leaves.Length; i++) {
            auto fid = folder.Leaves[i];
            ret.InsertLast(cast<CGameCtnBlockInfoClassic>(Fids::Preload(fid)));
        }
        return ret;
    }

    string GetPillarReplacement(uint nameId, PillarsType type) {
        if (pillarNames.Length == 0) InitializePillarNames();
        auto ix = pillarNames.Find(nameId);
        if (ix >= 0) {
            return GetMwIdName(replacePillarNames[ix]) + PillarTypeSuffix(type);
        }
        warn("Unknown pillar replacement for: " + GetMwIdName(nameId));
        return "";
    }

    void ConvertPillarTo(CGameCtnBlock@ block, PillarsType type) {
        if (!block.BlockModel.IsPillar) {
            warn("Block is not a pillar: " + block.BlockModel.Name);
            return;
        }
        auto replacement = GetPillarReplacement(block.BlockModel.Id.Value, type);
        if (replacement == "") {
            warn("No replacement found for: " + block.BlockModel.Name);
            return;
        }
        auto fid = Fids::GetGame("GameData/Stadium/GameCtnBlockInfo/GameCtnBlockInfoClassic/" + replacement + ".EDClassic.Gbx");
        if (fid is null) {
            warn("No replacement FID found for: " + block.BlockModel.Name);
            return;
        }
        auto bi = cast<CGameCtnBlockInfoClassic>(Fids::Preload(fid));
        if (bi is null) {
            warn("Failed to preload replacement: " + block.BlockModel.Name);
            return;
        }
        block.BlockModel.MwRelease();
        Dev::SetOffset(block, GetOffset(block, "BlockInfo"), bi);
        Dev::SetOffset(block, 0x18, bi.Id.Value);
        bi.MwAddRef();
    }
}

string PillarTypeSuffix(PillarsType type) {
    switch (type) {
        case PillarsType::Wood: return "";
        case PillarsType::Stone: return "Ice";
        case PillarsType::Concrete: return "Grass";
        case PillarsType::Dirt: return "Dirt";
    }
    return "";
}



/// copied







enum PillarsType {
    None = 0,
    Wood = 1,
    Stone = 2,
    Concrete = 3,
    Dirt = 4,
    XXX_Last
}





#endif



CGameItemModel@ tmp_ItemModelForMwIdSetting;

uint32 GetMwId(const string &in name) {
    if (tmp_ItemModelForMwIdSetting is null) {
        @tmp_ItemModelForMwIdSetting = CGameItemModel();
    }
    tmp_ItemModelForMwIdSetting.IdName = name;
    return tmp_ItemModelForMwIdSetting.Id.Value;
}

string GetMwIdName(uint id) {
    return MwId(id).GetName();
}



// get an offset from class name & member name
uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    if (ty is null) throw("Bad type: " + className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw("Bad member: " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}


// get an offset from a nod and member name
uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
    if (obj is null) return 0xFFFF;
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(obj);
    if (ty is null) throw("could not find a type for object");
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}



uint64 Dev_GetPointerForNod(CMwNod@ nod) {
    if (NodPtrs::g_TmpPtrSpace == 0) {
        NodPtrs::InitializeTmpPointer();
    }
    if (nod is null) return 0;
    Dev::SetOffset(NodPtrs::g_TmpSpaceAsNod, 0, nod);
    return Dev::GetOffsetUint64(NodPtrs::g_TmpSpaceAsNod, 0);
}


namespace NodPtrs {
    void InitializeTmpPointer() {
        if (g_TmpPtrSpace != 0) return;
        g_TmpPtrSpace = Dev::Allocate(0x1000);
        auto nod = CMwNod();
        uint64 tmp = Dev::GetOffsetUint64(nod, 0);
        Dev::SetOffset(nod, 0, g_TmpPtrSpace);
        @g_TmpSpaceAsNod = Dev::GetOffsetNod(nod, 0);
        Dev::SetOffset(nod, 0, tmp);
    }

    uint64 g_TmpPtrSpace = 0;
    CMwNod@ g_TmpSpaceAsNod = null;

    void Cleanup() {
        warn("NodPtrs::Cleanup");
        @g_TmpSpaceAsNod = null;
        if (g_TmpPtrSpace != 0) {
            Dev::Free(g_TmpPtrSpace);
            g_TmpPtrSpace = 0;
        }
    }
}
