function [MsecJumpStart,MsecJumpEnd]=FindExcludedDataStartStop(msec)
    StartCount=0;
    EndCount=0;
    MsecJumpStart=[];
    MsecJumpEnd  =[];
    for i = 2:length(msec)-1
        if msec(i+1) ~= msec(i)+1;
            %fprintf('Found a Break Start at i = %d, msec(i) = %d\n',i,msec(i))
            StartCount=StartCount+1;
            MsecJumpStart(StartCount)=msec(i);
        elseif msec(i-1) ~= msec(i)-1;
            %fprintf('Found a Break End   at i = %d, msec(i) = %d\n',i,msec(i))
            EndCount=EndCount+1;
            MsecJumpEnd(EndCount)=msec(i);
        end
    end
    return
end
