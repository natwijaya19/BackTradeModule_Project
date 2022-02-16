function priceVolumeClean = cleanDataFcn (priceVolumeRaw)
% cleandataFcn is function to preprocess data
% 
% Preprocessing steps: 
%   - Rearrange symbol alphabetically
%   - Substitute and change non numeric data to numeric
%   - Fill missing data with the previous and next in timeseries data 
%   - Remove symbols or data column containing price changes larger than ARA & ARB limit 
% 
%% Preprocessing is getting started

% Transfer data
openpriceTT = priceVolumeRaw.openPrice;
highpriceTT = priceVolumeRaw.highPrice;
lowpriceTT = priceVolumeRaw.lowPrice;
closepriceTT = priceVolumeRaw.closePrice;
volumeTT = priceVolumeRaw.volume ;
indexIHSGTT = priceVolumeRaw.indexIHSG ;

% number of symbol
symList = sort(eraseBetween(string(volumeTT.Properties.VariableNames),5,11)) ;
nsym = numel (symList) ; 

% Rearrange symbol alphabetcicaly
% openprice
openpriceTT = openpriceTT(:,strcat(symList,"_open")) ;

% highprice
highpriceTT = highpriceTT(:,strcat(symList,"_high")) ;

% lowprice
lowpriceTT = lowpriceTT(:,strcat(symList,"_low")) ;

% closeprice
closepriceTT = closepriceTT(:,strcat(symList,"_close")) ;

% volume
volumeTT = volumeTT(:,strcat(symList,"_volume")) ;



%% Substitute and change non numeric data to numeric
[indexIHSGTT, openpriceNumerTT, highpriceNumerTT, lowpriceNumerTT,...
    closepriceNumerTT, volumeNumerTT] = convertToNumericFcn(indexIHSGTT,...
    openpriceTT, nsym, symList, highpriceTT, lowpriceTT, closepriceTT,...
    volumeTT);

%% Fill missing data with the previous and next in timeseries data 
% openprice
[openpriceFilledTT, highpriceFilledTT, lowpriceFilledTT,... 
    closepriceFilledTT, volumepriceFilledTT, indexIHSGTT]...
    = fillMissingFcn(openpriceNumerTT, highpriceNumerTT,...
    lowpriceNumerTT, closepriceNumerTT, volumeNumerTT, indexIHSGTT);

%% cleanPriceChangeLimitFcn to remove price changes beyond ARB and ARA limit

[openpriceCleanTT, highpriceCleanTT, lowpriceCleanTT, closepriceCleanTT,...
    volumeCleanTT] = cleanPriceChangeLimitFcn(closepriceFilledTT,...
    openpriceFilledTT, highpriceFilledTT, lowpriceFilledTT,...
    volumepriceFilledTT);


%% Transfer ARA and ARB error-free dataset into struct output

priceVolumeClean.openPrice= openpriceCleanTT ;
priceVolumeClean.highPrice = highpriceCleanTT ;
priceVolumeClean.lowPrice = lowpriceCleanTT ;
priceVolumeClean.closePrice = closepriceCleanTT ;
priceVolumeClean.volume= volumeCleanTT ;
priceVolumeClean.indexIHSG = indexIHSGTT;

% Remove non-output variables 
clearvars -except priceVolumeClean


end

%% fillMissingFcn
function [openpriceFilledTT, highpriceFilledTT, lowpriceFilledTT,...
 closepriceFilledTT, volumepriceFilledTT, indexIHSGTT] =...
 fillMissingFcn(openpriceNumerTT, highpriceNumerTT, lowpriceNumerTT,...
 closepriceNumerTT, volumeNumerTT, indexIHSGTT)

openpriceFilledTT   = fillmissing(openpriceNumerTT, "previous") ;
openpriceFilledTT   = fillmissing(openpriceFilledTT, "next") ;

% highprice
highpriceFilledTT   = fillmissing(highpriceNumerTT, "previous") ;
highpriceFilledTT   = fillmissing(highpriceFilledTT, "next") ;

% lowprice
lowpriceFilledTT   = fillmissing(lowpriceNumerTT, "previous") ;
lowpriceFilledTT   = fillmissing(lowpriceFilledTT, "next") ;

% closeprice
closepriceFilledTT   = fillmissing(closepriceNumerTT, "previous") ;
closepriceFilledTT   = fillmissing(closepriceFilledTT, "next") ;

