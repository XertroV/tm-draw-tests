namespace NG {
    vec2 nodeGraphMousePos;
    vec2 rClickPos;

    class GraphTab : EffectTab {
        GraphTab(TabGroup@ p) {
            super(p, "Node Graph", Icons::Cube + Icons::SignIn + Icons::Sitemap + Icons::SignOut + Icons::Cubes);
            startnew(CoroutineFunc(LoadGraph));
            startnew(CoroutineFunc(WatchForSaveSoon));
        }


        void AddSampleGraph() {
            AddNode(TimeValue());
            AddNode(FloatValue());
            AddNode(MathOp());
            AddNode(MathFunc());

            AddEdge(Noodle(nodes[0].outputs[0], nodes[2].inputs[0]));
            AddEdge(Noodle(nodes[1].outputs[0], nodes[2].inputs[1]));
            AddEdge(Noodle(nodes[2].outputs[0], nodes[3].inputs[0]));

            nodes[0].pos = vec2(20, 100);
            nodes[1].pos = vec2(20, 300);
            cast<FloatValue>(nodes[1]).value = 1000. / PI;
            nodes[2].pos = vec2(220, 200);
            cast<MathOp>(nodes[2]).op = eMathOps::Divide;
            nodes[3].pos = vec2(420, 200);
            cast<MathFunc>(nodes[3]).func = eMathFunc1::Sin;
        }


        Node@[] nodes;
        Noodle@[] edges;
        Noodle@ tmpNoodle;

        void StartNoodle(Socket@ half) {
            if (half.IsInput) {
                @tmpNoodle = Noodle(null, half);
            } else {
                @tmpNoodle = Noodle(half, null);
            }
        }

        void RemoveNode(Node@ n) {
            for (uint i = 0; i < nodes.Length; i++) {
                if (nodes[i] is n) {
                    // nodes[i].Delete();
                    nodes.RemoveAt(i);
                    break;
                }
            }
            for (int i = 0; 0 <= i && i < edges.Length; i++) {
                if (edges[i].FromNode is n || edges[i].ToNode is n) {
                    edges[i].Disconnect();
                    edges.RemoveAt(i);
                    i--;
                }
            }
        }

        void SetTmpNoodle(Noodle@ n) {
            @tmpNoodle = n;
            for (uint i = 0; i < edges.Length; i++) {
                if (edges[i] is n) {
                    edges.RemoveAt(i);
                    break;
                }
            }
        }

        void RemoveEdge(Noodle@ e) {
            bool removed = false;
            trace('removing edge (len: ' + edges.Length + ')');
            for (uint i = 0; i < edges.Length; i++) {
                if (edges[i] is e) {
                    edges.RemoveAt(i);
                    removed = true;
                    break;
                }
            }
            if (removed) e.Disconnect();
            trace('removed edge (len: ' + edges.Length + ')');
        }

        uint saveSoonReqAt = 0;

        void WatchForSaveSoon() {
            while (true) {
                yield();
                if (saveSoonReqAt > 0 && Time::Now > saveSoonReqAt + 500) {
                    SaveGraph();
                    saveSoonReqAt = 0;
                }
            }
        }

        // isNew when creating, false when loading from file
        void AddNode(Node@ n, bool isNew = true) {
            nodes.InsertLast(n);
            @n.graph = this;
            if (isNew) {
                n.pos = rClickPos;
                saveSoonReqAt = Time::Now;
            }
        }

        void AddEdge(Noodle@ e) {
            edges.InsertLast(e);
            saveSoonReqAt = Time::Now;
        }


        void SaveGraph() {
            Json::Value@ j = Json::Object();
            j['nodes'] = Json::Array();
            j['edges'] = Json::Array();
            for (uint i = 0; i < nodes.Length; i++) {
                j['nodes'].Add(nodes[i].ToJson());
            }
            string fname = IO::FromStorageFolder("graph.json");
            Json::ToFile(fname, j);
            trace("Saved graph to " + fname);
        }

        bool HasEdge(Json::Value@ lookup, const string &in key) {
            return lookup.HasKey(key);
        }

        void AddEdgeToLookup(Json::Value@ lookup, const string &in key, uint node, uint ix, bool isInput) {
            auto v = Json::Object();
            v['node'] = node;
            if (isInput) {
                v['sock_in'] = ix;
            } else {
                v['sock_out'] = ix;
            }
            lookup[key] = v;
        }

        void ConnectEdgeFromLookup(Json::Value@ lookup, const string &in key, Node@ n, uint ix, bool isInput) {
            if (lookup.HasKey(key)) {
                auto v = lookup[key];
                print('Nodes len: ' + nodes.Length + ' / connect ix: ' + int(v['node']));
                auto node = nodes[int(v['node'])];
                if (isInput) {
                    auto input = n.inputs[ix];
                    AddEdge(Noodle(node.outputs[int(v['sock_out'])], input));
                } else {
                    auto output = n.outputs[ix];
                    AddEdge(Noodle(output, node.inputs[int(v['sock_in'])]));
                }
                lookup.Remove(key);
            }
        }

        void LoadGraph() {
            auto fname = IO::FromStorageFolder("graph.json");
            if (!IO::FileExists(fname)) {
                AddSampleGraph();
                return;
            }
                LoadGraphFromFile(fname);
            try {
            } catch {
                warn("Exception loading graph from file! " + getExceptionInfo());
                AddSampleGraph();
            }
        }

        void LoadGraphFromFile(const string &in fname) {
            Json::Value@ j = Json::FromFile(fname);
            print("Loading graph: " + Json::Write(j));
            Json::Value@ edgesLookup = Json::Object();
            Json::Value@ jn;
            Json::Value@ jne;
            if (j !is null) {
                nodes.Resize(0);
                edges.Resize(0);
                for (uint i = 0; i < j['nodes'].Length; i++) {
                    @jn = j['nodes'][i];
                    Node@ n = NodeFromJson(jn);
                    AddNode(n, false);
                    for (uint x = 0; x < jn['inputs'].Length; x++) {
                        @jne = jn['inputs'][x];
                        for (uint y = 0; y < jne.Length; y++) {
                            if (HasEdge(edgesLookup, string(jne[y]))) {
                                ConnectEdgeFromLookup(edgesLookup, string(jne[y]), n, x, true);
                            } else {
                                AddEdgeToLookup(edgesLookup, string(jne[y]), i, x, true);
                            }
                        }
                    }
                    for (uint x = 0; x < jn['outputs'].Length; x++) {
                        @jne = jn['outputs'][x];
                        for (uint y = 0; y < jne.Length; y++) {
                            if (HasEdge(edgesLookup, string(jne[y]))) {
                                ConnectEdgeFromLookup(edgesLookup, string(jne[y]), n, x, false);
                            } else {
                                AddEdgeToLookup(edgesLookup, string(jne[y]), i, x, false);
                            }
                        }
                    }
                }
            }
        }

        bool nodeCtxMenuOpen = false;

        void DrawInner() override {
            nodeCtxMenuOpen = false;
            if (UI::BeginChild(idNonce, vec2(), UI::ChildFlags::None, UI::WindowFlags::None)) {
                if (UI::Button("Save")) {
                    startnew(CoroutineFunc(SaveGraph));
                }
                DrawGraphInChild();
            }
            UI::EndChild();
            if (!nodeCtxMenuOpen) DrawRightClickMenu();
        }

        void DrawRightClickMenu() {
            if (UI::IsMouseClicked(UI::MouseButton::Right)) {
                rClickPos = nodeGraphMousePos;
            }
            if (UI::BeginPopupContextItem(idNonce + "rc")) {
                if (UI::BeginMenu("Add Value")) {
                    if (UI::MenuItem("Int")) {
                        AddNode(IntValue());
                    }
                    if (UI::MenuItem("Float")) {
                        AddNode(FloatValue());
                    }
                    if (UI::MenuItem("Time")) {
                        AddNode(TimeValue());
                    }
                    if (UI::MenuItem("String")) {
                        AddNode(StringValue());
                    }
                    if (UI::MenuItem("Vec2")) {
                        AddNode(Vec2Value());
                    }
                    if (UI::MenuItem("Vec3")) {
                        AddNode(Vec3Value());
                    }
                    if (UI::MenuItem("Vec4")) {
                        AddNode(Vec4Value());
                    }
                    // if (UI::MenuItem("Mat3")) {
                    //     AddNode(Mat3Value());
                    // }
                    // if (UI::MenuItem("Mat4")) {
                    //     AddNode(Mat4Value());
                    // }
                    UI::EndMenu();
                }
                if (UI::BeginMenu("Add Math")) {
                    if (UI::MenuItem("Scalar Op2")) {
                        AddNode(MathOp());
                    }
                    AddIndentedTooltip("Operations with 2 numbers.\nExamples: a - b, a * b, a ^ b, log(a, b), min(a, b), etc.", w: 20.0);

                    if (UI::MenuItem("Scalar Func (1)")) {
                        AddNode(MathFunc());
                    }
                    AddIndentedTooltip("Functions with 1 argument.\nExamples: sin(a), acos(a), sqrt(a), ln(a), round(a), toDeg(a), etc.", w: 20.0);

                    if (UI::MenuItem("Scalar Func (2)")) {
                        AddNode(MathFunc2());
                    }
                    AddIndentedTooltip("Functions with 2 arguments.\nExamples: atan2(a, b), pow(a, b), etc.", w: 20.0);

                    if (UI::MenuItem("Scalar Func (3)")) {
                        AddNode(MathFunc3());
                    }
                    AddIndentedTooltip("Functions with 3 arguments.\nExamples: clamp(x, min, max), lerp(min, max, t), etc.", w: 20.0);

                    UI::EndMenu();
                }
                if (UI::BeginMenu("Add Visualizer")) {
                    if (UI::MenuItem("Plot vs Time")) {
                        AddNode(PlotVsTimeNode());
                    }
                    UI::EndMenu();
                }
                if (UI::BeginMenu("Add Json")) {
                    if (UI::MenuItem("Json::Parse")) {
                        AddNode(JsonParseObj());
                    }
                    if (UI::MenuItem("Get Key")) {
                        AddNode(JsonGetKey());
                    }
                    UI::EndMenu();
                }
                if (UI::BeginMenu("Add Nod Node")) {
                    if (UI::MenuItem("Nod From File")) {
                        AddNode(NodFromFileNode());
                    }
                    if (UI::MenuItem("Nod Ptr")) {
                        AddNode(NodPtrNode());
                    }
                    if (UI::BeginMenu("Get Property")) {
                        if (UI::MenuItem("Nod")) {
                            AddNode(GetPropertyNod());
                        }
                        UI::EndMenu();
                    }
                    UI::EndMenu();
                }
                UI::EndPopup();
            }
        }

        void DrawGraphInChild() {
            UI::PushStyleVar(UI::StyleVar::FramePadding, vec2());
            auto dl = UI::GetWindowDrawList();
            vec2 startCur = UI::GetCursorPos();
            vec2 winPos = UI::GetWindowPos();
            vec2 startPos = winPos + startCur;
            auto mousePos = UI::GetMousePos() - startPos;
            nodeGraphMousePos = mousePos;
            // startCur += vec2(UI::GetStyleVarFloat(UI::StyleVar::IndentSpacing), 0);
            for (uint i = 0; i < nodes.Length; i++) {
                UI::PushID("node"+i);
                nodes[i].UIDraw(dl, startCur, startPos, mousePos);
                UI::PopID();
            }
            for (uint i = 0; i < edges.Length; i++) {
                UI::PushID("edge"+i);
                edges[i].UIDraw(dl, startCur, startPos, mousePos);
                UI::PopID();
            }
            if (tmpNoodle !is null) {
                UI::PushID("tmpNoodle");
                tmpNoodle.UIDraw(dl, startCur, startPos, mousePos);
                UI::PopID();
                if (!UI::IsMouseDown(UI::MouseButton::Left)) {
                    trace('edges.Length: ' + edges.Length);
                    for (uint i = 0; i < nodes.Length; i++) {
                        if (nodes[i].isHovered) {
                            tmpNoodle.TryConnect(nodes[i], mousePos);
                            if (tmpNoodle.IsConnected) {
                                trace("Connected!");
                                edges.InsertLast(tmpNoodle);
                            } else {
                                trace("Failed to connect! isNull? from: " + (tmpNoodle.FromNode is null) + " / to: " + (tmpNoodle.ToNode is null));
                            }
                            break;
                        }
                    }
                    if (!tmpNoodle.IsConnected) {
                        trace("Disconnected!");
                        tmpNoodle.Disconnect();
                    }
                    trace('edges.Length: ' + edges.Length);
                    @tmpNoodle = null;
                }
            }

            // dl.AddCircleFilled(startPos + vec2(000), 10, cRed, 12);
            // dl.AddCircleFilled(startPos + vec2(050), 10, cRed, 12);
            // dl.AddCircleFilled(startPos + vec2(100), 10, cGreen, 12);
            // dl.AddCircleFilled(startPos + vec2(150), 10, cGreen, 12);
            // dl.AddCircleFilled(startPos + vec2(200), 10, cLimeGreen, 12);
            // dl.AddCircleFilled(startPos + vec2(250), 10, cLimeGreen, 12);
            // dl.AddCircleFilled(startPos + vec2(300), 10, cRed, 12);
            // UI::SetCursorPos(startCur + vec2(0));
            // UI::Text("c0");
            // UI::SetCursorPos(startCur + vec2(50));
            // UI::Text("c1");
            // UI::SetCursorPos(startCur + vec2(100));
            // UI::Text("c2");
            // UI::SetCursorPos(startCur + vec2(150));
            // UI::Text("c3");
            // UI::SetCursorPos(startCur + vec2(200));
            // UI::Text("c4");
            // UI::SetCursorPos(startCur + vec2(250));
            // UI::Text("c5");
            // UI::SetCursorPos(startCur + vec2(300));
            // UI::Text("c6");

            UI::PopStyleVar();
        }
    }
}
