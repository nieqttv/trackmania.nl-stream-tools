const string TITLE = "Trackmania.nl Presence";

void RenderMenu() {
    if (UI::MenuItem(TITLE, "", S_WindowOpen, true)) S_WindowOpen = !S_WindowOpen;
}

void RenderInterface() {
    if (!S_WindowOpen || !UI::Begin(TITLE, S_WindowOpen)) return;

    UI::Text("Status: " + Presence::Status);
    UI::Text("Endpoint: " + Api::Endpoint());
    UI::Separator();

    S_Enabled = UI::Checkbox("Enabled", S_Enabled);
    S_SendRoom = UI::Checkbox("Send room", S_SendRoom);
    S_SendMap = UI::Checkbox("Send map", S_SendMap);
    S_TrackMapTime = UI::Checkbox("Track map time", S_TrackMapTime);
    S_SendLive = UI::Checkbox("Send map and PB for the stream overlay", S_SendLive);
    S_MapTimeReportInterval = UI::SliderInt("Map-time report interval", S_MapTimeReportInterval, 60, 900);

    UI::Text("Custom endpoint");
    S_CustomEndpoint = UI::InputText("##custom-endpoint", S_CustomEndpoint);
    UI::Text("Presence token");
    S_Token = UI::InputText("##presence-token", S_Token, UI::InputTextFlags::Password);

    UI::Separator();
    UI::Text("Room: " + OrDash(Presence::LastRoom));
    UI::Text("Club link: " + OrDash(Presence::LastClubLink));
    UI::Text("Club: " + (Club::Name.Length > 0 ? Club::Name : Club::Status));
    UI::Text("Map: " + OrDash(Presence::LastMap));
    UI::Text("Map time: " + (MapTime::MapUid.Length > 0 ? FormatSeconds(MapTime::Seconds) : "-"));
    UI::Text("Map time status: " + MapTime::Status);
    UI::Text("Overlay: " + Live::Status + (Live::Pb > 0 ? " (PB " + Time::Format(Live::Pb) + ")" : ""));
    UI::Text("HTTP: " + Api::LastCode);
    if (Api::LastError.Length > 0) UI::TextWrapped("Error: " + Api::LastError);

    if (UI::Button("Send snapshot")) startnew(Presence::SendNow);

    UI::End();
}
