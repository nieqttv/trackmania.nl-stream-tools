// Game text without $ format codes.
string Clean(const string &in value) {
    return Text::StripFormatCodes(value).Trim();
}

string Clean(const wstring &in value) {
    return Clean(tostring(value));
}

// A string or number field of a JSON object as text, empty when missing.
string JsonText(Json::Value@ obj, const string &in key) {
    if (obj is null || obj.GetType() != Json::Type::Object || !obj.HasKey(key)) return "";
    auto value = obj[key];
    if (value.GetType() == Json::Type::String) return Clean(string(value));
    if (value.GetType() == Json::Type::Number) return tostring(int64(value));
    return "";
}

int JsonInt(Json::Value@ obj, const string &in key) {
    if (obj is null || obj.GetType() != Json::Type::Object || !obj.HasKey(key)) return 0;
    return int(obj[key]);
}

string FormatSeconds(int seconds) {
    int h = seconds / 3600;
    int m = (seconds % 3600) / 60;
    int s = seconds % 60;
    if (h > 0) return h + "h " + m + "m";
    if (m > 0) return m + "m " + s + "s";
    return s + "s";
}

string OrDash(const string &in value) {
    return value.Length > 0 ? value : "-";
}
