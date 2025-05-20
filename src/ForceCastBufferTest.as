#if FALSE
void ForceCastBufferTest() {
    auto ptr = Dev::Allocate(0x1000);
    auto @nod = CMwNod();
    Dev::SetOffset(nod, 0x8, ptr);
    print("got ptr: " + Text::FormatPointer(ptr) + " and nod");
    auto allocAsNod = Dev::GetOffsetNod(nod, 0x8);
    print("allocAsNod");
    Dev::SetOffset(nod, 0x8, uint64(0));
    MemoryBuffer@ buf = MemoryBuffer();
    print("zeroing memory");
    for (uint i = 0; i < 100; i++) { // at least 87 needed for 0x2b8 = char vis size
        buf.Write(uint64(0));
        Dev::Write(ptr + i * 8, uint64(0));
    }
    // SGameCtnBlockInfoVariant_UsedData
    print("converting to NSceneCharVis_SMgr");
    NSceneCharVis_SMgr@ fake = Dev::ForceCast<NSceneCharVis_SMgr@>(allocAsNod).Get();
    print("got fake");
    print("fake.CharModels.Length: ...");
    print("fake.CharModels.Length: " + fake.CharModels.Length);
}
#endif
