NG::FidDrive UI_Combo_FidDrive(const string &in name, NG::FidDrive value) {
    if (UI::BeginCombo(name, tostring(value))) {
        if (UI::Selectable("User", value == NG::FidDrive::User)) value = NG::FidDrive::User;
        if (UI::Selectable("Game", value == NG::FidDrive::Game)) value = NG::FidDrive::Game;
        if (UI::Selectable("Fake", value == NG::FidDrive::Fake)) value = NG::FidDrive::Fake;
        if (UI::Selectable("ProgramData", value == NG::FidDrive::ProgramData)) value = NG::FidDrive::ProgramData;
        if (UI::Selectable("Resource", value == NG::FidDrive::Resource)) value = NG::FidDrive::Resource;
        UI::EndCombo();
    }
    return value;
}









void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifySuccess(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.4, .7, .1, .3), 10000);
    trace("Notified: " + msg);
}

shared void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

void Dev_NotifyWarning(const string &in msg) {
#if DEV
    warn(msg);
    UI::ShowNotification("Dev: Warning", msg, vec4(.9, .6, .2, .3), 15000);
#endif
}
