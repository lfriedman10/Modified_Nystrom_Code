function detectFixations(i,j)
%--------------------------------------------------------------------------
% Fixation detection
% Fixation are detected implicitly 
%--------------------------------------------------------------------------

global ETparams
global Scalers
global OutPathStr
global FileName

VerboseTF=true;

possibleFixationIdx = ~(ETparams(i,j).saccadeIdx.Idx | ETparams(i,j).glissadeIdx.Idx);
fixLabeled = bwlabel(possibleFixationIdx);
VertPos=ETparams(i,j).data.Ysmo;
% Process one fixation (or more precisely a period of gaze samples that might
% a fixation) at the time.
kk = 1;
ETparams(i,j).fixationIdx.Idx = zeros(1,length(ETparams(i,j).data.Xorg));

if VerboseTF, fprintf('-------- Detecting Fixations, Potential Number = %d ---------\n\n',max(fixLabeled)),end;

for k = 1:max(fixLabeled)
    
    if VerboseTF, fprintf('Checking Fixation # %d, Good Fixations Found = %d\n',k,kk-1), end;

    % The samples related to the current fixation
    fixIdx = find(fixLabeled == k);
    StartIdx=fixIdx(1);
    EndIdx=fixIdx(end);
    if VerboseTF, fprintf('This Potential Fixation Starts at %d and Ends at %d\n',StartIdx,EndIdx), end;
    
    % Check that the fixation is not all NaNs. 
    
    NaNCount=0;
    for q = StartIdx:EndIdx;
        if ETparams(i,j).data.Classification(q)>3;
            NaNCount=NaNCount+1;
        end
    end;
    MyLoopCount=EndIdx-StartIdx+1;
    fprintf('Checking For NaNs in this Fixation, NaNCount = %d, LoopCount = %d, percent = %5.2f\n',NaNCount, MyLoopCount, 100*NaNCount/MyLoopCount)
    if NaNCount/MyLoopCount > 0.75;
        fprintf('REJECT FIXATION: Its at least 75 percent NaNs\n')
        continue
    end;
    
    % Check to see if there are any NaNs in this fixation. Reset startidx and endidx to values not including any NaNs. 

    NewStartIdx=StartIdx;
    NewEndIdx=EndIdx;
    MidPoint=floor((StartIdx+EndIdx)/2);
    
    for q = StartIdx:MidPoint;
        if ETparams(i,j).data.Classification(q)>3;
            NaNCount=NaNCount+1;
            NewStartIdx=q+1;
            if VerboseTF && NaNCount == 1, fprintf('This fixation has NaN values before its center\n'), end;
        end;
    end;
    NaNCount=0;
    for q = EndIdx:-1:MidPoint+1;
        if ETparams(i,j).data.Classification(q)>3;
            NaNCount=NaNCount+1;
            NewEndIdx=q-1;
            if VerboseTF && NaNCount == 1, fprintf('This fixation has NaN values after its center\n'), end;
        end;
    end;
    if StartIdx~=NewStartIdx || EndIdx~=NewEndIdx;
        StartIdx=NewStartIdx;
        EndIdx=NewEndIdx;
        fixIdx=fixIdx((fixIdx)>=StartIdx);
        fixIdx=fixIdx((fixIdx)<=EndIdx);
    end;
  
    % Check that the fixation duration exceeds the minimum duration criteria.
    fixdur = length(fixIdx)/Scalers.samplingFreq;
    if fixdur < Scalers.minFixDur;
        if VerboseTF,fprintf('REJECT FIXATION: Too Short - Strt=%d, End=%d, Duration (sec) = %5.3f\n',StartIdx,EndIdx,fixdur), end;
        ETparams(i,j).data.Classification(StartIdx:EndIdx)=10;
        continue    
    end
    
    % Find the maximum position differene between any 2 points in this
    % fixation
    MaxX=max(ETparams(i,j).data.Xorg(fixIdx));
    MinX=min(ETparams(i,j).data.Xorg(fixIdx));
    MinMaxDiffX=abs(MaxX-MinX);
    MaxY=max(ETparams(i,j).data.Yorg(fixIdx));
    MinY=min(ETparams(i,j).data.Yorg(fixIdx));
    MinMaxDiffY=abs(MaxY-MinY);
    MinMaxDiff=max(MinMaxDiffX,MinMaxDiffY);
    if MinMaxDiff>4.0;
        fprintf('MinMaxDiff=%f *************\n',MinMaxDiff)
        fprintf('REJECT FIXATION: The Fixation has huge position MinMaxDiff - Strt=%d, End=%d\n',StartIdx,EndIdx);
        ETparams(i,j).data.Classification(StartIdx:EndIdx)=11;
        continue
    end;
      
    % If any of the sample has a velocity > peak saccade threshold, it
    % cannot be a fixation (missed by the saccade algorithm)

    % Taking this criteria out
    
    % if any(ETparams(i,j).data.vel(fixIdx) > [ETparams(i,j).data.peakDetectionThreshold])
    %         continue
    % end
    
