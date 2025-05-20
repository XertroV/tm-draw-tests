// Editor for Custom Maps

namespace CM_Editor {
    const string PluginStorageRoot = IO::FromStorageFolder("");
    const string ProjectsDir = IO::FromStorageFolder("CM_Editor/Projects");
    bool checkedDir = false;

    [Setting hidden]
    bool S_EditorWindowOpen = true;

    void OnPluginLoad() {
        checkedDir = _RunCheckProjDir();
    }

    bool _RunCheckProjDir() {
        if (checkedDir) return true;
        if (!IO::FolderExists(ProjectsDir)) {
            IO::CreateFolder(ProjectsDir, true);
        }
        return true;
    }

    void Main() {
        // if (!IO::FolderExists(ProjectsDir)) IO::CreateFolder(ProjectsDir, true);
        // auto projs = ListProjects();
        // if (projs.Length == 0) IO::CreateFolder(ProjectsDir + "/Test", false);
        // if (projs.Length < 2) IO::CreateFolder(ProjectsDir + "/Test2_ASDF", false);
        // @projs = ListProjects();
        // // trace("Projects: " + Json::Write(projs.ToJson()));
        // Dev::InterceptProc("CGameCtnEditorFree", "SwitchToTestWithMapTypeFromScript_OnOk", Dev::ProcIntercept(_SwitchToTestWithMapTypeFromScript_OnOk));
    }

    // bool _SwitchToTestWithMapTypeFromScript_OnOk(CMwStack &in stack) {
    //     NotifyWarning("SwitchToTestWithMapTypeFromScript_OnOk");
    //     return true;
    // }

    void Render() {
        if (!S_EditorWindowOpen) return;
        UI::SetNextWindowSize(500, 370, UI::Cond::FirstUseEver);
        if (UI::Begin("Dips++ CustomMap Editor", S_EditorWindowOpen)) {
            Draw_CMEditor_WindowMain();
        }
        UI::End();
    }

    void RenderMenu() {
        if (UI::MenuItem("Dips++ CustomMap Editor", "", S_EditorWindowOpen)) {
            S_EditorWindowOpen = !S_EditorWindowOpen;
        }
    }

    // MARK: Project Management

    string[]@ ListProjects() {
        auto folders = IO::IndexFolder(ProjectsDir, false);
        for (int i = int(folders.Length) - 1; i >= 0; i--) {
            if (!folders[i].EndsWith("/")) {
                trace('removing non-folder: ' + folders[i]);
                folders.RemoveAt(i);
            } else {
                folders[i] = folders[i].Replace(ProjectsDir, "");
                // remove leading and trailing slashes
                folders[i] = folders[i].SubStr(1, folders[i].Length - 2);
            }
        }
        return folders;
    }

    // MARK: Render/UI

    void Draw_CMEditor_WindowMain() {
        CM_Editor_TG.DrawTabs();
        CM_Editor_TG.DrawWindows();
    }

    TabGroup@ CM_Editor_TG = Init_CM_Editor_TG();
    TabGroup@ Init_CM_Editor_TG() {
        auto tg = TabGroup("CM_Editor_TG", null);
        LoadProjTab(tg);
        return tg;
    }

    class CompactTab : Tab {
        CompactTab(TabGroup@ parent, const string &in tabName, const string &in icon) {
            super(parent, tabName, icon);
            noContentWrap = true;
        }
    }

    class LoadProjTab : CompactTab {
        string[]@ projects;
        ProjectMeta@[] projectMetas;

        LoadProjTab(TabGroup@ parent) {
            super(parent, "Your Projects", Icons::FolderOpenO);
        }

        void DrawInner() override {
            if (projects is null) RefreshProjects();
            UI::SeparatorText("Your Projects (" + projects.Length + ")");

            if (UI::Button(Icons::FileO + " New")) {
                OnClickCreateNew();
            }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpenO + " Browse All")) {
                OpenExplorerPath(ProjectsDir);
            }
            UI::SameLine();
            if (UI::Button(Icons::Refresh + Icons::FolderOpenO + " Refresh")) {
                RefreshProjects();
            }

