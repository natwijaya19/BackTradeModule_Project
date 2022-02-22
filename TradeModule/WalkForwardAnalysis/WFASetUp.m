classdef WFASetUp
    %WFASetUp is to store all set up required to to a walk-forward analysis
    %   Detailed explanation goes here
    
    properties
        marketData = MarketData
    end
    
    methods
        function obj = loadSymbols(obj)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.marketData = obj.marketData.loadSymbolMCapRef;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

