namespace NG {
    enum PlotNodeXTy {
        Frames = 1, Index = 2 // Time = 3,
    }
    class PlotNode : Node {
        vec2 axisScale = vec2(-1);
        vec2 bl = vec2(0.0);
        protected vec2 pxSize = vec2(180.0, 150.);
        PlotNodeXTy xType = PlotNodeXTy::Frames;
        float[] values;
        int valuesUnique = 180;
        int valuesCapacity = 180;
        int nextIx = 0;

        PlotNode() {
            super("Plot");
            inputs = {FloatSocket(SocketType::Input, this, "y")};
            ResetValues();
        }

        void ResetValues() {
            values.Reserve(valuesCapacity);
            for (int i = values.Length; i < valuesCapacity; i++) {
                values.InsertLast(0.0);
            }
        }

        void SetPxSize(vec2 sz) {
            pxSize = sz;
            valuesUnique = int(sz.x);
            valuesCapacity = int(sz.x);
            ResetValues();
        }

        float v;
        void Update() override {
            v = GetFloat(0);
            values[nextIx] = v;
            // values[nextIx + valuesUnique] = v;
            nextIx = (nextIx + valuesUnique + 1) % valuesUnique;
        }

        vec2 GetParamsSize() override {
            return pxSize + vec2(0., 8.);
        }

        void UIDraw(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 mousePos) override {
            Node::UIDraw(dl, startCur, startPos, mousePos);
        }

        float UIDrawParams(UI::DrawList@ dl, vec2 startCur, vec2 startPos, vec2 pos, float width) override {
            UI::PushID(id);
            UI::SetCursorPos(startCur + pos + vec2(8.0, 4.));
            UI::SetNextItemWidth(pxSize.x);// / UI::GetScale());
            UI::PlotLines(id, values, nextIx, pxSize.y);
            UI::PopID();
            return pxSize.y;
        }

        void UIDrawRightClickMenuBeforeStd() override {
            UI::Text("X Axis Type");
            UI::Indent();
            // if (UI::RadioButton("Time", xType == PlotNodeXTy::Time)) xType = PlotNodeXTy::Time;
            if (UI::RadioButton("Frames", xType == PlotNodeXTy::Frames)) xType = PlotNodeXTy::Frames;
            if (UI::RadioButton("Field Index", xType == PlotNodeXTy::Index)) xType = PlotNodeXTy::Index;
            UI::Unindent();
        }

        Node@ FromJson(Json::Value@ j) override {
            Node::FromJson(j);
            axisScale.x = j['scale.x'];
            axisScale.y = j['scale.y'];
            bl.x = j['bl.x'];
            bl.y = j['bl.y'];
            pxSize.x = j['px.x'];
            pxSize.y = j['px.y'];
            xType = PlotNodeXTy(int(j['xType']));
            return this;
        }

        Json::Value@ ToJson() override {
            Json::Value@ j = Node::ToJson();
            j['type'] = "PlotNode";
            j['scale.x'] = axisScale.x;
            j['scale.y'] = axisScale.y;
            j['bl.x'] = bl.x;
            j['bl.y'] = bl.y;
            j['px.x'] = pxSize.x;
            j['px.y'] = pxSize.y;
            j['xType'] = int(xType);
            return j;
        }

    }
}
