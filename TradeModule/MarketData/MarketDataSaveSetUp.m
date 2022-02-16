classdef MarketDataSaveSetUp
    %MarketDataSaveSetUp is class data holder to hold input required to
    % save data
    %   
    % Input arguments
    %   filename: file name of spreadsheet
    %   openPriceSheetname: sheet name where openPriceSheetname will be stored
    %   highPriceSheetname: sheet name where highPriceSheetname will be stored
    %   lowPriceSheetname: sheet name where lowPriceSheetname will be stored
    %   closePriceSheetname: sheet name where closePriceSheetname will be stored
    %   volumeSheetname: sheet name where volumeSheetname will be stored
    %======================================================================
    
    properties
        filename {mustBeText, mustBeTextScalar} = "DataInput\PriceVolumeInput"
        openPriceSheetname {mustBeText, mustBeTextScalar} = "openPrice"
        lowPriceSheetname {mustBeText, mustBeTextScalar} = "lowPrice"
        highPriceSheetname {mustBeText, mustBeTextScalar} = "highPrice"
        closePriceSheetname {mustBeText, mustBeTextScalar} = "lowPrice"
        volumeSheetname {mustBeText, mustBeTextScalar} = "volume"        
    end

end