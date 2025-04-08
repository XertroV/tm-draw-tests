#if FALSE

uint64 g_ResultVtable = 0;

// void TestHandleCrash() {
//     print("\\$8f8\\$i - Create nods");
//     CPlugStaticObjectModel@ dyna = CPlugStaticObjectModel();
//     CPlugSolid2Model@ mesh = CPlugSolid2Model();
//     CPlugSurface@ surf = CPlugSurface();
//     print("\\$8f8\\$i - set mesh");
//     @dyna.Mesh = mesh;
//     print("\\$8f8\\$i - set static surf");
//     @dyna.Shape = surf;
//     print("\\$8f8\\$i - done");
// }

void ExtractGhosts() {
    // TestHandleCrash();

    auto app = GetApp();
    if (g_ResultVtable == 0) {
        try {
            auto gSample = app.PlaygroundScript.DataFileMgr.Ghosts[0];
            g_ResultVtable = Dev::GetOffsetUint64(gSample.Result, 0);
            print("Ghost vtable: " + Text::FormatPointer(g_ResultVtable));
        } catch {
            auto gSample = app.Network.ClientManiaAppPlayground.DataFileMgr.Ghosts[0];
            g_ResultVtable = Dev::GetOffsetUint64(gSample.Result, 0);
            print("Ghost vtable: " + Text::FormatPointer(g_ResultVtable));
        }
    }

    auto map = GetApp().RootMap;

    uint64 ghostNonce = Time::Now;
    array<GhostData@> ghosts;

    for (uint i = 0; i < map.ClipGroupInGame.Clips.Length; i++) {
        auto clip = map.ClipGroupInGame.Clips[i];
        for (uint j = 0; j < clip.Tracks.Length; j++) {
            auto track = clip.Tracks[j];
            // track.Blocks
            for (uint k = 0; k < track.Blocks.Length; k++) {
                auto block = cast<CGameCtnMediaBlockEntity>(track.Blocks[k]);
                if (block is null) continue;
                auto recordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(block, 0x58));
                if (recordData !is null) {
                    auto newGhost = CGameCtnGhost();
                    Dev::SetOffset(newGhost, 0x2e0, recordData);
                    recordData.MwAddRef();
                    newGhost.ModelIdentName.SetName("CarSport");
                    newGhost.ModelIdentAuthor.SetName("Nadeo");
                    newGhost.Validate_ChallengeUid.SetName(map.EdChallengeId);

                    auto ptr1 = GetSomeMemory();
                    auto ptr2 = GetSomeMemory();
                    Dev::SetOffset(newGhost, 0x2e8, ptr1);
                    Dev::SetOffset(newGhost, 0x2F0, uint(1));
                    Dev::SetOffset(newGhost, 0x2F4, uint(1));
                    Dev::Write(ptr1, ptr2);
                    Dev::Write(ptr2, uint(2));
                    Dev::Write(ptr2 + 4, uint(0x02000156));
                    Dev::Write(ptr2 + 8, uint(0));
                    Dev::Write(ptr2 + 0xC, uint(45450));
                    // ptr ot somewhere?
                    Dev::Write(ptr2 + 0x10, uint64(0));
                    Dev::Write(ptr2 + 0x18, uint64(0));
                    Dev::Write(ptr2 + 0x20, uint(0xD100000));
                    Dev::Write(ptr2 + 0x24, uint(1));

                    string ghostName = string(track.Name.StartsWith("ghost") ? track.Name.SubStr(6) : track.Name);  // Remove "ghost:" prefix
                    string savePath = ghostName + "_" + Text::Format("%d", ++ghostNonce) + ".Replay.Gbx";
                    ghosts.InsertLast(GhostData(ghostName, savePath, newGhost));
                    auto gd = ghosts[ghosts.Length - 1];
                    // gd.ConvertToScript(g_ResultVtable, newGhost);
                    gd.Save(map);
                }
            }
        }
    }
    trace("Done extracting ghosts");
}

