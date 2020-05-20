local logger = {};
logger.headers = {};
function logger:Start(fileName)
    self.log_file = io.open(fileName, "w");
end
function logger:Stop()
    self.log_file:close();
end
function logger:AddHeader(name)
    self.headers[#self.headers + 1] = name;
end
function logger:AddIndiHeaders(indi)
    local streamsCount = indi:getStreamCount();
    for i = 0, streamsCount - 1 do
        local stream = indi:getStream(i);
        self.headers[#self.headers + 1] = stream:name();
    end
end
function logger:Clear()
    self.values = {};
end
function logger:AddValue(name, val)
    self.values[name] = val;
end
function logger:AddIndiValues(indi, period)
    local streamsCount = indi:getStreamCount();
    for i = 0, streamsCount - 1 do
        local stream = indi:getStream(i);
        if stream:size() > period then
            self.values[stream:name()] = tostring(stream:tick(period));
        end
    end
end
function logger:FlushHeaders()
    for i, header in ipairs(self.headers) do
        self.log_file:write(header .. ";")
    end
    self.log_file:write("\n");
end
function logger:FlushValues()
    for i, header in ipairs(self.headers) do
        self.log_file:write(tostring(self.values[header]) .. ";");
    end
    self.log_file:write("\n");
    self.log_file:flush();
end