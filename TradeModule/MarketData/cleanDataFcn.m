function priceVolumeClean = cleanDataFcn (priceVolumeRaw)
% cleandataFcn is function to preprocess data
% 
% Preprocessing steps: 
%   - Rearrange symbol alphabetically
%   - Substitute and change non numeric data to numeric
%   - Fill missing data with the previous and next in timeseries data 
%   - Remove symbols or data column containing price changes larger than ARA & ARB limit 
% 
%% Preprocessing
% Transfer data
openPriceTT = priceVolumeRaw.openPrice;
highPriceTT = priceVolumeRaw.highPrice;
lowpPiceTT = priceVolumeRaw.lowPrice;
closePriceTT = priceVolumeRaw.closePrice;
volumeTT = priceVolumeRaw.volume;

% take only timeseries data based on the symbolsRef based

% number of symbol
symList = strrep(openPriceTT.Properties.VariableNames, "_open", "");
symList = sort(string(symList), "ascend");
nSym = numel (symList) ; 

symListOpenPrice = strcat(symList,"_open");
symListHighPrice = strcat(symList,"_high");
symListLowPrice = strcat(symList,"_low");
symListClosePrice = strcat(symList,"_close");
symListvolume = strcat(symList,"_volume");

%% Rearrange symbol alphabetcicaly
%--------------------------------------------------------------------------
% openprice
openPriceTT = openPriceTT(:,symListOpenPrice) ;

% highprice
highPriceTT = highPriceTT(:,symListHighPrice) ;

% lowprice
lowpPiceTT = lowpPiceTT(:,symListLowPrice) ;

% closeprice
closePriceTT = closePriceTT(:,symListClosePrice) ;

% volume
volumeTT = volumeTT(:,symListvolume) ;

% put price volume data into struct
priceVolumeStruct.openPrice = openPriceTT ;
priceVolumeStruct.highPrice = highPriceTT;
priceVolumeStruct.lowPrice = lowpPiceTT;
priceVolumeStruct.closePrice = closePriceTT;
priceVolumeStruct.volume = volumeTT;


%% Substitute and change non numeric data to numeric
%--------------------------------------------------------------------------
[priceVolumeNumerStruct] = convertToNumericFcn(priceVolumeStruct,...
                            symList);

%% Fill missing data with the previous and next in timeseries data 
%--------------------------------------------------------------------------
priceVolumeStruct = priceVolumeNumerStruct;

[priceVolumeFilledStruct]...
    = fillMissingFcn(priceVolumeStruct);


%% cleanPriceChangeLimitFcn to remove price changes beyond ARB and ARA limit
%--------------------------------------------------------------------------

% transfer variable value
priceVolumeStruct = priceVolumeFilledStruct;

[openpriceCleanTT, highpriceCleanTT, lowpriceCleanTT, closepriceCleanTT,...
    volumeCleanTT] = cleanPriceChangeLimitFcn(priceVolumeStruct);


%% Transfer ARA and ARB error-free dataset into struct output
%--------------------------------------------------------------------------
priceVolumeClean.openPrice= openpriceCleanTT ;
priceVolumeClean.highPrice = highpriceCleanTT ;
priceVolumeClean.lowPrice = lowpriceCleanTT ;
priceVolumeClean.closePrice = closepriceCleanTT ;
priceVolumeClean.volume = volumeCleanTT ;

% Remove non-output variables 
clearvars -except priceVolumeClean


end

%% Helper local function
%=========================================================================


