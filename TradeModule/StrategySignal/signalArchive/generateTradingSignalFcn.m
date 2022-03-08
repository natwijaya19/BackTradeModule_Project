function tradingSignalTTOut = generateTradingSignalFcn (dataInput, tradingSignalParameter)
%generateTradingSignalFcn to generate signal for trading strategy
%
% USAGE:
%       tradingSignalOut = generateTradingSignalFcn (dataInput, tradingSignalParameter)
%
% Input arguments:
%
% dataInput struct - consist of openPrice, highPrice, lowPrice, closePrice, volume.
% liquidityVolumeShortMALookback = paramInput(1);
% liquidityVolumeLongMALookback = paramInput(2);
% liquidityVolumeMAThreshold = paramInput(3) / 100 ; % percentage from LB to UB
% liquidityVolumeMANDayBuffer = paramInput(4);
% liquidityValueMALookback  = paramInput(5);
% liquidityValueMAThreshold  = paramInput(6)* 10^6; % multiplication of Rp 1 million
% liquidityValueMANDayBuffer = paramInput(7);
% liquidityNDayVolumeValueBuffer = paramInput(8);
% momentumPriceMALookback = paramInput(9);
% momentumPriceMAToCloseThreshold = paramInput(10) / 100; % in percentage
% momentumPriceRetLowToCloseLookback = paramInput(11);
% momentumPriceRetLowToCloseThreshold = paramInput(12) / 100; % in percentage
% momentumPriceRetLowToCloseNDayBuffer = paramInput(13);
% liquidityMomentumSignalBuffer = paramInput(14);
% cutLossHighToCloseNDayLookback = paramInput(15);
% cutLossHighToCloseMaxPct = paramInput(16) / 100; % in percentage
% nDayBackShift = paramInput(17) ;

% preparation
%======================================================================================

%% data preparation
%%TODO to be removed or commented
% path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project\DataInput";
% fileName = "PriceVolumeInput.mat";
% fullFileName = fullfile(path, fileName);
% dataInput = load(fullFileName); % struct data transfer

openPrice = dataInput.openPrice;
highPrice = dataInput.highPrice;
lowPrice = dataInput.lowPrice;
closePrice = dataInput.closePrice;
volume = dataInput.volume;

clearvars dataInput

%% parameter preparation
%---------------------------------------------------------------------------
% sample
% tradingSignalParameter =[             % open the array
%                             5         %liquidityVolumeShortMALookback = paramInput(1);
%                             80        % liquidityVolumeMALookback = paramInput(2);
%                             0.1        % liquidityVolumeMAThreshold = paramInput(3);
%                             3       %liquidityVolumeMANDayBuffer = paramInput(4)
%                             80        % liquidityValueMALookback  = paramInput(5);
%                             0.1        % liquidityValueeMAThreshold  = paramInput(6);
%                             3       %liquidityValueMANDayBuffer = paramInput(7)
%                             20        % liquidityNDayVolumeValueBuffer = paramInput(8);
%                             20        % momentumPriceMALookback = paramInput(9);
%                             1.2        % momentumPriceMAToCloseThreshold = paramInput(10);
%                             1        % momentumPriceRetLowToCloseLookback = paramInput(11);
%                             0.05        % momentumPriceRetLowToCloseThreshold = paramInput(12);
%                             3        % momentumPriceRetLowToCloseNDayBuffer = paramInput(13);
%                             5        % liquidityMomentumSignalBuffer = paramInput(14);
%                             5        % cutLossHighToCloseNDayLookback = paramInput(15);
%                             0.05        % cutLossHighToCloseMaxPct = paramInput(16);
%                             1        % nDayBackShift = paramInput(17);
%                                 ] ;  % close the array
%---------------------------------------------------------------------------
%% parameter preparation
paramInput = tradingSignalParameter; % param array transfer

