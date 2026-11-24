namespace GameState {
    class MapData {
        string uid;
        string name;
        string author;
        int authorTime = 0;
    }

    CGameCtnApp@ App() {
        return cast<CGameCtnApp>(GetApp());
    }

    string AccountId() {
        auto app = App();
        if (app is null || app.LocalPlayerInfo is null) return "";
        return Clean(app.LocalPlayerInfo.WebServicesUserId);
    }

    string DisplayName() {
        auto app = App();
        if (app is null || app.LocalPlayerInfo is null) return "";
        return Clean(app.LocalPlayerInfo.Name);
    }

    MapData@ NoMap() {
        return MapData();
    }

    // The loaded map, also in the editor and menus. Empty when there is none.
    MapData@ LoadedMap() {
        MapData@ m = MapData();
        auto app = App();
        if (app is null || app.RootMap is null) return m;
        auto map = app.RootMap;
        if (map.MapInfo !is null) {
            m.uid = Clean(map.MapInfo.MapUid);
            m.name = Clean(map.MapInfo.NameForUi);
            m.author = Clean(map.MapInfo.AuthorNickName);
        }
        if (m.name.Length == 0) m.name = Clean(map.MapName);
        if (m.author.Length == 0) m.author = Clean(map.AuthorNickName);
        m.authorTime = int(map.TMObjective_AuthorTime);
        return m;
    }

    // The map being played: not in the editor or menus. Empty when there is none.
    MapData@ PlayedMap() {
        auto app = App();
        if (app is null || app.CurrentPlayground is null || app.Editor !is null) return NoMap();
        return LoadedMap();
    }

    // Personal best on a map in ms, 0 when there is none. Reads the stored record and, on servers,
    // the best finish of this session (the stored PB can lag behind there).
    uint PersonalBest(const string &in mapUid) {
        auto app = App();
        if (app is null || mapUid.Length == 0) return 0;
        uint best = 0;

        auto net = cast<CGameCtnNetwork>(app.Network);
        if (net !is null && net.ClientManiaAppPlayground !is null) {
            auto mania = net.ClientManiaAppPlayground;
            if (mania.ScoreMgr !is null && mania.UserMgr !is null && mania.UserMgr.Users.Length > 0) {
                uint t = mania.ScoreMgr.Map_GetRecord_v2(mania.UserMgr.Users[0].Id, mapUid, "PersonalBest", "", "TimeAttack", "");
                if (IsTime(t)) best = t;
            }
        }

        auto playground = app.CurrentPlayground;
        if (playground !is null && playground.GameTerminals.Length > 0) {
            auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
            if (player !is null && player.Score !is null && player.Score.BestRaceTimes.Length > 0) {
                uint t = player.Score.BestRaceTimes[player.Score.BestRaceTimes.Length - 1];
                if (IsTime(t) && (best == 0 || t < best)) best = t;
            }
        }
        return best;
    }

    bool IsTime(uint t) {
        return t > 0 && t < 0xFFFFFFFF;
    }
}
