[Setting hidden]
bool g_Window = true;

const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$f5d";
const string PluginIcon = Icons::Cogs;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", g_Window)) {
        g_Window = !g_Window;
    }
    if (UI::MenuItem("g_RunDipsItemExp", "", g_RunDipsItemExp)) {
        g_RunDipsItemExp = !g_RunDipsItemExp;
    }
    // CM_Editor::RenderMenu();
    if (UI::BeginMenu(MenuTitle + " Debug")) {
        if (UI::MenuItem("Draw Debug Window", "", g_DrawLittleDebugWindow)) {
            g_DrawLittleDebugWindow = !g_DrawLittleDebugWindow;
        }
        DrawDebugSimpleText();
        UI::EndMenu();
    }
}

bool g_DrawLittleDebugWindow = false;
void DrawLittleDebugWindow() {
    if (!g_DrawLittleDebugWindow) return;
    if (UI::Begin("Debug Window", g_DrawLittleDebugWindow)) {
        DrawDebugSimpleText();
    }
    UI::End();
}
void DrawDebugSimpleText() {
    UI::Text("g_lastMousePos: " + g_lastMousePos.ToString());
    UI::Text("g_screen = " + g_screen.ToString());
    UI::Text("mouse pos uv = " + (g_lastMousePos / g_screen).ToString());
    UI::Text("g_DT: " + g_DT);
    UI::Text("g_TimeMs: " + g_TimeMs);
    UI::Text("g_shiftDown: " + g_shiftDown);
    UI::Text("g_ctrlDown: " + g_ctrlDown);
    UI::Text("g_altDown: " + g_altDown);
}

void Render() {
    Render_DipsItemExperiment();
    // CM_Editor::Render();
    g_toolbarExtras.Draw();
    DrawLittleDebugWindow();

    // if (testGizmo is null) @testGizmo = RotationTranslationGizmo("test");
    // testGizmo.DrawAll();

    // mat4 m = mat4::Translate(vec3(764, 140, 764)) * mat4::Scale(vec3(32, 8, 32));
    // auto faceOrder = getCubeFaceBackToFront(m);
    // for (uint i = 0; i < 6; i++) {
    //     drawCubeFace(m, faceOrder[i]);
    // }

    // RenderFireworkTest();

    if (!g_Window || root is null) return;
    if (UI::Begin(PluginName, g_Window)) {
        root.DrawTabsAsSidebar();
    }
    UI::End();
}

void RenderEarly() {
    g_lastMousePos = vec2(UI::GetMousePos());
}

float _PluginLoadTime = Time::Now;
float g_TimeMs = _PluginLoadTime;
float g_DT;
float g_LastGcDt, g_LastGcDt2, g_LastGcDt3;
vec2 g_screen = vec2(2000);
void Update(float dt) {
    g_DT = dt;
    g_TimeMs += dt;
    g_screen = vec2(Draw::GetWidth(), Draw::GetHeight());
}


/** Called when the plugin is unloaded and completely removed from memory.
*/
void OnDestroyed() {
    if (g_GraphTab !is null) g_GraphTab.SaveGraph();
    NodPtrs::Cleanup();
    CheckUnhookAllRegisteredHooks();
}


TabGroup@ root;
NG::GraphTab@ g_GraphTab;

void Main() {
    // startnew(PrintBlockInventory);
    // TestOutStuff();
    // ForceCastBufferTest();

    startnew(DipsItemExperiment).WithRunContext(Meta::RunContext::AfterMainLoop);
    // for dips++ CustomMap
    // CM_Editor::OnPluginLoad();
    // CM_Editor::Main();

    // tmp disable for load speed
    if (false) InitNodeGraphStuff();

    // startnew(TryExtractNewItem);
    // print("Path split: /test\\234/a/lskdjf.map.gbx: " + ArrayOfStrToStr(SplitPath("/test\\234/a/lskdjf.map.gbx")));

    // startnew(RunFireworksTest);
    // RunSaveMapFromReplayTest();
    // BlockInfoGroups::Run();
    // BlockInfoGroups::RunGetPillarsAndReplacements();
    // startnew(RunFindBlocks);
    // startnew(RunJsonBenchmarks);

//     CMwCmdBufferCore@ cmdBuffer = CMwCmdBufferCore();
//     auto vtablePtr = Dev::GetOffsetUint64(cmdBuffer, 0x0);
//     trace("vtablePtr: " + Text::FormatPointer(vtablePtr));
//     IO::SetClipboard(Text::FormatPointer(vtablePtr));
//     UI::ShowNotification("copied vtablePtr: " + Text::FormatPointer(vtablePtr));
}