%% fillMissingFcn
function [priceVolumeFilledStruct] = fillMissingFcn(...
    priceVolumeStruct)
    
    % data preparation
    % transfer variable value
    openPrice = priceVolumeStruct.openPrice;
    highPrice = priceVolumeStruct.highPrice;
    lowPrice = priceVolumeStruct.lowPrice;
    closePrice = priceVolumeStruct.closePrice;
    volume = priceVolumeStruct.volume;

    % DO NOT Delete: convert all variables into numeric via this stage:
    % - let say A is raw data  
    % - convert to string B = string(A)
    % - convert to double C = double (B)
    % - if C is price data, fill zero data with nan >> C(C==0) = nan
    % - if C is volume data, fill nan with 0 >> C(isnan(C)) = 0
    
    % convert all raw data to string
    openPriceVar = string(openPrice.Variables);
    highPriceVar = string(highPrice.Variables);
    lowPriceVar = string(lowPrice.Variables);
    closePriceVar = string(closePrice.Variables);
    volumeVar = string(volume.Variables);

    % convert string to double 
    openPriceVar = double(openPriceVar);
    highPriceVar = double(highPriceVar);
    lowPriceVar = double(lowPriceVar);
    closePriceVar = double(closePriceVar);
    volumeVar = double(volumeVar);
    
    % for price data, fill zero with nan
    openPriceVar(openPriceVar == 0) = nan;
    highPriceVar(highPriceVar == 0) = nan;
    lowPriceVar(lowPriceVar == 0) = nan;
    closePriceVar(closePriceVar == 0) = nan;

    % for volume data, fill nan with zero
    volumeVar(isnan(volumeVar)) = 0;

    % transfer back the variables to TT
    openPrice.Variables = openPriceVar;
    highPrice.Variables = highPriceVar;
    lowPrice.Variables = lowPriceVar;
    closePrice.Variables = closePriceVar;
    volume.Variables = volumeVar;

    % start fill missing value

    % openprice
    openpriceFilledTT   = fillmissing(openPrice, "previous") ;
    openpriceFilledTT   = fillmissing(openpriceFilledTT, "next") ;
    
    % highprice
    highpriceFilledTT   = fillmissing(highPrice, "previous") ;
    highpriceFilledTT   = fillmissing(highpriceFilledTT, "next") ;
    
    % lowprice
    lowpriceFilledTT   = fillmissing(lowPrice, "previous") ;
    lowpriceFilledTT   = fillmissing(lowpriceFilledTT, "next") ;
    
    % closeprice
    closepriceFilledTT   = fillmissing(closePrice, "previous") ;
    closepriceFilledTT   = fillmissing(closepriceFilledTT, "next") ;
    
    % volume
    volumeFilledTT   = fillmissing(volume, "previous") ;
    volumeFilledTT   = fillmissing(volumeFilledTT, "next") ;
    
    priceVolumeFilledStruct.openPrice = openpriceFilledTT;
    priceVolumeFilledStruct.highPrice = highpriceFilledTT;
    priceVolumeFilledStruct.lowPrice = lowpriceFilledTT;
    priceVolumeFilledStruct.closePrice = closepriceFilledTT;
    priceVolumeFilledStruct.volume = volumeFilledTT;

    clearvars -except priceVolumeFilledStruct 
end

%% convertToNumericFcn
function [priceVolumeNumerStruct]...
    = convertToNumericFcn(priceVolumeStruct, symList)

    % transfer variable value
    openPriceTT = priceVolumeStruct.openPrice;
    highPriceTT = priceVolumeStruct.highPrice;
    lowPriceTT = priceVolumeStruct.lowPrice;
    closePriceTT = priceVolumeStruct.closePrice;
    volumeTT = priceVolumeStruct.volume;
    nSym = numel(symList);
    
    % preallocate
    nrows = length(openPriceTT.Time) ;
    TT1 = timetable(openPriceTT.Time, zeros(nrows,1)) ;
    TT = repmat(TT1,1,nSym) ; % Prealltocation
    
    % Preallocate openprice
    openPriceNumerTT = TT ;
    openPriceNumerTT.Properties.VariableNames = strcat(symList,"_open") ;
    
    % Preallocate highprice
    highPriceNumerTT = TT ;
    highPriceNumerTT.Properties.VariableNames = strcat(symList,"_high") ;
    
    % Preallocate lowprice
    lowPriceNumerTT = TT ;
    lowPriceNumerTT.Properties.VariableNames = strcat(symList,"_low") ;
    
    % Preallocate closeprice
    closePriceNumerTT = TT ;
    closePriceNumerTT.Properties.VariableNames = strcat(symList,"_close") ;
    
    % Preallocate volume
    volumeNumerTT = TT ;
    volumeNumerTT.Properties.VariableNames = strcat(symList,"_volume") ;
    
        %% transfer variables per symbol
        for idx = 1:nSym
        %     idx = 63 % for test
    
            idx;
            sym_i = symList(idx) ;
            openpriceSym_i  = openPriceTT(:,idx).Variables ;
            highpriceSym_i  = highPriceTT(:,idx).Variables ;
            lowpriceSym_i   = lowPriceTT(:,idx).Variables ;
            closepriceSym_i = closePriceTT(:,idx).Variables ; 
            volumeSym_i     = volumeTT(:,idx).Variables ;
            
            % convert to string
            openpriceSym_i  = string(openpriceSym_i) ;
            highpriceSym_i  = string(highpriceSym_i) ;
            lowpriceSym_i   = string(lowpriceSym_i) ;
            closepriceSym_i = string(closepriceSym_i) ;
            volumeSym_i     = string(volumeSym_i) ;
            
            %  convert string to double 
            openpriceSym_i  = str2double(openpriceSym_i) ;
            highpriceSym_i  = str2double(highpriceSym_i) ;
            lowpriceSym_i   = str2double(lowpriceSym_i) ;
            closepriceSym_i = str2double(closepriceSym_i) ;
            volumeSym_i     = str2double(volumeSym_i) ;
            
            % put back the clean data into timetable
            openPriceNumerTT(:,idx).Variables    = openpriceSym_i  ;
            highPriceNumerTT(:,idx).Variables    = highpriceSym_i   ;
            lowPriceNumerTT(:,idx).Variables     = lowpriceSym_i  ;
            closePriceNumerTT(:,idx).Variables   = closepriceSym_i ; 
            volumeNumerTT(:,idx).Variables       = volumeSym_i ;
        
        end

        priceVolumeNumerStruct.openPrice = openPriceNumerTT;
        priceVolumeNumerStruct.highPrice  = highPriceNumerTT;
        priceVolumeNumerStruct.lowPrice  = lowPriceNumerTT;
        priceVolumeNumerStruct.closePrice  = closePriceNumerTT;
        priceVolumeNumerStruct.volume = volumeNumerTT;
         
        clearvars -except priceVolumeNumerStruct 
