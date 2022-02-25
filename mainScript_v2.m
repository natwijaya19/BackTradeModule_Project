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
toc
%% load data from yahoo finance
% tic
% wfaTester = wfaTester.loadDataFromYahoo;
% toc
%% load priceVolume data from matFile
tic
wfaTester = wfaTester.loadDataFromMatFile;
toc
%% calculate mktCap data
tic
wfaTester= wfaTester.classifyMktCap;
toc

%% test clean price volume data
% tic
% wfaTester = wfaTester.cleanMktData;
% toc

%% run the signalParam optimization
% setup the wfaParameters
wfaTester.wfaSetUp.nstepTest = 3*20;
wfaTester.wfaSetUp.nstepTrain = wfaTester.wfaSetUp.nstepTest*8;
% wfaTester.wfaSetUp.nWalk = 1;

wfaTester.wfaSetUp

%% 

% optimize the signalParam in trainDataset

wfaTester = wfaTester.runWalkForward;


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


%% save the results in matfile


%% save the results in excel

