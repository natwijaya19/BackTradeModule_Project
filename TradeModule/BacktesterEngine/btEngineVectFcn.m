function resultStruct = btEngineVectFcn (dataInputBT, tradeSignalInput,...
    backShiftNDay, tradingCost, maxCapAllocation)

% backtesterEngineFcn generate output backtesting signal against price
%
% USAGE:
%
%       resultStruct = btEngineVectorizedFcn (dataStructInput, tradingSignal, tradingCost, maxCapAllocation)
%
% Input arguments
% dataStructInput struct - consist of openPrice and closePrice in timetable class
% tradingSignal timetable - tradingSIgnal in timetable
% tradingCosts timetable - tradingCost = [buyCost, sellCost]
% maxCapAllocPerSym double - max capital allocation per symbol in each day to
%   maintain diversification


%TODO to be removed or commented
% path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project\DataInput";
% fileName = "PriceVolumeInput.mat";
% fullFileName = fullfile(path, fileName);
% dataInput = load(fullFileName); % struct data transfer
%
% tradingSignalParameter =[               % open the array
%                             80        % liquidityVolumeMALookback = paramInput(1);
%                             0.1        % liquidityVolumeMAThreshold = paramInput(2);
%                             3       %liquidityVolumeMANDayBuffer = paramInput(3)
%                             80        % liquidityValueMALookback  = paramInput(4);
%                             0.1        % liquidityValueeMAThreshold  = paramInput(5);
%                             3       %liquidityValueMANDayBuffer = paramInput(6)
%                             20        % liquidityNDayVolumeValueBuffer = paramInput(7);
%                             20        % momentumPriceMALookback = paramInput(8);
%                             1.2        % momentumPriceMAToCloseThreshold = paramInput(9);
%                             1        % momentumPriceRetLowToCloseLookback = paramInput(10);
%                             0.05        % momentumPriceRetLowToCloseThreshold = paramInput(11);
%                             3        % momentumPriceRetLowToCloseNDayBuffer = paramInput(12);
%                             5        % liquidityMomentumSignalBuffer = paramInput(13);
%                             5        % cutLossHighToCloseNDayLookback = paramInput(14);
%                             0.05        % cutLossHighToCloseMaxPct = paramInput(15);
%                             1        % nDayBackShift = paramInput(16);
%                                 ] ;  % close the array
%

%==========================================================================

%% argument validation
arguments
    dataInputBT cell
    tradeSignalInput timetable
    backShiftNDay {mustBeNumeric, mustBePositive, mustBeInteger}
    tradingCost {mustBeNumeric, mustBePositive}
    maxCapAllocation {mustBeNumeric, mustBePositive}

end

%% data transfer
%TODO finalize the data transfer
openPrice = dataInputBT{1};
closePrice = dataInputBT{4};

symbols = string(closePrice.Properties.VariableNames);
symbols = strrep(symbols,"_close","");

maxCapAllocPerSym = maxCapAllocation;
buyCost = tradingCost(1);
sellCost = tradingCost(2);

% backShift the signal
tradingSignal = tradeSignalInput;
tradingSignal.Variables = backShiftFcn (tradeSignalInput.Variables , backShiftNDay);

clearvars dataStructInput tradeSignalInput
%------------------------------------------------------------------------

% data preparation
openPriceVar = openPrice.Variables;
openPriceVarString = string(openPriceVar);
openPriceVar = double(openPriceVarString);
openPriceVar(isnan(openPriceVar)) = 0;

closePriceVar = closePrice.Variables;
closePriceVarString = string(closePriceVar);
closePriceVar = double(closePriceVarString);
closePriceVar(isnan(closePriceVar)) = 0;

signal = tradingSignal;
signalVar = signal.Variables;
signalVarString = string(signalVar);
signalVar = double(signalVarString);
signalVar(isnan(signalVar)) = 0;

clearvars openPriceVarString closePriceVarString signalVarString
%--------------------------------------------------------------------------------------

% calculate number of asset with signal to buy
nSignalDaily = sum(signalVar,2);
%------------------------------------------------------------------------

% start of day (SOD): calclate max capital allocation to be invested and cash
maxCapAllocPerSym;
capAlloc = ones(numel(nSignalDaily),1);
capAlloc = capAlloc ./ nSignalDaily;
capAlloc(isinf(capAlloc)) = 0;
capAlloc(isnan(capAlloc)) = 0;

capAlloc(capAlloc > maxCapAllocPerSym) = maxCapAllocPerSym;
%------------------------------------------------------------------------


% calculate capitalAllocation in start of day to be invested to each symbols to buy and to sell.
%   equally weighted capital allocation is use used
capAllocPerSym = signalVar .* capAlloc;

sodTotalAsset = ones(numel(nSignalDaily),1);
sodInvestedCapitalPerSym = capAllocPerSym;
sodTotalInvestedCapital = sum(sodInvestedCapitalPerSym,2);
sodCash = sodTotalAsset - sum(sodInvestedCapitalPerSym,2);
%------------------------------------------------------------------------


