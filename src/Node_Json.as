namespace NG {
    class JsonSocket : Socket {
        Json::Value@ data;

        JsonSocket(SocketType ty, Node@ parent, const string &in name = "") {
            super(ty, parent, DataTypes::Json);
            SetName(name);
        }

        void ResetValue() override {
            @data = null;
        }

        Json::Value@ GetJsonValue() override {
            return data;
        }

        void WriteJsonValue(Json::Value@ val) override {
            @data = val;
            SignalInputsUpdated();
        }

        int64 GetInt() override {
            return int64(data);
        }

        double GetFloat() override {
            return double(data);
        }

        string GetString() override {
            return string(data);
        }

        bool GetBool() override {
            return bool(data);
        }
    }

    class StringValue : Node {
        string value;

        StringValue() {
            super("StringValue");
            outputs = {StringSocket(SocketType::Output, this, "str")};
        }

        Node@ FromJson(Json::Value@ j) override {
            value = string(j["v"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "StringValue";
            j["v"] = value;
            return j;
        }

        void Update() override {
            WriteString(0, value);
        }

        vec2 GetParamsSize() override {
            return vec2(100., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0));
            bool changed = false;
            UI::SetNextItemWidth(width - 8.);
            value = UI::InputText("##" + id, value, changed);
            if (changed) Update();
            UI::PopID();
            return ioHeight;
        }
    }

    class JsonParseObj : Node {
        Json::Value@ data;

        JsonParseObj() {
            super("JsonParseObj");
            outputs = {JsonSocket(SocketType::Output, this, "data")};
            inputs = {StringSocket(SocketType::Input, this, "json")};
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "JsonParseObj";
            return j;
        }

        Node@ FromJson(Json::Value@ j) override {
            Node::FromJson(j);
            return this;
        }

        vec2 GetParamsSize() override {
            return vec2(100., 0.);
        }

        void Update() override {
            string str = GetString(0);
            @data = Json::Parse(str);
            if (data is null || data.GetType() == Json::Type::Null) {
                errorStr = "Invalid JSON";
            } else {
                errorStr = "";
            }
            WriteJsonValue(0, data);
        }
    }

    class JsonGetKey : Node {
        string key;
        Json::Value@ data;

        JsonGetKey() {
            super("JsonGetKey");
            inputs = {JsonSocket(SocketType::Input, this, "in")};
            outputs = {JsonSocket(SocketType::Output, this, "out")};
        }

        Node@ FromJson(Json::Value@ j) override {
            key = string(j["key"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "JsonGetKey";
            j["key"] = key;
            return j;
        }

        void Update() override {
            @data = GetJsonValue(0);
            errorStr = "";
            if (data !is null) {
                if (data.GetType() != Json::Type::Object) {
                    errorStr = "Not an object";
                } else if (data.HasKey(key)) {
                    WriteJsonValue(0, data[key]);
                } else {
                    errorStr = "Key not found";
                }
            } else {
                errorStr = "No data for: " + inputs[0].name;
            }
        }

        vec2 GetParamsSize() override {
            return vec2(100., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            if (data is null) {
                UI::Text("\\$iNo data");
                return ioHeight;
            }
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0));
            bool changed = false;
            UI::SetNextItemWidth(width - 8.);
            if (UI::BeginCombo("##" + id, key)) {
                auto @keys = data.GetKeys();
                if (keys is null) {
                    UI::BeginDisabled(true);
                    UI::Selectable("No data", false);
                    UI::EndDisabled();
                } else {
                    for (uint i = 0; i < keys.Length; i++) {
                        if (UI::Selectable(keys[i], key == keys[i])) {
                            key = keys[i];
                            changed = true;
                        }
                    }
                }
                UI::EndCombo();
            }
            if (changed) Update();
            UI::PopID();
            return ioHeight;
        }
    }
}
