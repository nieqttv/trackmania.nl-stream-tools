[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Custom endpoint"]
string S_CustomEndpoint = "";

[Setting category="General" name="Send room"]
bool S_SendRoom = true;

[Setting category="General" name="Send map"]
bool S_SendMap = true;

[Setting category="Map time" name="Track map time"]
bool S_TrackMapTime = true;

[Setting category="Map time" name="Report interval" min=60 max=900]
int S_MapTimeReportInterval = 180;

[Setting category="Overlay" name="Send map and PB for the stream overlay"]
bool S_SendLive = true;

[Setting hidden]
bool S_WindowOpen = true;

[Setting hidden]
string S_Token = "";
