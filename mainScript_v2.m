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
wfaTester.wfaSetUp = wfaTester.wfaSetUp.prepare  
wfaTester.wfaSetUp.nWalk = 4;
wfaTester.wfaSetUp.nstepTest = 10;
wfaTester.wfaSetUp.nstepTrain = 60;



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

% portretCumret = ret2tick(wfaOptimStructOut.btResultStruct.dailyNetRetPortfolioTT);
% x = portretCumret.Time ;
% y = portretCumret.Variables;
% plot(x,y)
%% save the results in matfile


%% save the results in excel