            UI::Separator();
            DrawProjectSelector();
        }

        void ResetSelectedProj() {
            selectedProject = "";
            selectedProjectIx = -1;
        }

        void SelectProjectNamed(const string &in name) {
            auto ix = projects.Find(name);
            if (ix < 0) {
                NotifyWarning("Project not found: " + name);
                return;
            }
            selectedProject = name;
            selectedProjectIx = ix;
        }

        void RefreshProjects() {
            ResetSelectedProj();
            @projects = ListProjects();
            projectMetas.RemoveRange(0, projectMetas.Length);
            for (uint i = 0; i < projects.Length; i++) {
                auto proj = ProjectMeta(projects[i]);
                projectMetas.InsertLast(proj);
            }
        }

        // MARK: Proj Selct

        void DrawProjectSelector() {
            auto childFlags = UI::ChildFlags::Border | UI::ChildFlags::AlwaysAutoResize | UI::ChildFlags::AutoResizeX | UI::ChildFlags::AutoResizeY;
            auto avail = UI::GetContentRegionAvail();
            auto fp = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

            auto left = avail * vec2(0.25, 1);
            if (left.x > 300) left.x = 300;
            auto tl = UI::GetCursorPos();
            auto tl2 = tl + vec2(left.x, 0);

            auto right = avail - vec2(left.x, 0) - fp * 2;
            left -= fp * 2.0;
            // UI::SetCursorPos(tl);
            if (UI::BeginChild("##projSelList", left, childFlags)) {
                // auto pos = UI::GetCursorPos();
                // UI::Dummy(left);
                // UI::SetCursorPos(pos);
                DrawProjectSelectables();
            }
            UI::EndChild();
            // UI::SetCursorPos(tl2);
            // UI::Text("Right");
            UI::SetCursorPos(tl2);
            if (UI::BeginChild("##projMetaRight", right, childFlags)) {
                // auto pos = UI::GetCursorPos();
                // UI::Dummy(right);
                // UI::SetCursorPos(pos);
                if (isCreatingNew) {
                    DrawCreateNewProject();
                } else {
                    DrawSelectedProjectMeta();
                }
            }
            UI::EndChild();
            // UI::Separator();
        }

        bool isCreatingNew = false;
        string m_newName = "Untitled";
        void OnClickCreateNew() {
            isCreatingNew = true;
            ResetSelectedProj();
        }

        int selectedProjectIx = -1;
        string selectedProject = "";
        void DrawProjectSelectables() {
            if (projects.Length == 0) {
                UI::Text("No projects found.");
                return;
            }
            for (uint i = 0; i < projects.Length; i++) {
                auto proj = projects[i];
                auto projMeta = projectMetas[i];
                if (UI::Selectable(proj, proj == selectedProject)) {
                    OpenProject(i, projMeta);
                }
                if (UI::IsItemHovered()) {
                    UI::SetMouseCursor(UI::MouseCursor::Hand);
                    UI::SetTooltip("Open project: " + proj);
                }
            }
        }

        void OpenProject(uint ix, ProjectMeta@ meta) {
            selectedProject = meta.name;
            selectedProjectIx = ix;
            isCreatingNew = false;
        }


        void DrawSelectedProjectMeta() {
            if (selectedProjectIx < 0) {
                UI::Text("No project selected.");
                return;
            }
            auto meta = projectMetas[selectedProjectIx];
            UI::Text("Selected Project: " + meta.name);
            UI::Text("Path: " + meta.path);
            UI::Separator();
            if (UI::Button(Icons::Pencil + " Edit Project")) {
                AddProjectTab(meta);
            }
            UI::SameLine();
            if (UI::Button(Icons::FolderOpenO + " Browse")) {
                OpenExplorerPath(meta.path);
            }
            UI::SameLine();
            UI::BeginDisabled(!UI::IsKeyDown(UI::Key::LeftShift));
            if (UI::Button(Icons::Trash + " Delete")) {
                startnew(CoroutineFuncUserdata(DeleteProject), meta);
            }
            UI::EndDisabled();
            UI::SameLine();
            UI::AlignTextToFramePadding();
            UI::Text(Icons::InfoCircle);
            AddSimpleTooltip("Hold Left Shift to enable delete button.");
        }

        string newProjectErrMsg = "";
        void DrawCreateNewProject() {
            UI::SeparatorText("Create New Project");
            bool changed;
            m_newName = UI::InputText("##newProjName", m_newName, changed, UI::InputTextFlags::EnterReturnsTrue);

            if (UI::Button(Icons::Plus + " Create") || changed) {
                newProjectErrMsg = "";
                CreateNewProject(m_newName);
            }

            if (newProjectErrMsg.Length > 0) {
                UI::TextWrapped(newProjectErrMsg);
            }
        }

        void CreateNewProject(const string &in pName) {
            string errPre = Time::FormatString("[%H:%M:%S] ");
            if (IO::FolderExists(ProjectsDir + "/" + pName)) {
                newProjectErrMsg = errPre + "Project already exists: " + pName;
                return;
            }
            if (pName.Contains("/") || pName.Contains("\\")) {
                newProjectErrMsg = errPre + "Project name cannot contain slashes: " + pName;
                return;
            }
            if (pName.Length < 3) {
                newProjectErrMsg = errPre + "Project name must be at least 3 characters: " + pName;
                return;
            }
            if (pName.Length > 50) {
                newProjectErrMsg = errPre + "Project name must be at most 50 characters: " + pName;
                return;
            }
            IO::CreateFolder(ProjectsDir + "/" + pName, false);
            if (!IO::FolderExists(ProjectsDir + "/" + pName)) {
                newProjectErrMsg = errPre + "Failed to create project folder: " + pName;
                return;
            }
            RefreshProjects();
            SelectProjectNamed(pName);
            ResetCreateNewProject();
        }

        void ResetCreateNewProject() {
            newProjectErrMsg = "";
            isCreatingNew = false;
            m_newName = "Untitled";
        }

        void DeleteProject(ref@ meta) {
            auto pm = cast<ProjectMeta>(meta);
            if (pm is null) {
                Notify("Failed to delete project (null ref)");
                return;
            }
            Notify("Deleting project: " + pm.name);
            IO::DeleteFolder(pm.GetPathEnsureSubdir(), true);
            RefreshProjects();
        }

        void AddProjectTab(ProjectMeta@ meta) {
            if (Parent.HasTabNamed(meta.name)) {
                Parent.FocusTab(meta.name);
                return;
            }
            Tab@ tab = meta.CreateTab(Parent);
            if (tab is null) {
                Notify("Failed to add project tab: " + meta.name);
                return;
            }
            tab.SetSelectedTab();
        }
    }

    // MARK: Proj Meta

    class ProjectMeta {
        string name;
        string path;

        ProjectMeta(const string &in name) {
            this.name = name;
            this.path = ProjectsDir + "/" + name;
        }

        bool ProjectFileExists(const string &in file) {
            return IO::FileExists(ProjectFilePath(file));
        }

        string ProjectFilePath(const string &in file) {
            return path + "/" + file;
        }

        // returns absolute path or throws
        string GetPathEnsureSubdir() {
            if (!path.StartsWith(ProjectsDir)) throw("Path does not start with ProjectsDir: " + path);
            // - 1 for the slash after projects dir
            if (int(path.Length) - int(ProjectsDir.Length) - 1 < 2) throw("Path is too short: " + path);
            return path;
        }

        Tab@ CreateTab(TabGroup@ parent) {
            if (name.Length == 0) throw("Name is empty");
            if (path.Length == 0) throw("Path is empty");
            return ProjectTab(parent, this);
        }

        bool CheckStillExists() {
            if (path.Length == 0) return false;
            return IO::FolderExists(path);
        }

        bool hasFloors = false;
        bool hasVoiceLines = false;
        bool hasTriggers = false;
        bool hasMinigames = false;
        bool hasAssets = false;

        void LoadIndex() {
            if (LoadedIndex) return;
            // if (!hasFloors) LoadFloors();
            // if (!hasVoiceLines) LoadVoiceLines();
            // if (!hasTriggers) LoadTriggers();
            // if (!hasMinigames) LoadMinigames();
            // if (!hasAssets) LoadAssets();
            LoadedIndex = true;
        }

        // bool dirty_Floors = false;
        // bool dirty_VoiceLine = false;
        // bool dirty_Triggers = false;
        // bool dirty_Minigames = false;
        // bool dirty_Assets = false;
        bool LoadedIndex = false;

        // private Json::Value@ _Floors;
        // private Json::Value@ _VoiceLines;
        // private Json::Value@ _Triggers;
        // private Json::Value@ _Minigames;
        // private Json::Value@ _Assets;

        // // jrw: read write access
        // // jro: read only
        // Json::Value@ get_jrw_Floors() {
        //     dirty_Floors = true;
        //     return _Floors;
        // }
        // const Json::Value@ get_jro_Floors() const {
        //     return _Floors;
        // }
        // Json::Value@ get_jrw_VoiceLine() {
        //     dirty_VoiceLine = true;
        //     return _VoiceLines;
        // }
        // const Json::Value@ get_jro_VoiceLine() const {
        //     return _VoiceLines;
        // }
        // Json::Value@ get_jrw_Triggers() {
        //     dirty_Triggers = true;
        //     return _Triggers;
        // }
        // const Json::Value@ get_jro_Triggers() const {
        //     return _Triggers;
        // }
        // Json::Value@ get_jrw_Minigames() {
        //     dirty_Minigames = true;
        //     return _Minigames;
        // }
        // const Json::Value@ get_jro_Minigames() const {
        //     return _Minigames;
        // }
        // Json::Value@ get_jrw_Assets() {
        //     dirty_Assets = true;
        //     return _Assets;
        // }
        // const Json::Value@ get_jro_Assets() const {
        //     return _Assets;
        // }

        // void LoadFloors() {
        //     hasFloors = ProjectFileExists(PROJ_FILE_FLOORS);
        //     if (!hasFloors) return;
        //     _Floors = Json::FromFile(ProjectFilePath(PROJ_FILE_FLOORS));
        //     dirty_Floors = false;
        // }
        // void LoadVoiceLines() {
        //     hasVoiceLines = ProjectFileExists(PROJ_FILE_VOICELINES);
        //     if (!hasVoiceLines) return;
        //     jrw_VoiceLine = Json::FromFile(ProjectFilePath(PROJ_FILE_VOICELINES));
        //     dirty_VoiceLine = false;
        // }
        // void LoadTriggers() {
        //     hasTriggers = ProjectFileExists(PROJ_FILE_TRIGGERS);
        //     if (!hasTriggers) return;
        //     jrw_Triggers = Json::FromFile(ProjectFilePath(PROJ_FILE_TRIGGERS));
        //     dirty_Triggers = false;
        // }
        // void LoadMinigames() {
        //     hasMinigames = ProjectFileExists(PROJ_FILE_MINIGAMES);
        //     if (!hasMinigames) return;
        //     jrw_Minigames = Json::FromFile(ProjectFilePath(PROJ_FILE_MINIGAMES));
        //     dirty_Minigames = false;
        // }
        // void LoadAssets() {
        //     hasAssets = ProjectFileExists(PROJ_FILE_ASSETS);
        //     if (!hasAssets) return;
        //     jrw_Assets = Json::FromFile(ProjectFilePath(PROJ_FILE_ASSETS));
        //     dirty_Assets = false;
        // }
    }

    const string PROJ_FILE_INFO = "info.json.txt";
    const string PROJ_FILE_FLOORS = "floors.json.txt";
    const string PROJ_FILE_VOICELINES = "voicelines.json.txt";
    const string PROJ_FILE_TRIGGERS = "triggers.json.txt";
    const string PROJ_FILE_MINIGAMES = "minigames.json.txt";
    const string PROJ_FILE_ASSETS = "assets.json.txt";
    const string PROJ_FILE_COLLECTABLES = "collectables.json.txt";

    // MARK: Project Tab

    class ProjectTab : CompactTab {
        ProjectMeta@ meta;
        ProjectComponentGroup@[] componentGroups;

        ProjectTab(TabGroup@ parent, ProjectMeta@ meta) {
            super(parent, meta.name, "");
            @this.meta = meta;
            meta.LoadIndex();

            auto grp1 = AddComponentGroup("Project");
            auto grp2 = AddComponentGroup("Components");
            grp1.AddComponent(ProjectInfoComponent(PROJ_FILE_INFO, meta));
            grp1.AddComponent(ProjectFloorsComponent(PROJ_FILE_FLOORS, meta));
            grp2.AddComponent(ProjectVoiceLinesComponent(PROJ_FILE_VOICELINES, meta));
            grp2.AddComponent(ProjectAssetsComponent(PROJ_FILE_ASSETS, meta));
            // grp2.AddComponent(ProjectTriggersComponent());
            // grp2.AddComponent(ProjectMinigamesComponent());
            // grp2.AddComponent(ProjectCollectablesComponent());
        }

        ProjectComponentGroup@ AddComponentGroup(const string &in name) {
            auto grp = ProjectComponentGroup(name, meta);
            componentGroups.InsertLast(grp);
            return grp;
        }

        ProjectFloorsComponent@ GetFloorsComponent() {
            ProjectFloorsComponent@ r;
            for (uint i = 0; i < componentGroups.Length; i++) {
                @r = componentGroups[i].GetFloorsComponent();
                if (r !is null) {
                    return r;
                }
            }
            return null;
        }

        ProjectAssetsComponent@ GetAssetsComponent() {
            return cast<ProjectAssetsComponent>(GetComponentByType(EProjectComponent::Assets));
        }

        ProjectComponent@ GetComponentByType(EProjectComponent type) {
            for (uint i = 0; i < componentGroups.Length; i++) {
                auto cmp = componentGroups[i].GetComponentByType(type);
                if (cmp !is null) {
                    return cmp;
                }
            }
            return null;
        }

        void _AfterDrawTab() override {
            if (!keepProjectOpen) startnew(CoroutineFunc(CheckCloseProject));
        }

        bool keepProjectOpen;
        bool _BeginTabItem(const string&in l, int flags) override {
            return UI::BeginTabItem(l, keepProjectOpen, flags);
        }

        int get_TabFlags() override property {
            auto flags = TabFlagSelected;
            if (HasAnyUnsaved()) {
                return flags | UI::TabItemFlags::UnsavedDocument;
            }
            return flags;
        }

        bool HasAnyUnsaved() {
            for (uint i = 0; i < componentGroups.Length; i++) {
                if (componentGroups[i].HasUnsavedChanges()) {
                    return true;
                }
            }
            return false;
        }

        void CheckCloseProject() {
            if (keepProjectOpen) return;
            // otherwise, prompt to save or discard changes
            // otherwise, remove from parent
            Parent.RemoveTab(this);
        }

        void DrawInner() override {
            if (!meta.LoadedIndex) {
                UI::Text("Loading project...");
                meta.LoadIndex();
                return;
            }

            int cFlags = UI::ChildFlags::Border | UI::ChildFlags::AlwaysAutoResize | UI::ChildFlags::AutoResizeX | UI::ChildFlags::AutoResizeY;
            auto avail = UI::GetContentRegionAvail();
            auto fp = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);
            auto left = avail * vec2(0.25, 1);
            if (left.x > 300) left.x = 300;
            auto tlRight = UI::GetCursorPos() + vec2(left.x, 0);
            auto right = avail - vec2(left.x, 0) - fp * 2;
            left -= fp * 2.0;

            if (UI::BeginChild("##projMetaLeft", left, cFlags)) {
                DrawProjComponentSelector();
            }
            UI::EndChild();
            UI::SetCursorPos(tlRight);
            if (UI::BeginChild("##projMetaRight", right, cFlags)) {
                DrawProjComponent();
            }
            UI::EndChild();
        }

        int selectedComponent = EProjectComponent::Info;
        void DrawProjComponentSelector() {
            for (uint i = 0; i < componentGroups.Length; i++) {
                selectedComponent = componentGroups[i].DrawSelector(selectedComponent);
            }
        }

        void DrawProjComponent() {
            for (uint i = 0; i < componentGroups.Length; i++) {
                auto grp = componentGroups[i];
                if (grp.DrawProjComponent(selectedComponent, this)) {
                    break;
                }
            }
        }

        // void DrawTriggers() {
        //     UI::Text("Triggers");
        //     UI::Separator();
        //     if (meta.hasTriggers) {
        //         UI::TextWrapped("Triggers loaded: " + meta.jro_Triggers.Length);
        //     } else {
        //         UI::TextWrapped("No triggers found.");
        //         if (UI::Button(Icons::Plus + " Add Triggers")) {
        //             InitTriggers();
        //         }
        //     }
        // }
        // void DrawMinigames() {
        //     UI::Text("Minigames");
        //     UI::Separator();
        //     if (meta.hasMinigames) {
        //         UI::TextWrapped("Minigames loaded: " + meta.jro_Minigames.Length);
        //     } else {
        //         UI::TextWrapped("No minigames found.");
        //         if (UI::Button(Icons::Plus + " Add Minigames")) {
        //             InitMinigames();
        //         }
        //     }
        // }
        // void DrawAssets() {
        //     UI::Text("Assets");
        //     UI::Separator();
        //     if (meta.hasAssets) {
        //         UI::TextWrapped("Assets loaded: " + meta.jro_Assets.Length);
        //     } else {
        //         UI::TextWrapped("No assets found.");
        //         if (UI::Button(Icons::Plus + " Add Assets")) {
        //             InitAssets();
        //         }
        //     }
        // }
    }

    enum EProjectComponent {
        Unknown,
        Info,
        Floors,
        VoiceLines,
        Triggers,
        Minigames,
        Assets,
        Collectables,
        _LAST
    }

    string ProjectComponentToString(EProjectComponent c) {
        switch (c) {
            case EProjectComponent::Unknown: return "Unknown";
            case EProjectComponent::Info: return "Project Info";
            case EProjectComponent::Floors: return "Floors";
            case EProjectComponent::VoiceLines: return "Voice Lines";
            case EProjectComponent::Triggers: return "Triggers";
            case EProjectComponent::Minigames: return "Minigames";
            case EProjectComponent::Assets: return "Assets";
            case EProjectComponent::Collectables: return "Collectables";
        }
        return "? Unknown ?";
    }

    // MARK: Proj Cmpnt Group

    class ProjectComponentGroup {
        string name;
        ProjectMeta@ meta;
        ProjectComponent@[] components;
        EProjectComponent[] componentTypes;

        ProjectComponentGroup(const string &in name, ProjectMeta@ meta) {
            this.name = name;
            @this.meta = meta;
        }

        ProjectComponent@ AddComponent(ProjectComponent@ component) {
            components.InsertLast(component);
            componentTypes.InsertLast(component.type);
            return component;
        }

        ProjectFloorsComponent@ GetFloorsComponent() {
            return cast<ProjectFloorsComponent>(GetComponentByType(EProjectComponent::Floors));
        }

        ProjectAssetsComponent@ GetAssetsComponent() {
            return cast<ProjectAssetsComponent>(GetComponentByType(EProjectComponent::Assets));
        }

        ProjectComponent@ GetComponentByType(EProjectComponent type) {
            for (uint i = 0; i < components.Length; i++) {
                if (components[i].type == type) {
                    return components[i];
                }
            }
            return null;
        }

        bool HasUnsavedChanges() {
            for (uint i = 0; i < components.Length; i++) {
                if (components[i].isDirty) {
                    return true;
                }
            }
            return false;
        }

        int DrawSelector(int selected) {
            UI::SeparatorText("\\$i\\$bbb" + name);
            for (uint i = 0; i < components.Length; i++) {
                auto comp = components[i];
                if (UI::Selectable(comp.icon + " " + comp.name, selected == int(comp.type))) {
                    selected = comp.type;
                }
            }
            return selected;
        }

        bool DrawProjComponent(int selectedType, ProjectTab@ pTab) {
            for (uint i = 0; i < components.Length; i++) {
                if (componentTypes[i] == selectedType) {
                    // draw
                    components[i].DrawComponent(pTab);
                    return true;
                }
            }
            return false;
        }
    }

    class ProjectComponent {
        string name;
        string icon;
        ProjectMeta@ meta;
        private Json::Value@ data = Json::Value();
        string jsonPath;
        EProjectComponent type;
        bool isDirty = false;
        bool hasFile = false;
        bool canInitFromDipsSpecComment = false;
        bool thisTabClickRequiresTestPlaceMode = false;

        ProjectComponent(const string &in _jsonFName, ProjectMeta@ meta) {
            // default values
            name = "! New Component";
            icon = Icons::ExclamationTriangle;
            type = EProjectComponent::Unknown;
            @this.meta = meta;
            startnew(CoroutineFuncUserdataString(TryLoadingJson), _jsonFName);
        }

        void TryLoadingJson(const string &in jFName) {
            jsonPath = meta.ProjectFilePath(jFName);
            if (!meta.ProjectFileExists(jFName)) {
                hasFile = false;
                return;
            }
            hasFile = true;
            @data = Json::FromFile(jsonPath);
        }

        const Json::Value@ get_ro_data() const {
            return data;
        }

        Json::Value@ get_rw_data() {
            isDirty = true;
            return data;
        }

        int DrawSelector(int selected) {
            if (UI::Selectable(icon + " " + name, selected == int(type))) {
                selected = type;
            }
            return selected;
        }

        string get_ComponentTitleName() {
            return name;
        }

        void DrawComponent(ProjectTab@ pTab) {
            UI::Text(ComponentTitleName);
            UI::Separator();
            if (!hasFile) {
                UI::TextWrapped("Component not found: " + name);
                UI::TextWrapped("Create?");
                if (canInitFromDipsSpecComment) {
                    DrawInitializeFromDipsSpecComment();
                }
                DrawInitializeButton();
            } else {
                DrawComponentInner(pTab);
            }
        }

        void DrawInitializeFromDipsSpecComment() {
            if (UI::Button("" + Icons::Plus + " Create " + name + " from Map Comment")) {
                CreateComponentFromComment();
            }
        }

        void DrawInitializeButton() {
            if (UI::Button("" + Icons::Plus + " Add " + name)) {
                CreateComponentFile();
            }
        }

        void DrawComponentInner(ProjectTab@ pTab) {
            UI::TextWrapped("This is the " + name + " component. Override DrawComponentInner.");
        }

        void CreateComponentFromComment() {
            CreateJsonDataFromComment(DipsSpec(GetApp().RootMap.Comments));
            SaveToFile();
        }

        // creates the components data file and initializes the json object
        void CreateComponentFile() {
            CreateDefaultJsonObject();
            SaveToFile();
        }

        void CreateDefaultJsonObject() {
            throw("Override me: CreateDefaultJsonObject");
        }

        void CreateJsonDataFromComment(DipsSpec@ spec) {
            throw("Override me (only necessary if canInitFromDipsSpecComment == true)");
        }

        void SaveToFile() {
            if (data is null) {
                NotifyError("Failed to save " + name + ": data is null");
                return;
            }
            if (jsonPath == "") {
                NotifyError("Failed to save " + name + ": path is empty");
                return;
            }
            Json::ToFile(jsonPath, data, true);
            trace("Saved " + name + " to " + jsonPath);
            hasFile = true;
            isDirty = false;
        }

        void OnMouseClick(int x, int y, int button) {
            // do nothing, for overrides
        }

        void OnSelfAwaitingMouseClick() {
            @componentWaitingForMouseClick = this;
            g_InterceptOnMouseClick = true;
            g_InterceptClickRequiresTestMode = thisTabClickRequiresTestPlaceMode;
        }

        bool get_IAmAwaitingMouseClick() {
            return componentWaitingForMouseClick is this;
        }

        void OnSelfCancelAwaitMouseClick() {
            if (componentWaitingForMouseClick is this) {
                @componentWaitingForMouseClick = null;
                g_InterceptOnMouseClick = false;
            } else if (componentWaitingForMouseClick !is null) {
                NotifyWarning("Some other component is waiting for a mouse click: " + componentWaitingForMouseClick.name);
            }
        }

        // utility for drawing nvg instruction text easily.
        void DrawInstructionText(const string &in text, bool alsoUI) {
            if (alsoUI) UI::Text(text);
            nvg::Reset();
            auto fontSize = 64.0 * g_screen.y / 1440.0;
            nvg::FontSize(fontSize);
            auto bounds = nvg::TextBounds(text) + vec2(fontSize * 0.25);
            auto midPoint = g_screen * vec2(.5, .2);
            auto bgRect = vec4(midPoint - bounds * 0.5, bounds);

            nvg::BeginPath();
            nvg::FillColor(cBlack);
            nvg::RoundedRect(bgRect.xy, bgRect.zw, 8);
            nvg::Fill();
            nvg::ClosePath();

            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            nvgDrawTextWithStroke(midPoint, text, cOrange);
        }

    }

    // MARK: Proj Info Cmpnt

    class ProjectInfoComponent : ProjectComponent {
        ProjectInfoComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Project Info";
            icon = Icons::InfoCircle;
            type = EProjectComponent::Info;
            canInitFromDipsSpecComment = true;
        }

        string get_ComponentTitleName() override property {
            return name + ": " + meta.name;
        }

        // proxy methods for data access
        string get_px_minClientVersion() { return ro_data.Get("minClientVersion", ""); }
        void set_px_minClientVersion(const string &in v) { rw_data["minClientVersion"] = v; }
        string get_px_url() { return ro_data.Get("url", ""); }
        void set_px_url(const string &in v) { rw_data["url"] = v; }

        void CreateDefaultJsonObject() override {
            auto j = Json::Object();
            j["minClientVersion"] = "0.0.0";
            // j["url"] = "";
            rw_data = j;
        }

        void CreateJsonDataFromComment(DipsSpec@ spec) override {
            CreateDefaultJsonObject();
            px_minClientVersion = spec.minClientVersion;
            px_url = spec.url;
        }

        void DrawComponentInner(ProjectTab@ pTab) override {
            auto fc = pTab.GetFloorsComponent();
            UI::Text("Tower Floors: " + fc.nbFloors);
            for (uint i = uint(EProjectComponent::Info) + 1; i < uint(EProjectComponent::_LAST); i++) {
                DrawHasComponent(EProjectComponent(i), pTab);
            }
            UI::Separator();

            bool changedMCV = false, changedURL = false;

            auto newMCV = UI::InputText("Min Client Version (optional)", px_minClientVersion, changedMCV);
            AddSimpleTooltip("Default: empty or '0.0.0'. This will prevent Dips++ clients with a lower version from working with this map.");
            if (changedMCV) px_minClientVersion = newMCV;

            if (UI::CollapsingHeader("Advanced")) {
                auto newUrl = UI::InputText("URL (optional)", px_url, changedURL);
                AddSimpleTooltip("Default: empty. Reserved for future use.");
                if (changedURL) px_url = newUrl;
            }

            UI::Separator();

            // todo: buttons and displays for checking that VL and Asset URLs are fine.
            UI::Text("Todo: Checked Voice Lines Exist: x / N");
            UI::Text("Todo: Checked Assets Exist: x / N");
        }

        void DrawHasComponent(EProjectComponent ty, ProjectTab@ pTab) {
            auto comp = pTab.GetComponentByType(ty);
            UI::Text(BoolIcon(comp is null ? false : comp.hasFile) + " " + ProjectComponentToString(ty));
        }
    }

    // MARK: Floors Cmpnt

    class ProjectFloorsComponent : ProjectComponent {
        ProjectFloorsComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Floors";
            icon = Icons::BuildingO;
            type = EProjectComponent::Floors;
            canInitFromDipsSpecComment = true;
            thisTabClickRequiresTestPlaceMode = true;
        }

        // proxy methods for data access (px = proxy)
        bool get_px_lastFloorEnd() const { return ro_data.Get("lastFloorEnd", false); }
        void set_px_lastFloorEnd(bool v) { rw_data["lastFloorEnd"] = v; }
        uint get_nbFloors() const { return ro_data.HasKey("floors") ? ro_data["floors"].Length : 0; }
        Json::Value getFloor(uint i) const { return ro_data["floors"][i]; }
        Json::Value@ getRwFloor(uint i) { return rw_data["floors"][i]; }
        void pushFloor(Json::Value@ floor) { rw_data["floors"].Add(floor); }
        void setFloor(uint i, Json::Value@ floor) { rw_data["floors"][i] = floor; }
        void removeFloor(uint i) {
            if (i >= nbFloors) return;
            rw_data["floors"].Remove(i);
        }

        void sortFloors() {
            // simple sorting; should not be too inefficient if we keep floors in sorted order
            auto @floors = rw_data["floors"];
            if (floors.Length == 0) return;
            // subtract 1 for the last floor
            int nb = nbFloors - 1;
            for (int i = 0; i < nb; i++) {
                if (float(floors[i]["height"]) > float(floors[i + 1]["height"])) {
                    SwapFloors(i, i + 1);
                    i = -1; // restart
                }
            }
        }

        void SwapFloors(uint i, uint j) {
            auto @floors = rw_data["floors"];
            if ((i > j ? i : j) >= nbFloors) return;
            string tName = floors[i]["name"];
            float tHeight = floors[i]["height"];
            floors[i]["name"] = floors[j]["name"];
            floors[i]["height"] = floors[j]["height"];
            floors[j]["name"] = tName;
            floors[j]["height"] = tHeight;
        }

        void CreateJsonDataFromComment(DipsSpec@ spec) override {
            CreateDefaultJsonObject();
            px_lastFloorEnd = spec.lastFloorEnd;
            auto nbFloors = spec.floors.Length;
            for (uint i = 0; i < nbFloors; i++) {
                rw_data["floors"].Add(spec.floors[i].ToJson());
            }
        }

        void CreateDefaultJsonObject() override {
            auto j = Json::Object();
            j["floors"] = Json::Array();
            j["lastFloorEnd"] = false;
            rw_data = j;
        }

        void DrawComponentInner(ProjectTab@ pTab) override {
            UI::AlignTextToFramePadding();
            UI::Text("# Floors: " + nbFloors);
            UI::SameLine();
            if (UI::Button(Icons::Plus + " Add Floor")) {
                OnCreateNewFloor();
            }
            UI::Separator();
            if (IsCreatingFloor) {
                DrawFloorCreation();
            } else {
                DrawFloorsList();
            }
        }

        void DrawFloorCreation() {
            UI::Text("Creating new floor...");
            DrawInstructionText("Place Car at Floor Start (or Height)", true);

            if (UI::Button(Icons::Times + " Cancel")) {
                @creatingFloor = null;
                OnSelfCancelAwaitMouseClick();
            }
        }

        int editIx = -1;

        void DrawFloorsList() {
            UI::AlignTextToFramePadding();
            UI::Text("Floors List");
            UI::SameLine();
            if (UI::Button(Icons::Sort + " Sort")) {
                sortFloors();
            }

            UI::TextWrapped("By default, floor names get cut off after 3-4 characters.\nLeave empty for default (the floor number).");

            int remIx = -1;

            UI::Separator();

            UI::BeginChild("fl");

            UI::BeginTable("Floors", 3, UI::TableFlags::SizingStretchProp);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Height", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);

            for (uint i = 0; i < nbFloors; i++) {
                bool editing = int(i) == editIx;
                UI::PushID("flr" + i);
                UI::TableNextRow();
                auto floor = getFloor(i);
                float height = floor["height"];
                string name = floor["name"];
                if (name.Length == 0 && !editing) name = "\\$i\\$aaaFloor " + i;

                UI::TableNextColumn();
                if (editing) {
                    name = UI::InputText("##name" + i, name);
                    floor["name"] = name;
                    // if (name.Length == 0) name = "\\$i\\$aaaFloor " + i;
                } else {
                    UI::AlignTextToFramePadding();
                    UI::Text(name);
                }

                UI::TableNextColumn();
                if (editing) {
                    height = UI::InputFloat("##height" + i, height);
                    floor["height"] = height;
                } else {
                    UI::Text(tostring(height));
                }

                UI::TableNextColumn();
                if (editing) {
                    if (UI::Button(Icons::Check + " Done")) {
                        editIx = -1;
                    }
                } else {
                    if (UI::Button(Icons::Pencil + " Edit")) {
                        editIx = i;
                        // UI::SetKeyboardFocusHere(-1); // -2 = assert fail
                    }
                    UI::SameLine();
                    UI::BeginDisabled(!UI::IsKeyDown(UI::Key::LeftShift));
                    if (UI::Button(Icons::TrashO + " Delete")) {
                        remIx = i;
                    }
                    UI::EndDisabled();
                    UI::SameLine();
                    UI::AlignTextToFramePadding();
                    UI::Text("\\$8af"+Icons::InfoCircle);
                    AddSimpleTooltip("Hold Shift to delete");
                }
                UI::PopID();
            }

            UI::EndTable();
            UI::EndChild();

            if (remIx != -1) {
                removeFloor(remIx);
                SaveToFile();
            }
        }

        bool get_IsCreatingFloor() {
            return creatingFloor !is null;
        }

        Json::Value@ creatingFloor = null;
        void OnCreateNewFloor() {
            auto floor = Json::Object();
            floor["height"] = 0.0;
            floor["name"] = "";
            @creatingFloor = floor;
            OnSelfAwaitingMouseClick();
            startnew(SetEditorToTestMode);
        }

        void SetCreatingFloorHeight(float height) {
            creatingFloor["height"] = height;
            pushFloor(creatingFloor);
            sortFloors();
            @creatingFloor = null;
            SaveToFile();
        }


        void OnMouseClick(int x, int y, int button) override {
            if (creatingFloor is null) return;
            if (!EditorIsInTestPlaceMode() || button != 0) {
                // doing something else like moving camera. requeue intercept
                startnew(CoroutineFunc(OnSelfAwaitingMouseClick));
                return;
            }
            auto icPos = GetEditorItemCursorPos();
            // car is offset +0.5
            SetCreatingFloorHeight(icPos.y - 0.5);
        }
    }

    // MARK: VoiceLines Cmpnt

    const vec3 DEFAULT_MT_SIZE = vec3(10.6666667, 8, 10.6666667);
    const vec3 DEFAULT_VL_POS = vec3(32, 8, 32) - vec3(10.6666667, 0, 10.6666667) * 0.5;

    class VoiceLineEl {
        string file;
        string subtitles;
        string imageAsset;
        int subtitleParts = 0;
        vec3 posBottomCenter = DEFAULT_VL_POS;
        vec3 size = DEFAULT_MT_SIZE;

        VoiceLineEl() {}
        VoiceLineEl(const Json::Value@ j) {
            file = j.Get("file", "");
            subtitles = j.Get("subtitles", "");
            imageAsset = j.Get("imageAsset", "");
            posBottomCenter = JsonToVec3(j["pos"], DEFAULT_VL_POS);
            size = JsonToVec3(j["size"], DEFAULT_MT_SIZE);
            subtitleParts = subtitles.Split("\n").Length;
        }

        vec3 get_posMin() {
            return posBottomCenter - size * vec3(0.5, 0, 0.5);
        }

        Json::Value ToJson() {
            auto j = Json::Object();
            j["file"] = file;
            j["subtitles"] = subtitles;
            j["imageAsset"] = imageAsset;
            j["pos"] = Vec3ToJson(posBottomCenter);
            j["size"] = Vec3ToJson(size);
            return j;
        }

        string PosStr() {
            return "< " + posBottomCenter.x + ", " + posBottomCenter.y + ", " + posBottomCenter.z + " >";
        }

        void DrawEditor(ProjectVoiceLinesComponent@ cmp, ProjectTab@ pTab) {
            bool changedFile = false, changedSubtitles = false;
            string fullUrl = cmp.UrlPrefix + file;

            file = UI::InputText("File", file, changedFile);
            UI::SameLine();
            if (UI::Button(Icons::Download + " Test")) {
                OpenBrowserURL(fullUrl);
            }
            AddSimpleTooltip("Full URL: " + fullUrl);

            if (file.EndsWith(".mp3") && file.Length > 4) {
                UI::Text(BoolIcon(true) + " file name looks good.");
            } else {
                UI::Text(BoolIcon(false) + " file name should be an .mp3 file. (It is appended to UrlPrefix)");
            }

            UI::Separator();

            UI::Text("Subtitles:");
            subtitles = UI::InputTextMultiline("##subtitles", subtitles, changedSubtitles);
            DrawSameLineSubtitlesHelper();
            UI::Text("Subtitle Parts: " + subtitleParts);

            if (subtitles.Length > 0) {
                if (!subtitles.StartsWith("0:")) UI::Text(BoolIcon(false) + " Subtitles should start at t = 0. (First line should start with \"0:\")");
            }

            imageAsset = UI::InputText("Speaker Image", imageAsset);
            auto assetsComp = pTab.GetAssetsComponent();
            UI::AlignTextToFramePadding();
            if (assetsComp.HasImageAsset(imageAsset)) {
                UI::Text(BoolIcon(true) + " Image asset found.");
            } else if (imageAsset.Length > 0) {
                UI::Text(BoolIcon(false) + " Image asset not found.");
                UI::SameLine();
                if (UI::Button(Icons::Plus + " Add Image Asset")) {
                    assetsComp.AddImageAsset(imageAsset);
                    assetsComp.SaveToFile();
                }
            }

            UI::Separator();

            if (cmp.IAmAwaitingMouseClick) {
                posBottomCenter = GetEditorItemCursorPos() - vec3(0, 0.5, 0);
                UI::BeginDisabled();
                UI::InputFloat3("Position##pos", posBottomCenter, "%.3f", UI::InputTextFlags::ReadOnly);
                UI::EndDisabled();
            } else {
                posBottomCenter = UI::InputFloat3("Position##pos", posBottomCenter);
            }
            UI::SameLine();
            if (UI::Button(Icons::PencilSquareO + " Set")) OnClickSetPos(cmp);

            size = UI::InputFloat3("Size##size", size);

            if (UI::Button(Icons::Eye + " Show")) {
                SetEditorCameraToPos(posBottomCenter);
            }

            UI::Separator();
            UI::Text("Hints:");
            UI::TextWrapped("- Make sure the bottom of the trigger is on the ground (or slightly below it).");
            UI::TextWrapped("- The mediatracker trigger size is 10.667 x 8 x 10.667");
        }

        void OnClickSetPos(ProjectVoiceLinesComponent@ cmp) {
            startnew(SetEditorToTestMode);
            cmp.OnSelfAwaitingMouseClick();
        }

        void DrawSameLineSubtitlesHelper() {
            UI::SameLine();
            UI::AlignTextToFramePadding();
            UI::Text(Icons::InfoCircle);
            bool circleClicked = UI::IsItemClicked(UI::MouseButton::Left);
            AddSimpleTooltip(SUBTITLES_HELP);
            if (circleClicked) OpenBrowserURL("https://github.com/XertroV/tm-dips-plus-plus/blob/0d481094ef9fabb2095f93f853d841604ffaf35f/remote_assets/secret/subs-3948765.txt");
        }
    }

    const string SUBTITLES_HELP = "# Subtitles Help\n\n"
        "Line format: `<startTime_ms>: <text>`\n"
        "Example: `500: Before you continue,`\n"
        "- Starts at 0.5 seconds\n"
        "- Text shown: \"Before you continue,\"\n\n"
        + Icons::ExclamationCircle + " Also: put an empty subtitle line at the end to better control fade out timing.\n\n"
        "Click to open an example subtitles file in the browser.\n";

    class ProjectVoiceLinesComponent : ProjectComponent {
        ProjectVoiceLinesComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Voice Lines";
            icon = Icons::CommentO;
            type = EProjectComponent::VoiceLines;
            thisTabClickRequiresTestPlaceMode = true;
        }

        // proxy methods for data access (px = proxy)
        uint get_nbLines() const { return ro_data.HasKey("lines") ? ro_data["lines"].Length : 0; }
        VoiceLineEl getLine(uint i) const { return VoiceLineEl(ro_data["lines"][i]); }
        void setLine(uint i, VoiceLineEl@ vl) { rw_lines[i] = vl.ToJson(); }
        string get_UrlPrefix() const { return ro_data.Get("urlPrefix", ""); }
        void set_UrlPrefix(const string &in v) { rw_data["urlPrefix"] = v; }

        Json::Value@ get_rw_lines() {
            if (!ro_data.HasKey("lines") || ro_data["lines"].GetType() != Json::Type::Array) {
                rw_data["lines"] = Json::Array();
            }
            return rw_data["lines"];
        }

        int PushVoiceLine(VoiceLineEl@ vl) {
            auto @lines = rw_lines;
            lines.Add(vl.ToJson());
            return lines.Length - 1;
        }

        void CreateDefaultJsonObject() override {
            auto j = Json::Object();
            j["lines"] = Json::Array();
            j["urlPrefix"] = "";
            rw_data = j;
        }

        void DrawComponentInner(ProjectTab@ pTab) override {
            if (editingVL >= int(nbLines)) {
                NotifyWarning("Invalid voice line index: " + editingVL);
                editingVL = -1;
            }
            DrawSelectedVLBox();
            // if not editing, show header
            if (editingVL == -1) {
                DrawHeader();
                // if still not editing, draw VLs
                if (editingVL == -1) {
                    UI::Separator();
                    DrawVoiceLines();
                }
            } else {
                // only draw editing if it was not set this frame to avoid flicker
                DrawEditVoiceLine(pTab);
            }
        }

        void DrawSelectedVLBox() {
            if (editingVL != -1) @vlToDraw = getLine(editingVL);
            if (vlToDraw is null) return;
            nvgDrawWorldBox(vlToDraw.posMin, vlToDraw.size, cOrange);
        }

        int editingVL = -1;
        VoiceLineEl@ vlToDraw = null;

        void DrawHeader() {
            if (UI::Button(Icons::Plus + " Add Voice Line")) {
                OnCreateNewVoiceLine();
            }
            bool urlPrefixChanged = false;
            string urlPrefix = UI::InputText("URL Prefix", UrlPrefix, urlPrefixChanged);
            if (urlPrefixChanged) {
                UrlPrefix = urlPrefix;
            }
        }

        void DrawEditVoiceLine(ProjectTab@ pTab) {
            bool clickedEnd = false;
            UI::PushID("vlEdit" + editingVL);
            auto vl = getLine(editingVL);

            UI::AlignTextToFramePadding();
            UI::Text("Editing VL: " + editingVL);

            UI::SameLine();
            auto pos1 = UI::GetCursorPos();
            if (UI::Button(Icons::FloppyO + " Save")) {
                clickedEnd = true;
            }

            UI::SameLine();
            auto saveWidth = UI::GetCursorPos().x - pos1.x;

            auto avail = UI::GetContentRegionAvail();
            UI::Dummy(vec2(Math::Max(0.0, avail.x - saveWidth - 12 * g_scale), 0));
            UI::SameLine();
            // UI::BeginDisabled(!UI::IsKeyDown(UI::Key::LeftShift));
            if (UI::Button(Icons::TrashO + " Delete")) {
                startnew(CoroutineFuncUserdataInt64(OnDeleteVoiceLine), editingVL);
            }
            // UI::EndDisabled();

            UI::Separator();

            vl.DrawEditor(this, pTab);
            setLine(editingVL, vl);

            UI::PopID();

            if (clickedEnd) {
                editingVL = -1;
            }
        }

        void OnDeleteVoiceLine(int64 i) {
            if (i >= int64(nbLines)) return;
            auto @lines = rw_lines;
            lines.Remove(i);
            editingVL = -1;
            SaveToFile();
        }

        void OnCreateNewVoiceLine() {
            auto vl = VoiceLineEl();
            editingVL = PushVoiceLine(vl);
            OnSetVoiceLineToDraw(vl, false);
        }

        void DrawVoiceLines() {
            string urlPrefix = UrlPrefix;
            UI::Text("# Voice Lines: " + nbLines);
            UI::Separator();
            UI::BeginChild("vl");

            UI::BeginTable("Voice Lines", 4, UI::TableFlags::SizingStretchProp);
            UI::TableSetupColumn("File", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Has Subtitles", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();

            for (uint i = 0; i < nbLines; i++) {
                UI::PushID("vl" + i);
                auto vl = getLine(i);
                string fullUrl = urlPrefix + vl.file;
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(vl.file.Length > 0 ? vl.file : "\\$i\\$aaaNo file name");
                UI::SameLine();
                if (UI::Button(Icons::Download + " Test URL")) {
                    OpenBrowserURL(fullUrl);
                }
                AddSimpleTooltip(fullUrl);

                UI::TableNextColumn();
                UI::Text(BoolIcon(vl.subtitles.Length > 0) + " / parts: " + vl.subtitleParts);
                AddSimpleTooltip("Subtitles:\n" + vl.subtitles);

                UI::TableNextColumn();
                UI::Text(vl.PosStr());
                UI::SameLine();
                if (UI::Button(Icons::Crosshairs + " Show")) {
                    OnSetVoiceLineToDraw(vl);
                }

                UI::TableNextColumn();
                if (UI::Button(Icons::Pencil + " Edit")) {
                    editingVL = i;
                    OnSetVoiceLineToDraw(vl);
                }
                UI::PopID();
            }

            UI::EndTable();
            UI::EndChild();
        }


        void OnSetVoiceLineToDraw(VoiceLineEl@ vl, bool focusCamera = true) {
            @vlToDraw = vl;
            if (focusCamera) {
                SetEditorCameraToPos(vl.posBottomCenter, vl.size.Length() * 4.0);
            }
        }

        void OnMouseClick(int x, int y, int button) override {
            if (!EditorIsInTestPlaceMode()) {
                // doing something else like moving camera. requeue intercept
                startnew(CoroutineFunc(OnSelfAwaitingMouseClick));
                return;
            }
        }
    }

    // MARK: Assets

    enum AssetTy {
        Image,
        Sound
    }

    string AssetTy_ToKey(AssetTy ty) {
        switch (ty) {
            case AssetTy::Image: return "images";
            case AssetTy::Sound: return "sounds";
        }
        throw("Invalid AssetTy: " + tostring(ty));
        return "";
    }

    class ProjectAssetsComponent : ProjectComponent {
        ProjectAssetsComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Assets";
            icon = Icons::FileO;
            type = EProjectComponent::Assets;
        }

        string get_UrlPrefix() const { return ro_data.Get("urlPrefix", ""); }
        void set_UrlPrefix(const string &in v) { rw_data["urlPrefix"] = v; }

        Json::Value@ getRwAssets(AssetTy ty) {
            auto key = AssetTy_ToKey(ty);
            if (!ro_data.HasKey(key) || ro_data[key].GetType() != Json::Type::Array) {
                rw_data[key] = Json::Array();
            }
            return rw_data[key];
        }

        const Json::Value@ getRoAssets(AssetTy ty) {
            auto key = AssetTy_ToKey(ty);
            if (!ro_data.HasKey(key) || ro_data[key].GetType() != Json::Type::Array) {
                rw_data[key] = Json::Array();
            }
            return ro_data[key];
        }

        void pushAsset(AssetTy ty, const string &in asset) {
            auto @assets = getRwAssets(ty);
            assets.Add(asset);
        }

        void CreateDefaultJsonObject() override {
            auto j = Json::Object();
            j["urlPrefix"] = "";
            j["images"] = Json::Array();
            j["sounds"] = Json::Array();
            rw_data = j;
        }

        void DrawComponentInner(ProjectTab@ pTab) override {
            UrlPrefix = UI::InputText("URL Prefix", UrlPrefix);
            UI::Separator();
            UI::BeginTabBar("Assets", UI::TabBarFlags::None);
            if (UI::BeginTabItem("Images")) {
                DrawAssetTab(AssetTy::Image, pTab);
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Audio")) {
                DrawAssetTab(AssetTy::Sound, pTab);
                UI::EndTabItem();
            }
            UI::EndTabBar();
        }

        bool HasImageAsset(const string &in asset) {
            return HasAsset(AssetTy::Image, asset);
        }

        bool HasAsset(AssetTy ty, const string &in asset) {
            auto @images = getRoAssets(ty);
            for (uint i = 0; i < images.Length; i++) {
                if (images[i].GetType() == Json::Type::String && string(images[i]) == asset) return true;
            }
            return false;
        }

        void AddImageAsset(const string &in asset) {
            if (HasImageAsset(asset)) {
                NotifyWarning("Image asset already exists: " + asset);
                return;
            }
            pushAsset(AssetTy::Image, asset);
        }

        string iAsset = "";
        AssetTy lastAssetTy = AssetTy::Image;

        void DrawAssetTab(AssetTy ty, ProjectTab@ pTab) {
            if (lastAssetTy != ty) {
                lastAssetTy = ty;
                iAsset = "";
            }
            string assetType = AssetTy_ToKey(ty);
            bool changed = false;
            iAsset = UI::InputText("Asset File(s)", iAsset, changed);
            AddSimpleTooltip("Separate with commas to add many.");
            UI::SameLine();
            UI::BeginDisabled(iAsset.Length == 0);
            if (UI::Button(Icons::Plus + " Add")) {
                AddAssetsFromInput(ty, iAsset);
                iAsset = "";
            }
            UI::EndDisabled();

            UI::BeginChild(assetType + "Assets");
            UI::BeginTable(assetType + "Assets", 2, UI::TableFlags::SizingStretchProp);
            UI::TableSetupColumn("Asset", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
            // UI::TableHeadersRow();
            auto @assets = getRoAssets(ty);
            int remIx = -1;
            for (uint i = 0; i < assets.Length; i++) {
                UI::PushID(assetType + i);
                UI::TableNextRow();
                auto asset = string(assets[i]);
                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(asset);
                UI::SameLine();
                if (UI::Button(Icons::Download + " Test")) {
                    try {
                        OpenBrowserURL(UrlPrefix + asset);
                    } catch {
                        NotifyWarning("Invalid URL: " + UrlPrefix + asset);
                    }
                }
                AddSimpleTooltip("Full URL: " + UrlPrefix + asset);

                UI::TableNextColumn();
                if (UI::Button(Icons::TrashO + " Delete")) {
                    remIx = i;
                }
                UI::PopID();
            }
            UI::EndTable();
            UI::EndChild();

            if (remIx != -1) {
                auto @assets = getRwAssets(ty);
                assets.Remove(remIx);
                SaveToFile();
            }
        }

        void AddAssetsFromInput(AssetTy ty, const string &in input) {
            auto @assets = getRwAssets(ty);
            auto assetList = input.Split(",");
            int nbAdded = 0;
            for (uint i = 0; i < assetList.Length; i++) {
                string asset = assetList[i].Trim();
                if (asset.Length == 0) continue;
                if (HasAsset(ty, asset)) {
                    NotifyWarning("Asset already exists: " + asset);
                    continue;
                }
                assets.Add(asset);
                trace("Added asset: " + asset);
                nbAdded++;
            }
            SaveToFile();
            Notify("Added " + nbAdded + " assets.");
        }
    }
}


