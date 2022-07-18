[Setting category="General" name="Enabled"]
bool enabled = true;

vec2 ButtonSize;
vec2 ButtonPosition;

bool execute = false;

UI::Texture@ ButtonInactive;
UI::Texture@ ButtonActive;

bool CurrentlyInMap;
bool CurrentlyHoveringButton;

void Main() {
    @ButtonInactive = UI::LoadTexture("assets/RefreshLB_inactive.png");
    @ButtonActive = UI::LoadTexture("assets/RefreshLB_active.png");
    while(true) {
        if(Permissions::ViewRecords() && enabled && execute) {
            auto app = cast<CTrackMania>(GetApp());
            if(app !is null) {
                app.UserManagerScript.Users[0].Config.Interface_AlwaysDisplayRecords = !app.UserManagerScript.Users[0].Config.Interface_AlwaysDisplayRecords;
                sleep(1);
                app.UserManagerScript.Users[0].Config.Interface_AlwaysDisplayRecords = !app.UserManagerScript.Users[0].Config.Interface_AlwaysDisplayRecords;
                execute = false;
                trace(Icons::Refresh + " Refreshed Leaderboard");
            }
        }
        yield();
    }
}

void Update(float dt) {
	if (GetApp().CurrentPlayground !is null && GetApp().RootMap !is null) {
        CurrentlyInMap = true;
	} else {
		CurrentlyInMap = false;
	}
}

void Render() {
    if(!Permissions::ViewRecords() || !enabled) return;
	auto app = cast<CTrackMania>(GetApp());
    if(isLBvisible() && app !is null && CurrentlyInMap != false && app.RootMap !is null && app.CurrentPlayground !is null && app.Editor is null) {
        if(!UI::IsGameUIVisible()) return;
        auto windowFlags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking | UI::WindowFlags::NoResize | UI::WindowFlags::NoTitleBar;

        float height = Draw::GetHeight();
        ButtonSize = vec2(height / 22.5, height / 22.5);
        ButtonPosition = vec2(height / 20, 0.333 * height);

        UI::DrawList@ DrawList = UI::GetBackgroundDrawList();
        if(CurrentlyHoveringButton) {
            DrawList.AddImage(ButtonActive, ButtonPosition, ButtonSize);
        } else {
            DrawList.AddImage(ButtonInactive, ButtonPosition, ButtonSize);
        }
    }
}

void OnMouseMove(int x, int y) {
    if(!Permissions::ViewRecords() || !enabled) return;
	CurrentlyHoveringButton = (x > ButtonPosition.x && x < ButtonPosition.x + ButtonSize.x && y > ButtonPosition.y && y < ButtonPosition.y + ButtonSize.y);
}

UI::InputBlocking OnMouseButton(bool down, int button, int x, int y) {
    if(!Permissions::ViewRecords() || !enabled) return UI::InputBlocking::DoNothing;
	if (isLBvisible() && down && button == 0 && (x > ButtonPosition.x && x < ButtonPosition.x + ButtonSize.x && y > ButtonPosition.y && y < ButtonPosition.y + ButtonSize.y)) {
		execute = true;
		return UI::InputBlocking::Block;
	}
	return UI::InputBlocking::DoNothing;
}

bool isLBvisible() {
    bool ManialinkVisibility = false;
    bool GamemodeVisibility = false;

    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CGameCtnNetwork>(GetApp().Network);
    auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);

    string sCurGameModeStr = ServerInfo.CurGameModeStr;

    // Thanks chips for the code in the if-statement below!
    if (network.ClientManiaAppPlayground !is null && network.ClientManiaAppPlayground.Playground !is null && network.ClientManiaAppPlayground.UILayers.Length > 0) {
        auto uilayers = network.ClientManiaAppPlayground.UILayers;

        for (uint i = 0; i < uilayers.Length; i++) {
            CGameUILayer@ curLayer = uilayers[i];
            int start = curLayer.ManialinkPageUtf8.IndexOf("<");
            int end = curLayer.ManialinkPageUtf8.IndexOf(">");
            if (start != -1 && end != -1) {
                auto manialinkname = curLayer.ManialinkPageUtf8.SubStr(start, end);
                if (manialinkname.Contains("UIModule_Race_Record")) {
                    CGameManialinkQuad@ mButton = cast<CGameManialinkQuad@>(curLayer.LocalPage.GetFirstChild("quad-toggle-records-icon"));
                    if(mButton !is null) {
                        if (mButton.ImageUrl == "file://Media/Manialinks/Nadeo/TMxSM/Race/Icon_ArrowLeft.dds") {
                            ManialinkVisibility = true;
                        } else if (mButton.ImageUrl == "file://Media/Manialinks/Nadeo/TMxSM/Race/Icon_WorldRecords.dds") {
                            ManialinkVisibility = false;
                        }
                    } else ManialinkVisibility = false;

                }
            }
        }
    }

    if(sCurGameModeStr != "") {
        if(sCurGameModeStr == "TM_TimeAttack_Online" || sCurGameModeStr == "TM_Campaign_Local" || sCurGameModeStr == "TM_PlayMap_Local") {
            GamemodeVisibility = true;
        }
        else GamemodeVisibility = false;
    } else GamemodeVisibility = false;

    if(ManialinkVisibility && GamemodeVisibility) return true;
    else return false;
}