namespace Api {
    const string ENDPOINT = "https://trackmania.nl/api/twitch/presence";
    const string SOURCE = "openplanet-trackmania-nl-presence";

    int LastCode = 0;
    string LastError = "";

    string Endpoint() {
        string custom = S_CustomEndpoint.Trim();
        return custom.Length > 0 ? custom : ENDPOINT;
    }

    string Token() {
        return S_Token.Trim();
    }

    // A request body with the fields every call carries.
    Json::Value@ Body(const string &in accountId) {
        Json::Value@ body = Json::Object();
        body["accountId"] = accountId;
        body["token"] = Token();
        body["source"] = SOURCE;
        return body;
    }

    // Posts the body to the endpoint plus path and waits for the answer. Returns the request, or null
    // when it failed; LastCode and LastError say why.
    Net::HttpRequest@ Post(const string &in path, Json::Value@ body) {
        try {
            Net::HttpRequest@ req = Net::HttpRequest();
            req.Method = Net::HttpMethod::Post;
            req.Url = Endpoint() + path;
            req.Headers["Accept"] = "application/json";
            req.Headers["Content-Type"] = "application/json";
            req.Body = Json::Write(body);
            req.Start();
            while (!req.Finished()) yield();
            LastCode = req.ResponseCode();
            LastError = req.Error();
            return LastError.Length == 0 && LastCode >= 200 && LastCode < 300 ? req : null;
        } catch {
            LastCode = 0;
            LastError = getExceptionInfo();
            return null;
        }
    }

    // A short status for the last request: the given text when it worked, else what went wrong.
    string Status(const string &in ok) {
        if (LastError.Length > 0) return "Error";
        if (LastCode < 200 || LastCode >= 300) return "HTTP " + LastCode;
        return ok;
    }
}
