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
        if (!IO::FolderExists(ProjectsDir)) IO::CreateFolder(ProjectsDir, true);
        auto projs = ListProjects();
        if (projs.Length == 0) IO::CreateFolder(ProjectsDir + "/Test", false);
        if (projs.Length < 2) IO::CreateFolder(ProjectsDir + "/Test2_ASDF", false);
        @projs = ListProjects();
        // trace("Projects: " + Json::Write(projs.ToJson()));
    }

    void Render() {
        if (!S_EditorWindowOpen) return;
        UI::SetNextWindowSize(500, 370, UI::Cond::FirstUseEver);
        if (UI::Begin("Dips++ CustomMap Editor", S_EditorWindowOpen)) {
            Draw_CMEditor_WindowMain();
        }
        UI::End();
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
            if (UI::Button(Icons::FolderOpenO + " Open")) {
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
            // grp2.AddComponent(ProjectTriggersComponent());
            // grp2.AddComponent(ProjectMinigamesComponent());
            // grp2.AddComponent(ProjectCollectablesComponent());
            // grp2.AddComponent(ProjectAssetsComponent());
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

        int selectedComponent = 0;
        void DrawProjComponentSelector() {
            for (uint i = 0; i < componentGroups.Length; i++) {
                selectedComponent = componentGroups[i].DrawSelector(selectedComponent);
            }
            return;
            // UI::SeparatorText("\\$i\\$bbbProject");
            // if (UI::Selectable(Icons::InfoCircle + " Project Info", selectedComponent == int(EProjectComponent::Info))) {
            //     selectedComponent = EProjectComponent::Info;
            // }
            // if (UI::Selectable(Icons::BuildingO + " Floors", selectedComponent == int(EProjectComponent::Floors))) {
            //     selectedComponent = EProjectComponent::Floors;
            // }
            // UI::SeparatorText("\\$i\\$bbbComponents");
            // if (UI::Selectable(Icons::CommentO + " Voice Lines", selectedComponent == int(EProjectComponent::VoiceLines))) {
            //     selectedComponent = EProjectComponent::VoiceLines;
            // }
            // if (UI::Selectable(Icons::Cog + " Triggers", selectedComponent == int(EProjectComponent::Triggers))) {
            //     selectedComponent = EProjectComponent::Triggers;
            // }
            // if (UI::Selectable(Icons::Gamepad + " Minigames", selectedComponent == int(EProjectComponent::Minigames))) {
            //     selectedComponent = EProjectComponent::Minigames;
            // }
            // if (UI::Selectable(Icons::FileO + " Assets", selectedComponent == int(EProjectComponent::Assets))) {
            //     selectedComponent = EProjectComponent::Assets;
            // }
        }

        void DrawProjComponent() {
            for (uint i = 0; i < componentGroups.Length; i++) {
                auto grp = componentGroups[i];
                if (grp.DrawProjComponent(selectedComponent, this)) {
                    break;
                }
            }
            // switch (EProjectComponent(selectedComponent)) {
            //     case EProjectComponent::Info: DrawProjInfo(); break;
            //     case EProjectComponent::Floors: DrawFloors(); break;
            //     case EProjectComponent::VoiceLines: DrawVoiceLines(); break;
            //     case EProjectComponent::Triggers: DrawTriggers(); break;
            //     case EProjectComponent::Minigames: DrawMinigames(); break;
            //     case EProjectComponent::Assets: DrawAssets(); break;
            // }
        }

        // void DrawProjInfo() {
        //     UI::Text("Project Name: " + meta.name);
        //     UI::Text("Project Path: " + meta.path);
        //     UI::Separator();
        //     UI::TextWrapped("This is the project info tab. You can add more info here.");
        // }

        // void DrawFloors() {
        //     UI::Text("Floors");
        //     UI::Separator();
        //     if (meta.hasFloors) {
        //         UI::TextWrapped("Floors loaded: " + meta.jro_Floors.Length);
        //     } else {
        //         UI::TextWrapped("No floors found.");
        //         if (UI::Button(Icons::Plus + " Add Floors")) {
        //             InitFloors();
        //         }
        //     }
        // }

        // void DrawVoiceLines() {
        //     UI::Text("Voice Lines");
        //     UI::Separator();
        //     if (meta.hasVoiceLines) {
        //         UI::TextWrapped("Voice lines loaded: " + meta.jro_VoiceLine.Length);
        //     } else {
        //         UI::TextWrapped("No voice lines found.");
        //         if (UI::Button(Icons::Plus + " Add Voice Lines")) {
        //             InitVoiceLines();
        //         }
        //     }
        // }
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

        // void InitFloors() {

        // }

        // void InitVoiceLines() {

        // }

        // void InitTriggers() {

        // }

        // void InitMinigames() {

        // }

        // void InitAssets() {

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

    // MARK: Project Component Group

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

        void DrawComponent(ProjectTab@ pTab) {
            UI::Text(name);
            UI::Separator();
            if (!hasFile) {
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
            throw("Override me");
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
    }

    class ProjectInfoComponent : ProjectComponent {
        ProjectInfoComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Project Info";
            icon = Icons::InfoCircle;
            type = EProjectComponent::Info;
            canInitFromDipsSpecComment = true;
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
        }

        void DrawHasComponent(EProjectComponent ty, ProjectTab@ pTab) {
            auto comp = pTab.GetComponentByType(ty);
            UI::Text(BoolIcon(comp is null ? false : comp.hasFile) + " " + ProjectComponentToString(ty));
        }
    }

    class ProjectFloorsComponent : ProjectComponent {
        ProjectFloorsComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Floors";
            icon = Icons::BuildingO;
            type = EProjectComponent::Floors;
            canInitFromDipsSpecComment = true;
        }

        // proxy methods for data access
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
    }

    class ProjectVoiceLinesComponent : ProjectComponent {
        ProjectVoiceLinesComponent(const string &in jsonPath, ProjectMeta@ meta) {
            super(jsonPath, meta);
            name = "Voice Lines";
            icon = Icons::CommentO;
            type = EProjectComponent::VoiceLines;
        }
    }

    string BoolIcon(bool f) {
        return f
            ? "\\$<\\$4f4" + Icons::Check + "\\$>"
            : "\\$<\\$f44" + Icons::Times + "\\$>";
    }
}







// Stub

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
