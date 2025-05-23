
void SetClipboard(const string &in msg) {
    IO::SetClipboard(msg);
    Notify("Copied: " + msg.SubStr(0, 300));
}

funcdef bool LabeledValueF(const string &in l, const string &in v);

bool ClickableLabel(const string &in label, const string &in value) {
    return ClickableLabel(label, value, ": ");
}
bool ClickableLabel(const string &in label, const string &in value, const string &in between) {
    UI::Text(label.Length > 0 ? label + between + value : value);
    if (UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::SetMouseCursor(UI::MouseCursor::Hand);
    }
    return UI::IsItemClicked();
}

bool CopiableLabeledPtr(CMwNod@ nod) {
    return CopiableLabeledValue("ptr", Text::FormatPointer(Dev_GetPointerForNod(nod)));
}
bool CopiableLabeledPtr(const uint64 ptr) {
    return CopiableLabeledValue("ptr", Text::FormatPointer(ptr));
}

bool CopiableLabeledValue(const string &in label, const string &in value) {
    if (ClickableLabel(label, value)) {
        SetClipboard(value);
        return true;
    }
    return false;
}

bool CopiableValue(const string &in value) {
    if (ClickableLabel("", value)) {
        SetClipboard(value);
        return true;
    }
    return false;
}
