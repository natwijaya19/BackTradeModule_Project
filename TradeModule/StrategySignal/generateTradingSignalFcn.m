function tradingSignalOut = generateTradingSignalFcn (dataInput, tradingSignalParameter)
%generateTradingSignalFcn to generate signal for trading strategy
%
% USAGE:
%       tradingSignalOut = generateTradingSignalFcn (dataInput, tradingSignalParameter)
%
% Input arguments:
%     
    % dataInput struct - consist of openPrice, highPrice, lowPrice,
    %                       closePrice, volume.
    % liquidityVolumeMALookback 
    % liquidityVolumeMAThreshold 
    % liquidityValueMALookback 
    % liquidityValueeMAThreshold 
    % liquidityNDayVolumeValueBuffer 
    % momentumPriceMALookback 
    % momentumPriceMAToCloseThreshold 
    % momentumPriceRetLowToCloseLookback 
    % momentumPriceRetLowToCloseThreshold 
    % momentumPriceRetLowToCloseNDayBuffer 
    % liquidityMomentumSignalBuffer 
    % cutLossHighToCloseNDayLookback 
    % cutLossHighToCloseMaxPct 
    % nDayBackShift 

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


%% parameter preparation
%---------------------------------------------------------------------------
% sample 
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
%---------------------------------------------------------------------------
% parameter preparation
paramInput = tradingSignalParameter; % param array transfer

liquidityVolumeMALookback = paramInput(1);
liquidityVolumeMAThreshold = paramInput(2) / 100;
liquidityVolumeMANDayBuffer = paramInput(3); 
liquidityValueMALookback  = paramInput(4);
liquidityValueMAThreshold  = paramInput(5) / 100;
liquidityValueMANDayBuffer = paramInput(6);
liquidityNDayVolumeValueBuffer = paramInput(7);
momentumPriceMALookback = paramInput(8);
momentumPriceMAToCloseThreshold = paramInput(9) / 100;
momentumPriceRetLowToCloseLookback = paramInput(10);
momentumPriceRetLowToCloseThreshold = paramInput(11) / 100;
momentumPriceRetLowToCloseNDayBuffer = paramInput(12);
liquidityMomentumSignalBuffer = paramInput(13);
cutLossHighToCloseNDayLookback = paramInput(14);
cutLossHighToCloseMaxPct = paramInput(15) / 100;
nDayBackShift = paramInput(16);

%-----------------------------------------------------------------------------------------


% argument validation
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
liquidityVolumeMALookback;
liquidityVolumeMAThreshold;
liquidityVolumeMANDayBuffer;
volumeMA = movmean(volume.Variables, [liquidityValueMALookback, 0], 1);
signalVolumeMA = volumeMA > liquidityVolumeMAThreshold;
signalVolumeMABuffer = movmax(signalVolumeMA, [liquidityVolumeMANDayBuffer , 0], 1);

clear volumeMA signalVolumeMA

%check
a = sum(signalVolumeMABuffer,2);
% b = max(a)
% c = sum(a)
%-----------------------------------------------------------------------------------------

%% liquidity  on value signal
liquidityValueMALookback;
liquidityValueMAThreshold;
liquidityValueMANDayBuffer ;

valueVar = volume.Variables .* closePrice.Variables;
valueMA = movmean(valueVar, [liquidityValueMALookback, 0], 1);
SignalvalueMA = valueMA > liquidityValueMAThreshold;
SignalvalueMABuffer =  movmax(SignalvalueMA, [liquidityValueMANDayBuffer, 0], 1);

clear valueMA SignalvalueMA valueVar

%check
a = sum(SignalvalueMABuffer,2);
% b = max(a)
% c = sum(a)
%-----------------------------------------------------------------------------------------


%% liquidity NDay Volume Value Buffer
liquidityNDayVolumeValueBuffer;

signalVolumeValue = signalVolumeMABuffer .* SignalvalueMABuffer;
signalVolumeValueBuffer = movmax(signalVolumeValue, [liquidityNDayVolumeValueBuffer, 0], 1) ;

clear signalVolumeValue

%check
a = sum(signalVolumeValueBuffer,2);
% b = max(a)
% c = sum(a)
%-----------------------------------------------------------------------------------------


%% momentum closePrice MA
momentumPriceMALookback;
momentumPriceMAToCloseThreshold;
closePriceMA = movmean(closePrice.Variables, [momentumPriceMALookback, 0], 1);
signalClosePriceMA =  closePrice.Variables > closePriceMA;

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
lowToClosePriceRet = (lowPriceShifted ./ closePrice.Variables)-1 ;
lowToClosePriceRet(1:momentumPriceRetLowToCloseLookback,:) = 0 ;

signalLowToClose = lowToClosePriceRet > momentumPriceRetLowToCloseThreshold;
signalLowToCloseNDayBuffer = movmax(signalLowToClose,...
                            [momentumPriceRetLowToCloseNDayBuffer, 0], 1);

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
                                [liquidityMomentumSignalBuffer, 0], 1) ;

%check
% a = sum(signalLiquidityMomentumBuffer,2);
% b = max(a)
% c = sum(a)
%------------------------------------------------------------------------------------------


%% cut loss signal
cutLossHighToCloseNDayLookback ;
cutLossHighToCloseMaxPct ;

lastHighPrice = movmax(highPrice.Variables, [cutLossHighToCloseNDayLookback, 0], 1);
lastHighToLastClosePriceRet = (closePrice.Variables ./ lastHighPrice) - 1;
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
                liquidityVolumeMALookback
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
tradingSignalOut = openPrice;
tradingSignalOut.Variables = FinalSignal;
symbols = tradingSignalOut.Properties.VariableNames;
symbols = strrep(symbols,"_open", "");
tradingSignalOut.Properties.VariableNames = symbols;

clear symbols
%------------------------------------------------------------------------------------------

%check tradingSignalOut
a = sum(FinalSignal,2);
b = max(a);
c = sum(a);

clearvars -except tradingSignalOut

% end of of function
end
