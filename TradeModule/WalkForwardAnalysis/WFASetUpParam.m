classdef WFASetUpParam
    %WFASetUp is to store all set up required to to a walk-forward analysis
    %   Detailed explanation goes here

    properties
        % WFA specific set up
        nWalk = 1 ; % Number of walk for the whole walk forwad
        lookbackUB = 300; % lookback upper bound
        nstepTrain = 60; % Number of step for training datastasket
        nstepTest = 20; % Number of step for testing dataset

        % btEngineSetUp
        tradingCost = [0.15/100, 0.25/100];
        maxCapAllocation = 0.25;

        % optimization set up
        maxFcnEval = 840;

        % nlConstParam
        maxDDThreshold = -15/100;
        minPortRet = 1.2;
        minDailyRetThreshold = -35/100;
        minLast20DRetThreshold = -20/100;
        minLast60DRetThreshold = -15/100;
        minLast200DRetThreshold = 0/100;

    end

    properties (SetAccess = private)
        lbubConst

    end

    methods

        function obj = prepare(obj)
            ubLookback = obj.lookbackUB;

            obj.lbubConst = [            % open the array
                5,  10;              %liquidityVolumeShortMALookback = paramInput(1);
                200,ubLookback;      %liquidityVolumeLongMALookback = paramInput(2);
                10, 400;               % liquidityVolumeMAThreshold = paramInput(3) * % percentage short MA to long MA
                20, 40;                 %liquidityVolumeMANDayBuffer = paramInput(4)
                1,  100;        % liquidityValueMALookback  = paramInput(5);
                100,  10^5;              % liquidityValueMAThreshold  = paramInput(6)* 10^6; % multiplication of Rp 1 million
                1,  30;             %liquidityValueMANDayBuffer = paramInput(7)
                1,  30              % liquidityNDayVolumeValueBuffer = paramInput(8);
                1,  30          % momentumPriceMALookback = paramInput(9);
                40, 400            % momentumPriceMAToCloseThreshold = paramInput(10); % in percentage
                0,  10              % momentumPriceRetLowToCloseLookback = paramInput(11);
                0,  50             % momentumPriceRetLowToCloseThreshold = paramInput(12); % in percentage
                1,  20              % momentumPriceRetLowToCloseNDayBuffer = paramInput(13);
                1,  20              % liquidityMomentumSignalBuffer = paramInput(14);
                1,  10            % cutLossHighToCloseNDayLookback = paramInput(15);
                0,  10             % cutLossHighToCloseMaxPct = paramInput(16); % in percentage
                1,  1               % nDayBackShift = paramInput(17);
                ] ;                 % close the array

        end
    end

end