liquidityVolumeShortMALookback = paramInput(1);
liquidityVolumeLongMALookback = paramInput(2);
liquidityVolumeMAThreshold = paramInput(3) / 100 ; % percentage from LB to UB
liquidityVolumeMANDayBuffer = paramInput(4);
liquidityValueMALookback  = paramInput(5);
liquidityValueMAThreshold  = paramInput(6)* 10^6; % multiplication of Rp 1 million
liquidityValueMANDayBuffer = paramInput(7);
liquidityNDayVolumeValueBuffer = paramInput(8);
momentumPriceMALookback = paramInput(9);
momentumPriceMAToCloseThreshold = paramInput(10) / 100; % in percentage
momentumPriceRetLowToCloseLookback = paramInput(11);
momentumPriceRetLowToCloseThreshold = paramInput(12) / 100; % in percentage
momentumPriceRetLowToCloseNDayBuffer = paramInput(13);
liquidityMomentumSignalBuffer = paramInput(14);
cutLossHighToCloseNDayLookback = paramInput(15);
cutLossHighToCloseMaxPct = paramInput(16) / 100; % in percentage
nDayBackShift = paramInput(17) ;

%-----------------------------------------------------------------------------------------


%% argument validation
%TODO remove the %

%arguments
%     openPrice timetable
%     highPrice timetable
%     lowPrice timetable
%     closePrice timetable
%     volume timetable
%     tradingSignalParameter double
% end

value = nDayBackShift < 1;
if value
    error(message('finance:backtest:nDayBackShift must be greater than 0'));
end

%-----------------------------------------------------------------------------------------


%% liquidity on volume signal

liquidityVolumeShortMALookback ;
liquidityVolumeLongMALookback ;
liquidityVolumeMAThreshold;
liquidityVolumeMANDayBuffer;
volumeShortMA = movmean(volume.Variables, [liquidityVolumeShortMALookback, 0], 1,"omitnan");
volumeLongMA = movmean(volume.Variables, [liquidityVolumeLongMALookback, 0], 1,"omitnan");
volumeShortMA(isnan(volumeShortMA)) = 0;
volumeLongMA(isnan(volumeLongMA)) = 0;

signalVolume = volumeShortMA > (volumeLongMA*liquidityVolumeMAThreshold);
signalVolumeMABuffer = movmax(signalVolume, [liquidityVolumeMANDayBuffer , 0], 1,"omitnan");

clear volumeMA signalVolume

%check
% a = sum(signalVolumeMABuffer,2);
% b = max(a)
% c = sum(a)
%-----------------------------------------------------------------------------------------

%% liquidity  on value signal
liquidityValueMALookback;
liquidityValueMAThreshold;
liquidityValueMANDayBuffer ;

valueVar = volume.Variables .* closePrice.Variables;
valueMA = movmean(valueVar, [liquidityValueMALookback, 0], 1,"omitnan");
valueMA(isnan(valueMA)) = 0;
SignalvalueMA = valueMA > liquidityValueMAThreshold;
SignalvalueMABuffer =  movmax(SignalvalueMA, [liquidityValueMANDayBuffer, 0], 1,"omitnan");

clear valueMA SignalvalueMA valueVar

%check
% a = sum(SignalvalueMABuffer,2);
% b = max(a)
% c = sum(a)
%-----------------------------------------------------------------------------------------


%% liquidity NDay Volume Value Buffer
liquidityNDayVolumeValueBuffer;

signalVolumeValue = signalVolumeMABuffer .* SignalvalueMABuffer;
signalVolumeValueBuffer = movmax(signalVolumeValue, [liquidityNDayVolumeValueBuffer, 0], 1,"omitnan") ;

clear signalVolumeValue

% %check
% a = sum(signalVolumeValueBuffer,2);
% % b = max(a)
% % c = sum(a)
%-----------------------------------------------------------------------------------------


%% momentum closePrice MA
momentumPriceMALookback;
momentumPriceMAToCloseThreshold;
closePriceMA = movmean(closePrice.Variables, [momentumPriceMALookback, 0], 1,"omitnan");
closePriceMA(isnan(closePriceMA)) = 0;
signalClosePriceMA =  closePrice.Variables > momentumPriceMAToCloseThreshold*closePriceMA;

