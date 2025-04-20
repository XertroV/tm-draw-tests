// void TryExtractNewItem() {
//     sleep(100);
//     auto item = CGameItemModel();
//     item.MwAddRef();
//     print("Created item! Refs: " + Reflection::GetRefCount(item));
//     auto fid = Fids::GetUser("test-out.Item.Gbx");
//     print("Fid created: " + (fid !is null));


//     Dev::SetOffset(item, 0x8, fid);
//     Dev::SetOffset(fid, GetOffset("CSystemFidFile", "Nod"), item);
//     print("Set fid<->item");

//     sleep(5000);

//     print("extracting item: " + fid.FullFileName);
//     // fid.CopyToFileRelative("test-out2.Item.Gbx", true);
//     // bool extracted = Fids::Extract(fid, true);
//     // print("Extracted: " + extracted);

//     sleep(5000);

//     auto vtable1 = Dev::GetOffsetUint64(item, 0x0);
//     print("vtable1: " + Text::FormatPointer(vtable1));
//     print("type: " + Reflection::TypeOf(item).Name);
//     item.MwRelease();
//     print("item released");
//     auto vtable2 = Dev::GetOffsetUint64(item, 0x0);
//     print("vtable2: " + Text::FormatPointer(vtable2));
//     print("type: " + Reflection::TypeOf(item).Name);
// }