uint64 GetSomeMemory() {
    CGameGhostScript@ tmp1 = CGameGhostScript();
    Dev::SetOffset(tmp1, 0x8, tmp1);
    auto ptr = Dev::GetOffsetUint64(tmp1, 0x8);
    for (uint i = 0; i < 0x58; i+=8) {
        Dev::SetOffset(tmp1, i, uint64(0));
    }
    return ptr;
}

enum LogLevel {
    Error,
    Warning,
    Info,
    Debug,
    Trace
}

void log(const string &in msg, LogLevel level, int line, const string &in func) {
    print("[" + tostring(level) + "] " + func + " (" + line + "): " + msg);
}

class GhostData {
    int selcetedGhostIndex = -1;

    string name;
    string savePath;
    CGameCtnGhost@ ghost;
    CGameGhostScript@ ghostScript;

    GhostData(const string &in name, const string &in savePath, CGameCtnGhost@ ghost) {
        this.name = name;
        this.savePath = savePath;
        @this.ghost = ghost;
        ConvertToScript(g_ResultVtable, ghost);
    }

    void ConvertToScript(uint64 CTmRaceResult_VTable_Ptr, CGameCtnGhost@ ghost) {
        if (ghost is null) @ghost = this.ghost;
        if (ghost is null) { log("Ghost is null in ConvertToScript", LogLevel::Error, 386, "ConvertToScript"); return; }
        if (CTmRaceResult_VTable_Ptr == 0) { log("CTmRaceResult_VTable_Ptr is null in ConvertToScript", LogLevel::Error, 387, "ConvertToScript"); return; }

        ghost.MwAddRef();

        @ghostScript = CGameGhostScript();
        MwId ghostId = MwId();
        Dev::SetOffset(ghostScript, 0x18, uint(0xFFFFFFFF));
        Dev::SetOffset(ghostScript, 0x20, ghost);
        uint64 ghostPtr = Dev::GetOffsetUint64(ghostScript, 0x20);
        IO::SetClipboard(Text::FormatPointer(ghostPtr));
        CGameGhostScript@ tmRaceResultNodPre = CGameGhostScript();
        Dev::SetOffset(tmRaceResultNodPre, 0x0, ghostScript);
        auto ghostScriptPtr = Dev::GetOffsetUint64(tmRaceResultNodPre, 0x0);
        Dev::SetOffset(tmRaceResultNodPre, 0x0, CTmRaceResult_VTable_Ptr);
        IO::SetClipboard(Text::FormatPointer(ghostScriptPtr));
        trace('casting');
        // CTmRaceResultNod@ tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod@>(tmRaceResultNodPre).Get();
        // auto tmRaceResultNod = cast<CTmRaceResultNod>(cast<CMwNod>(tmRaceResultNodPre));
        CTmRaceResultNod@ tmRaceResultNod = Dev::ForceCast<CTmRaceResultNod>(tmRaceResultNodPre).Get();
        trace('done casting; !null: ' + (tmRaceResultNod !is null));
        @tmRaceResultNodPre = null;
        Dev::SetOffset(tmRaceResultNod, 0x18, ghostPtr + 0x28);
        tmRaceResultNod.MwAddRef();

        Dev::SetOffset(ghostScript, 0x28, tmRaceResultNod);
    }

    void Save(CGameCtnChallenge@ rootMap) {
        if (ghostScript is null) { log("GhostScript is null in Save for ghost " + name, LogLevel::Error, 409, "Save"); return; }

        print(savePath);
        print(rootMap.MapName);
        print(ghostScript.Nickname);

        CGameDataFileManagerScript@ dataFileMgr;
        try {
            @dataFileMgr = GetApp().PlaygroundScript.DataFileMgr;
        } catch {
            @dataFileMgr = GetApp().Network.ClientManiaAppPlayground.DataFileMgr;
        }
        CWebServicesTaskResult@ taskResult = dataFileMgr.Replay_Save(savePath, rootMap, ghostScript);
        if (taskResult is null) {
            log("Replay task returned null for ghost " + name, LogLevel::Error, 418, "Save");
        }
        trace('saved ghost ' + name + ' to ' + savePath);
    }
}

Meta::PluginCoroutine@ _extractGhosts = startnew(ExtractGhosts);

#endif
