// Counts the time spent on each map, keeps it in plugin storage and reports it to the site.
namespace MapTime {
    const int MAX_TICK_SECONDS = 10;
    const int SAVE_INTERVAL_SECONDS = 15;

    string Status = "Waiting";

    Json::Value@ Maps;
    string MapUid = "";
    string AccountId = "";
    int Seconds = 0;
    bool Dirty = false;
    int64 LastTick = 0;
    int64 LastReport = 0;
    int64 LastSave = 0;

    string StoragePath() {
        return IO::FromStorageFolder("map-times.json");
    }

    void Load() {
        try {
            if (IO::FileExists(StoragePath())) @Maps = Json::FromFile(StoragePath());
        } catch {
            Status = "Storage reset";
        }
        if (Maps is null || Maps.GetType() != Json::Type::Object) @Maps = Json::Object();
    }

    void Save() {
        try {
            Json::ToFile(StoragePath(), Maps, false);
            LastSave = Time::Stamp;
        } catch {
            Status = "Save error";
        }
    }

    void Loop() {
        LastTick = Time::Stamp;
        while (true) {
            if (S_Enabled && S_TrackMapTime) Tick();
            sleep(1000);
        }
    }

    void Tick() {
        int64 now = Time::Stamp;
        int delta = Math::Clamp(LastTick > 0 ? int(now - LastTick) : 0, 0, MAX_TICK_SECONDS);
        LastTick = now;

        string accountId = GameState::AccountId();
        auto map = GameState::LoadedMap();
        if (accountId.Length == 0 || map.uid.Length == 0) {
            Flush();
            MapUid = "";
            AccountId = "";
            Seconds = 0;
            return;
        }

        if (map.uid != MapUid || accountId != AccountId) {
            Flush();
            Start(accountId, map);
            return;
        }

        if (delta > 0) {
            Seconds += delta;
            Update(accountId, map);
            Dirty = true;
        }

        if (Dirty && now - LastReport >= Math::Max(60, S_MapTimeReportInterval)) {
            Flush();
        } else if (Dirty && now - LastSave >= SAVE_INTERVAL_SECONDS) {
            Save();
        }
    }

    void Start(const string &in accountId, GameState::MapData@ map) {
        MapUid = map.uid;
        AccountId = accountId;
        Seconds = JsonInt(Entry(map.uid), "totalSeconds");
        Update(accountId, map);
        LastReport = Time::Stamp;
        Dirty = true;
        Status = "Tracking";
        Save();
    }

    // Saves the current map's time and reports it to the site.
    void Flush() {
        if (!Dirty || MapUid.Length == 0) return;
        Save();
        startnew(Report, MapUid);
        LastReport = Time::Stamp;
        Dirty = false;
    }

    Json::Value@ Entry(const string &in mapUid) {
        if (!Maps.HasKey(mapUid) || Maps[mapUid].GetType() != Json::Type::Object) Maps[mapUid] = Json::Object();
        return Maps[mapUid];
    }

    void Update(const string &in accountId, GameState::MapData@ map) {
        auto entry = Entry(map.uid);
        entry["accountId"] = accountId;
        entry["mapUid"] = map.uid;
        entry["mapName"] = map.name;
        entry["mapAuthor"] = map.author;
        entry["authorTime"] = map.authorTime;
        entry["totalSeconds"] = Seconds;
        entry["updatedAt"] = int(Time::Stamp);
    }

    void Report(const string &in mapUid) {
        if (!Maps.HasKey(mapUid) || Maps[mapUid].GetType() != Json::Type::Object) return;
        auto entry = Maps[mapUid];
        string accountId = JsonText(entry, "accountId");
        if (accountId.Length == 0) return;

        auto body = Api::Body(accountId);
        body["mapUid"] = mapUid;
        body["mapName"] = JsonText(entry, "mapName");
        body["mapAuthor"] = JsonText(entry, "mapAuthor");
        body["authorTime"] = JsonInt(entry, "authorTime");
        body["totalSeconds"] = JsonInt(entry, "totalSeconds");
        Api::Post("/map-time", body);
        Status = Api::Status("Reported");
    }
}