// MARK: Icons

string BoolIcon(bool f) {
    return f
        ? "\\$<\\$4f4" + Icons::Check + "\\$>"
        : "\\$<\\$f44" + Icons::Times + "\\$>";
}


// MARK: Misc


void SetEditorCameraToPos(vec3 pos, float dist = -1.0) {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto pmt = editor.PluginMapType;
    pmt.CameraTargetPosition = pos;
    if (dist > 0.0) pmt.CameraToTargetDistance = dist;
}

void SetEditorToTestMode() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Test;
    editor.PluginMapType.EditMode = CGameEditorPluginMap::EditMode::Place;
}

vec3 GetEditorItemCursorPos() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null || editor.ItemCursor is null) {
        return vec3(-1.0);
    }
    return editor.ItemCursor.CurrentPos;
}

// edit mode = place and place mode = test
bool EditorIsInTestPlaceMode() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto pmt = editor.PluginMapType;
    return pmt.EditMode == CGameEditorPluginMap::EditMode::Place && pmt.PlaceMode == CGameEditorPluginMap::EPlaceMode::Test;
}


void nvgDrawWorldBox(vec3 pos, vec3 size, vec4 color, float strokeWidth = 2.0) {
    vec3[] corners = array<vec3>(8);
    // Bottom face
    corners[0] = pos;
    corners[1] = pos + vec3(size.x, 0, 0);
    corners[2] = pos + vec3(size.x, 0, size.z);
    corners[3] = pos + vec3(0, 0, size.z);
    // Top face
    corners[4] = pos + vec3(0, size.y, 0);
    corners[5] = pos + vec3(size.x, size.y, 0);
    corners[6] = pos + vec3(size.x, size.y, size.z);
    corners[7] = pos + vec3(0, size.y, size.z);

    nvg::BeginPath();
    nvg::StrokeColor(color);
    nvg::StrokeWidth(strokeWidth);
    nvg::LineCap(nvg::LineCapType::Round);
    nvg::LineJoin(nvg::LineCapType::Round);

    // Bottom face loop (0→1→2→3→0)
    nvgMoveToWorldPos(corners[0]);
    nvgLineToWorldPos(corners[1]);
    nvgLineToWorldPos(corners[2]);
    nvgLineToWorldPos(corners[3]);
    nvgLineToWorldPos(corners[0]);

    // Top face loop (4→5→6→7→4)
    nvgMoveToWorldPos(corners[4]);
    nvgLineToWorldPos(corners[5]);
    nvgLineToWorldPos(corners[6]);
    nvgLineToWorldPos(corners[7]);
    nvgLineToWorldPos(corners[4]);

    // Vertical edges (0→4, 1→5, 2→6, 3→7)
    nvgMoveToWorldPos(corners[0]); nvgLineToWorldPos(corners[4]);
    nvgMoveToWorldPos(corners[1]); nvgLineToWorldPos(corners[5]);
    nvgMoveToWorldPos(corners[2]); nvgLineToWorldPos(corners[6]);
    nvgMoveToWorldPos(corners[3]); nvgLineToWorldPos(corners[7]);

    nvg::Stroke();
    nvg::ClosePath();
}




// MARK: Stub

class DipsSpec {
    string minClientVersion;
    string url;
    bool lastFloorEnd;
    FloorSpec[] floors;

    DipsSpec(const string &in comment) {
        warn("DipsSpec stub");
    }
}

class FloorSpec {
    float height;
    string name;
    Json::Value ToJson() {
        auto j = Json::Object();
        j["height"] = height;
        j["name"] = name;
        return j;
    }
}
