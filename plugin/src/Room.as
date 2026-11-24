namespace Room {
    class Info {
        string serverName;
        string serverLogin;
        string joinLink;
        string modeName;
        string clubLink;
        string clubLink1;
        string clubLink2;
        string serverHostName;
        string firstPartySessionId;
        int playerCount = 0;
        int maxPlayerCount = 0;
        bool isPrivate = false;
        bool isPrivateForSpectator = false;

        bool IsOnline() {
            return serverName.Length > 0 || serverLogin.Length > 0 || joinLink.Length > 0;
        }
    }

    Info@ None() {
        return Info();
    }

    // The room the player is in, gathered from every place the game keeps it. Each field keeps the
    // first value found.
    Info@ Read() {
        Info@ room = Info();
        auto app = GameState::App();
        if (app is null) return room;

        if (app.Network !is null) {
            FromServerInfo(room, cast<CGameCtnNetServerInfo>(app.Network.ServerInfo));
        }
        if (app.CurrentPlayground !is null && app.CurrentPlayground.Interface !is null) {
            auto ui = app.CurrentPlayground.Interface;
            FromServerInfo(room, ui.ServerInfo);
            FromPlaygroundHandler(room, ui.ManialinkScriptHandler);
        }
        FromPlaygroundScript(room, app.PlaygroundScript);
        auto maniaPlanet = cast<CGameManiaPlanet>(app);
        if (maniaPlanet !is null) FromManiaPlanetApi(room, maniaPlanet.ManiaPlanetScriptAPI);
        FromChatManager(room, app.ChatManagerScript);
        return room;
    }

    // The current value when there is one, else the new one.
    string First(const string &in current, const string &in value) {
        return current.Length > 0 ? current : Clean(value);
    }

    string First(const string &in current, const wstring &in value) {
        return current.Length > 0 ? current : Clean(value);
    }

    int First(int current, uint value) {
        return current != 0 ? current : int(value);
    }

    void FillClubLinks(Info@ room, const string &in first, const string &in second) {
        room.clubLink1 = First(room.clubLink1, first);
        room.clubLink2 = First(room.clubLink2, second);
        if (room.clubLink.Length == 0) room.clubLink = room.clubLink1.Length > 0 ? room.clubLink1 : room.clubLink2;
    }

    void FromServerInfo(Info@ room, CGameCtnNetServerInfo@ server) {
        if (server is null) return;
        room.serverName = First(room.serverName, server.ServerName);
        room.serverLogin = First(room.serverLogin, server.ServerLogin);
        room.joinLink = First(room.joinLink, server.JoinLink);
        room.modeName = First(room.modeName, server.ModeName);
        FillClubLinks(room, server.ForcedClubLinkUrl1, server.ForcedClubLinkUrl2);
        room.serverHostName = First(room.serverHostName, server.ServerHostName);
        room.firstPartySessionId = First(room.firstPartySessionId, server.FirstPartySessionId);
        room.playerCount = First(room.playerCount, server.PlayerCount);
        room.maxPlayerCount = First(room.maxPlayerCount, server.MaxPlayerCount);
        room.isPrivate = room.isPrivate || server.IsPrivate;
        room.isPrivateForSpectator = room.isPrivateForSpectator || server.IsPrivateForSpectator;
    }

    void FromPlaygroundScript(Info@ room, CGamePlaygroundScript@ script) {
        if (script is null) return;
        room.serverName = First(room.serverName, script.ServerName);
        room.serverLogin = First(room.serverLogin, script.ServerLogin);
        room.modeName = First(room.modeName, script.ServerModeName);
        FillClubLinks(room, script.ForcedClubLinkUrl1, script.ForcedClubLinkUrl2);
    }

    void FromChatManager(Info@ room, CGameScriptChatManager@ chat) {
        if (chat is null) return;
        room.serverName = First(room.serverName, chat.CurrentServerName);
        room.serverLogin = First(room.serverLogin, chat.CurrentServerLogin);
        room.joinLink = First(room.joinLink, chat.CurrentServerJoinLink);
        room.modeName = First(room.modeName, chat.CurrentServerModeName);
        room.playerCount = First(room.playerCount, chat.CurrentServerPlayerCount);
        room.maxPlayerCount = First(room.maxPlayerCount, chat.CurrentServerPlayerCountMax);
        room.isPrivate = room.isPrivate || chat.CurrentServer_IsPrivate;
        room.isPrivateForSpectator = room.isPrivateForSpectator || chat.CurrentServer_IsPrivateSpec;
    }

    void FromManiaPlanetApi(Info@ room, CGameManiaPlanetScriptAPI@ api) {
        if (api is null) return;
        room.serverName = First(room.serverName, api.CurrentServerName);
        room.serverLogin = First(room.serverLogin, api.CurrentServerLogin);
        room.joinLink = First(room.joinLink, api.CurrentServerJoinLink);
        room.modeName = First(room.modeName, api.CurrentServerModeName);
        FromChatManager(room, api.ChatManager);
    }

    void FromPlaygroundHandler(Info@ room, CGameScriptHandlerPlaygroundInterface@ handler) {
        if (handler is null) return;
        room.serverName = First(room.serverName, handler.CurrentServerName);
        room.serverLogin = First(room.serverLogin, handler.CurrentServerLogin);
        room.joinLink = First(room.joinLink, handler.CurrentServerJoinLink);
        room.modeName = First(room.modeName, handler.CurrentServerModeName);
        if (handler.Playground !is null) FromServerInfo(room, handler.Playground.ServerInfo);
    }
}
