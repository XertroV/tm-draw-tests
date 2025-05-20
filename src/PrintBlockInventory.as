#if FALSE

void PrintBlockInventory() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto inventory = editor.PluginMapType.Inventory;
    PrintInventoryRootNode(inventory, InventoryRootNode::Blocks);
}

void PrintInventoryRootNode(CGameEditorGenericInventory@ inv, InventoryRootNode root) {
    print("---- [ INVENTORY ROOT NODE " + tostring(root) + " ] ----");

    CGameCtnArticleNodeDirectory@ rootNode = cast<CGameCtnArticleNodeDirectory>(inv.RootNodes[int(root)]);
    if (rootNode is null) {
        print("Root node is null");
        return;
    }
    string[]@ linesOut = array<string>();

    DumpInvDirectory(rootNode, "/", "", linesOut);

    print("Dumping directory: " + tostring(root));

    IO::File file(IO::FromStorageFolder("InventoryDump.txt"), IO::FileMode::Write);
    if (linesOut.Length > 0) {
        for (uint i = 0; i < linesOut.Length; i++) {
            file.WriteLine(linesOut[i]);
            if (i % 200 == 0) yield();
        }
        // print(Json::Write(linesOut.ToJson()));
        // print("   >> CONTENTS <<\n" + string::Join(linesOut, "\n"));
    }
    file.Close();

    OpenExplorerPath(IO::FromStorageFolder("InventoryDump.txt"));

    print("---- [ DONE INVENTORY ROOT NODE " + tostring(root) + " ] ----");
}

void DumpInvDirectory(CGameCtnArticleNodeDirectory@ dir, const string &in path, const string &in numPath, string[]@ linesOut) {
    if (dir is null) {
        print("Directory is null: " + path);
        return;
    }

    for (uint i = 0; i < dir.Children.Length; i++) {
        CGameCtnArticleNode@ node = dir.Children[i];
        if (node is null) continue;

        string newPath = path + node.Name;
        string newNumPath = numPath.Length == 0 ? tostring(i+1) : numPath + "-" + tostring(i+1);

        if (node.IsDirectory) {
            DumpInvDirectory(cast<CGameCtnArticleNodeDirectory>(node), newPath + "/", newNumPath, linesOut);
        } else {
            linesOut.InsertLast(newNumPath + ", " + newPath + ", " + node.Name);
        }
    }
}


















enum InventoryRootNode {
    CrashBlocks = 0,
    Blocks = 1,
    Grass = 2,
    Items = 3,
    Macroblocks = 4,
    // 6/7 = MP4? Stadium256?
    Plugins = 9,

}
#endif
