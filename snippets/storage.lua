storage = {};
-- public fields
storage.Name = "Storage";
storage.Version = "1.0";
storage.Debug = false;
--private fields
storage._ids_start = nil;
storage._tz = nil;
storage._signaler = nil;

function storage:trace(str)
    if not self.Debug then
        return;
    end
    core.host:trace(self.Name .. ": " .. str);
end

function storage:Init(parameters)
    --insert your parameters here
end

function storage:Prepare(name_only)
    --do what you usually do in prepare
    if name_only then
        return;
    end
    require("storagedb");
    self.db = storagedb.get_db(profile:id());
end

function storage:SaveNumber(id, number)
    if number ~= nil then
        self.db:put(id, tostring(number));
    end
end

function storage:ReadNumber(id)
    local val = self.db:get(id, "");
    if val == "" then
        return nil;
    end
    return tonumber(val);
end

function storage:OnNewModule(module)
end

function storage:RegisterModule(modules)
    for _, module in pairs(modules) do
        self:OnNewModule(module);
        module:OnNewModule(self);
    end
    modules[#modules + 1] = self;
    self._ids_start = (#modules) * 100;
end

function storage:ReleaseInstance()
    --do what you usually do in ReleaseInstance
end

function storage:AsyncOperationFinished(cookie, success, message, message1, message2)
    --do what you usually do in AsyncOperationFinished/ExtAsyncOperationFinished
end

function storage:ExtUpdate(id, source, period)
    --do what you usually do in Update
end