%buySellPortion
% sz = size(signalVar);
% buySellPortion = zeros(sz)
buySellPortion = capAllocPerSym;
buySellPortion(2:end,:) = capAllocPerSym(2:end,:) - capAllocPerSym(1:end-1,:);
%------------------------------------------------------------------------


% invested value from BuyPortion
sodGrossBuyPortion = buySellPortion;
sodGrossBuyPortion(sodGrossBuyPortion < 0 ) = 0;

% sellCost from SellPortion
sodGrossSellPortion = buySellPortion;
sodGrossSellPortion(sodGrossSellPortion> 0 ) = 0;
sodGrossSellPortion = -1 .* sodGrossSellPortion;

% invested value from prevRemain
sz = size(signalVar);
sodPrevRemainPortion = zeros(sz);
sodPrevRemainPortion(2:end,:) = capAllocPerSym(1:end-1,:) - sodGrossSellPortion(2:end,:);
%------------------------------------------------------------------------


% calculate net invested value from buy portion at the end of day eodNetBuyPortion
% sodGrossBuyPortion will experience the effect of buyCost,
% dailyRet (closeToClosePriceRet) and slippageCost (closeToOpenPriceRet)
buyCost;
sodGrossBuyPortion;

% sodGrossBuyPortion contain both buyCostPortion and sodNetBuyPortion
sodNetBuyPortion = sodGrossBuyPortion ./ (1+buyCost);
sodNetBuyPortion(isnan(sodNetBuyPortion)) = 0;
buyCostPortion = sodGrossBuyPortion - sodNetBuyPortion;