void InitNodeGraphStuff() {
    startnew(LoadFonts);
    yield();
    yield();
    @root = RootTabGroupCls();
    @g_GraphTab = NG::GraphTab(root);
    sleep(0);
    yield(500);
}



vec2 g_lastMousePos;

// only updates when not hovering imgui and input not carried off imgui
void OnMouseMove(int x, int y) {
    g_lastMousePos = vec2(x, y);
    // trace(g_lastMousePos.ToString());
}

bool g_InterceptOnMouseClick = false;
bool g_InterceptClickRequiresTestMode = false;
// x, y, button
int3 g_InterceptedMouseClickPosBtn = int3();
// CM_Editor::ProjectComponent@ componentWaitingForMouseClick = null;

void OnInterceptedMouseClick(int x, int y, int button) {
    g_InterceptedMouseClickPosBtn.x = x;
    g_InterceptedMouseClickPosBtn.y = y;
    g_InterceptedMouseClickPosBtn.z = button;
    g_InterceptOnMouseClick = false;
    // if (componentWaitingForMouseClick !is null) {
    //     try {
    //         componentWaitingForMouseClick.OnMouseClick(x, y, button);
    //     } catch {
    //         error("OnInterceptedMouseClick failed: " + getExceptionInfo());
    //     }
    //     @componentWaitingForMouseClick = null;
    // }
}

/** Called whenever a mouse button is pressed. `x` and `y` are the viewport coordinates. */
UI::InputBlocking OnMouseButton(bool down, int button, int x, int y) {
    // if (down && button == 0 && g_InterceptOnMouseClick && (!g_InterceptClickRequiresTestMode || EditorIsInTestPlaceMode())) {
    //     OnInterceptedMouseClick(x, y, button);
    //     return UI::InputBlocking::Block;
    // }
    return UI::InputBlocking::DoNothing;
}

bool IsLMBPressed() {
    return UI::IsMouseDown(UI::MouseButton::Left);
}

bool IsRMBPressed() {
    return UI::IsMouseDown(UI::MouseButton::Right);
}

bool IsShiftDown() {
    // return (Time::Now / 1000) % 2 == 0;
    return g_shiftDown;
}

bool IsCtrlDown() {
    return g_ctrlDown;
}

bool IsAltDown() {
    return g_altDown;
}

bool g_shiftDown = false;
bool g_ctrlDown = false;
bool g_altDown = false;

/** Called whenever a key is pressed on the keyboard. See the documentation for the [`VirtualKey` enum](https://openplanet.dev/docs/api/global/VirtualKey).
*/
UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (key == VirtualKey::Shift) {
        g_shiftDown = down;
    } else if (key == VirtualKey::Control) {
        g_ctrlDown = down;
    } else if (key == VirtualKey::Menu) {
        g_altDown = down;
    }
    return UI::InputBlocking::DoNothing;
}

void RunJsonBenchmarks() {
    Bench(FromFileOpenplanetJson, "FromFileOpenplanetJson", 10, true);
    Bench(WriteOpenplanetJson, "WriteOpenplanetJson", 10, true);
    Bench(ToFileOpenplanetJson, "ToFileOpenplanetJson", 10, true);
    Bench(InstanceSimpleJsonObj1k, "InstanceSimpleJsonObj1k", 1000);
    Bench(WriteSimpleJsonObj1k, "WriteSimpleJsonObj1k", 1000);
    Bench(ParseSimpleJsonObj1k, "ParseSimpleJsonObj1k", 1000);
}

void Bench(CoroutineFunc@ f, const string &in name, int count, bool yield_between = false) {
    uint start = Time::Now;
    uint duration = 0.;
    for (int i = 0; i < count; i++) {
        f();
        if (yield_between) {
            duration += Time::Now - start;
            sleep(0);
            start = Time::Now;
        }
    }
    uint end = Time::Now;
    uint ms = end - start + duration;
    trace(name + " took " + (float(ms) / float(count)) + "ms per iteration");
}

