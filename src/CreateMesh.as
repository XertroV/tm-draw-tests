// Meta::PluginCoroutine@ _createMesh = startnew(_CreateMesh);

void _CreateMesh() {
    auto s2m = CPlugSolid2Model();
    s2m.MwAddRef();
    auto tmp = CMwNod();
    Dev::SetOffset(tmp, 8, s2m);
    auto ptr = Dev::GetOffsetUint64(tmp, 8);
    Dev::SetOffset(tmp, 8, uint64(0));
    print("new s2m ptr: " + Text::FormatPointer(ptr));
    IO::SetClipboard(Text::FormatPointer(ptr));
    ExploreNod("New S2M", s2m);
}
