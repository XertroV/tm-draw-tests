// void RunSaveMapFromReplayTest() {
//     auto app = GetApp();
//     while (app.TimeSinceInitMs < 90000) sleep(100);
//     auto replayInfo = app.ReplayRecordInfos[app.ReplayRecordInfos.Length - 1];
//     auto replay = cast<CGameCtnReplayRecord>(Fids::Preload(replayInfo.Fid));
//     auto map = replay.Challenge;
//     trace('Creating map folder...');
//     sleep(1000);
//     IO::CreateFolder(IO::FromUserGameFolder("Maps/RipMap"));
//     trace('Getting Map Fid...');
//     sleep(1000);
//     auto mapFid = Fids::GetUser("Maps/RipMap/Output.Map.Gbx");
//     ExploreNod(mapFid);
//     trace('Setting map offset...');
//     sleep(1000);
//     Dev::SetOffset(map, 0x8, mapFid);
//     Dev::SetOffset(mapFid, 0x80, map);
//     Dev::SetOffset(mapFid, 0x78, uint(0x3043000));
//     trace('Saving map...');
//     sleep(1000);
//     if (!Fids::Extract(mapFid)) {
//         warn("Extract failed!");
//     }
//     trace('Done!');
// }
