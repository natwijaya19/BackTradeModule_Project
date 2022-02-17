classdef TradeSignal
    %TradeSignal - TradeSignal class to contain parameter to generate
    % trading signal for a specific strategty both proven or under research
    %   
    % Input arguments
    %   nDayBackShift - nDayBackShift should be >= 1. If it is <1 then
    %   forward looking bias occurs
    % 
    % 
    % Output arguments
    % 
    % 
    % 
    % 
    % 
    % Mehtods

    properties
%         liquidityVolumeMALookback 
%         liquidityVolumeMAThreshold 
%         liquidityValueMALookback 
%         liquidityValueeMAThreshold 
%         liquidityNDayVolumeValueBuffer 
%         momentumPriceMALookback 
%         momentumPriceMAToCloseThreshold 
%         momentumPriceRetLowToCloseLookback 
%         momentumPriceRetLowToCloseThreshold 
%         momentumPriceRetLowToCloseNDayBuffer 
%         liquidityMomentumSignalBuffer 
%         cutLossHighToCloseNDayLookback 
%         cutLossHighToCloseMaxPct 
%         nDayBackShift 

        liquidityVolumeMALookback {mustBeInteger, mustBeGreaterThan(liquidityVolumeMALookback,0)}
        liquidityVolumeMAThreshold {mustBeGreaterThan(liquidityVolumeMAThreshold,0)}
        liquidityValueMALookback {mustBeInteger, mustBeGreaterThan(liquidityValueMALookback,0)}
        liquidityValueeMAThreshold {mustBeGreaterThan(liquidityValueeMAThreshold,0)}
        liquidityNDayVolumeValueBuffer {mustBeInteger, mustBeGreaterThan(liquidityNDayVolumeValueBuffer,0)}
        momentumPriceMALookback {mustBeInteger, mustBeGreaterThan(momentumPriceMALookback,0)}
        momentumPriceMAToCloseThreshold {mustBeGreaterThan(momentumPriceMAToCloseThreshold,0)}
        momentumPriceRetLowToCloseLookback {mustBeInteger, mustBeGreaterThan(momentumPriceRetLowToCloseLookback,0)}
        momentumPriceRetLowToCloseThreshold {mustBeGreaterThan(momentumPriceRetLowToCloseThreshold,0)}
        momentumPriceRetLowToCloseNDayBuffer {mustBeInteger, mustBeGreaterThan(momentumPriceRetLowToCloseNDayBuffer,0)}
        liquidityMomentumSignalBuffer {mustBeInteger, mustBeGreaterThan(liquidityMomentumSignalBuffer,0)}
        cutLossHighToCloseNDayLookback {mustBeInteger, mustBeGreaterThan(cutLossHighToCloseNDayLookback,0)}
        cutLossHighToCloseMaxPct {mustBeGreaterThan(cutLossHighToCloseMaxPct,0)}
        nDayBackShift {mustBeGreaterThan(nDayBackShift,1)}

%         tradingSignalParameter

    end

    properties (SetAccess = private)
        tradingSignalTT timetable
        tradingSignalParameterTT timetable
    end

    methods
        function obj = TradeSignal(inputArg)
            %TradeSignal Construct an instance of this class

            % transfer input arguments to properties variables
            obj.liquidityVolumeMALookback = inputArg(:,1);
            obj.liquidityVolumeMAThreshold = inputArg(:,2);
            obj.liquidityValueMALookback = inputArg(:,3);
            obj.liquidityValueeMAThreshold = inputArg(:,4);
            obj.liquidityNDayVolumeValueBuffer = inputArg(:,5);
            obj.momentumPriceMALookback = inputArg(:,6);
            obj.momentumPriceMAToCloseThreshold = inputArg(:,7);
            obj.momentumPriceRetLowToCloseLookback = inputArg(:,8);
            obj.momentumPriceRetLowToCloseThreshold = inputArg(:,9);
            obj.momentumPriceRetLowToCloseNDayBuffer = inputArg(:,10);
            obj.liquidityMomentumSignalBuffer = inputArg(:,11);
            obj.cutLossHighToCloseNDayLookback = inputArg(:,12);
            obj.cutLossHighToCloseMaxPct = inputArg(:,13);
            obj.nDayBackShift = inputArg(:,14);

%             obj.tradingSignalParameter = inputArg;


        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end