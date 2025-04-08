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