% volume
volumepriceFilledTT   = fillmissing(volumeNumerTT, "previous") ;
volumepriceFilledTT   = fillmissing(volumepriceFilledTT, "next") ;

% indexIHSGTT
indexIHSGTT = fillmissing(indexIHSGTT, "previous");
indexIHSGTT = fillmissing(indexIHSGTT, "next");
end

%% convertToNumericFcn
function [indexIHSGTT, openpriceNumerTT, highpriceNumerTT, ...
    lowpriceNumerTT, closepriceNumerTT, volumeNumerTT]...
    = convertToNumericFcn(indexIHSGTT, openpriceTT, nsym, symList,...
    highpriceTT, lowpriceTT, closepriceTT, volumeTT)

% indexIHSGTT change to numeric
indexIHSGTT.Variables = fillmissing(indexIHSGTT.Variables, "previous");
indexIHSGTT.Variables = fillmissing(indexIHSGTT.Variables, "next");
indexIHSGTT.Variables = double(indexIHSGTT.Variables);

% preallocate
nrows = length(openpriceTT.Time) ;
TT1 = timetable(openpriceTT.Time, zeros(nrows,1)) ;
TT = repmat(TT1,1,nsym) ; % Prealltocation

% Preallocate openprice
openpriceNumerTT = TT ;
openpriceNumerTT.Properties.VariableNames = strcat(symList,"_open") ;

% Preallocate highprice
highpriceNumerTT = TT ;
highpriceNumerTT.Properties.VariableNames = strcat(symList,"_high") ;

% Preallocate lowprice
lowpriceNumerTT = TT ;
lowpriceNumerTT.Properties.VariableNames = strcat(symList,"_low") ;

% Preallocate closeprice
closepriceNumerTT = TT ;
closepriceNumerTT.Properties.VariableNames = strcat(symList,"_close") ;

% Preallocate volumeprice
volumeNumerTT = TT ;
volumeNumerTT.Properties.VariableNames = strcat(symList,"_volume") ;

%% transfer variables per symbol
for idx = 1:nsym
    %     idx = 63 % for test

    idx;
    sym_i = symList(idx) ;
    openpriceSym_i  = openpriceTT(:,idx).Variables ;
    highpriceSym_i  = highpriceTT(:,idx).Variables ;
    lowpriceSym_i   = lowpriceTT(:,idx).Variables ;
    closepriceSym_i = closepriceTT(:,idx).Variables ; 
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
    openpriceNumerTT(:,idx).Variables    = openpriceSym_i  ;
    highpriceNumerTT(:,idx).Variables    = highpriceSym_i   ;
    lowpriceNumerTT(:,idx).Variables     = lowpriceSym_i  ;
    closepriceNumerTT(:,idx).Variables   = closepriceSym_i ; 
    volumeNumerTT(:,idx).Variables       = volumeSym_i ;
    
end
end

%% cleanPriceChangeLimitFcn
function [openpriceCleanTT, highpriceCleanTT, lowpriceCleanTT,...
    closepriceCleanTT, volumeCleanTT] = cleanPriceChangeLimitFcn(...
    closepriceFilledTT, openpriceFilledTT, highpriceFilledTT,...
    lowpriceFilledTT, volumepriceFilledTT)
%% Identify daily ret crossing the arb and ara limit
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
openpriceCleanTT = openpriceFilledTT ;
openpriceClean = openpriceCleanTT.Variables ;
openpriceClean(:,crosslimitposition) = nan;
openpriceCleanTT.Variables = openpriceClean ;

% high price
highpriceCleanTT = highpriceFilledTT ;
highpriceClean = highpriceCleanTT.Variables ;
highpriceClean(:,crosslimitposition) = nan ;
highpriceCleanTT.Variables = highpriceClean ;

% low price
lowpriceCleanTT = lowpriceFilledTT ;
lowpriceClean = lowpriceCleanTT.Variables ;
lowpriceClean(:,crosslimitposition) = nan ;
lowpriceCleanTT.Variables = lowpriceClean ;

% close price
closepriceCleanTT = closepriceFilledTT ;
closepriceClean = closepriceCleanTT.Variables ;
closepriceClean(:,crosslimitposition) = nan ;
closepriceCleanTT.Variables = closepriceClean ;

% volume price
volumeCleanTT = volumepriceFilledTT ;
volumeClean = volumeCleanTT.Variables ;
volumeClean(:,crosslimitposition) = nan ;
volumeCleanTT.Variables = volumeClean ;
end