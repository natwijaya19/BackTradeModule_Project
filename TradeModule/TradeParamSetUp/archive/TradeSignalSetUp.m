classdef TradeSignalSetUp
    % TradeSignalSetUp is class to populate setup parameters to generate
    % trading signal
    % --------------------------------------------------------------------
    % Variable definition:
    % --------------------------------------------------------------------

    % liquidityVolumeNDayLookback: nDay lookback to calculate moving
    % average on volume data

    % liquidityVolumeMAThreshold: ratio of last day volume to volume MA 
    % liquidityValueLookback >> nDay lookback to calculate moving
    % average on value data

    % liquidityValueMAThreshold
    % liquidityVolumeValueNDayBuffer
    % momentumPriceRetLowToCloseDaily
    % momentumPriceRetLowToCloseDailyNDayBuffer
    % MomentumClosePriceMALookback
    % momentumPriceMAToClosePriceThreshold
    % signalBufferLookback
    % cutLossMaxPct
    % cutLossNDayLookback

    % nDayBackShift  >> should be > 1. It is number days signal shifter 
    % from previous dayt. The value should be greater 1. If it is lower 
    % than 1 than forward-looking bias occurrs
    %====================================================================

    %% Property definition
    properties
        liquidityVolumeNDayLookback (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(liquidityVolumeNDayLookback,0)}
        liquidityVolumeMAThreshold (:,1) double {mustBePositive}
        liquidityValueNDayLookback (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(liquidityValueNDayLookback,0)}
        liquidityValueMAThreshold (:,1) double {mustBePositive}
        liquidityVolumeValueNDayBuffer (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(liquidityVolumeValueNDayBuffer,0)}
        momentumPriceRetLowToCloseDailyThreshold (:,1) double {mustBePositive}
        momentumPriceRetLowToCloseDailyNDayBuffer (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(momentumPriceRetLowToCloseDailyNDayBuffer,0)}
        MomentumClosePriceMALookback (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(MomentumClosePriceMALookback,0)}
        momentumPriceMAToClosePriceThreshold (:,1) double {mustBePositive} = 0
        signalBufferLookback (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(signalBufferLookback,0)}
        cutLossMaxPct (:,1) double {mustBePositive} = 0
        cutLossNDayLookback (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(cutLossNDayLookback,0)}
        nDayBackShift (:,1) int32 {mustBeInteger,...
            mustBePositive, mustBeGreaterThan(nDayBackShift,0)}
        
    end

    methods
        function obj = TradeSignalSetUp(inputArgs)
            % TradeSignalSetUp Construct an instance of this class

            % Validate the inputArgs must be in size (:,nVar)
            nVar = 13;
            if size(inputArgs,2) ~= nVar
                error(message('TradeSignalSetUp:inputArgs~=nVar'))
            end
            
            % Transfer inputArgs value
            obj.liquidityVolumeNDayLookback = inputArgs(:,1);
            obj.liquidityVolumeMAThreshold = inputArgs(:,1);
            obj.liquidityValueNDayLookback = inputArgs(:,1);
            obj.liquidityValueMAThreshold = inputArgs(:,1);
            obj.liquidityVolumeValueNDayBuffer = inputArgs(:,1);
            obj.momentumPriceRetLowToCloseDailyThreshold = inputArgs(:,1);
            obj.momentumPriceRetLowToCloseDailyNDayBuffer = inputArgs(:,1);
            obj.MomentumClosePriceMALookback = inputArgs(:,1);
            obj.momentumPriceMAToClosePriceThreshold = inputArgs(:,1);
            obj.signalBufferLookback = inputArgs(:,1);
            obj.cutLossMaxPct = inputArgs(:,1);
            obj.cutLossNDayLookback = inputArgs(:,1);
            obj.nDayBackShift = inputArgs(:,1);
        end
    end
end