Json::Value@ OpenplanetJson;

void FromFileOpenplanetJson() {
    @OpenplanetJson = Json::FromFile(IO::FromDataFolder("OpenplanetNext.json"));
}

void WriteOpenplanetJson() {
    Json::Write(OpenplanetJson);
}

void ToFileOpenplanetJson() {
    Json::ToFile(IO::FromDataFolder("OpenplanetNext.json.tmp"), OpenplanetJson);
}

Json::Value@ SimpleJson;

void InstanceSimpleJsonObj1k() {
    @SimpleJson = Json::Object();
    for (int i = 0; i < 100; i++) {
        SimpleJson["key" + i] = Json::Array();
        for (int j = 0; j < 100; j++) {
            SimpleJson["key" + i].Add(j);
        }
    }
}

string simpleJsonStr;

void WriteSimpleJsonObj1k() {
    simpleJsonStr = Json::Write(SimpleJson);
}

void ParseSimpleJsonObj1k() {
    Json::Parse(simpleJsonStr);
}




UI::Font@ g_MonoFont;
UI::Font@ g_BoldFont;
UI::Font@ g_BigFont;
UI::Font@ g_MidFont;
UI::Font@ g_NormFont;
void LoadFonts() {
    @g_BoldFont = UI::LoadFont("DroidSans-Bold.ttf");
    @g_MonoFont = UI::LoadFont("DroidSansMono.ttf");
    @g_BigFont = UI::LoadFont("DroidSans.ttf", 26);
    @g_MidFont = UI::LoadFont("DroidSans.ttf", 20);
    @g_NormFont = UI::LoadFont("DroidSans.ttf", 16);
}



void AddSimpleTooltip(const string &in msg, bool pushFont = false) {
    if (UI::IsItemHovered()) {
        if (pushFont) UI::PushFont(g_NormFont);
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
        if (pushFont) UI::PopFont();
    }
}

void AddIndentedTooltip(const string &in msg, bool pushFont = false, float w = -1.0) {
    if (UI::IsItemHovered()) {
        if (pushFont) UI::PushFont(g_NormFont);
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::Indent(w);
        UI::TextWrapped(msg);
        UI::Unindent(w);
        UI::EndTooltip();
        if (pushFont) UI::PopFont();
    }
}

// void AddHoverRight(const string &in msg, float maxWidth = 300.0) {
//     if (!UI::IsItemHovered()) return;
//     auto rect = UI::GetItemRect();
//     auto windowPos = UI::GetWindowPos();
//     auto scrollPos = vec2(UI::GetScrollX(), UI::GetScrollY());
//     auto pos = UI::GetCursorPos();
//     UI::SameLine();
//     UI::TextWrapped(msg);
//     return;
//     auto rightPos = UI::GetCursorPos();
//     UI::SetCursorPos(vec2(pos.x, rightPos.y));
//     UI::SetNextItemOpen(true, UI::Cond::Always);
//     if (UI::BeginMenu("##hoverRightMenu", true)) {
//         UI::TextWrapped(msg);
//         UI::EndMenu();
//     }
//     UI::SetCursorPos(pos);
//     // rightPos.x = rect.x + rect.z;
//     // rightPos.y = rect.y;
//     // auto cardPos = rightPos + vec2(rect.z + 20, 0);
//     // UI::SetNextWindowPos(cardPos.x, cardPos.y, UI::Cond::Appearing);
//     // UI::SetNextWindowSize(maxWidth, 0, UI::Cond::Appearing);
//     // if (UI::Begin("##hoverRight", UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoSavedSettings | UI::WindowFlags::AlwaysAutoResize)) {
//     //     UI::TextWrapped(msg);
//     //     UI::TextWrapped("windowPos: " + windowPos.ToString());
//     //     UI::TextWrapped("scrollPos: " + scrollPos.ToString());
//     //     UI::TextWrapped("pos: " + pos.ToString());
//     //     UI::TextWrapped("rightPos: " + rightPos.ToString());
//     //     UI::TextWrapped("cardPos: " + cardPos.ToString());
//     // }
//     // UI::End();
// }
