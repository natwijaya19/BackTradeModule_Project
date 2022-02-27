% this script shows the typical workflow of the trading research by using
% WFA methods
%
% set up input parameters can be done from the following class. Use Ctrl+D to go the file:
%     - WFASetUpParam;
%     - MarketData;
%

%% start from the beginning
clear
clc

%% instantiate the WalkForwardEngine as wfaTester

wfaTester = WalkForwardEngine;


%% load symbols reference from an excel file
tic
wfaTester = wfaTester.loadSymbols;
tLoadSym = toc
%% load data from yahoo finance
% tic
% wfaTester = wfaTester.loadDataFromYahoo;
% tLoadYahoo = toc
%% load priceVolume data from matFile
tic
wfaTester = wfaTester.loadDataFromMatFile;
tLoadMatFile = toc
%% calculate mktCap data
tic
wfaTester= wfaTester.classifyMktCap;
tClassifyMCap = toc

%% test clean price volume data
% tic
% wfaTester = wfaTester.cleanMktData;
% tCleanMktData = toc

%% run the signalParam optimization
% setup the wfaParameters
tic

wfaTester.wfaSetUp.maxFcnEval = 780;
wfaTester.wfaSetUp.nWalk = 16;
wfaTester.wfaSetUp.nstepTest = 20;
wfaTester.wfaSetUp.nstepTrain = 80;
wfaTester.wfaSetUp.lookbackUB = 250;
wfaTester.wfaSetUp.maxDDThreshold = -20/100;
wfaTester.wfaSetUp.minPortRet = 1.2;
wfaTester.wfaSetUp.minDailyRetThreshold = -35/100;
wfaTester.wfaSetUp.minLast20DRetThreshold = -20/100;
wfaTester.wfaSetUp.minLast60DRetThreshold = -10/100;
wfaTester.wfaSetUp.minLast200DRetThreshold = +0/100;

wfaTester.wfaSetUp = wfaTester.wfaSetUp.prepare ;

marketData = wfaTester.marketData
wfaSetUpParam = wfaTester.wfaSetUp


tOptimParam = toc
%%

% optimize the signalParam in trainDataset

% wfaTester = wfaTester.runWalkForward;


% generate signal and return in testDataset





%% evaluate the strategy performance
%
% Min max average returns on daily,  monthly,  quarterly, and yearly.
%
% Top 10 and bottom 10 returns by symbols.
%
% Trading costs
% Slippage costs
% MaxDD
%
% Plot line
% Equity curve: portfolio, nSignalDaily, top 3 and most bottom 3 symbols equity curve
% Plot of cash vs invested asset value
%
% Histogram: monthly and daily returns histogram
%%
% figure
% tiledlayout(2,2)
%
% %tile [1,1]
% nexttile
% equityCurvePortfolioTrain = wfaOptimStructOut.btResultTrainSet.equityCurvePortfolioTT;
% timeCol = equityCurvePortfolioTrain.Time;
% trainPlot = semilogy(timeCol, equityCurvePortfolioTrain.Variables);
% title("equityCurvePortfolioTrainSet")
% % axis([timeCol(1) timeCol(end)])
%
% %tile [1,2]
% nexttile
% equityCurvePortfolioTest = wfaOptimStructOut.btResultTestSet.equityCurvePortfolioTT;
% timeCol = equityCurvePortfolioTest.Time;
% testPlot = plot(timeCol , equityCurvePortfolioTest.Variables);
% title("equityCurvePortfolioTestSet")
% % axis([timeCol(1) timeCol(end)])
%
% %tile [2,1]
% nexttile
% tradingSignalTrainSet = wfaOptimStructOut.tradingSignalTrainSet;
% nDailyTradingSignalTrain = sum(tradingSignalTrainSet.Variables,2);
% trainBar = bar(tradingSignalTrainSet.Time, nDailyTradingSignalTrain);
% title("nDailyTradingSignalTrain")
%
% %tile [2,2]
% nexttile
% tradingSignalTestSet = wfaOptimStructOut.tradingSignalTestSet;
% nDailyTradingSignalTest = sum(tradingSignalTestSet.Variables,2);
% testBar = bar(tradingSignalTestSet.Time, nDailyTradingSignalTest);
% title("nDailyTradingSignalTest")

%%

% maxDDTrainSet = maxdrawdown(equityCurvePortfolioTrain.Variables);
% maxDDTestSet = maxdrawdown(equityCurvePortfolioTest.Variables);

%%
%% save the results in matfile


%% save the results in excel

