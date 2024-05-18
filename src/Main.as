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
    if (!g_Window || root is null) return;
    if (UI::Begin(PluginName, g_Window)) {
        root.DrawTabsAsSidebar();
    }
    UI::End();
}

float _PluginLoadTime = Time::Now;
float g_TimeMs = _PluginLoadTime;
void Update(float dt) {
    g_TimeMs += dt;
}

TabGroup@ root;
NG::GraphTab@ g_GraphTab;

void Main() {
    startnew(LoadFonts);
    yield();
    yield();
    @root = RootTabGroupCls();
    @g_GraphTab = NG::GraphTab(root);
}

vec2 g_lastMousePos;

// only updates when not hovering imgui and input not carried off imgui
void OnMouseMove(int x, int y) {
    g_lastMousePos = vec2(x, y);
    // trace(g_lastMousePos.ToString());
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