%     % If the saccade contains NaN samples, continue
%     if any(ETparams(i,j).data.nanIdx.Idx(fixIdx));
%         if VerboseTF, fprintf('REJECT FIXATION: The fixation contains NaN samples - Strt=%d, End=%d\n',StartIdx,EndIdx),end;
%         WhereAreTheNaNs=find(isnan(ETparams(i,j).data.vel(StartIdx:EndIdx)));
%         for q = 1:length(WhereAreTheNaNs)
%             if VerboseTF, fprintf('a NaN occurs at %d\n',StartIdx+WhereAreTheNaNs(q)), end;
%         end;
%         continue;
%     end

    % If all the above criteria are fulfilled, label it as a fixation.
    fprintf('Its a Fixation!!!\n')
    ETparams(i,j).fixationIdx.Idx(fixIdx) = 1;
    
    % Calculate the position of the fixation
    % ETparams(i,j).fixinfo(kk).fixationInfo.X = nanmean(ETparams(i,j).data.X(fixIdx));
    % ETparams(i,j).fixinfo(kk).fixationInfo.Y = nanmean(ETparams(i,j).data.Y(fixIdx));
    ETparams(i,j).fixinfo(kk).fixationInfo.meanXSmoPos = nanmean(ETparams(i,j).data.Xsmo(fixIdx));
    ETparams(i,j).fixinfo(kk).fixationInfo.meanYSmoPos = nanmean(ETparams(i,j).data.Ysmo(fixIdx));

    % Collect information about the fixation
    fixationStartIdx = fixIdx(1);
    fixationEndIdx = fixIdx(end);
%     fprintf('fixationStartIdx=%d,fixationEndIdx=%d\n',fixationStartIdx,fixationEndIdx)
    for m = fixationStartIdx:fixationEndIdx
        if ETparams(i,j).data.Classification(m) == 2;
            if VerboseTF, fprintf('Oops!!!, a fixation is trying to overwrite a saccade %d\n',ETparams(i,j).data.Classification(m)), pause, end;
        end;
        if ETparams(i,j).data.Classification(m) == 3;
            if VerboseTF, fprintf('Oops!!!, a fixation is trying to overwrite a glissade %d\n',ETparams(i,j).data.Classification(m)), pause, end;
        end;
    end;
    ETparams(i,j).data.Classification(fixationStartIdx:fixationEndIdx)=1;
    ETparams(i,j).fixinfo(kk).fixationInfo.start    = fixationStartIdx/[Scalers.samplingFreq]; % in seconds
    ETparams(i,j).fixinfo(kk).fixationInfo.end      = fixationEndIdx/[Scalers.samplingFreq]; % in seconds
    ETparams(i,j).fixinfo(kk).fixationInfo.duration = ETparams(i,j).fixinfo(kk).fixationInfo.end - ETparams(i,j).fixinfo(kk).fixationInfo.start;    
    kk = kk+1;
end
ETparams(i,j).ff=kk-1;
out=[ETparams(i,j).data.Msec' ETparams(i,j).data.Xorg' ETparams(i,j).data.Xsmo' ETparams(i,j).data.Yorg' ETparams(i,j).data.Ysmo' ETparams(i,j).data.vel' ETparams(i,j).data.acc' ETparams(i,j).data.Pupil' ETparams(i,j).data.Classification' ETparams(i,j).data.SubType'];
fprintf('OutPathStr = %s\n',OutPathStr)
FileName(13:22)='_Class.csv'
fprintf('FileName = %s\n',FileName)
csvwrite([OutPathStr FileName],out);

