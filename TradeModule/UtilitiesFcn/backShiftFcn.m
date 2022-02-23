function argsOut = backShiftFcn (argsInput, nBackShift)
    arguments
        argsInput {mustBeNumeric}
        nBackShift {mustBeInteger}
    end

    argsInputShifted = argsInput;
    argsInputShifted(1:nBackShift,:) = 0;
    argsInputShifted(nBackShift+1:end,:) = argsInput(1:end-nBackShift,:);
    argsInputShifted(isnan(argsInputShifted)) = 0;
    argsOut = argsInputShifted;

end