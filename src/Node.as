namespace NG {
#if DEV
    bool DRAW_DEBUG = true;
#else
    bool DRAW_DEBUG = false;
#endif
    enum DataTypes {
        Int,
        Float,
        Bool,
        String,
        Json,
        Vec2,
        Vec3,
        Vec4,
        Mat3,
        Mat4,
        Nod,
    }

    interface Operation {
        int get_NbInputs() const;
        int get_NbOutputs() const;
        void Update();
    }

    enum SocketType {
        Input,
        Output
    }

    enum SocketDataKind {
        Value,
        Field,
        Both
    }

    class Socket {
        string id;
        string origId;
        string name;
        string errorStr;
        SocketType ty;
        DataTypes dataTy;
        SocketDataKind dataKind;
        Noodle@[] edges;
        bool allowMultipleEdges = false;
        Node@ node;
        // set when drawing
        vec2 pos;

        Socket(SocketType ty, Node@ parent, DataTypes dataTy) {
            @this.node = parent;
            this.ty = ty;
            this.dataTy = dataTy;
            id = "##" + Math::Rand(-1000000000, 1000000000);
            origId = id;
            SetName(tostring(dataTy));
        }

        Json::Value@ GetEdgeIdsJson() {
            Json::Value@ j = Json::Array();
            for (uint i = 0; i < edges.Length; i++) {
                j.Add(edges[i].id);
            }
            return j;
        }

        void SetName(const string &in name) {
            this.name = name;
            if (name.Length > 0) {
                id = name + origId;
            }
        }

        void Destroy() {
            trace('Socket destroy');
            for (uint i = 0; i < edges.Length; i++) {
                if (edges[i] !is null) {
                    startnew(CoroutineFunc(edges[i].Disconnect));
                }
            }
            edges.RemoveRange(0, edges.Length);
        }

        void Disconnect(Noodle@ edge = null) {
            trace('socket disconnecting ' + id + '; edge: ' + (edge !is null ? edge.id : "null"));
            for (uint i = 0; i < edges.Length; i++) {
                if (edge is null || edges[i] is edge) {
                    edges.RemoveAt(i);
                    i--;
                }
            }
            if (edges.Length == 0 && IsInput)
                ResetValue();
        }

        void ResetValue() {
            // socket specific
        }

        bool get_IsInput() { return ty == SocketType::Input; }
        bool get_IsOutput() { return ty == SocketType::Output; }

        bool get_IsArrayType() {
            return dataKind == SocketDataKind::Field;
        }

        void Connect(Noodle@ edge) {
            if (IsInput && edges.Length > 0) {
                if (edges[0] !is edge) {
                    trace('Connect is disconnecting prior edge: ' + edges[0].id);
                    startnew(CoroutineFunc(edges[0].Disconnect));
                    @edges[0] = edge;
                }
            } else {
                edges.InsertLast(edge);
            }

            try {
                if (IsInput && edge.from !is null) {
                    WriteFromSocket(edge.from);
                } else if (edge.to !is null) {
                    edge.to.WriteFromSocket(this);
                }
                errorStr = "";
            } catch {
                errorStr = "Error: " + getExceptionInfo();
            }
        }

        void SignalUpdated() {
            for (uint i = 0; i < edges.Length; i++) {
                edges[i].WriteOutFrom(this);
            }
        }

        void SignalInputsUpdated() {
            if (IsInput && node !is null) {
                node.SignalInputsUpdated();
            }
        }

        Noodle@ get_SingularEdge() {
            if (edges.Length > 0) {
                return edges[0];
            }
            return null;
        }

        void WriteFromSocket(Socket@ socket) {
            if (socket is null) {
                throw("Socket.WriteFromSocket: socket is null");
            }
            switch (dataTy) {
                case DataTypes::Int: WriteInt(socket.GetInt()); break;
                case DataTypes::Bool: WriteBool(socket.GetBool()); break;
                case DataTypes::Float: WriteFloat(socket.GetFloat()); break;
                case DataTypes::String: WriteString(socket.GetString()); break;
                case DataTypes::Json: WriteJsonValue(socket.GetJsonValue()); break;
                case DataTypes::Vec2: WriteVec2(socket.GetVec2()); break;
                case DataTypes::Vec3: WriteVec3(socket.GetVec3()); break;
                case DataTypes::Vec4: WriteVec4(socket.GetVec4()); break;
                case DataTypes::Mat3: WriteMat3(socket.GetMat3()); break;
                case DataTypes::Mat4: WriteMat4(socket.GetMat4()); break;
                case DataTypes::Nod: WriteNod(socket.GetNod()); break;
                default: throw("unknown data type: " + tostring(dataTy));
            }
        }

        string GetValueString() {
            if (IsArrayType) {
                throw("todo: GetValueString for array types");
            }
            switch (dataTy) {
                case DataTypes::Int: return tostring(GetInt());
                case DataTypes::Bool: return GetBool() ? "true" : "false";
                case DataTypes::Float: return Text::Format("%.3f", GetFloat());
                case DataTypes::String: return truncString(GetString(), 16);
                case DataTypes::Json: return truncString(Json::Write(GetJsonValue()), 16);
                case DataTypes::Vec2: return GetVec2().ToString();
                case DataTypes::Vec3: return GetVec3().ToString();
                case DataTypes::Vec4: return GetVec4().ToString();
                case DataTypes::Mat3: return Mat3ToStr(GetMat3());
                case DataTypes::Mat4: return Mat4ToStr(GetMat4());
                case DataTypes::Nod: return NodToStr(GetNod());
                default: throw("unknown data type: " + tostring(dataTy));
            }
            return "?";
        }

        int64 GetInt() { throw("Socket::GetInt: no implementation"); return 0; }
        void WriteInt(int64 value) { throw("Socket::WriteInt: no implementation"); }
        bool GetBool() { throw("Socket::GetBool: no implementation"); return false; }
        void WriteBool(bool value) { throw("Socket::WriteBool: no implementation"); }
        double GetFloat() { throw("Socket::GetFloat: no implementation"); return 0; }
        void WriteFloat(double value) { throw("Socket::WriteFloat: no implementation"); }
        string GetString() { throw("Socket::GetString: no implementation"); return ""; }
        void WriteString(const string &in value) { throw("Socket::WriteString: no implementation"); }
        Json::Value@ GetJsonValue() { throw("Socket::GetJsonValue: no implementation"); return null; }
        void WriteJsonValue(Json::Value@ value) { throw("Socket::WriteJsonValue: no implementation"); }
        vec2 GetVec2() { throw("Socket::GetVec2: no implementation"); return vec2(); }
        void WriteVec2(const vec2 &in value) { throw("Socket::WriteVec2: no implementation"); }
        vec3 GetVec3() { throw("Socket::GetVec3: no implementation"); return vec3(); }
        void WriteVec3(const vec3 &in value) { throw("Socket::WriteVec3: no implementation"); }
        vec4 GetVec4() { throw("Socket::GetVec4: no implementation"); return vec4(); }
        void WriteVec4(const vec4 &in value) { throw("Socket::WriteVec4: no implementation"); }
        mat3 GetMat3() { throw("Socket::GetMat3: no implementation"); return mat3(); }
        void WriteMat3(const mat3 &in value) { throw("Socket::WriteMat3: no implementation"); }
        mat4 GetMat4() { throw("Socket::GetMat4: no implementation"); return mat4(); }
        void WriteMat4(const mat4 &in value) { throw("Socket::WriteMat4: no implementation"); }
        ReferencedNod@ GetNod() { throw("Socket::GetNod: no implementation"); return null; }
        void WriteNod(ReferencedNod@ n) { throw("Socket::WriteNod: no implementation"); }

        const float[]@ GetFloatArray() {
            throw("Socket::GetFloatArray: no implementation");
            return {};
        }
        void WriteFloatArray(const float[] &in values) { throw("Socket::WriteFloatArray: no implementation"); }
        const int64[]@ GetIntArray() {
            throw("Socket::GetIntArray: no implementation");
            return {};
        }
        void WriteIntArray(const int64[] &in values) { throw("Socket::WriteIntArray: no implementation"); }

        vec2 textSize;

        string GetMainLabel() {
            return name.Length > 0 ? name + " = " + GetValueString() : GetValueString();
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) {
            this.pos = pos;
            vec2 size = vec2(10.);
            // pos -= size / 2.;
            UI::SetCursorPos(startCur + pos - size / 2.);
            UI::InvisibleButton(id, size);
            bool clicked = UI::IsItemClicked();
            dl.AddCircleFilled(startPos + pos, size.x / 2., cWhite, 12);
            bool alignRight = IsOutput;
            string label = GetMainLabel();
            textSize = Draw::MeasureString(label, g_NormFont, 16.);
            auto yOff = size.y / 2. + 3.;
            if (alignRight) {
                UI::SetCursorPos(startCur + pos - vec2(textSize.x + 8., yOff));
            } else {
                UI::SetCursorPos(startCur + pos + vec2(8., -yOff));
            }
            UI::Text(label);

            if (clicked) {
                if (IsInput && edges.Length == 1) {
                    SingularEdge.DisconnectOther(this);
                    node.graph.SetTmpNoodle(SingularEdge);
                } else {
                    // if 0 or > 1 noodles, start a new noodle
                    node.graph.StartNoodle(this);
                }
            }
        }
    }

    // class Connection : Input, Output {
    //     Connection()
    // }

    class IntSocket : Socket {
        int64 value;
        int64[] values;
        int64 _default;
        bool RenderIntAsPtr = false;

        IntSocket(SocketType ty, Node@ parent, const string &in name = "", int64 _default = 0) {
            super(ty, parent, DataTypes::Int);
            this._default = _default;
            SetName(name);
        }

        string GetValueString() override {
            if (RenderIntAsPtr) {
                return Text::FormatPointer(value);
            }
            return Socket::GetValueString();
        }

        void ResetValue() override {
            WriteInt(_default);
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) override {
            Socket::UIDraw(dl, startCur, startPos, pos);
        }

        int64 GetInt() override {
            return value;
        }

        double GetFloat() override {
            return double(value);
        }

        bool GetBool() override {
            return value != 0;
        }

        void WriteInt(int64 value) override {
            this.value = value;
            SignalInputsUpdated();
        }

        void WriteFloat(double value) override {
            WriteInt(int(value));
        }

        void WriteBool(bool value) override {
            WriteInt(value ? 1 : 0);
        }

        // Converts field of ints to field of floats
        const float[]@ GetFloatArray() override {
            if (!IsArrayType) throw("IntSocket::GetFloatArray: not an array type");
            float[] arr = array<float>(values.Length);
            for (uint i = 0; i < values.Length; i++) {
                arr[i] = float(values[i]);
            }
            return arr;
        }

        void WriteFloatArray(const array<float>&in newVals) override {
            if (!IsArrayType) throw("IntSocket::WriteFloatArray: not an array type");
            values.Resize(newVals.Length);
            for (uint i = 0; i < values.Length; i++) {
                this.values[i] = int64(newVals[i]);
            }
            SignalInputsUpdated();
        }

        const array<int64>@ GetIntArray() override {
            if (!IsArrayType) throw("IntSocket::GetIntArray: not an array type");
            return values;
        }

        void WriteIntArray(const array<int64>&in newVals) override {
            if (!IsArrayType) throw("IntSocket::WriteIntArray: not an array type");
            values.Resize(newVals.Length);
            for (uint i = 0; i < newVals.Length; i++) {
                values[i] = newVals[i];
            }
            SignalInputsUpdated();
        }
    }

    class FloatSocket : Socket {
        double value;
        float[] values;
        double _default;

        FloatSocket(SocketType ty, Node@ parent, const string &in name = "", double _default = 0) {
            super(ty, parent, DataTypes::Float);
            this._default = _default;
            SetName(name);
        }

        void ResetValue() override {
            WriteFloat(_default);
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) override {
            Socket::UIDraw(dl, startCur, startPos, pos);
        }

        int64 GetInt() override {
            return int(value);
        }

        double GetFloat() override {
            return value;
        }

        void WriteInt(int64 value) override {
            WriteFloat(double(value));
        }

        void WriteFloat(double value) override {
            this.value = value;
            SignalInputsUpdated();
        }

        const float[]@ GetFloatArray() override {
            if (!IsArrayType) throw("FloatSocket::GetFloatArray: not an array type");
            return values;
        }

        void WriteFloatArray(const array<float>&in newVals) override {
            if (!IsArrayType) throw("FloatSocket::WriteFloatArray: not an array type");
            values.Resize(newVals.Length);
            for (uint i = 0; i < values.Length; i++) {
                this.values[i] = newVals[i];
            }
            SignalInputsUpdated();
        }

        const array<int64>@ GetIntArray() override {
            if (!IsArrayType) throw("FloatSocket::GetIntArray: not an array type");
            int64[] arr = array<int64>(values.Length);
            for (uint i = 0; i < values.Length; i++) {
                arr[i] = int64(values[i]);
            }
            return arr;
        }

        void WriteIntArray(const array<int64>&in newVals) override {
            if (!IsArrayType) throw("FloatSocket::WriteIntArray: not an array type");
            values.Resize(newVals.Length);
            for (uint i = 0; i < newVals.Length; i++) {
                values[i] = float(newVals[i]);
            }
            SignalInputsUpdated();
        }
    }

    class StringSocket : Socket {
        string value;
        string _default;

        StringSocket(SocketType ty, Node@ parent, const string &in name = "", const string &in _default = "") {
            super(ty, parent, DataTypes::String);
            this._default = _default;
            SetName(name);
        }

        void ResetValue() override {
            WriteString(_default);
        }

        string GetString() override {
            return value;
        }

        void WriteString(const string &in value) override {
            this.value = value;
            SignalInputsUpdated();
        }
    }

    bool IsCompatFromTo(Socket@ from, Socket@ to) {
        if (from.dataTy == to.dataTy) return true;
        if (from.dataTy == DataTypes::Json) return true;
        if (to.dataTy == DataTypes::Json) return true;
        if (from.dataTy == DataTypes::Int && to.dataTy == DataTypes::Float) return true;
        if (from.dataTy == DataTypes::Float && to.dataTy == DataTypes::Int) return true;
        return false;
    }

    class Noodle {
        string id;
        Socket@ from;
        Socket@ to;
        string errorMsg;

        Noodle(Socket@ from, Socket@ to) {
            @this.from = from;
            @this.to = to;
            CheckToFromTypesOkay();
            if (from !is null) from.Connect(this);
            if (to !is null) to.Connect(this);
            id = "##" + Math::Rand(-1000000000, 1000000000);
        }


        bool CheckToFromTypesOkay() {
            if (from !is null && to !is null && !IsCompatFromTo(from, to)) {
                errorMsg = "Data types do not match: " + from.dataTy + " != " + to.dataTy;
                return false;
            }
            errorMsg = "";
            return true;
        }

        bool get_IsConnected() {
            return FromNode !is null && ToNode !is null;
        }

        void TryConnect(Node@ node, vec2 mousePos) {
            trace('noodle '+id+' trying connect to ' + node.id + ' at ' + mousePos.ToString());
            if (node is FromNode || node is ToNode) return;
            if (FromNode !is null) {
                trace('From: ' + FromNode.id);
            }
            if (ToNode !is null) {
                trace('To: ' + ToNode.id);
            }
            trace('finding sock');
            auto sock = node.FindSocketNear(mousePos);
            trace('found sock: ' + (sock !is null));
            if (sock !is null) {
                if (from is null && sock.IsOutput) {
                    trace('connecting from');
                    @from = sock;
                    CheckToFromTypesOkay();
                    from.Connect(this);
                } else if (to is null && sock.IsInput) {
                    trace('connecting to');
                    @to = sock;
                    CheckToFromTypesOkay();
                    to.Connect(this);
                }
            }
        }

        Node@ get_FromNode() {
            if (from !is null) return from.node;
            return null;
        }

        Node@ get_ToNode() {
            if (to !is null) return to.node;
            return null;
        }

        void Destroy() {
            if (from !is null) from.Destroy();
            if (to !is null) to.Destroy();
            @from = null;
            @to = null;
        }

        void Disconnect() {
            trace('noodle disconnecting ' + id);
            if (from !is null) from.Disconnect(this);
            if (to !is null) to.Disconnect(this);
            @from = null;
            @to = null;
            g_GraphTab.RemoveEdge(this);
        }

        void DisconnectOther(Socket@ socket) {
            trace('noodle disconnecting other ' + id);
            if (from is socket) {
                to.Disconnect(this);
                @to = null;
            } else if (to is socket) {
                from.Disconnect(this);
                @from = null;
            }
        }

        void WriteOutFrom(Socket@ socket) {
            if (!CheckToFromTypesOkay()) return;
            if (to !is null) {
                try {
                    to.WriteFromSocket(socket);
                } catch {
                    errorMsg = "Error: " + getExceptionInfo();
                }
            }
        }

        vec2 get_FromPos() {
            if (from !is null) return from.pos;
            return nodeGraphMousePos;
        }

        vec2 get_ToPos() {
            if (to !is null) return to.pos;
            return nodeGraphMousePos;
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 mousePos) {
            auto col = errorMsg.Length > 0 ? cOrangeA50 : cLimeGreen;
            auto fromPos = FromPos;
            auto toPos = ToPos;
            dl.AddLine(startPos + fromPos, startPos + toPos, col, 3.f);
            if (errorMsg.Length > 0) {
                dl.AddText(startPos + Math::Lerp(fromPos, toPos, .5), cOrange, errorMsg, g_BoldFont, 0.0, 60.0f);
            }
            // if (DRAW_DEBUG) {
            //     UI::SetCursorPos(startCur + vec2(FromPos + ToPos) / 2. - vec2(0, 16.) - Draw::MeasureString(id, g_NormFont, 16.) / 2.);
            //     UI::Text(id);
            // }
        }
    }

    class Node : Operation {
        Socket@[] inputs;
        Socket@[] outputs;
        string nodeName = "Node";
        string id;
        GraphTab@ graph;
        string errorStr;

        Node(const string &in name) {
            nodeName = name;
            id = "##n" + Math::Rand(-1000000000, 1000000000);
        }

        Node@ FromJson(Json::Value@ j) {
            if (j.HasKey("pos")) pos = Vec2FromJson(j["pos"]);
            print("Node::FromJson: " + pos.ToString() + " from " + Json::Write(j));
            pos.x = Math::Max(0., pos.x);
            pos.y = Math::Max(0., pos.y);
            Update();
            return this;
        }

        Json::Value@ ToJson() {
            Json::Value@ j = Json::Object();
            AddSocketEdgesToJsonObj(j);
            j['pos'] = Vec2ToJson(pos);
            return j;
        }

        Json::Value@ AddSocketEdgesToJsonObj(Json::Value@ j) {
            Json::Value@ ins = Json::Array();
            Json::Value@ outs = Json::Array();
            for (uint i = 0; i < inputs.Length; i++) {
                ins.Add(inputs[i].GetEdgeIdsJson());
            }
            for (uint i = 0; i < outputs.Length; i++) {
                outs.Add(outputs[i].GetEdgeIdsJson());
            }
            j["inputs"] = ins;
            j["outputs"] = outs;
            return j;
        }

        void Destroy() {
            for (uint i = 0; i < inputs.Length; i++) {
                if (inputs[i] !is null) inputs[i].Destroy();
            }
            for (uint i = 0; i < outputs.Length; i++) {
                if (outputs[i] !is null) outputs[i].Destroy();
            }
            inputs.RemoveRange(0, inputs.Length);
            outputs.RemoveRange(0, outputs.Length);
            if (graph !is null) {
                graph.RemoveNode(this);
            }
        }

        void Delete() {
            if (graph !is null) {
                graph.RemoveNode(this);
            }
            for (uint i = 0; i < inputs.Length; i++) {
                if (inputs[i] !is null) {
                    inputs[i].Disconnect();
                }
            }
            for (uint i = 0; i < outputs.Length; i++) {
                if (outputs[i] !is null) {
                    outputs[i].Disconnect();
                }
            }
        }

        int get_NbInputs() const {
            return inputs.Length;
        }

        int get_NbOutputs() const {
            return outputs.Length;
        }

        Socket@ FindSocketNear(vec2 mousePos) {
            for (uint i = 0; i < inputs.Length; i++) {
                if (MathX::Within(mousePos, vec4(inputs[i].pos - vec2(7.), vec2(14.)))) {
                    return inputs[i];
                }
            }
            for (uint i = 0; i < outputs.Length; i++) {
                if (MathX::Within(mousePos, vec4(outputs[i].pos - vec2(7.), vec2(14.)))) {
                    return outputs[i];
                }
            }
            return null;
        }

        bool CheckIO() {
            for (int i = 0; i < inputs.Length; i++) {
                if (inputs[i] is null) {
                    return false;
                }
            }
            for (int i = 0; i < outputs.Length; i++) {
                if (outputs[i] is null) {
                    return false;
                }
            }
            return true;
        }

        void Update() {
            // node specific
        }

        void SignalInputsUpdated() {
            Update();
        }

        void SignalUpdated() {
            for (uint i = 0; i < outputs.Length; i++) {
                outputs[i].SignalUpdated();
            }
        }

        int64 GetInt(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetInt();
            }
            return 0;
        }

        void WriteInt(int index, int64 value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteInt(value);
                outputs[index].SignalUpdated();
            }
        }

        double GetFloat(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetFloat();
            }
            return 0;
        }

        void WriteFloat(int index, double value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteFloat(value);
                outputs[index].SignalUpdated();
            }
        }

        string GetString(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetString();
            }
            return "";
        }

        void WriteString(int index, const string &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteString(value);
                outputs[index].SignalUpdated();
            }
        }

        Json::Value@ GetJsonValue(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetJsonValue();
            }
            return null;
        }

        void WriteJsonValue(int index, Json::Value@ value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteJsonValue(value);
                outputs[index].SignalUpdated();
            }
        }

        vec2 GetVec2(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetVec2();
            }
            return vec2();
        }

        void WriteVec2(int index, const vec2 &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteVec2(value);
                outputs[index].SignalUpdated();
            }
        }

        vec3 GetVec3(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetVec3();
            }
            return vec3();
        }

        void WriteVec3(int index, const vec3 &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteVec3(value);
                outputs[index].SignalUpdated();
            }
        }

        vec4 GetVec4(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetVec4();
            }
            return vec4();
        }

        void WriteVec4(int index, const vec4 &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteVec4(value);
                outputs[index].SignalUpdated();
            }
        }

        mat3 GetMat3(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetMat3();
            }
            return mat3();
        }

        void WriteMat3(int index, const mat3 &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteMat3(value);
                outputs[index].SignalUpdated();
            }
        }

        mat4 GetMat4(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetMat4();
            }
            return mat4();
        }

        void WriteMat4(int index, const mat4 &in value) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteMat4(value);
                outputs[index].SignalUpdated();
            }
        }

        ReferencedNod@ GetNod(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetNod();
            }
            return null;
        }

        void WriteNod(int index, ReferencedNod@ n) {
            // Write the value to the output
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteNod(n);
                outputs[index].SignalUpdated();
            }
        }

        bool IsInputArray(int index) {
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].IsArrayType;
            }
            return false;
        }

        const float[]@ GetFloatArray(int index) {
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetFloatArray();
            }
            return null;
        }

        void WriteFloatArray(int index, const float[] &in values) {
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteFloatArray(values);
                outputs[index].SignalUpdated();
            }
        }

        const int64[]@ GetIntArray(int index) {
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetIntArray();
            }
            return null;
        }

        void WriteIntArray(int index, const int64[] &in values) {
            if (index < outputs.Length && outputs[index] !is null) {
                outputs[index].WriteIntArray(values);
                outputs[index].SignalUpdated();
            }
        }

        vec2 pos;
        bool isDragging;
        vec2 dragOffset;
        bool isHovered;

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 mousePos) {
            if (isDragging) {
                pos = UI::GetMousePos() - dragOffset;
                if (!UI::IsMouseDown(UI::MouseButton::Left)) {
                    isDragging = false;
                }
            }

            auto size = UIDrawBackground(dl, startCur, startPos, pos);
            isHovered = MathX::Within(mousePos, vec4(pos - vec2(5.), size + vec2(10.)));
            if (isHovered) UIDrawBackgroundOutline(dl, startCur, startPos, pos, size);

            auto offsetY = UIDrawTitleBar(dl, startCur, startPos, pos, size.x);
            offsetY += UIDrawOutputs(dl, startCur, startPos, pos + vec2(0, offsetY), size.x);
            offsetY += UIDrawParams(dl, startCur, startPos, pos + vec2(0, offsetY), size.x);
            offsetY += UIDrawInputs(dl, startCur, startPos, pos + vec2(0, offsetY), size.x);

            if (errorStr.Length > 0) {
                UI::SetCursorPos(startCur + pos - vec2(0, 20.));
                UI::PushStyleColor(UI::Col::Text, cOrange);
                UI::Text(errorStr);
                UI::PopStyleColor();
            }

            UIDrawInvisButton(dl, startCur, startPos, pos, size);
            bool clicked = UI::IsItemClicked();
            if (clicked) {
                isDragging = true;
                dragOffset = UI::GetMousePos() - pos;
            }

            UIDrawRightClickMenu();
        }

        void UIDrawRightClickMenu() {
            if (UI::BeginPopupContextItem(id+"rc")) {
                graph.nodeCtxMenuOpen = true;
                UIDrawRightClickMenuBeforeStd();
                if (UI::MenuItem("Delete")) {
                    Delete();
                }
                UI::EndPopup();
            }
        }

        void UIDrawRightClickMenuBeforeStd() {
            // node specific
        }

        vec2 GetParamsSize() {
            return vec2(80., ioHeight);
        }

        vec2 uiDrawSize = vec2();
        vec2 tbPadding = vec2(8, 4);
        float ioHeight = 20.;
        vec2 titleBarSize;

        void RefreshDrawSize() {
            uiDrawSize = vec2();
        }

        vec2 UIGetDrawSize() {
            if (uiDrawSize.LengthSquared() > 100.) return uiDrawSize;
            titleBarSize = Draw::MeasureString(nodeName, g_NormFont, 16.);
            titleBarSize.y += tbPadding.y * 2.;
            vec2 outputsSize = ioHeight * vec2(2., outputs.Length);
            vec2 inputsSize = ioHeight * vec2(2., inputs.Length);
            vec2 paramsSize = GetParamsSize();
            uiDrawSize = vec2(
                30. + Math::Max(titleBarSize.x, Math::Max(outputsSize.x, Math::Max(inputsSize.x, paramsSize.x))),
                titleBarSize.y + outputsSize.y + inputsSize.y + paramsSize.y
            );
            return uiDrawSize;
        }

        vec2 UIDrawBackground(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) {
            vec2 size = UIGetDrawSize();
            dl.AddRectFilled(vec4(startPos + pos, size), cSkyBlue25, 6.f);
            // UI::BeginDisabled();
            // UI::Button(id+"b", size);
            // UI::EndDisabled();
            return size;
        }

        void UIDrawBackgroundOutline(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, vec2 size) {
            dl.AddRect(vec4(startPos + pos, size), cWhite, 6.f, 2.f);
        }

        bool UIDrawInvisButton(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, vec2 size) {
            UI::SetCursorPos(startCur + pos);
            return UI::InvisibleButton(id+"b", size, UI::ButtonFlags::MouseButtonLeft);
        }

        float UIDrawTitleBar(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) {
            dl.AddRectFilled(vec4((startPos + pos), vec2(width, titleBarSize.y)), errorStr.Length > 0 ? cRed25 : cGray50, 6.f);
            // dl.AddText(pos + vec2((width - titleBarSize.x) / 2., tbPadding.y), cWhite, nodeName, g_NormFont, 16.);
            UI::SetCursorPos(pos + startCur + vec2((width - titleBarSize.x) / 2., tbPadding.y));
            UI::Text(nodeName);
            return titleBarSize.y;
        }

        float UIDrawOutputs(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) {
            for (uint i = 0; i < outputs.Length; i++) {
                UI::PushID("out"+i);
                outputs[i].UIDraw(dl, startCur, startPos, pos + vec2(width, ioHeight * i + ioHeight / 2.));
                UI::PopID();
            }
            return ioHeight * outputs.Length;
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) {
            return 0;
        }

        float UIDrawInputs(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) {
            for (uint i = 0; i < inputs.Length; i++) {
                UI::PushID("in"+i);
                inputs[i].UIDraw(dl, startCur, startPos, pos + vec2(0, ioHeight * i + ioHeight / 2.));
                UI::PopID();
            }
            return ioHeight * inputs.Length;
        }
    }

    enum eMathOps {
        Add,
        Subtract,
        Multiply,
        Divide,
        Mod,
        Exp,
        Log,
        Max,
        Min,
        XXX_LAST
    }

    eMathOps MathOpCombo(const string &in label, eMathOps v) {
        // UI::ComboFlags::HeightSmall
        if (UI::BeginCombo(label, tostring(v))) {
            for (int i = 0; i < int(eMathOps::XXX_LAST); i++) {
                if (UI::Selectable(tostring(eMathOps(i)), i == int(v))) {
                    v = eMathOps(i);
                }
            }
            UI::EndCombo();
        }
        return v;
    }

    eMathFunc1 MathFuncCombo(const string &in label, eMathFunc1 v) {
        // UI::ComboFlags::HeightSmall
        if (UI::BeginCombo(label, tostring(v))) {
            for (int i = 0; i < int(eMathFunc1::XXX_LAST); i++) {
                if (UI::Selectable(tostring(eMathFunc1(i)), i == int(v))) {
                    v = eMathFunc1(i);
                }
            }
            UI::EndCombo();
        }
        return v;
    }

    eMathFunc2 MathFuncCombo(const string &in label, eMathFunc2 v) {
        if (UI::BeginCombo(label, tostring(v))) {
            for (int i = 0; i < int(eMathFunc2::XXX_LAST); i++) {
                if (UI::Selectable(tostring(eMathFunc2(i)), i == int(v))) {
                    v = eMathFunc2(i);
                }
            }
            UI::EndCombo();
        }
        return v;
    }

    eMathFunc3 MathFuncCombo(const string &in label, eMathFunc3 v) {
        if (UI::BeginCombo(label, tostring(v))) {
            for (int i = 0; i < int(eMathFunc3::XXX_LAST); i++) {
                if (UI::Selectable(tostring(eMathFunc3(i)), i == int(v))) {
                    v = eMathFunc3(i);
                }
            }
            UI::EndCombo();
        }
        return v;
    }

    // f(x) style functions -- DO NOT CHANGE ORDER
    enum eMathFunc1 {
        Sin,
        Cos,
        Tan,
        ASin,
        ACos,
        ATan,
        Sqrt,
        Exp,
        Ln,
        Log2,
        Log10,
        Abs,
        Floor,
        Ceil,
        Round,
        ToDeg,
        ToRad,
        XXX_LAST
    }

    // f(x,y) style functions -- DO NOT CHANGE ORDER
    enum eMathFunc2 {
        Atan2,
        Log,
        Min,
        Max,
        Pow,
        Round,
        XXX_LAST
    }

    // f(x,y,z) style functions -- DO NOT CHANGE ORDER
    enum eMathFunc3 {
        Clamp,
        InvLerp,
        Lerp,
        XXX_LAST
    }

    class MathOp : Node {
        eMathOps op = eMathOps::Add;

        MathOp() {
            super("Scalar Op");
            inputs = {FloatSocket(SocketType::Input, this, "a"), FloatSocket(SocketType::Input, this, "b")};
            outputs = {FloatSocket(SocketType::Output, this, "")};
        }

        Node@ FromJson(Json::Value@ j) override {
            op = eMathOps(int(j["op"]));
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "MathOp";
            j["op"] = int(op);
            return j;
        }

        void Update() override {
            outputs[0].SetName(GetOutputLabel());
            errorStr = "";
            try {
                switch (op) {
                    case eMathOps::Add: WriteFloat(0, GetFloat(0) + GetFloat(1)); break;
                    case eMathOps::Subtract: WriteFloat(0, GetFloat(0) - GetFloat(1)); break;
                    case eMathOps::Multiply: WriteFloat(0, GetFloat(0) * GetFloat(1)); break;
                    case eMathOps::Divide: WriteFloat(0, GetFloat(0) / GetFloat(1)); break;
                    case eMathOps::Mod: WriteFloat(0, GetFloat(0) % GetFloat(1)); break;
                    case eMathOps::Exp: WriteFloat(0, Math::Pow(GetFloat(0), GetFloat(1))); break;
                    case eMathOps::Log: WriteFloat(0, Math::Log(GetFloat(1)) / Math::Log(GetFloat(0))); break;
                    default: throw("Unknown math op: " + tostring(op));
                }
            } catch {
                errorStr = getExceptionInfo();
            }
        }

        string GetOutputLabel() {
            switch (op) {
                case eMathOps::Add: return "a + b";
                case eMathOps::Subtract: return "a - b";
                case eMathOps::Multiply: return "a * b";
                case eMathOps::Divide: return "a / b";
                case eMathOps::Mod: return "a % b";
                case eMathOps::Exp: return "a ^ b";
                case eMathOps::Log: return "log_a(b)";
            }
            return "???";
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto preOp = op;
            op = MathOpCombo("##op", op);
            if (op != preOp) Update();
            UI::PopID();
            return ioHeight;
        }
    }


    class MathFunc : Node {
        eMathFunc1 func = eMathFunc1::Sin;

        MathFunc() {
            super("Scalar Func");
            inputs = {FloatSocket(SocketType::Input, this, "a")};
            outputs = {FloatSocket(SocketType::Output, this, "")};
        }

        Node@ FromJson(Json::Value@ j) override {
            func = eMathFunc1(int(j["func"]));
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "MathFunc";
            j["func"] = int(func);
            return j;
        }

        void Update() override {
            outputs[0].SetName(GetOutputLabel());
            errorStr = "";
            try {
                if (IsInputArray(0)) {
                    Update_Array();
                    return;
                }
                switch (func) {
                    case eMathFunc1::Sin: WriteFloat(0, Math::Sin(GetFloat(0))); break;
                    case eMathFunc1::Cos: WriteFloat(0, Math::Cos(GetFloat(0))); break;
                    case eMathFunc1::Tan: WriteFloat(0, Math::Tan(GetFloat(0))); break;
                    case eMathFunc1::ASin: WriteFloat(0, Math::Asin(GetFloat(0))); break;
                    case eMathFunc1::ACos: WriteFloat(0, Math::Acos(GetFloat(0))); break;
                    // case eMathFunc::ATan: WriteFloat(0, Math::Atan(GetFloat(0))); break;
                    case eMathFunc1::ATan: WriteFloat(0, Math::Atan(GetFloat(0))); break;
                    case eMathFunc1::Sqrt: WriteFloat(0, Math::Sqrt(GetFloat(0))); break;
                    case eMathFunc1::Exp: WriteFloat(0, Math::Exp(GetFloat(0))); break;
                    case eMathFunc1::Ln: WriteFloat(0, Math::Log(GetFloat(0))); break;
                    case eMathFunc1::Log2: WriteFloat(0, Math::Log2(GetFloat(0))); break;
                    case eMathFunc1::Log10: WriteFloat(0, Math::Log10(GetFloat(0))); break;
                    case eMathFunc1::Abs: WriteFloat(0, Math::Abs(GetFloat(0))); break;
                    case eMathFunc1::Floor: WriteFloat(0, Math::Floor(GetFloat(0))); break;
                    case eMathFunc1::Ceil: WriteFloat(0, Math::Ceil(GetFloat(0))); break;
                    case eMathFunc1::Round: WriteFloat(0, Math::Round(GetFloat(0))); break;
                    case eMathFunc1::ToDeg: WriteFloat(0, Math::ToDeg(GetFloat(0))); break;
                    case eMathFunc1::ToRad: WriteFloat(0, Math::ToRad(GetFloat(0))); break;
                    default: throw("Unknown math func: " + tostring(func));
                }
            } catch {
                errorStr = getExceptionInfo();
            }
        }

        // keep an array here to avoid reallocating every frame
        float[] _outputValues;

        void Update_Array() {
            switch (func) {
                case eMathFunc1::Sin: WriteFloatArray(0, MathX::Sin(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Cos: WriteFloatArray(0, MathX::Cos(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Tan: WriteFloatArray(0, MathX::Tan(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::ASin: WriteFloatArray(0, MathX::Asin(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::ACos: WriteFloatArray(0, MathX::Acos(GetFloatArray(0), _outputValues)); break;
                // case eMathFunc::ATan: WriteFloatArray(0, MathX::Atan(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::ATan: WriteFloatArray(0, MathX::Atan(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Sqrt: WriteFloatArray(0, MathX::Sqrt(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Exp: WriteFloatArray(0, MathX::Exp(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Ln: WriteFloatArray(0, MathX::Ln(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Log2: WriteFloatArray(0, MathX::Log2(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Log10: WriteFloatArray(0, MathX::Log10(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Abs: WriteFloatArray(0, MathX::Abs(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Floor: WriteFloatArray(0, MathX::Floor(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Ceil: WriteFloatArray(0, MathX::Ceil(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::Round: WriteFloatArray(0, MathX::Round(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::ToDeg: WriteFloatArray(0, MathX::ToDeg(GetFloatArray(0), _outputValues)); break;
                case eMathFunc1::ToRad: WriteFloatArray(0, MathX::ToRad(GetFloatArray(0), _outputValues)); break;
                default: throw("Unknown math func: " + tostring(func));
            }
        }

        string GetOutputLabel() {
            switch (func) {
                case eMathFunc1::Sin: return "Sin(a)";
                case eMathFunc1::Cos: return "Cos(a)";
                case eMathFunc1::Tan: return "Tan(a)";
                case eMathFunc1::ASin: return "ASin(a)";
                case eMathFunc1::ACos: return "ACos(a)";
                case eMathFunc1::ATan: return "ATan(a)";
                case eMathFunc1::Sqrt: return "Sqrt(a)";
                case eMathFunc1::Exp: return "Exp(a)";
                case eMathFunc1::Ln: return "Ln(a)";
                case eMathFunc1::Log2: return "Log2(a)";
                case eMathFunc1::Log10: return "Log10(a)";
                case eMathFunc1::Abs: return "Abs(a)";
                case eMathFunc1::Floor: return "Floor(a)";
                case eMathFunc1::Ceil: return "Ceil(a)";
                case eMathFunc1::Round: return "Round(a)";
                case eMathFunc1::ToDeg: return "ToDeg(a)";
                case eMathFunc1::ToRad: return "ToRad(a)";
                default: throw("Unknown math func: " + tostring(func));
            }
            return "???";
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto preFunc = func;
            func = MathFuncCombo("##func", func);
            if (func != preFunc) Update();
            UI::PopID();
            return ioHeight;
        }
    }

    class MathFunc2 : Node {
        eMathFunc2 func = eMathFunc2::Atan2;

        MathFunc2() {
            super("Scalar Func2");
            inputs = {FloatSocket(SocketType::Input, this, "a"), FloatSocket(SocketType::Input, this, "b")};
            outputs = {FloatSocket(SocketType::Output, this, "")};
        }

        Node@ FromJson(Json::Value@ j) override {
            func = eMathFunc2(int(j["func"]));
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "MathFunc2";
            j["func"] = int(func);
            return j;
        }

        void Update() override {
            outputs[0].SetName(GetOutputLabel());
            errorStr = "";
            try {
                if (IsInputArray(0)) {
                    Update_Array();
                    return;
                }
                switch (func) {
                    case eMathFunc2::Atan2: WriteFloat(0, Math::Atan2(GetFloat(0), GetFloat(1))); break;
                    case eMathFunc2::Log: WriteFloat(0, Math::Log(GetFloat(0)) / Math::Log(GetFloat(1))); break;
                    case eMathFunc2::Min: WriteFloat(0, Math::Min(GetFloat(0), GetFloat(1))); break;
                    case eMathFunc2::Max: WriteFloat(0, Math::Max(GetFloat(0), GetFloat(1))); break;
                    case eMathFunc2::Pow: WriteFloat(0, Math::Pow(GetFloat(0), GetFloat(1))); break;
                    case eMathFunc2::Round: WriteFloat(0, Math::Round(GetFloat(0), GetFloat(1))); break;
                    default: throw("Unknown math func: " + tostring(func));
                }
            } catch {
                errorStr = getExceptionInfo();
            }
        }

        float[] _outputValues;

        void Update_Array() {
            switch (func) {
                case eMathFunc2::Atan2: WriteFloatArray(0, MathX::Atan2(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc2::Log: WriteFloatArray(0, MathX::Log(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc2::Min: WriteFloatArray(0, MathX::Min(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc2::Max: WriteFloatArray(0, MathX::Max(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc2::Pow: WriteFloatArray(0, MathX::Pow(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc2::Round: WriteFloatArray(0, MathX::Round(GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                default: throw("Unknown math func: " + tostring(func));
            }
        }

        string GetOutputLabel() {
            switch (func) {
                case eMathFunc2::Atan2: return "Atan2(a, b)";
                case eMathFunc2::Log: return "Log(a, base)";
                case eMathFunc2::Min: return "Min(a, b)";
                case eMathFunc2::Max: return "Max(a, b)";
                case eMathFunc2::Pow: return "Pow(a, p)";
                case eMathFunc2::Round: return "Round(a, dps)";
            }
            return "???";
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto preFunc = func;
            func = MathFuncCombo("##func", func);
            if (func != preFunc) Update();
            UI::PopID();
            return ioHeight;
        }
    }

    class MathFunc3 : Node {
        eMathFunc3 func = eMathFunc3::Clamp;

        MathFunc3() {
            super("Scalar Func3");
            inputs = {FloatSocket(SocketType::Input, this, "a"), FloatSocket(SocketType::Input, this, "b"), FloatSocket(SocketType::Input, this, "c")};
            outputs = {FloatSocket(SocketType::Output, this, "")};
        }

        Node@ FromJson(Json::Value@ j) override {
            func = eMathFunc3(int(j["func"]));
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "MathFunc3";
            j["func"] = int(func);
            return j;
        }

        void Update() override {
            outputs[0].SetName(GetOutputLabel());
            errorStr = "";
            try {
                if (IsInputArray(0)) {
                    Update_Array();
                    return;
                }
                switch (func) {
                    // clamp arg order on node matches lerp
                    case eMathFunc3::Clamp: WriteFloat(0, Math::Clamp(GetFloat(2), GetFloat(0), GetFloat(1))); break;
                    case eMathFunc3::InvLerp: WriteFloat(0, Math::InvLerp(GetFloat(0), GetFloat(1), GetFloat(2))); break;
                    case eMathFunc3::Lerp: WriteFloat(0, Math::Lerp(GetFloat(0), GetFloat(1), GetFloat(2))); break;
                    default: throw("Unknown math func: " + tostring(func));
                }
            } catch {
                errorStr = getExceptionInfo();
            }
        }

        float[] _outputValues;

        void Update_Array() {
            switch (func) {
                // clamp arg order on node matches lerp
                case eMathFunc3::Clamp: WriteFloatArray(0, MathX::Clamp(GetFloatArray(2), GetFloatArray(0), GetFloatArray(1), _outputValues)); break;
                case eMathFunc3::InvLerp: WriteFloatArray(0, MathX::InvLerp(GetFloatArray(0), GetFloatArray(1), GetFloatArray(2), _outputValues)); break;
                case eMathFunc3::Lerp: WriteFloatArray(0, MathX::Lerp(GetFloatArray(0), GetFloatArray(1), GetFloatArray(2), _outputValues)); break;
                default: throw("Unknown math func: " + tostring(func));
            }
        }

        string GetOutputLabel() {
            switch (func) {
                case eMathFunc3::Clamp: return "Clamp(min, max, x)";
                case eMathFunc3::InvLerp: return "InvLerp(min, max, v)";
                case eMathFunc3::Lerp: return "Lerp(min, max, t)";
            }
            return "???";
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto preFunc = func;
            func = MathFuncCombo("##func", func);
            if (func != preFunc) Update();
            UI::PopID();
            return ioHeight;
        }
    }


    class IntValue : Node {
        int64 value;

        IntValue() {
            super("Int");
            outputs = {IntSocket(SocketType::Output, this, "v")};
        }

        Node@ FromJson(Json::Value@ j) override {
            value = int64(j["v"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "IntValue";
            j["v"] = value;
            return j;
        }

        void Update() override {
            WriteInt(0, value);
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto priorVal = value;
            value = UI::InputInt("##value", value);
            if (value != priorVal) Update();
            UI::PopID();
            return ioHeight;
        }
    }

    class FloatValue : Node {
        double value;

        FloatValue() {
            super("Float");
            outputs = {FloatSocket(SocketType::Output, this, "v")};
        }

        Node@ FromJson(Json::Value@ j) override {
            value = double(j["v"]);
            Node::FromJson(j);
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j["type"] = "FloatValue";
            j["v"] = value;
            return j;
        }

        void Update() override {
            WriteFloat(0, value);
        }

        vec2 GetParamsSize() override {
            return vec2(80., ioHeight);
        }

        float preDrag;
        bool wasDragging = false;

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8., 0.));
            UI::SetNextItemWidth(width - 16.);
            auto postVal = value;
            postVal = UI::InputFloat("##v"+id, postVal, 0.1f);
            if (value != postVal && (UI::IsItemClicked() || UI::IsItemFocused()) && !wasDragging) {
                preDrag = postVal;
                value = postVal;
                Update();
            } else if ((UI::IsItemFocused() && UI::IsMouseDown()) || wasDragging) {
                if (UI::IsMouseDown(UI::MouseButton::Left)) {
                    auto delta = UI::GetMouseDragDelta(UI::MouseButton::Left, 12.f);
                    if (delta.x != 0) {
                        value = preDrag + delta.x / 10.;
                        Update();
                        wasDragging = true;
                    }
                } else {
                    wasDragging = false;
                }
            } else {
                wasDragging = false;
            }
            UI::PopID();
            return ioHeight;
        }
    }

    class TimeValue : Node {
        TimeValue() {
            super("Time");
            outputs = {IntSocket(SocketType::Output, this, "t")};
        }

        Node@ FromJson(Json::Value@ j) override {
            Node::FromJson(j);
            return this;
        }

        void Update() override {
            WriteInt(0, Time::Now);
        }

        vec2 GetParamsSize() override {
            return vec2(80., 0.);
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 mousePos) override {
            Update();
            Node::UIDraw(dl, startCur, startPos, mousePos);
        }

        Json::Value@ ToJson() override {
            trace('time val to json start');
            Json::Value@ j = Node::ToJson();
            trace('time val to json mid');
            j["type"] = "TimeValue";
            trace('time val to json done');
            return j;
        }
    }


    Node@ NodeFromJson(Json::Value@ j) {
        print("NodeFromJson: " + Json::Write(j));
        string type = j["type"];
        Node@ node;
        if (type == "MathOp") {
            @node = MathOp().FromJson(j);
        } else if (type == "MathFunc") {
            @node = MathFunc().FromJson(j);
        } else if (type == "MathFunc2") {
            @node = MathFunc2().FromJson(j);
        } else if (type == "MathFunc3") {
            @node = MathFunc3().FromJson(j);
        } else if (type == "IntValue") {
            @node = IntValue().FromJson(j);
        } else if (type == "FloatValue") {
            @node = FloatValue().FromJson(j);
        } else if (type == "TimeValue") {
            @node = TimeValue().FromJson(j);
        } else if (type == "PlotNode" || type == "PlotOverTimeNode") {
            @node = PlotVsTimeNode().FromJson(j);
        } else if (type == "JsonParseObj") {
            @node = JsonParseObj().FromJson(j);
        } else if (type == "StringValue") {
            @node = StringValue().FromJson(j);
        } else if (type == "JsonGetKey") {
            @node = JsonGetKey().FromJson(j);
        } else if (type == "Vec2Value") {
            @node = Vec2Value().FromJson(j);
        } else if (type == "Vec3Value") {
            @node = Vec3Value().FromJson(j);
        } else if (type == "Vec4Value") {
            @node = Vec4Value().FromJson(j);
        // } else if (type == "Mat3Value") {
        //     @node = Mat3Value().FromJson(j);
        // } else if (type == "Mat4Value") {
        //     @node = Mat4Value().FromJson(j);
        } else if (type == "NodFromFileNode") {
            @node = NodFromFileNode().FromJson(j);
        } else if (type == "NodPtrNode") {
            @node = NodPtrNode().FromJson(j);
        } else {
            warn("Unknown node type: " + type);
        }
        return node;
    }
}


Json::Value@ Vec3ToJson(vec3 v) {
    Json::Value@ j = Json::Array();
    j.Add(v.x);
    j.Add(v.y);
    j.Add(v.z);
    return j;
}

vec3 Vec3FromJson(Json::Value@ j) {
    return vec3(float(j[0]), float(j[1]), float(j[2]));
}

Json::Value@ Vec2ToJson(vec2 v) {
    Json::Value@ j = Json::Array();
    j.Add(v.x);
    j.Add(v.y);
    return j;
}

vec2 Vec2FromJson(Json::Value@ j) {
    return vec2(float(j[0]), float(j[1]));
}
