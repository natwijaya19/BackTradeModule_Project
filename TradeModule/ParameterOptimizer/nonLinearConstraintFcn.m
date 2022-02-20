function [c, ceq] = nonLinearConstraintFcn (tradingSignalParam, dataStructInput,...
              optimLookbackStep, tradingCost, maxCapAllocation,...
              maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)
% 
% nonLinearConstraintFcn
% 
% USAGE:
%       Fval = nonLinearConstraintFcn (dataStructInput, tradingSignalParam,...
%               optimLookbackStep, tradingCost, maxCapAllocation,...
%               maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)
% 
% input argument:
%   tradingSignalParam      vector array    :   1xnVars
%   dataStructInput         struct          :   field openPrice, highPrice, lowPrice, 
%                                               highPrice and volume. All these data are in timetable               
%   optimLookbackStep       scalar          :   nStep lookback for total return calculation
%   maxDDThreshold          scalar          :   max acceptable drawdown
%   minPortfolioReturn               scalar          :   min acceptable return of
%                                               the portfolio for the optimLookbackStep period
%   minDailyRetThreshold    scalar          :   min acceptable dailyRet of the portfolio
%------------------------------------------------------------------------------------
% prepare data input
% tradingSignalParam = tradingSignalParameter;
% optimLookbackStep = 40;
% maxDDThreshold = -0.15;
% minPortfolioReturn = 1.15;
% minDailyRetThreshold = -0.20;

% generate signal
    tradingSignalOut = generateTradingSignalFcn (dataStructInput, tradingSignalParam);

% backtest the signal against the price
tradingSignalIn = tradingSignalOut;
resultStruct = btEngineVectorizedFcn (dataStructInput, tradingSignalIn,...
                tradingCost, maxCapAllocation);

% calculate equityCurve at for the evaluation
equityCurvePortfolioVar_raw = resultStruct.equityCurvePortfolioTT.Variables;
equityCurvePortfolioVar = equityCurvePortfolioVar_raw(end-optimLookbackStep: end);

% % calcluate return for the given  optimLookbackWindow minPortfolioReturn
startOptimPortValue = equityCurvePortfolioVar(1);
endOptimPortValue = equityCurvePortfolioVar(end);
cumPortfolioReturn = endOptimPortValue / startOptimPortValue;
cumPortfolioReturn(isnan(cumPortfolioReturn)) = 0;
cumPortfolioReturn(isinf(cumPortfolioReturn)) = 0;

% calculate maxDD for maxDDThreshold
maxDD = -maxdrawdown(equityCurvePortfolioVar);

% calculate dailyRet for minDailyRetThreshold
dailyRet = tick2ret(equityCurvePortfolioVar);
minDailyRet = min(dailyRet);


% formulate the constraints
c = [   maxDDThreshold - maxDD;
        minPortfolioReturn - cumPortfolioReturn;
        minDailyRetThreshold - minDailyRet];
ceq = [];

clearvars -except c eq

end
%------------------------------------------------------------------------------------