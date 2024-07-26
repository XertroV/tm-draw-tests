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
}

void Render() {

    // if (testGizmo is null) @testGizmo = RotationTranslationGizmo("test");
    // testGizmo.DrawAll();

    // RenderFireworkTest();
    if (!g_Window || root is null) return;
    if (UI::Begin(PluginName, g_Window)) {
        root.DrawTabsAsSidebar();
    }
    UI::End();
}

float _PluginLoadTime = Time::Now;
float g_TimeMs = _PluginLoadTime;
float g_DT;
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
}


TabGroup@ root;
NG::GraphTab@ g_GraphTab;

void Main() {
    // startnew(RunFireworksTest);
    // RunSaveMapFromReplayTest();
    // BlockInfoGroups::Run();
    // BlockInfoGroups::RunGetPillarsAndReplacements();
    // startnew(RunFindBlocks);
    InitNodeGraphStuff();
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
