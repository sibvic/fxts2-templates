function AddAverages(id, name, default)
    strategy.parameters:addString(id, name, "", default);
    strategy.parameters:addStringAlternative(id, "MVA", "", "MVA");
    strategy.parameters:addStringAlternative(id, "EMA", "", "EMA");
    strategy.parameters:addStringAlternative(id, "Wilder", "", "Wilder");
    strategy.parameters:addStringAlternative(id, "LWMA", "", "LWMA");
    strategy.parameters:addStringAlternative(id, "SineWMA", "", "SineWMA");
    strategy.parameters:addStringAlternative(id, "TriMA", "", "TriMA");
    strategy.parameters:addStringAlternative(id, "LSMA", "", "LSMA");
    strategy.parameters:addStringAlternative(id, "SMMA", "", "SMMA");
    strategy.parameters:addStringAlternative(id, "HMA", "", "HMA");
    strategy.parameters:addStringAlternative(id, "ZeroLagEMA", "", "ZeroLagEMA");
    strategy.parameters:addStringAlternative(id, "DEMA", "", "DEMA");
    strategy.parameters:addStringAlternative(id, "T3", "", "T3");
    strategy.parameters:addStringAlternative(id, "ITrend", "", "ITrend");
    strategy.parameters:addStringAlternative(id, "Median", "", "Median");
    strategy.parameters:addStringAlternative(id, "GeoMean", "", "GeoMean");
    strategy.parameters:addStringAlternative(id, "REMA", "", "REMA");
    strategy.parameters:addStringAlternative(id, "ILRS", "", "ILRS");
    strategy.parameters:addStringAlternative(id, "IE/2", "", "IE/2");
    strategy.parameters:addStringAlternative(id, "TriMAgen", "", "TriMAgen");
    strategy.parameters:addStringAlternative(id, "JSmooth", "", "JSmooth");
    strategy.parameters:addStringAlternative(id, "KAMA", "", "KAMA");
    strategy.parameters:addStringAlternative(id, "ARSI", "", "ARSI");
    strategy.parameters:addStringAlternative(id, "VIDYA", "", "VIDYA");
    strategy.parameters:addStringAlternative(id, "HPF", "", "HPF");
    strategy.parameters:addStringAlternative(id, "VAMA", "", "VAMA");
end

function CreateAverates(method, source, period)
    if method == "MVA" or method == "EMA" or method == "ARSI" 
        or method == "KAMA" or method == "LWMA" or method == "SMMA"
        or method == "VIDYA"
    then
        --assert(core.indicators:findIndicator(method) ~= nil, method .. " indicator must be installed");
        return core.indicators:create(method, source, period);
    end
    assert(core.indicators:findIndicator("AVERAGES") ~= nil, "Please, download and install AVERAGES indicator");
    return core.indicators:create("AVERAGES", source, method, period);
end
