// Answers the site's questions about where the player is, for chat commands like !room and !map.
namespace Presence {
    const int TTL_SECONDS = 30;

    string Status = "Starting";
    string LastRoom = "";
    string LastClubLink = "";
    string LastMap = "";

    class Snapshot {
        string accountId;
        GameState::MapData@ map;
        Room::Info@ room;
    }

    void Loop() {
        while (true) {
            if (!S_Enabled) {
                Status = "Disabled";
                sleep(1000);
                continue;
            }
            auto now = Take();
            if (now.accountId.Length == 0) {
                Status = "No account";
                sleep(2500);
                continue;
            }
            Poll(now.accountId);
            sleep(250);
        }
    }

    // Where the player is now. Also keeps the window's room, map and club up to date.
    Snapshot@ Take() {
        Snapshot@ s = Snapshot();
        s.accountId = GameState::AccountId();
        @s.map = S_SendMap ? GameState::LoadedMap() : GameState::NoMap();
        @s.room = S_SendRoom ? Room::Read() : Room::None();
        LastRoom = s.room.serverName;
        LastClubLink = s.room.clubLink;
        LastMap = s.map.name.Length > 0 ? s.map.name : s.map.uid;
        Club::Follow(s.room.serverLogin);
        return s;
    }

    // Asks the site whether someone wants to know where the player is, and answers when so.
    void Poll(const string &in accountId) {
        auto req = Api::Post("/poll", Api::Body(accountId));
        if (req is null) {
            Status = Api::Status("");
            return;
        }
        string requestId = RequestId(req.Json());
        if (requestId.Length == 0) {
            Status = "Listening";
            return;
        }
        Status = "Answering";
        Send("/respond", requestId, "Answered");
    }

    string RequestId(Json::Value@ json) {
        if (json is null || json.GetType() != Json::Type::Object || !json.HasKey("request")) return "";
        return JsonText(json["request"], "id");
    }

    void SendNow() {
        Send("", "", "Sent");
    }

    // Sends where the player is now; with a request id it answers that request.
    void Send(const string &in path, const string &in requestId, const string &in okStatus) {
        auto now = Take();
        if (now.accountId.Length == 0) {
            Status = "No account";
            return;
        }
        auto body = ToJson(now);
        if (requestId.Length > 0) body["requestId"] = requestId;
        Api::Post(path, body);
        Status = Api::Status(okStatus);
    }

    Json::Value@ ToJson(Snapshot@ s) {
        auto map = s.map;
        auto room = s.room;
        auto body = Api::Body(s.accountId);
        body["displayName"] = GameState::DisplayName();
        body["state"] = State(s);
        body["serverName"] = room.serverName;
        body["serverLogin"] = room.serverLogin;
        body["joinLink"] = room.joinLink;
        body["modeName"] = room.modeName;
        body["clubLink"] = room.clubLink;
        body["clubLink1"] = room.clubLink1;
        body["clubLink2"] = room.clubLink2;
        body["serverHostName"] = room.serverHostName;
        body["firstPartySessionId"] = room.firstPartySessionId;
        body["isPrivate"] = room.isPrivate;
        body["isPrivateForSpectator"] = room.isPrivateForSpectator;
        body["mapUid"] = map.uid;
        body["mapName"] = map.name;
        body["mapAuthor"] = map.author;
        body["authorTime"] = map.authorTime;
        body["playerCount"] = room.playerCount;
        body["maxPlayerCount"] = room.maxPlayerCount;
        if (Club::KnownFor(room.serverLogin)) {
            body["clubId"] = Club::Id;
            if (Club::Name.Length > 0) body["clubName"] = Club::Name;
        }
        body["ttlSeconds"] = TTL_SECONDS;
        return body;
    }

    string State(Snapshot@ s) {
        if (s.room.IsOnline()) return "online";
        if (s.map.uid.Length > 0 || s.map.name.Length > 0) return "solo";
        return "idle";
    }
}
