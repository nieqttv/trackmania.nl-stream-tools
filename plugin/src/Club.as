// Club rooms tell the game their club in the script variables Net_TMGame_DecoImage_ClubId and
// _ClubName: the room's own data, so it names the exact club. Read once per server.
namespace Club {
    string Login = "";
    string Id = "";
    string Name = "";
    string Status = "-";
    bool Busy = false;

    // Starts reading the club when the player joined another server, forgets it after leaving.
    void Follow(const string &in serverLogin) {
        if (serverLogin.Length > 0 && serverLogin != Login && !Busy) {
            Login = serverLogin;
            Busy = true;
            startnew(Read, serverLogin);
        } else if (serverLogin.Length == 0 && Login.Length > 0) {
            Login = "";
            Id = "";
            Name = "";
            Status = "-";
        }
    }

    bool KnownFor(const string &in serverLogin) {
        return serverLogin.Length > 0 && serverLogin == Login && Id.Length > 0;
    }

    void Read(const string &in serverLogin) {
        Status = "Reading";
        Id = "";
        Name = "";
        int startedAt = Time::Now;
        try {
            while (Time::Now - startedAt < 60000) {
                auto app = GameState::App();
                auto net = app is null ? null : cast<CGameCtnNetwork>(app.Network);
                if (net is null || net.ClientManiaAppPlayground is null) break;
                auto server = cast<CGameCtnNetServerInfo>(net.ServerInfo);
                if (server is null || Clean(server.ServerLogin) != serverLogin) break;

                string vars = string(net.ClientManiaAppPlayground.Dbg_DumpDeclareForVariables(server.TeamProfile1, false));
                string id = DeclaredValue(vars, "Net_TMGame_DecoImage_ClubId");
                if (id.Length > 0) {
                    int n = Text::ParseInt(id);
                    if (n > 0) {
                        Id = tostring(n);
                        Name = Clean(DeclaredValue(vars, "Net_TMGame_DecoImage_ClubName"));
                        Status = Name.Length > 0 ? "Found" : "Found id " + Id;
                    } else {
                        Status = "Not a club room";
                    }
                    break;
                }
                sleep(500);
            }
            if (Status == "Reading") Status = "Not a club room";
        } catch {
            Status = "Error";
        }
        Busy = false;
    }

    // The value of one variable in a script variable dump, without quotes.
    string DeclaredValue(const string &in vars, const string &in name) {
        auto parts = vars.Split(name + " = ");
        if (parts.Length < 2) return "";
        string value = parts[1].Split("\n")[0].Trim();
        if (value.EndsWith(";")) value = value.SubStr(0, value.Length - 1).Trim();
        if (value.Length >= 2 && value.StartsWith("\"") && value.EndsWith("\"")) value = value.SubStr(1, value.Length - 2);
        return value;
    }
}