% closeToClosePriceRet is dailyRet without slippage
closeToClosePriceRet = zeros(size(signalVar));
closeToClosePriceRet(2:end,:) = (closePriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToClosePriceRet(isnan(closeToClosePriceRet)) = 0;
closeToClosePriceRet(isinf(closeToClosePriceRet)) = 0;

%slippage priceRet from last trading day close price to open price in the start of day
closeToOpenPriceRet = zeros(size(signalVar));
closeToOpenPriceRet(2:end,:) = (openPriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToOpenPriceRet(isnan(closeToOpenPriceRet)) = 0;
closeToOpenPriceRet(isinf(closeToOpenPriceRet)) = 0;

% netPriceRet after slippage is closeToClosePriceRet minus by closeToOpenPrice
% netPriceRetAfterSlippage = closeToClosePriceRet - closeToOpenPrice
netPriceRetAfterSlippage = closeToClosePriceRet - closeToOpenPriceRet;

% eodNetBuyPortion at athe end of day is
eodNetBuyPortion = sodNetBuyPortion .* (1+netPriceRetAfterSlippage);

slippageCostOfSodNetBuyPortion = sodNetBuyPortion .* closeToOpenPriceRet;
dailySlippageCostOfSodNetBuyPortion = sum(slippageCostOfSodNetBuyPortion,2);
totalSlippageCostOfSodNetBuyPortion = sum(dailySlippageCostOfSodNetBuyPortion);

%------------------------------------------------------------------------


% calculate net invested value at the end of day from prevRemainPortion.
% prevRemainPortion will only have the effect of dailyRet (closeToClosePriceRet)
sodPrevRemainPortion;

% closeToClosePriceRet is dailyRet without slippage
closeToClosePriceRet = zeros(size(signalVar));
closeToClosePriceRet(2:end,:) = (closePriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToClosePriceRet(isnan(closeToClosePriceRet)) = 0;
closeToClosePriceRet(isinf(closeToClosePriceRet)) = 0;

eodPrevRemainPortion = sodPrevRemainPortion .*(1+closeToClosePriceRet);
%------------------------------------------------------------------------


% calculate sellCostPortion from sodGrossSellPortion. This portion will
% have the effect of slippage and sellCost. sellCost is the only cost will be
% included into the eod asset calc.
sodGrossSellPortion;
sellCost;

% slippageCost
% slippage priceRet from last trading day close price to open price in the start of day
%TODO remove NAN
closeToOpenPriceRet = zeros(size(signalVar));
closeToOpenPriceRet(2:end,:) = (openPriceVar(2:end,:) ./ closePriceVar(1:end-1,:)) - 1;
closeToOpenPriceRet(isnan(closeToOpenPriceRet)) = 0;
closeToOpenPriceRet(isinf(closeToOpenPriceRet)) = 0;

sodGrossSellPortionAtOpenPrice = sodGrossSellPortion .* (closeToOpenPriceRet+1);
sodNetSellPortionAfterSellCost = sodGrossSellPortionAtOpenPrice ./ (1+sellCost);

sellCostPortion = sodGrossSellPortionAtOpenPrice - sodNetSellPortionAfterSellCost;
totalDailySellCostPortion = sum(sellCostPortion,2);

slippageCostOfGrossSellPortion = sodGrossSellPortionAtOpenPrice - sodGrossSellPortion;
dailySlippageCostOfGrossSellPortion = sum(slippageCostOfGrossSellPortion,2);
totalSlippageCostOfGrossSellPortion = sum(dailySlippageCostOfGrossSellPortion);

%------------------------------------------------------------------------

% calculate end of day (EOD) invested capital
eodInvestedCapital = eodNetBuyPortion + eodPrevRemainPortion;
eodTotalInvestedCapital = sum(eodInvestedCapital,2);

% calculate total asset = invested capital + cash at the end of day (EOD)
eodCash = sodCash;
totalDailySellCostPortion;
eodTotalAsset = eodCash + eodTotalInvestedCapital - totalDailySellCostPortion;

% calculate daily return dailyRet
dailyNetRetPortfolio = (eodTotalAsset ./ sodTotalAsset) - 1;
dailyNetRetPortfolio = string(dailyNetRetPortfolio);
dailyNetRetPortfolio = double(dailyNetRetPortfolio);
dailyNetRetPortfolio (isnan(dailyNetRetPortfolio)) = 0;
dailyNetRetPortfolio (isinf(dailyNetRetPortfolio)) = 0;

timeCol = openPrice.Time;
nRow = size(nSignalDaily,1);
nCol = size(nSignalDaily,2);
sz = [nRow, nCol];
variableTypes = repmat({'double'},1, nCol);
variableNames = "dailyNetRetPortfolio";
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

dailyNetRetPortfolioTT = TT;
dailyNetRetPortfolioTT.Variables = dailyNetRetPortfolio;
resultStruct.dailyNetRetPortfolioTT = dailyNetRetPortfolioTT;


% equityCurvePortfolio
equityCurvePortfolio = ret2tick (dailyNetRetPortfolio);
equityCurvePortfolio(1,:) = [];
equityCurvePortfolio = string(equityCurvePortfolio);
equityCurvePortfolio = double(equityCurvePortfolio);
equityCurvePortfolio = fillmissing(equityCurvePortfolio, "previous");

% put equityCurvePortfolio into timetable
timeCol = openPrice.Time;
nRow = size(nSignalDaily,1);
nCol = size(nSignalDaily,2);
sz = [nRow, nCol];
variableTypes = repmat({'double'},1, nCol);
variableNames = "equityCurvePortfolio";
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

equityCurvePortfolioTT = TT;
equityCurvePortfolioTT.Variables = equityCurvePortfolio;
resultStruct.equityCurvePortfolioTT = equityCurvePortfolioTT;

%------------------------------------------------------------------------


% dailyNetRetPerSym can be calculated buy taking into account the
% sellCostPortion per symbol
eodInvestedCapitalPerSym = eodNetBuyPortion + eodPrevRemainPortion - sellCostPortion ;
dailyNetRetPerSym = (eodInvestedCapitalPerSym ./ sodInvestedCapitalPerSym) - 1 ;
dailyNetRetPerSym(isnan(dailyNetRetPerSym)) = 0;
dailyNetRetPerSym(isinf(dailyNetRetPerSym)) = 0;
%------------------------------------------------------------------------


% wrap up the result output packed in a data struct resultStruct
% assume 1 is invested at beginning o the signal
% dailyNetRetPerSym
timeCol = openPrice.Time;
nRow = size(openPriceVar,1);
nCol = size(openPriceVar,2);
variableTypes = repmat({'double'},1, nCol);
sz = [nRow, nCol];
variableNames = string(signal.Properties.VariableNames);
TT = timetable('Size', sz, 'VariableTypes', variableTypes,...
    'RowTimes', timeCol, 'VariableNames', variableNames);

dailyNetRetPerSymTT = TT;
dailyNetRetPerSymTT.Variables = dailyNetRetPerSym;
dailyNetRetPerSymTT.Properties.VariableNames = symbols;
resultStruct.dailyNetRetPerSymTT = dailyNetRetPerSymTT;

% equityCurvePerSym
equityCurvePerSym = ret2tick(dailyNetRetPerSym);
equityCurvePerSym(1,:) = [];
equityCurvePerSymTT = openPrice;
equityCurvePerSymTT.Variables = equityCurvePerSym;
equityCurvePerSymTT.Properties.VariableNames = symbols;
resultStruct.equityCurvePerSymTT = equityCurvePerSymTT;
%------------------------------------------------------------------------

% totalBuyCost
buyCostPortion;
DailyBuyCost = sum(buyCostPortion,2);
totalDailyBuyCost = DailyBuyCost .* equityCurvePortfolio;
totalBuyCost = sum(totalDailyBuyCost) ;
resultStruct.totalBuyCost = totalBuyCost;

% totalSellCost
sellCostPortion;
dailySellCost = sum(sellCostPortion,2);
totalDailySellCost =  dailySellCost .* equityCurvePortfolio;
totalSellCost = sum(totalDailySellCost);
resultStruct.totalSellCost = totalSellCost;

% totalSlippage
totalSlippageCost = totalSlippageCostOfSodNetBuyPortion + totalSlippageCostOfGrossSellPortion ;
resultStruct.totalSlippageCost = totalSlippageCost;

%------------------------------------------------------------------------

% TODO summary statistics


%%

clearvars -except resultStruct

end