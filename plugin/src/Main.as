void Main() {
    NadeoServices::AddAudience("NadeoLiveServices");
    NadeoServices::AddAudience("NadeoServices");
    MapTime::Load();
    startnew(Presence::Loop);
    startnew(MapTime::Loop);
    startnew(Live::Loop);
}
