classdef WalkForwardEngine
    %WalkForwardEngine features:
    %   Detailed explanation goes here
    %   
    %   list of properties:
    %   - marketData
    %   - wfaSetUp
    %   - tradingSignalParam
    %   - btEngineVectorizedSetUp %TODO
    %   - btEngineEventDrivenSetUp %TODO
    %   - etc
    %
    %   lis of methods:
    %   - loadSymbols
    %   - cleanMarketData
    %   - generateTradingSignal
    %   - runBTEngineVectorized
    %   - runBTEngineEventDriven
    %   - runWalkForward
    %   - optimSignalParam
    %   - generateStockPick
    %   - analyzeWFAResults
    %   - etc
    
    
    %%=================================================================
    properties
        wfaSetUp = WFASetUpParam;
        marketData = MarketData;
        
    end
    
    properties (SetAccess = private)
        tradingSignalParam
        
    end
    
    methods
        function obj = loadSymbols(obj)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.marketData= obj.marketData.loadSymbolMCapRef;
        end
        
        function obj= loadDataFromYahoo(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData = obj.marketData.loadDataFromYahoo;
        end
%         function obj= loadDataFromSpreadsheet(obj)
%             %METHOD1 Summary of this method goes here
%             %   Detailed explanation goes here
%             obj.marketData = obj.marketData.loadDataFromSpreadsheet;
%         end
        
        function obj= loadDataFromMatFile(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData = obj.marketData.loadDataFromMatFile;
        end
        
        function obj= cleanMarketData(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData = obj.marketData.cleanData;
        end
        
        function saveDataToMatFile(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData.saveDataToMatFile;
        end
        
        function saveDataToSpreadsheet(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData.saveDataToSpreadsheet;
        end
        
        function obj= loadDataFromSpreadsheet(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.marketData = obj.marketData.loadDataFromSpreadsheet;
        end
        
        
        function obj = optimSignalParam(obj)
            obj.wfaSetUp.lbubConst = obj.wfaSetUp.prepare;
            
            
        end
    end
end

