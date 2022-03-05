function Fval = objectiveFcn (tradingSignalParam, dataStructInput,...
                tradingCost, maxCapAllocation, optimLookbackStep)
    %
    % USAGE:
    %       Fval = objectiveFcn (tradingSignalParam, dataStructInput, optimLookbackStep)
    %
    % input argument:
    %   tradingSignalParam      vector array    :   1xnVars
    %   dataStructInput         struct          :   field openPrice, highPrice, lowPrice, 
    %                                               highPrice and volume. All these data are in timetable               
    %   optimLookbackStep       scalar          :   nStep lookback for total return calculation
    
    % prepare data input
    % tradingSignalParam = tradingSignalParameter;
    % optimLookbackStep = 40;
    
    % generate signal
    tradingSignalOut = generateTradingSignalFcn (dataStructInput, tradingSignalParam);
    
    % backtest the signal against the price
    tradingSignalIn = tradingSignalOut;
    resultStruct = btEngineVectFcn (dataStructInput, tradingSignalIn,...
                    tradingCost, maxCapAllocation);
    
    % calculate equityCurve at for the evaluation
    equityCurvePortfolioVar_raw = resultStruct.equityCurvePortfolioTT.Variables;
    equityCurvePortfolioVar = equityCurvePortfolioVar_raw(end-optimLookbackStep: end);
    
    % % calcluate return for the given  optimLookbackWindow
    startOptimPortValue = equityCurvePortfolioVar(1);
    endOptimPortValue = equityCurvePortfolioVar(end);
    cumPortfolioReturn = endOptimPortValue / startOptimPortValue;
    cumPortfolioReturn(isnan(cumPortfolioReturn)) = 0;
    
    Fval = -cumPortfolioReturn;
    clearvars -except Fval


end
%---------------------------------------------------------------------------------------


