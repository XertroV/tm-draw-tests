namespace NG {
    class NodSocket : Socket {
        private ReferencedNod@ nod;

        NodSocket(SocketType ty, Node@ parent, const string &in name = "") {
            super(ty, parent, DataTypes::Nod);
            SetName(name);
        }

        void ResetValue() override {
            WriteNod(null);
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) override {
            Socket::UIDraw(dl, startCur, startPos, pos);
        }

        string GetMainLabel() override {
            if (nod is null) return "\\$inull";
            return nod.TypeName;
        }

        ReferencedNod@ GetNod() override {
            return nod;
        }

        void WriteNod(ReferencedNod@ n) override {
            @this.nod = n;
            SignalInputsUpdated();
        }
    }


    class NodPtrNode : Node {
        uint64 ptr;

        NodPtrNode() {
            super("Nod Ptr");
            inputs = {NodSocket(SocketType::Input, this, "Nod")};
            auto out1 = IntSocket(SocketType::Output, this, "Pointer");
            out1.RenderIntAsPtr = true;
            outputs = {out1};
        }

        Node@ FromJson(Json::Value@ j) override {
            ptr = 0;
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "NodPtrNode";
            return j;
        }

        void Update() override {
            errorStr = "";
            try {
                auto nod = GetNod(0);
                ptr = nod is null ? 0 : nod.ptr;
                WriteInt(0, ptr);
                outputs[0].SetName(ptr == 0 ? "null ptr" : "");
            } catch {
                errorStr = getExceptionInfo();
                WriteInt(0, 0);
                outputs[0].SetName("null (error)");
            }
        }

        vec2 GetParamsSize() override {
            return vec2(100., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            vec2 cur = startCur + pos + vec2(8., 0.);
            UI::PushID(id);

            UI::SetCursorPos(cur);
            UI::SetNextItemWidth(width - 16.);
            if (UI::Button("Copy Ptr")) {
                IO::SetClipboard(Text::FormatPointer(ptr));
                UI::ShowNotification("Copied ptr: " + Text::FormatPointer(ptr), 5000);
            }

            UI::PopID();
            return ioHeight;
        }
    }


    enum FidDrive {
        User, Game, Fake, ProgramData, Resource
    }

    class NodFromFileNode : Node {
        string path;
        FidDrive drive = FidDrive::User;
        ReferencedNod@ lastLoaded;

        NodFromFileNode() {
            super("Nod From File");
            inputs = {StringSocket(SocketType::Input, this, "Path")};
            outputs = {NodSocket(SocketType::Output, this, "Nod")};
        }

        Node@ FromJson(Json::Value@ j) override {
            path = j.Get("path", "");
            drive = FidDrive(int(j.Get("drive", 0)));
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "NodFromFileNode";
            j["path"] = path;
            j["drive"] = int(drive);
            return j;
        }

        void Update() override {
            print("\\$f8f [NodFromFileNode] Update: " + path);
            outputs[0].SetName("Nod: " + path);
            errorStr = "";
            try {
                path = GetString(0);
                TryAndLoadNod();
                WriteNod(0, this.lastLoaded);
            } catch {
                errorStr = getExceptionInfo();
                outputs[0].SetName("Nod (null)");
                print("\\$f8f [NodFromFileNode] Error: " + errorStr);
                WriteNod(0, null);
            }
        }

        private void TryAndLoadNod() {
            @lastLoaded = null;
            if (path.Length == 0) return;
            auto parts = SplitPath(path);
            auto fidsFolder = GetDriveRoot(drive);
            auto fidFile = LookupFidFile(fidsFolder, parts);
            if (fidFile is null) throw("File not found: " + path);
            if (fidFile.ByteSize == 0) warn("[TryAndLoadNod] File is empty: " + path);
            auto nod = Fids::Preload(fidFile);
            if (nod is null) throw("Failed to load nod: " + path);
            @lastLoaded = ReferencedNod(nod);
            print("\\$f8f [TryAndLoadNod] Loaded nod: " + path);
            print("\\$f8f [TryAndLoadNod] Loaded nod: " + NodToStr(lastLoaded));
            UI::ShowNotification("Loaded nod: " + path, 5000);
        }

        vec2 GetParamsSize() override {
            return vec2(120., ioHeight * 2);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            vec2 cur = startCur + pos + vec2(8., 0.);
            UI::PushID(id);

            UI::SetCursorPos(cur);
            UI::SetNextItemWidth(width - 16.);
            auto _drive = this.drive;
            this.drive = UI_Combo_FidDrive("##drive", this.drive);
            if (this.drive != _drive) Update();

            UI::SetCursorPos(cur + vec2(0., ioHeight));
            if (UI::Button("Update FID Tree")) {
                Fids::UpdateTree(GetDriveRoot(this.drive));
                Update();
            }

            UI::PopID();
            return ioHeight * 2;
        }
    }

    CSystemFidsFolder@ GetDriveRoot(FidDrive drive) {
        switch (drive) {
            case FidDrive::User: return Fids::GetUserFolder("");
            case FidDrive::Game: return Fids::GetGameFolder("");
            case FidDrive::Fake: return Fids::GetFakeFolder("");
            case FidDrive::ProgramData: return Fids::GetProgramDataFolder("");
            case FidDrive::Resource: return Fids::GetResourceFolder("");
        }
        throw("Invalid drive: " + tostring(drive));
        return null;
    }

    CSystemFidFile@ LookupFidFile(CSystemFidsFolder@ folder, string[]@ parts, int depth = 0) {
        if (depth >= parts.Length) throw("Invalid depth: " + depth);
        if (parts.Length == 0) throw("Empty path");
        auto lenLeft = parts.Length - depth;
        if (lenLeft > 1) {
            auto subFolder = FindSubfolder(folder, parts[depth]);
            if (subFolder is null) throw("Folder not found: " + parts[depth]);
            return LookupFidFile(subFolder, parts, depth + 1);
        }
        // lenLeft == 1
        if (parts[depth].Length == 0) throw("Empty file name");
        return FindFidFileIn(folder, parts[depth]);
    }

    CSystemFidFile@ FindFidFileIn(CSystemFidsFolder@ folder, const string &in name) {
        for (uint i = 0; i < folder.Leaves.Length; i++) {
            auto fid = folder.Leaves[i];
            if (fid.FileName == name) return fid;
        }
        return null;
    }

    CSystemFidsFolder@ FindSubfolder(CSystemFidsFolder@ folder, const string &in name) {
        for (uint i = 0; i < folder.Trees.Length; i++) {
            auto subFolder = folder.Trees[i];
            if (subFolder.DirName == name) return subFolder;
        }
        return null;
    }
}
