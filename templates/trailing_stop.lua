local Modules = {};

function Init()
    strategy:name("Trailing stop");
    strategy:description("");
    strategy:setTag("Version", "1.0");
    strategy:setTag("strategy_type", "Money management");
    
    -- ADD PARAMS
    
    strategy.parameters:addString("TF", "Time frame", "", "m1");
    strategy.parameters:setFlag("TF", core.FLAG_BARPERIODS);
    
    strategy.parameters:addGroup("Trade");
    strategy.parameters:addBoolean("all_trades", "All trades", "", false);
    strategy.parameters:addString("Trade", "(non-FIFO) Choose Trade", "", "");
    strategy.parameters:setFlag("Trade", core.FLAG_TRADE);
 
    CreateTradingParameters();
end

function CreateTradingParameters()
    strategy.parameters:addGroup("Execution Parameters");

    strategy.parameters:addBoolean("AllowTrade", "Allow strategy to trade", "", true);   
    strategy.parameters:setFlag("AllowTrade", core.FLAG_ALLOW_TRADE);
    
    strategy.parameters:addString("ExecutionType", "Execution Type", "", "Live");
    strategy.parameters:addStringAlternative("ExecutionType", "End of Turn", "", "EndOfTurn");
    strategy.parameters:addStringAlternative("ExecutionType", "Live", "", "Live");
end

local tradeId
local all_trades;
local Source,TickSource;
local AllowTrade;
local ExecutionType;
local TF;
local Indicator;
local commands = {};

function Prepare(nameOnly)
    for _, module in pairs(Modules) do module:Prepare(nameOnly); end
    ExecutionType = instance.parameters.ExecutionType;
    
    TF = instance.parameters.TF;
    tradeId = instance.parameters.Trade;
    all_trades = instance.parameters.all_trades;
    if not all_trades then
        local trade = core.host:findTable("trades"):find("TradeID", tradeId);
        assert(trade ~= nil, "Trade can not be found")
    end
        
    name = profile:id() .. ", " .. instance.bid:name() ;
    instance:name(name);
   
    AllowTrade = instance.parameters.AllowTrade;

    if nameOnly then
        return ;
    end

    Source = ExtSubscribe(2, nil, TF, instance.parameters.Type == "Bid", "bar");
    -- Indicator = core.indicators:create("ICH", Source, 
    --     instance.parameters.TenkanSenPeriod,
    --     instance.parameters.KijunSenPeriod,
    --     instance.parameters.SenkouSpanPeriod);
    
    if ExecutionType == "Live" then
        TickSource = ExtSubscribe(1, nil, "t1", instance.parameters.Type == "Bid", "close");
    end
end

function DoMoveStop(trade)
    if commands[trade.TradeID] ~= nil and not commands[trade.TradeID].Finished then
        return;
    end
    local newStop;
    if (trade.BS == "B") then
        newStop = math.min(Indicator.SL[NOW], Indicator.TL[NOW]);
    else
        newStop = math.max(Indicator.SL[NOW], Indicator.TL[NOW]);
    end
    local stop = trading:FindStopOrder(trade);
    if stop == nil or stop.Rate ~= newStop then
        commands[trade.TradeID] = trading:MoveStop(trade, newStop);
    end
end

local commands = {};
function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.
    for _, module in pairs(Modules) do if module.BlockTrading ~= nil and module:BlockTrading(id, source, period) then return; end end for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(id, source, period); end end
    if AllowTrade then
        if not(checkReady("trades")) or not(checkReady("orders")) then
            return ;
        end
    end
    
    Indicator:update(core.UpdateLast);

    if all_trades then
        trading:FindTrade()
            :WhenInstrument(source:instrument())
            :Do(DoMoveStop);
    else
        local trade = core.host:findTable("trades"):find("TradeID", tradeId);
        if (trade == nil) then
            core.host:execute("stop");
            return;
        end
        DoMoveStop(trade);
    end
end
 
-- NG: Introduce async function for timer/monitoring for the order results
function ExtAsyncOperationFinished(cookie, success, message)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
end

--===========================================================================--
--                    TRADING UTILITY FUNCTIONS                              --
--============================================================================--

function checkReady(table)
    local rc;
    if Account == "TESTACC_ID" then
        -- run under debugger/simulator
        rc = true;
    else
        rc = core.host:execute("isTableFilled", table);
    end

    return rc;
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
 
-- include trading.lua