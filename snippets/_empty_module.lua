your_module_name = {};
-- public fields
your_module_name.Name = "your module name";
your_module_name.Version = "1.0";
your_module_name.Debug = false;
--private fields
your_module_name._ids_start = nil;
your_module_name._tz = nil;
your_module_name._signaler = nil;

function your_module_name:trace(str)
    if not self.Debug then
        return;
    end
    core.host:trace(self.Name .. ": " .. str);
end

function your_module_name:Init(parameters)
    --insert your parameters here
end

function your_module_name:Prepare(name_only)
    --do what you usually do in prepare
    if name_only then
        return;
    end
end

function your_module_name:OnNewModule(module)
    if module.Name == "Timezone Parameter" then
        self._tz = module;
    elseif module.Name == "Signaler" then
        self._signaler = module;
    end
end

function your_module_name:RegisterModule(modules)
    for _, module in pairs(modules) do
        self:OnNewModule(module);
        module:OnNewModule(self);
    end
    modules[#modules + 1] = self;
    self._ids_start = (#modules) * 100;
end

function your_module_name:ReleaseInstance()
    --do what you usually do in ReleaseInstance
end

function your_module_name:AsyncOperationFinished(cookie, success, message, message1, message2)
    --do what you usually do in AsyncOperationFinished/ExtAsyncOperationFinished
end

function your_module_name:ExtUpdate(id, source, period)
    --do what you usually do in Update
end

function your_module_name:BlockTrading(id, source, period)
    --do what you usually do in Update
    return false;
end

function your_module_name:BlockOrder(order_value_map)
    --use to forbid openind an order
    return false;
end

function your_module_name:OnOrder(order_value_map)
    --pre-order actions
end