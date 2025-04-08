#if FALSE

void RunFindBlocks() {
    // RunFindNewPillars
    // RunFindPlatformBlocks();
}

enum RootNodes {
    BlocksCrash = 0,
    Blocks = 1,
    Grass = 2,
    Items = 3,
    Macroblocks = 4,
    Unk5 = 5,
    Mp4CustomItemsHuh6 = 6,
    Mp4CustomItemsHuh7 = 7,
    Unk8 = 8,
    EditorPlugins = 9,
}

void RunFindPlatformBlocks() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    auto pmt = cast<CSmEditorPluginMapType>(editor.PluginMapType);
    auto nbBlocks = pmt.BlockModels.Length;
    auto rn = cast<CGameCtnArticleNodeDirectory>(pmt.Inventory.RootNodes[RootNodes::Blocks]);
    CGameCtnArticleNode@ node;
    CGameCtnArticleNodeArticle@ art;
    CGameCtnArticleNodeDirectory@ dir;
    CGameCtnArticleNode@[] queue = {rn.Children[1], rn.ChildNodes[2], rn.ChildNodes[3], cast<CGameCtnArticleNodeDirectory>(rn.ChildNodes[6]).ChildNodes[1]};
    while (queue.Length > 0) {
        @rn = cast<CGameCtnArticleNodeDirectory>(queue[queue.Length - 1]);
        queue.RemoveLast();
        for (uint i = 0; i < rn.Children.Length; i++) {
            @node = rn.Children[i];
            @art = cast<CGameCtnArticleNodeArticle>(node);
            if (art !is null) {
                print("Found article: " + art.Name + " | " + art.Id.GetName());
            } else {
                @dir = cast<CGameCtnArticleNodeDirectory>(node);
                if (dir !is null) {
                    print("Found directory: " + dir.Name + " | " + dir.Id.GetName());
                    queue.InsertLast(dir);
                }
            }
        }
    }
}


void RunFindNewPillars() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    auto pmt = cast<CSmEditorPluginMapType>(editor.PluginMapType);
    auto nbBlocks = pmt.BlockModels.Length;
    auto nbPillars = 0;
    CGameCtnBlockInfo@ bi;
    for (uint i = 0; i < nbBlocks; i++) {
        @bi = pmt.BlockModels[i];
        if (bi.MaterialModifier2 !is null) {
            // print("Found matmod2 on " + bi.Name + " | " + bi.MaterialModifier2.Id.GetName() + " | " + GetFidFromNod(bi.MaterialModifier2).FileName);
            LogMatMod(bi.MaterialModifier2, i);
        }
        if (bi.MaterialModifier !is null) {
            // print("Found matmod on " + bi.Name + " | " + bi.MaterialModifier.Id.GetName() + " | " + GetFidFromNod(bi.MaterialModifier).FileName);
            LogMatMod(bi.MaterialModifier, i);
        }
    }
    print("Found " + matModNames.Length + " unique MatMods");
    print(Json::Write(matModPaths.ToJson()));
    print(Json::Write(matModNames.ToJson()));
}

string[] matModPaths;
string[] matModNames;

void LogMatMod(CPlugGameSkinAndFolder@ matmod, uint i) {
    auto fid = GetFidFromNod(matmod);
    if (fid is null) return;
    auto path = string(fid.ParentFolder.FullDirName).Split("\\Trackmania\\")[1].Replace("\\", "/") + fid.FileName;
    if (matModPaths.Find(path) == -1) {
        matModPaths.InsertLast(path);
        matModNames.InsertLast(matmod.Id.GetName());
        print("Found new matmod: " + path + " | " + matmod.Id.GetName() + " (index: " + i + ")");
    }
}

#endif
