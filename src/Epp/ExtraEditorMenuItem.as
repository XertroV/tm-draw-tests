const vec2 UiUv_Screen_WH = vec2(3.2, 1.8);
const vec2 Inv_UiUv_Screen_WH = vec2(1.0/3.2, 1.0/1.8);

int font_Bold = nvg::LoadFont("DroidSans-Bold.ttf");
const vec2 btnTextOff = vec2(0.0, 0.007);
float toolbarBtnWidth = 0.05;

class ExtraMainToolbarItem {
    string name;
    string tooltip;
    string icon;
    string icon2;
    string idNonce;
    int order;
    vec2 btnUv;
    vec2 screenPos;
    vec4 color;
    vec4 hoverColor = cWhite;
    vec4 secColor = cWhite;
    vec4 secHoverColor = cRed;
    bool hovered, clicked;
    CoroutineFunc@ onClick;

    ExtraMainToolbarItem(int order, const string &in icon, const string &in name, const string &in tooltip, const vec4 &in col = cBlack, const string &in icon2 = "") {
        this.order = order;
        this.icon = icon;
        this.icon2 = icon2;
        this.name = name;
        this.tooltip = tooltip;
        this.color = col;
        idNonce = idNonce + Math::Rand(-20000, 200000);
        SetBtnUv();
    }

    vec2 base = vec2(0.235, 0.939);
    void SetBtnUv() {
        btnUv = base + vec2(toolbarBtnWidth * order, 0.0);
    }

    void RunOnClick() {
        if (onClick !is null) {
            try {
                onClick();
            } catch {
                NotifyWarning("Error in onClick function for " + name + " / " + getExceptionInfo());
            }
        } else {
            NotifyWarning("No onClick function set for " + name);
        }
    }

    void Draw(ToolbarExtras@ toolbar) {
        // base = UI::SliderFloat2("pos", base, -2, 2, "%.3f");
        // toolbarBtnWidth = UI::InputFloat("btn width", toolbarBtnWidth, .01, .05, "%.3f", UI::InputTextFlags::AutoSelectAll);
        // SetBtnUv();


        // get editor overlay size and position
        // calculate horizontal pos for start of the item
        screenPos = toolbar.UvToScreen(btnUv + btnTextOff);
        auto rectSz = vec2(toolbar.fontSize, toolbar.fontSize);
        auto tl = screenPos - rectSz * .5;
        hovered = IsWithin(g_lastMousePos, vec4(tl, rectSz))
            && !IsOpenplanetUIHovered()
            && IsActionMapEditor();

        clicked = hovered && UI::IsMouseClicked(UI::MouseButton::Left);
        if (clicked) {
            startnew(CoroutineFunc(RunOnClick));
        }

        // nvgDrawRect(tl, rectSz);
        // nvg::TextAlign(nvg::Align::Left | nvg::Align::Top);
        // nvg::FillColor(col);
        nvgDrawTextWithStroke(screenPos, GetIcon(), GetPrimaryColor(), 0.0);
        if (icon2.Length > 0) {
            screenPos = toolbar.UvToScreen(btnUv + btnTextOff * .6);
            nvg::FontSize(toolbar.fontSize * 0.6);
            nvgDrawTextWithStroke(screenPos, GetIcon2(), GetSecondaryColor(), 0.0);
            nvg::FontSize(toolbar.fontSize);
        }

        if (hovered) {
            startnew(CoroutineFunc(ShowTooltip)).WithRunContext(Meta::RunContext::UpdateSceneEngine);
        }

        return;

        nvg::Reset();
        nvg::BeginPath();
        // // from [-e, e] for both
        // for (float x = -xExtent; x <= xExtent; x += dx) {
        //     for (float y = -yExtent; y <= yExtent; y += dy) {
        //         // scale -1,1 to 0,1
        //         auto p3 = vec3((vec2(x, y)), 0);
        //         auto pos = (loc * p3).xy * g_screen;
        //         auto pxSize = MathX::Abs(p3.xy) * g_screen;
        //         // if (first) nvgDrawRect(g_screen / 4., pxSize);
        //         pos.y = halfScreen.y + pos.y;
        //         pos.x = halfScreen.x - pos.x;
        //         // pos.x = g_screen.x * .5 - pos.x;
        //         // pos.y = g_screen.y * .5 - pos.y;
        //         nvg::FontSize(32.);
        //         nvg::TextAlign(Get_NvgAlign(int(x), int(y)));
        //         nvgDrawTextWithStroke(pos, "" + x + "," + y + " @ " + pos.ToString(), cBlack, 5., cWhite);
        //         nvgDrawCircle(pos);

        //         first = false;
        //     }
        // }
        nvg::ClosePath();
    }

    string GetIcon() {
        return icon;
    }
    string GetIcon2() {
        return icon2;
    }
    vec4 GetPrimaryColor() {
        return hovered ? hoverColor : color;
    }
    vec4 GetSecondaryColor() {
        return hovered ? secHoverColor : secColor;
    }
    string GetTooltip() {
        return tooltip;
    }

    void ShowTooltip() {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        auto frameMain = cast<CControlContainer>(editor.EditorInterface.InterfaceRoot.Childs[0]);
        auto frameToolTips = cast<CControlContainer>(frameMain.Childs[6]);
        auto overlayTooltips = cast<CControlEntry>(frameToolTips.Childs[0]);
        overlayTooltips.String = GetTooltip();
        // trace('Set tooltip: ' + overlayTooltips.String + " / ptr: " + Text::FormatPointer(Dev_GetPointerForNod(overlayTooltips)));
        // overlayTooltips.Clean();
        overlayTooltips.Draw();
        // trace('Set tooltip: ' + overlayTooltips.String);
    }
}


