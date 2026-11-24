// Sends the map being played and the player's PB to the site as they change, for the stream overlay.
namespace Live {
    const int KEEPALIVE_SECONDS = 60;
    const int TTL_SECONDS = KEEPALIVE_SECONDS * 2 + 30;

    string Status = "Waiting";
    string MapUid = "";
    uint Pb = 0;
    int64 SentAt = 0;

    // The map thumbnail, asked from Nadeo with the player's own token once per map.
    string ThumbAskedUid = "";
    string ThumbUid = "";
    string ThumbUrl = "";
    bool ThumbChanged = false;

    void Loop() {
        while (true) {
            sleep(250);
            if (!S_Enabled || !S_SendLive || Api::Token().Length == 0) continue;
            try {
                Tick();
            } catch {
                Status = "Error";
            }
        }
    }

    void Tick() {
        string accountId = GameState::AccountId();
        if (accountId.Length == 0) return;

        auto map = GameState::PlayedMap();
        if (map.uid.Length == 0) {
            if (MapUid.Length > 0) {
                MapUid = "";
                Pb = 0;
                Send(accountId, "leave", map);
            }
            return;
        }

        if (map.uid != ThumbAskedUid) {
            ThumbAskedUid = map.uid;
            startnew(FetchThumbnail, map.uid);
        }

        uint pb = GameState::PersonalBest(map.uid);
        string event = NextEvent(map.uid, pb);
        if (event.Length == 0) return;

        MapUid = map.uid;
        if (pb > 0) Pb = pb;
        ThumbChanged = false;
        Send(accountId, event, map);
    }

    // What to tell the site now, empty for nothing.
    string NextEvent(const string &in mapUid, uint pb) {
        if (mapUid != MapUid) return "map";
        if (pb > 0 && pb != Pb) return "pb";
        if (ThumbChanged || Time::Stamp - SentAt >= KEEPALIVE_SECONDS) return "keepalive";
        return "";
    }

    void Send(const string &in accountId, const string &in event, GameState::MapData@ map) {
        auto body = Api::Body(accountId);
        body["event"] = event;
        body["mapUid"] = map.uid;
        body["mapName"] = map.name;
        body["mapAuthor"] = map.author;
        body["authorTime"] = map.authorTime;
        body["pbTime"] = int(Pb);
        if (ThumbUid == map.uid && ThumbUrl.Length > 0) body["thumbnailUrl"] = ThumbUrl;
        body["ttlSeconds"] = TTL_SECONDS;
        SentAt = Time::Stamp;
        Api::Post("/live", body);
        Status = Api::Status(event == "pb" ? "PB sent" : "Sent");
    }

    void FetchThumbnail(const string &in mapUid) {
        try {
            while (!NadeoServices::IsAuthenticated("NadeoServices")) yield();
            auto req = NadeoServices::Get("NadeoServices", NadeoServices::BaseURLCore() + "/maps/?mapUidList=" + mapUid);
            req.Start();
            while (!req.Finished()) yield();
            if (req.ResponseCode() != 200 || mapUid != ThumbAskedUid) return;
            auto json = req.Json();
            if (json is null || json.GetType() != Json::Type::Array || json.Length == 0) return;
            string url = JsonText(json[0], "thumbnailUrl");
            if (url.Length == 0) return;
            ThumbUid = mapUid;
            ThumbUrl = url;
            ThumbChanged = true;
        } catch {}
    }
}
