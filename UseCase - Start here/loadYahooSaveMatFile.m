clear
clc
tic
marketData = MarketData;
marketData = marketData.loadSymbolMCapRef;
toc
%%

tic
marketData = marketData.loadDataFromYahoo
toc

%% tic
marketData.saveDataToMatFile;
toc
%% 

head(marketData.openPrice)
tail(marketData.openPrice)
