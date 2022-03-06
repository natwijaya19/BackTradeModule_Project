function tradeSignal = tradeSignalShortMomFcn(paramInput, dataInput)

% tradeSignalShortMomFcn generate trading signal and is core of the
% strategy

%% argument validation
arguments
    paramInput {mustBeNumeric}
    dataInput cell

end
%% setUp dataInput
% dataInput = dataClean;

%=======================================================================

%% setup the params

% % dummy paramInput
% x = [
%     40  %1
%     200 %2
%     5   %3
%     5   %4
%     10  %5
%     8   %6
%     120 %7
%     20  %8
%     5   %9
%     8   %10
%     5   %11
%     ];

%% Transfer input values to each variables. All variables are converted from
% integer value in optimization adjusted to the suitable unit

x = paramInput ; % TODO remove comment when final

volumeMATreshold = x(1)/100 ; % input #1
volumeMALookback = x(2) ; % input #2
valueThreshold = x(3)*10^7 ; % input #3 in Rp hundreds million
valueLookback = x(4) ; % input #4 nDays
volumeValueBufferDays = x(5) ; % input #5
priceRetLowCloseThresh = x(6)/100 ; % input #6
priceMAThreshold = x(7)/100 ; % input #7
priceMALookback = x(8) ; % input #8
priceVolumeValueBufferDays = x(9) ; % input #9
cutLossLookback = x(10) ; % input #10
cutLossPct = x(11)/100 ; % input #11

%=======================================================================

%% Signal from higher volume than historical volume MA
volumeMALookback;
volumeMATreshold;

volumeTT = dataInput{5};
volumeMA = movmean (volumeTT.Variables, [volumeMALookback 0], 1, 'omitnan');
volumeMA(isnan(volumeMA)) = 0;
volumeMA(isinf(volumeMA)) = 0;

volumeSignal = volumeTT.Variables > (volumeMA *volumeMATreshold);
volumeSignal(isnan(volumeSignal)) = 0;
volumeSignal(isinf(volumeSignal)) = 0;

% % check
% signal = sum(volumeSignal,2);
% barFig = bar(signal);
% title("volumeSignal")

clear volumeMA volumeTT
%=======================================================================

%% Signal value threshold
closePriceTT = dataInput{4};
volumeTT = dataInput{5};
valueThreshold;
valueLookback;

tradeValue = closePriceTT.Variables .* volumeTT.Variables ;
valueMA = movmean (tradeValue, [valueLookback 0], 1, 'omitnan');
valueMA(isnan(valueMA)) = 0;
valueMA(isinf(valueMA)) = 0;

valueSignal = valueMA > valueThreshold ;
clear valueMA tradeValue

% % check
% signal = sum(valueSignal,2);
% barFig = bar(signal);
% title("valueSignal")

clear volumeMA volumeTT closePriceTT tradeValue valueMA
%=======================================================================

%% Volume value buffer days
volumeValueBufferDays ;

volumeValueSignal = volumeSignal .* valueSignal;
volumeValueBufferSignal = movmax(volumeValueSignal,[volumeValueBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(volumeValueBufferSignal,2);
% barFig = bar(signal);
% title("volumeValueBufferSignal")

clear volumeValueSignal valueSignal

%=======================================================================

%% Signal price return from low to close
priceRetLowCloseThresh;

lowPriceTT = dataInput{3};
closePriceTT = dataInput{4};

priceRetLowClose = (closePriceTT.Variables ./ lowPriceTT.Variables) -1 ;
priceRetLowClose(isnan(priceRetLowClose)) = 0;
priceRetLowClose(isinf(priceRetLowClose)) = 0;

priceRetLowCloseSignal = priceRetLowClose > priceRetLowCloseThresh;


% % check
% signal = sum(priceRetLowCloseSignal,2);
% barFig = bar(signal);
% title("priceRetLowCloseSignal")

clear lowPriceTT closePriceTT priceRetLowClose
%=======================================================================

%% price MA signal
priceMALookback;
priceMAThreshold;
closePriceTT = dataInput{4};

priceMA = movmean (closePriceTT.Variables, [priceMALookback, 0], 1, 'omitnan');
priceMA(isnan(priceMA)) = 0;
priceMA(isinf(priceMA)) = 0;

priceMASignal = closePriceTT.Variables > (priceMA .* priceMAThreshold);

% % check
% signal = sum(priceMASignal,2);
% barFig = bar(signal);
% title("priceMASignal")

clear closePriceTT volumeTT priceMA

%=======================================================================

%% price volume value buffer days
priceVolumeValueBufferDays;

priceVolumeValueBuffer =  volumeValueBufferSignal .* priceRetLowCloseSignal .* priceMASignal;

priceVolumeValueBufferSignal = movmax(priceVolumeValueBuffer,[priceVolumeValueBufferDays, 0], 1, 'omitnan');

% % check
% signal = sum(priceVolumeValueBufferSignal,2);
% barFig = bar(signal);
% title("priceVolumeValueBufferSignal")

%=======================================================================

%% cut loss signal
cutLossLookback;
cutLossPct;

highPriceTT = dataInput{2};
closePriceTT = dataInput{4};

lastHighPrice = movmax(highPriceTT.Variables ,[cutLossLookback, 0], 1, 'omitnan');
lastHighPrice(isnan(lastHighPrice)) = 0;
lastHighPrice(isinf(lastHighPrice)) = 0;

LastHightoCloseRet = (closePriceTT.Variables ./ lastHighPrice) -1 ;
cutlossSignal = LastHightoCloseRet > (-cutLossPct);

% % check
% signal = sum(cutlossSignal,2);
% barFig = bar(signal);
% title("cutlossSignal")

clearvars highpriceTT closePriceTT LastHightoCloseRet lastHighPrice

%=======================================================================

%% Pre final signal (not yet 1 step lag shifted to avoid look ahead bias)
finalSignal = priceVolumeValueBufferSignal .* cutlossSignal;

% % check
% signal = sum(preFinalSignal,2);
% barFig = bar(signal);
% title("preFinalSignal")

%=======================================================================

%% Warming up or initialization days
lookbackArray = [volumeMALookback, priceMALookback, cutLossLookback] ;
warmingUpPeriod = max(lookbackArray) ;
finalSignal (1:warmingUpPeriod, :) = 0 ;

% % check
% signal = sum(finalSignal,2);
% barFig = bar(signal);
% title("finalSignal")

%=======================================================================

%% transfer to the output variable
tradeSignal = dataInput{1};
tradeSignal.Variables = finalSignal;

symbols = tradeSignal.Properties.VariableNames ;
symbols = strrep(symbols,"_open","_signal") ;
tradeSignal.Properties.VariableNames  = symbols ;

%=======================================================================

%% end of function, remove intermediary variables

clearvars -except tradeSignal

end