end

%% cleanPriceChangeLimitFcn

function [openPriceCleanTT, highPriceCleanTT, lowPriceCleanTT,...
    closePriceCleanTT, volumeCleanTT] = cleanPriceChangeLimitFcn(...
    priceVolumeStruct)

% data preparation
openpriceFilledTT = priceVolumeStruct.openPrice;
highpriceFilledTT = priceVolumeStruct.highPrice;
lowpriceFilledTT = priceVolumeStruct.lowPrice;
closepriceFilledTT = priceVolumeStruct.closePrice;
volumeFilledTT = priceVolumeStruct.volume;

% Identify daily ret crossing the arb and ara limit
closepriceretTT = tick2ret (closepriceFilledTT) ;
closepriceret = closepriceretTT.Variables ;
sym = closepriceretTT.Properties.VariableNames ;

% ARA limit
priceretLimit = 35/100 ;
priceretcrosslimit = closepriceret > priceretLimit  ;
crossARAposition = max(priceretcrosslimit)  ;
nsymARA = sum(crossARAposition) ;
symARA  = sym(crossARAposition);
symARAout = transpose(symARA) ;

% ARB limit
priceretLimit = 35/100 ;
priceretcrosslimit = closepriceret < -priceretLimit ;
crossARBposition = max(priceretcrosslimit)  ;
nsymARB = sum(crossARBposition) ;
symARB = sym(crossARBposition);
symARBout = transpose(symARB) ;

% combine marker
combinemarker = crossARAposition + crossARBposition ;
crosslimitposition = combinemarker > 0 ;
symCrossLimit = transpose(eraseBetween (sym(:,crosslimitposition), 5,10)) ;
nsymCrossLimit = numel(symCrossLimit) ;

%% Remove data column containing priceretlimit ARA & ARB error 
% open price
openPriceCleanTT = openpriceFilledTT ;
openPriceClean = openPriceCleanTT.Variables ;
openPriceClean(:,crosslimitposition) = nan;
openPriceCleanTT.Variables = openPriceClean ;

% high price
highPriceCleanTT = highpriceFilledTT ;
highPriceClean = highPriceCleanTT.Variables ;
highPriceClean(:,crosslimitposition) = nan ;
highPriceCleanTT.Variables = highPriceClean ;

% low price
lowPriceCleanTT = lowpriceFilledTT ;
lowPriceClean = lowPriceCleanTT.Variables ;
lowPriceClean(:,crosslimitposition) = nan ;
lowPriceCleanTT.Variables = lowPriceClean ;

% close price
closePriceCleanTT = closepriceFilledTT ;
closePriceClean = closePriceCleanTT.Variables ;
closePriceClean(:,crosslimitposition) = nan ;
closePriceCleanTT.Variables = closePriceClean ;

% volume price
volumeCleanTT = volumeFilledTT ;
volumeClean = volumeCleanTT.Variables ;
volumeClean(:,crosslimitposition) = nan ;
volumeCleanTT.Variables = volumeClean ;


end