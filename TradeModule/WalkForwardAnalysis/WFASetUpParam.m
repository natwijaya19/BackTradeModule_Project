classdef WFASetUpParam
    %WFASetUp is to store all set up required to to a walk-forward analysis
    %   Detailed explanation goes here
    
    properties
        % WFA specific set up
        nWalk = 2 ; % Number of walk for the whole walk forwad
        lookbackUB = 300; % lookback upper bound
        nstepTrain = 60; % Number of step for training datastasket
        nstepTest = 20; % Number of step for testing dataset
        
        % btEngineSetUp
        tradingCost = [0.15/100, 0.25/100];
        maxCapAllocation = 0.2;
        
        % optimization set up
        maxFcnEval = 300;

        % nlConstParam
        maxDDThreshold = -15/100;
        minPortRet = 1.05;
        minDailyRetThreshold = -20/100;
        minLast20DRetThreshold = -5/100;
        minLast60DRetThreshold = 0;
        minLast200DRetThreshold = 0;

        
    end

    properties (SetAccess = private)
    lbubConst
        
    end
    
    methods
        
        function obj = prepare(obj)
        ubLookback = obj.lookbackUB;
        
        obj.lbubConst = [            % open the array
            1,  ubLookback;        % liquidityVolumeMALookback = paramInput(1);
            1,  10^6;               % liquidityVolumeMAThreshold = paramInput(2) * 100; % 100 share per lot
            1,  40;        %liquidityVolumeMANDayBuffer = paramInput(3) 
            1,  ubLookback;        % liquidityValueMALookback  = paramInput(4);
            1,  10^6;              % liquidityValueMAThreshold  = paramInput(5)* 10^6; % multiplication of Rp 1 million 
            1,  40;             %liquidityValueMANDayBuffer = paramInput(6)
            1,  40           % liquidityNDayVolumeValueBuffer = paramInput(7);
            1,  ubLookback     % momentumPriceMALookback = paramInput(8);
            0,  500            % momentumPriceMAToCloseThreshold = paramInput(9); % in percentage
            0,  40       % momentumPriceRetLowToCloseLookback = paramInput(10);
            0,  200             % momentumPriceRetLowToCloseThreshold = paramInput(11); % in percentage
            1,  40              % momentumPriceRetLowToCloseNDayBuffer = paramInput(12);
            1,  40              % liquidityMomentumSignalBuffer = paramInput(13);
            0,  60            % cutLossHighToCloseNDayLookback = paramInput(14);
            0,  10             % cutLossHighToCloseMaxPct = paramInput(15); % in percentage
            1,  1        % nDayBackShift = paramInput(16);
            ] ;                 % close the array

        
        
        end
    end
    
end