class MacroRecordMainToolbarItem : ExtraMainToolbarItem {
    MacroRecordMainToolbarItem(int order) {
        super(order, Icons::CircleONotch, "Macroblock Recording", "[E++] Record Macroblock.\nOn finish -> Copy mode.", cBlack, Icons::VideoCamera);
    }

    // tmp standin
    bool active = false;
    void RunOnClick() override {
        ExtraMainToolbarItem::RunOnClick();
        active = !active;
    }

    vec4 GetPrimaryColor() override {
        if (active) return hovered ? cBlack : cRed;
        return ExtraMainToolbarItem::GetPrimaryColor();
    }
    vec4 GetSecondaryColor() override {
        if (active) return hovered ? cRed : cWhite;
        return ExtraMainToolbarItem::GetSecondaryColor();
    }
    string GetIcon() override {
        if (active) return Icons::Square;
        return ExtraMainToolbarItem::GetIcon();
    }
    string GetIcon2() override {
        if (active) return Icons::VideoCamera;
        return ExtraMainToolbarItem::GetIcon2();
    }
    string GetTooltip() override {
        if (active) return "[E++] Recording Macroblock.\nClick to stop recording.";
        return ExtraMainToolbarItem::GetTooltip();
    }
}


// x,y in [-1, 0, 1]
int Get_NvgAlign(int8 x, int8 y) {
    int r = 0;
    r |= (x < 0 ? nvg::Align::Left : x == 0 ? nvg::Align::Center : nvg::Align::Right);
    r |= (y < 0 ? nvg::Align::Top : y == 0 ? nvg::Align::Middle : nvg::Align::Bottom);
    return r;
}

ExtraMainToolbarItem@ g_MainToolbarIcon_MacroRecord;

const float fontScreenRatio = 0.032;

class ToolbarExtras {
    array<ExtraMainToolbarItem@> items;

    ToolbarExtras() {
        // add extra items here
        @g_MainToolbarIcon_MacroRecord = MacroRecordMainToolbarItem(0);
        items.InsertLast(g_MainToolbarIcon_MacroRecord);
        items.InsertLast(ExtraMainToolbarItem(1, Icons::Bicycle, "IDK", "Starts recording a macroblock.\nWhen you are finished it will take you to copy mode. [E++]"));
    }

    vec2 halfScreen;
    // mat4 loc;
    vec2 scale;
    vec2 offset;
    float fontSize;
    bool doDraw = false;

    void UpdateEditorBounds() {
        halfScreen = g_screen * .5;
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorFree>(app.Editor);
        doDraw = editor !is null && IsActionMapEditor() && EditorToolbarIsVisible(editor.EditorInterface.InterfaceRoot);
        doDraw = doDraw && int(app.LoadProgress.State) == 0;
        if (!doDraw) return;
        auto loc = mat4(editor.EditorInterface.InterfaceRoot.Parent.Item.Corpus.Location);
        scale = vec2(loc.xx, loc.yy);
        offset = vec2(loc.tx, loc.ty) * -1.;
        fontSize = fontScreenRatio * g_screen.y * scale.y;
    }

    vec2 UvToScreen(const vec2 &in uv) {
        auto pos = uv * scale + offset * 2.0 * Inv_UiUv_Screen_WH;
        return pos * halfScreen + halfScreen;
    }

    void Draw() {
        UpdateEditorBounds();
        if (!doDraw) return;
        nvg::Reset();
        nvg::FontFace(font_Bold);
        nvg::FontSize(fontSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        for (uint i = 0; i < items.Length; i++) {
            auto b = items[i];
            UI::PushID(b.idNonce);
            b.Draw(this);
            UI::PopID();
        }
    }
}

ToolbarExtras@ g_toolbarExtras = ToolbarExtras();

// float screenAspect;
// const float aspect16x9 = 16.0 / 9.0;

// // vec2 of coefficients to multiply resolution by to get a 16x9 aspect, shrinked to fit the screen
// vec2 GetAspectCorrection() {
//     screenAspect = g_screen.x / g_screen.y;
//     if (screenAspect > aspect16x9) {
//         return vec2(aspect16x9 / screenAspect, 1.0);
//     } else {
//         return vec2(1.0, screenAspect / aspect16x9);
//     }
// }

// vec2 UiScale2Pixels(vec2 sizeUi) {
//     return sizeUi * g_screen * GetAspectCorrection();
// }



bool IsWithin(const vec2 &in pos, const vec2 &in min, const vec2 &in max) {
    return pos.x >= min.x && pos.x <= max.x
        && pos.y >= min.y && pos.y <= max.y;
}
bool IsWithin(const vec2 &in pos, const vec4 &in rect) {
    return pos.x >= rect.x && pos.x < (rect.x + rect.z)
        && pos.y >= rect.y && pos.y < (rect.y + rect.w);
}

bool IsOpenplanetUIHovered() {
    return int(GetApp().InputPort.MouseVisibility) == 2;
}

bool IsActionMapEditor() {
    return UI::CurrentActionMap() == "CtnEditor";
}

bool EditorToolbarIsVisible(CControlContainer@ editorRoot) {
    if (editorRoot is null || !editorRoot.IsVisible) return false;
    auto frameMain = cast<CControlContainer>(editorRoot.Childs[0]);
    if (frameMain is null || !frameMain.IsVisible) return false;
    auto frameToolTips = cast<CControlContainer>(frameMain.Childs[6]);
    if (frameToolTips is null || !frameToolTips.IsVisible) return false;
    auto overlayTooltips = cast<CControlEntry>(frameToolTips.Childs[0]);
    if (overlayTooltips is null || !overlayTooltips.IsVisible) return false;
    return true;
}
