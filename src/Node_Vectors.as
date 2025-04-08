namespace NG {
    class Vec2Socket : Socket {
        vec2 value;

        Vec2Socket(SocketType ty, Node@ parent, const string &in name = "") {
            super(ty, parent, DataTypes::Vec2);
            SetName(name);
        }

        void ResetValue() override {
            value = vec2(0);
        }

        vec2 GetVec2() override {
            return value;
        }

        void WriteVec2(const vec2 &in val) override {
            value = val;
            SignalInputsUpdated();
        }

        Json::Value@ GetJsonValue() override {
            auto @v = Json::Array();
            v.Add(value.x);
            v.Add(value.y);
            return v;
        }

        void WriteJsonValue(Json::Value@ val) override {
            value = vec2(val[0], val[1]);
            SignalInputsUpdated();
        }
    }

    class Vec3Socket : Socket {
        vec3 value;

        Vec3Socket(SocketType ty, Node@ parent, const string &in name = "") {
            super(ty, parent, DataTypes::Vec3);
            SetName(name);
        }

        void ResetValue() override {
            value = vec3(0);
        }

        vec3 GetVec3() override {
            return value;
        }

        void WriteVec3(const vec3 &in val) override {
            value = val;
            SignalInputsUpdated();
        }

        Json::Value@ GetJsonValue() override {
            auto @v = Json::Array();
            v.Add(value.x);
            v.Add(value.y);
            v.Add(value.z);
            return v;
        }

        void WriteJsonValue(Json::Value@ val) override {
            value = vec3(val[0], val[1], val[2]);
            SignalInputsUpdated();
        }
    }

    class Vec4Socket : Socket {
        vec4 value;

        Vec4Socket(SocketType ty, Node@ parent, const string &in name = "") {
            super(ty, parent, DataTypes::Vec4);
            SetName(name);
        }

        void ResetValue() override {
            value = vec4(0);
        }

        vec4 GetVec4() override {
            return value;
        }

        void WriteVec4(const vec4 &in val) override {
            value = val;
            SignalInputsUpdated();
        }

        Json::Value@ GetJsonValue() override {
            auto @v = Json::Array();
            v.Add(value.x);
            v.Add(value.y);
            v.Add(value.z);
            v.Add(value.w);
            return v;
        }

        void WriteJsonValue(Json::Value@ val) override {
            value = vec4(val[0], val[1], val[2], val[3]);
            SignalInputsUpdated();
        }
    }


    class Vec2Value : Node {
        vec2 value;

        Vec2Value() {
            super("Vec2");
            outputs = {
                Vec2Socket(SocketType::Output, this, "xy"),
                FloatSocket(SocketType::Output, this, "x"),
                FloatSocket(SocketType::Output, this, "y")
            };
        }

        Node@ FromJson(Json::Value@ j) override {
            value = vec2(j["x"], j["y"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "Vec2Value";
            j["x"] = value.x;
            j["y"] = value.y;
            return j;
        }

        void Update() override {
            WriteVec2(0, value);
            WriteFloat(1, value.x);
            WriteFloat(2, value.y);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8.0, 0));
            UI::SetNextItemWidth(width - 8.);
            auto origVal = value;
            value = UI::InputFloat2(id, value);
            if (origVal != value) Update();
            UI::PopID();
            return ioHeight;
        }
    }

    class Vec3Value : Node {
        vec3 value;

        Vec3Value() {
            super("Vec3");
            outputs = {
                Vec3Socket(SocketType::Output, this, "xyz"),
                FloatSocket(SocketType::Output, this, "x"),
                FloatSocket(SocketType::Output, this, "y"),
                FloatSocket(SocketType::Output, this, "z")
            };
        }

        Node@ FromJson(Json::Value@ j) override {
            value = vec3(j["x"], j["y"], j["z"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "Vec3Value";
            j["x"] = value.x;
            j["y"] = value.y;
            j["z"] = value.z;
            return j;
        }

        void Update() override {
            WriteVec3(0, value);
            WriteFloat(1, value.x);
            WriteFloat(2, value.y);
            WriteFloat(3, value.z);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8.0, 0));
            UI::SetNextItemWidth(width - 8.);
            auto origVal = value;
            value = UI::InputFloat3(id, value);
            if (origVal != value) Update();
            UI::PopID();
            return ioHeight;
        }

        vec2 GetParamsSize() override {
            return vec2(110., ioHeight);
        }
    }

    class Vec4Value : Node {
        vec4 value;

        Vec4Value() {
            super("Vec4");
            outputs = {
                Vec4Socket(SocketType::Output, this, "xyzw"),
                FloatSocket(SocketType::Output, this, "x"),
                FloatSocket(SocketType::Output, this, "y"),
                FloatSocket(SocketType::Output, this, "z"),
                FloatSocket(SocketType::Output, this, "w")
            };
        }

        Node@ FromJson(Json::Value@ j) override {
            value = vec4(j["x"], j["y"], j["z"], j["w"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "Vec4Value";
            j["x"] = value.x;
            j["y"] = value.y;
            j["z"] = value.z;
            j["w"] = value.w;
            return j;
        }

        void Update() override {
            WriteVec4(0, value);
            WriteFloat(1, value.x);
            WriteFloat(2, value.y);
            WriteFloat(3, value.z);
            WriteFloat(4, value.w);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8.0, 0));
            UI::SetNextItemWidth(width - 8.);
            auto origVal = value;
            value = UI::InputFloat4(id, value);
            if (origVal != value) Update();
            UI::PopID();
            return ioHeight;
        }

        vec2 GetParamsSize() override {
            return vec2(140., ioHeight);
        }
    }
}