clear closePriceMA

%check
a = sum(signalClosePriceMA,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% momentum lowPrice to closePrice
momentumPriceRetLowToCloseLookback ;
momentumPriceRetLowToCloseThreshold ;
momentumPriceRetLowToCloseNDayBuffer ;

lowPriceShifted = backShiftFcn(lowPrice.Variables, momentumPriceRetLowToCloseLookback) ;
lowToClosePriceRet = (closePrice.Variables ./ lowPriceShifted  )-1 ;
lowToClosePriceRet(1:momentumPriceRetLowToCloseLookback,:) = 0 ;
lowToClosePriceRet(isnan(lowToClosePriceRet)) = 0;

signalLowToClose = lowToClosePriceRet > momentumPriceRetLowToCloseThreshold;
signalLowToCloseNDayBuffer = movmax(signalLowToClose,...
    [momentumPriceRetLowToCloseNDayBuffer, 0], 1,"omitnan");

clear lowPriceShifted lowToClosePriceRet signalLowToClose

%check
% a = sum(signalLowToCloseNDayBuffer,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% combine liquidity and momentum signal
signalLliquidityMomentum = signalVolumeValueBuffer .*...
    (signalClosePriceMA .* signalLowToCloseNDayBuffer);

% signal buffer on liquidity and momentum
liquidityMomentumSignalBuffer;
signalLiquidityMomentumBuffer = movmax(signalLliquidityMomentum,...
    [liquidityMomentumSignalBuffer, 0], 1,"omitnan") ;

%check
% a = sum(signalLiquidityMomentumBuffer,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% cut loss signal
cutLossHighToCloseNDayLookback ;
cutLossHighToCloseMaxPct ;

lastHighPrice = movmax(highPrice.Variables, [cutLossHighToCloseNDayLookback, 0], 1,"omitnan");
lastHighToLastClosePriceRet = (closePrice.Variables ./ lastHighPrice) - 1;
lastHighToLastClosePriceRet(isnan(lastHighToLastClosePriceRet)) = 0;
cutLossSignal = lastHighToLastClosePriceRet > (-cutLossHighToCloseMaxPct) ;

clear lastHighPrice lastHighToLastClosePriceRet

%check
% a = sum(cutLossSignal,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% combine signalLiquidityMomentumBuffer and cutLossSignal
signalCombineLiquidityMomentumCutLoss = signalLiquidityMomentumBuffer .* cutLossSignal ;

%check
% a = sum(signalCombineLiquidityMomentumCutLoss,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% nDayBackShiftFinalSignal
nDayBackShift;

signalNDayBackShifted = backShiftFcn(signalCombineLiquidityMomentumCutLoss, nDayBackShift);
%------------------------------------------------------------------------------------------


%% warm up no-signal
warmUpPeriod = [
    liquidityVolumeLongMALookback
    liquidityValueMALookback
    momentumPriceMALookback
    momentumPriceRetLowToCloseLookback
    cutLossHighToCloseNDayLookback
    nDayBackShift
    ];

warmUpPeriodMax = max(warmUpPeriod);
FinalSignal = signalNDayBackShifted;
FinalSignal(1:warmUpPeriodMax,:) = 0;
%------------------------------------------------------------------------------------------

%% final tradingSignalOut
tradingSignalTTOut = openPrice;
tradingSignalTTOut.Variables = FinalSignal;
symbols = tradingSignalTTOut.Properties.VariableNames;
symbols = strrep(symbols,"_open", "");
tradingSignalTTOut.Properties.VariableNames = symbols;

clear symbols
%------------------------------------------------------------------------------------------

%% check tradingSignalOut
% a = sum(FinalSignal,2);
% b = max(a);
% c = sum(a);

clearvars -except tradingSignalTTOut

% end of of function

end
