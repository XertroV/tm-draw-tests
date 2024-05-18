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
        String
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

        void Connect(Noodle@ edge) {
            if (!allowMultipleEdges && edges.Length > 0) {
                if (edges[0] !is edge) {
                    trace('Connect is disconnecting prior edge: ' + edges[0].id);
                    startnew(CoroutineFunc(edges[0].Disconnect));
                    @edges[0] = edge;
                }
            } else {
                edges.InsertLast(edge);
            }
            if (IsInput && edge.from !is null) {
                WriteFromSocket(edge.from);
            } else if (edge.to !is null) {
                edge.to.WriteFromSocket(this);
            }
        }

        void SignalUpdated() {
            for (uint i = 0; i < edges.Length; i++) {
                edges[i].WriteOutFrom(this);
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
                warn("Socket.WriteFromSocket: socket is null");
            }
            switch (dataTy) {
                case DataTypes::Int: WriteInt(socket.GetInt()); break;
                case DataTypes::Bool: WriteBool(socket.GetBool()); break;
                case DataTypes::Float: WriteFloat(socket.GetFloat()); break;
                case DataTypes::String: WriteString(socket.GetString()); break;
                default: warn("unknown data type: " + tostring(dataTy));
            }
        }

        string GetValueString() {
            switch (dataTy) {
                case DataTypes::Int: return tostring(GetInt());
                case DataTypes::Bool: return GetBool() ? "true" : "false";
                case DataTypes::Float: return Text::Format("%.3f", GetFloat());
                case DataTypes::String: return GetString();
                default: warn("unknown data type: " + tostring(dataTy));
            }
            return "?";
        }

        int64 GetInt() { return 0; }
        void WriteInt(int64 value) {}
        bool GetBool() { return false; }
        void WriteBool(bool value) {}
        double GetFloat() { return 0; }
        void WriteFloat(double value) {}
        string GetString() { return ""; }
        void WriteString(const string &in value) {}

        vec2 textSize;

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos) {
            this.pos = pos;
            vec2 size = vec2(10.);
            // pos -= size / 2.;
            UI::SetCursorPos(startCur + pos - size / 2.);
            UI::InvisibleButton(id, size);
            bool clicked = UI::IsItemClicked();
            dl.AddCircleFilled(startPos + pos, size.x / 2., cWhite, 12);
            bool alignRight = IsOutput;
            string label;
            label = name + " = " + GetValueString();
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
        int64 _default;

        IntSocket(SocketType ty, Node@ parent, const string &in name = "", int64 _default = 0) {
            super(ty, parent, DataTypes::Int);
            this._default = _default;
            SetName(name);
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
            if (IsInput && node !is null) {
                node.SignalInputsUpdated();
            }
        }

        void WriteFloat(double value) override {
            WriteInt(int(value));
        }

        void WriteBool(bool value) override {
            WriteInt(value ? 1 : 0);
        }
    }

    class FloatSocket : Socket {
        double value;
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
            if (IsInput && node !is null) {
                node.SignalInputsUpdated();
            }
        }
    }

    bool IsCompatFromTo(Socket@ from, Socket@ to) {
        if (from.dataTy == to.dataTy) return true;
        if (from.dataTy == DataTypes::Int && to.dataTy == DataTypes::Float) return true;
        if (from.dataTy == DataTypes::Float && to.dataTy == DataTypes::Int) return true;
        return false;
    }

    class Noodle {
        string id;
        Socket@ from;
        Socket@ to;
        string error;

        Noodle(Socket@ from, Socket@ to) {
            if (from !is null && to !is null && IsCompatFromTo(from, to)) {
                error = "Data types do not match: " + from.dataTy + " != " + to.dataTy;
            }
            @this.from = from;
            @this.to = to;
            if (from !is null) from.Connect(this);
            if (to !is null) to.Connect(this);
            id = "##" + Math::Rand(-1000000000, 1000000000);
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
                    from.Connect(this);
                } else if (to is null && sock.IsInput) {
                    trace('connecting to');
                    @to = sock;
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
            if (to !is null) {
                to.WriteFromSocket(socket);
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
            dl.AddLine(startPos + FromPos, startPos + ToPos, cLimeGreen, 3.f);
            if (DRAW_DEBUG) {
                UI::SetCursorPos(startCur + vec2(FromPos + ToPos) / 2. - vec2(0, 16.) - Draw::MeasureString(id, g_NormFont, 16.) / 2.);
                UI::Text(id);
            }
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

        int GetInt(int index) {
            // Read the value from the input
            if (index < inputs.Length && inputs[index] !is null) {
                return inputs[index].GetInt();
            }
            return 0;
        }

        void WriteInt(int index, int value) {
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
                if (UI::MenuItem("Delete")) {
                    Delete();
                }
                UI::EndPopup();
            }
        }

        vec2 GetParamsSize() {
            return vec2(0, 0);
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

    eMathFunc MathFuncCombo(const string &in label, eMathFunc v) {
        // UI::ComboFlags::HeightSmall
        if (UI::BeginCombo(label, tostring(v))) {
            for (int i = 0; i < int(eMathFunc::XXX_LAST); i++) {
                if (UI::Selectable(tostring(eMathFunc(i)), i == int(v))) {
                    v = eMathFunc(i);
                }
            }
            UI::EndCombo();
        }
        return v;
    }

    enum eMathFunc {
        Sin,
        Cos,
        Tan,
        ASin,
        ACos,
        ATan,
        Sqrt,
        Abs,
        Floor,
        Ceil,
        Round,
        ToDeg,
        ToRad,
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
            Node::FromJson(j);
            op = eMathOps(int(j["op"]));
            print("MathOp::FromJson: " + op + " pos: " + pos.ToString());;
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
                    default: warn("Unknown math op: " + tostring(op));
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
                case eMathOps::Log: return "lg_a(b)";
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
        eMathFunc func = eMathFunc::Sin;

        MathFunc() {
            super("Scalar Func");
            inputs = {FloatSocket(SocketType::Input, this, "a")};
            outputs = {FloatSocket(SocketType::Output, this, "")};
        }

        Node@ FromJson(Json::Value@ j) override {
            Node::FromJson(j);
            func = eMathFunc(int(j["func"]));
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
                switch (func) {
                    case eMathFunc::Sin: WriteFloat(0, Math::Sin(GetFloat(0))); break;
                    case eMathFunc::Cos: WriteFloat(0, Math::Cos(GetFloat(0))); break;
                    case eMathFunc::Tan: WriteFloat(0, Math::Tan(GetFloat(0))); break;
                    case eMathFunc::ASin: WriteFloat(0, Math::Asin(GetFloat(0))); break;
                    case eMathFunc::ACos: WriteFloat(0, Math::Acos(GetFloat(0))); break;
                    // case eMathFunc::ATan: WriteFloat(0, Math::Atan(GetFloat(0))); break;
                    case eMathFunc::ATan: WriteFloat(0, Math::Atan(GetFloat(0))); break;
                    case eMathFunc::Sqrt: WriteFloat(0, Math::Sqrt(GetFloat(0))); break;
                    case eMathFunc::Abs: WriteFloat(0, Math::Abs(GetFloat(0))); break;
                    case eMathFunc::Floor: WriteFloat(0, Math::Floor(GetFloat(0))); break;
                    case eMathFunc::Ceil: WriteFloat(0, Math::Ceil(GetFloat(0))); break;
                    case eMathFunc::Round: WriteFloat(0, Math::Round(GetFloat(0))); break;
                    case eMathFunc::ToDeg: WriteFloat(0, Math::ToDeg(GetFloat(0))); break;
                    case eMathFunc::ToRad: WriteFloat(0, Math::ToRad(GetFloat(0))); break;
                    default: warn("Unknown math func: " + tostring(func));
                }
            } catch {
                errorStr = getExceptionInfo();
            }
        }

        string GetOutputLabel() {
            switch (func) {
                case eMathFunc::Sin: return "Sin(a)";
                case eMathFunc::Cos: return "Cos(a)";
                case eMathFunc::Tan: return "Tan(a)";
                case eMathFunc::ASin: return "ASin(a)";
                case eMathFunc::ACos: return "ACos(a)";
                case eMathFunc::ATan: return "ATan(a)";
                case eMathFunc::Sqrt: return "Sqrt(a)";
                case eMathFunc::Abs: return "Abs(a)";
                case eMathFunc::Floor: return "Floor(a)";
                case eMathFunc::Ceil: return "Ceil(a)";
                case eMathFunc::Round: return "Round(a)";
                case eMathFunc::ToDeg: return "ToDeg(a)";
                case eMathFunc::ToRad: return "ToRad(a)";
                default: warn("Unknown math func: " + tostring(func));
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
        int value;

        IntValue() {
            super("Int");
            outputs = {IntSocket(SocketType::Output, this, "v")};
        }

        Node@ FromJson(Json::Value@ j) override {
            Node::FromJson(j);
            value = int(j["v"]);
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
            Node::FromJson(j);
            value = double(j["v"]);
            Update();
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
            Json::Value@ j = Node::ToJson();
            j["type"] = "TimeValue";
            return j;
        }
    }


    Node@ NodeFromJson(Json::Value@ j) {
        string type = j["type"];
        Node@ node;
        if (type == "MathOp") {
            @node = MathOp().FromJson(j);
        } else if (type == "MathFunc") {
            @node = MathFunc().FromJson(j);
        } else if (type == "IntValue") {
            @node = IntValue().FromJson(j);
        } else if (type == "FloatValue") {
            @node = FloatValue().FromJson(j);
        } else if (type == "TimeValue") {
            @node = TimeValue().FromJson(j);
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
