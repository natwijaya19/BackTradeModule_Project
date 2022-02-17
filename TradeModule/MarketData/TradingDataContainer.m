classdef TradingDataContainer 
    %PriceVolumeContainer is class object for price and volume container

    properties
        openPrice timetable
        highPrice timetable
        lowPrice timetable
        closePrice timetable
        volume timetable
        indexIHSG timetable
        marketCap timetable
        tradingSignal timetable
        tradingParameter timetable

    end

end