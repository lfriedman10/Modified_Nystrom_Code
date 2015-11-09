function detectSaccades(i,j)
% Detects start and end by velocity criteria

global ETparams
global Scalers

VerboseTF=true;

if VerboseTF, fprintf('---------------------- Detecting Saccades and Glissades ------------------\n\n'),end;

V = [ETparams(i,j).data.vel];
A = [ETparams(i,j).data.acc];
len = length(V);

% Preallocate memory
velLabeled = bwlabel(ETparams(i,j).data.velPeakIdx);
ETparams(i,j).saccadeIdx.Idx  = zeros(1,len);  % Saccade index
ETparams(i,j).glissadeIdx.Idx = zeros(1,len);  % Glissade index

% If no saccades are detected, return
if isempty(velLabeled);
    return
end

% Process one velocity peak at the time
kk = 1;
if VerboseTF, fprintf('Number Of Potential Saccades To Process = %d\n',max(velLabeled)),end;
for k = 1:max(velLabeled)
    
    if VerboseTF, fprintf('\nChecking Saccade # %d, Good Saccades Found = %d\n',k,kk-1), end;
    
    %----------------------------------------------------------------------  
    % Check the saccade peak samples
    %----------------------------------------------------------------------       
    % The samples related to the current saccade
    peakIdx = find(velLabeled == k);
    
    % If the peak consists of =< minPeakSamples consecutive samples, it is probably
    % noise (1/6 of the min saccade duration)
    minPeakSamples = ceil([Scalers.minSaccadeDur]/6*[Scalers.samplingFreq]);
    if length(peakIdx) <= minPeakSamples;
        if VerboseTF,fprintf('REJECT> This peak consists of too few samples (%d), Min Allowed > minPeakSamples (%d) samples, it it probably noise.\n\n',length(peakIdx),minPeakSamples), end;
        continue;
    end
    % Check whether this peak is already included in the previous saccade
    % (can be like this for glissades)
    if kk > 1
        if ~isempty(intersect(peakIdx,[find(ETparams(i,j).saccadeIdx.Idx) find(ETparams(i,j).glissadeIdx.Idx)]))
            if VerboseTF, fprintf('REJECT> This peak is already included in the previous saccade (can be like this for glissades).\n\n'),end;
            continue
        end       
    end
    %----------------------------------------------------------------------
    % DETECT SACCADE
    %----------------------------------------------------------------------       
    
    % Detect saccade start.
    saccadeStartIdx = find(V(peakIdx(1):-1:1) <= Scalers.SacOnOffThresh & [diff(V(peakIdx(1):-1:1)) 0] >= 0);          % acc <= 0
   if isempty(saccadeStartIdx)
        if VerboseTF, fprintf('REJECT> Cannot find the start of a saccade.\n\n');end;
        continue
    end
    saccadeStartIdx = peakIdx(1) - saccadeStartIdx(1) + 1;
    
    % Calculate local fixation noise (the adaptive part)
    EndOfSaccadeVector=max(1,ceil(saccadeStartIdx - [Scalers.minFixDur]*[Scalers.samplingFreq]));
    localVelNoise = V(saccadeStartIdx:-1: EndOfSaccadeVector);
    localVelNoise = mean(localVelNoise) + 3*std(localVelNoise);
    localsaccadeVelocityThreshold = localVelNoise*0.3 + ETparams(i,j).data.saccadeVelocityThreshold*0.7; % 30% local + 70% global
%     % Check whether the local vel. noise exceeds the peak vel. threshold.
    if (localVelNoise > ETparams(i,j).data.peakDetectionThreshold)
        if VerboseTF, fprintf('REJECT> The local vel. noise exceeds the peak vel. threshold.\n\n');end
        continue;
    end
              
    % Detect end of saccade
    % Original Algorithm uses local velocity threshold for ending of saccade
    % saccadeEndIdx = find(V(peakIdx(end):end) <= localsaccadeVelocityThreshold & [diff(V(peakIdx(end):end)) 0] >= 0);
    % We are trying to use the same threshold for the start and end of a saccade
    saccadeEndIdx = find(V(peakIdx(end):end) <= Scalers.SacOnOffThresh & [diff(V(peakIdx(end):end)) 0] >= 0);% acc <= 0
    if isempty(saccadeEndIdx)
        if VerboseTF, fprintf('REJECT> Cannot detect the end of saccade.\n\n');end;
        continue;
    end      
    saccadeEndIdx = peakIdx(end) + saccadeEndIdx(1) - 1;

    % If the saccade contains NaN samples, continue
    if any(ETparams(i,j).data.nanIdx.Idx(saccadeStartIdx:saccadeEndIdx))
        if VerboseTF, fprintf('REJECT> The saccade contains NaN samples.))\n\n');end;
        continue
    end
    
    % Make sure the saccade duration exceeds the minimum duration.
    saccadeLen = saccadeEndIdx - saccadeStartIdx;
    if saccadeLen/[Scalers.samplingFreq] < Scalers.minSaccadeDur;
        if VerboseTF, fprintf('REJECT> The saccade duration does not exceed the minimum saccade duration.\n\n');end;
        continue    
    end
    
    % If all the above criteria are fulfilled, label it as a saccade.
    if VerboseTF, fprintf('Its a saccade!!!\n\n'), end;
    ETparams(i,j).saccadeIdx.Idx(saccadeStartIdx:saccadeEndIdx) = 1;
    ETparams(i,j).data.Classification(saccadeStartIdx:saccadeEndIdx)=2;
    ETparams(i,j).sacinfo(kk).localSaccadeVelocityThreshold = localsaccadeVelocityThreshold;

    % Collect information about the saccade
    if VerboseTF, fprintf('Saccade Starts at %d, Saccade Ends at %d\n',saccadeStartIdx,saccadeEndIdx), end;
    ETparams(i,j).sacinfo(kk).saccadeInfo.start = saccadeStartIdx/[Scalers.samplingFreq]; % in seconds
    ETparams(i,j).sacinfo(kk).saccadeInfo.end = saccadeEndIdx/[Scalers.samplingFreq]; % in seconds
    ETparams(i,j).sacinfo(kk).saccadeInfo.duration = ETparams(i,j).sacinfo(kk).saccadeInfo.end - ETparams(i,j).sacinfo(kk).saccadeInfo.start;
%     ETparams(i,j).sacinfo(kk).saccadeInfo.amplitude = sqrt(((ETparams(i,j).data.(saccadeEndIdx)-...
%                                                 (ETparams(i,j).data.X(saccadeStartIdx))))^2 + ...
%                                                ((ETparams(i,j).data.Y(saccadeEndIdx)-...
%                                                 (ETparams(i,j).data.Y(saccadeStartIdx))))^2   );
    Xamp=[ETparams(i,j).data.Xsmo(saccadeEndIdx)]-[ETparams(i,j).data.Xsmo(saccadeStartIdx)];
    Yamp=[ETparams(i,j).data.Ysmo(saccadeEndIdx)]-[ETparams(i,j).data.Ysmo(saccadeStartIdx)];
    ETparams(i,j).sacinfo(kk).saccadeInfo.amplitude = sqrt(Xamp^2 + Yamp^2);
%     ETparams(i,j).sacinfo(kk).saccadeInfo.HorAmplitude = abs([ETparams(i,j).data.X(saccadeEndIdx)]-[ETparams(i,j).data.X(saccadeStartIdx)]);
%     ETparams(i,j).sacinfo(kk).saccadeInfo.VerAmplitude = abs([ETparams(i,j).data.Y(saccadeEndIdx)]-[ETparams(i,j).data.Y(saccadeStartIdx)]);   
    ETparams(i,j).sacinfo(kk).saccadeInfo.peakVelocity = max(V(saccadeStartIdx:saccadeEndIdx)); 
    ETparams(i,j).sacinfo(kk).saccadeInfo.peakAcceleration = max(A(saccadeStartIdx:saccadeEndIdx)); 
% %
% %   Check for Outliers - SacAmp vs SacDurat relationship
% %
%     SacDurInSamples=[ETparams(i,j).sacinfo(kk).saccadeInfo.duration]*[Scalers.samplingFreq];
%     fprintf('SacDurInSamples = %f,duration = %f\n',SacDurInSamples,ETparams(i,j).sacinfo(kk).saccadeInfo.duration)
%     SacAmpPred=SacDurInSamples*Scalers.AmpDurSlope+Scalers.AmpDurIntercept;
%     SacAmpActual=[ETparams(i,j).sacinfo(kk).saccadeInfo.amplitude];
%     if abs(SacAmpActual-SacAmpPred) > [Scalers.maxDistanceAmpDur];
%         ETparams(i,j).data.SubType(saccadeStartIdx:saccadeEndIdx)=1;
%         if SacAmpActual < Scalers.maxSaccadeAmplitude;
%             fprintf('Subject = %d, Session = %d\n',i,j);
%             fprintf('SacAmp < max and abs(SacAmpActual-SacAmpPred) > 3.0, Act = %f, Prd = %f, Dif = %f\n',SacAmpActual,SacAmpPred,SacAmpActual-SacAmpPred);
%         end;
%     end;
% %
% %   Check for Outliers - Log10 Pkv vs Log10 SacAmp
% %
%     SacPkVPred=log10(SacAmpActual)*Scalers.PkVAmpSlope+Scalers.PkVAmpIntercept;
%     SacPkVActual=log10([ETparams(i,j).sacinfo(kk).saccadeInfo.peakVelocity]);
%     if abs(SacPkVActual-SacPkVPred) > Scalers.maxDistancePkvAmp;
%         ETparams(i,j).data.SubType(saccadeStartIdx:saccadeEndIdx)=2;
%         fprintf('Subject = %d, Session = %d\n',i,j);
%         fprintf('abs(SacPkVActual-SacPkVPred) > 0.5, Act = %f, Prd = %f, Dif = %f\n',SacPkVActual,SacPkVPred,SacPkVActual-SacPkVPred);
%     end;
%
%   Label Large Saccades as SubType 3
%
    if ETparams(i,j).sacinfo(kk).saccadeInfo.amplitude > Scalers.maxSaccadeAmplitude;
        ETparams(i,j).data.SubType(saccadeStartIdx:saccadeEndIdx)=3;
    end;
  
    %----------------------------------------------------------------------  
    % DETECT GLISSADE (ETparams(i,j).glissadeInfo(i,j,kk).type
    %----------------------------------------------------------------------   
    % Search only for glissade peaks in a window <= min fix duration after
    % the saccade end
    IsGlissade=false;
    IsStrongGlissade=false;
    IsWeakGlissade=false;
    glissadeDuration=0;
    glissadeIdx=[];
    GlissadeStartIndex=saccadeEndIdx;
    GlissadeEndIndex  =min((saccadeEndIdx) + [Scalers.minFixDur]*[Scalers.samplingFreq],len-1);
    if VerboseTF, fprintf('\nChecking For Strong Glissade for from %d to %d, For Good Saccade # %d\n',GlissadeStartIndex,GlissadeEndIndex,kk), end; 
    GlissadeVelocity = V(GlissadeStartIndex:GlissadeEndIndex);
    % Test if this a Strong Glissade
    glissadePeakIdxS = GlissadeVelocity >= Scalers.PeakVelocityThreshold;
    glissadePeakGT200 = GlissadeVelocity >= 180.;
    if sum(glissadePeakIdxS)> 1 && sum(glissadePeakGT200) == 0;
        if VerboseTF, fprintf('This is a Strong Glissade\n'), end;
        IsGlissade=true;IsStrongGlissade=true;IsWeakGlissade=false;
        glissadeEndStrongIdx = find(glissadePeakIdxS,1,'last');
        glissadeEndStrongIdx = saccadeEndIdx + 1 + glissadeEndStrongIdx + 1;
        nGlissadesStrong = length(unique(bwlabel(glissadePeakIdxS))) - 1;
        MaxGlissadeVelocity = max(V(GlissadeStartIndex:min(glissadeEndStrongIdx,len)));
        fprintf('MaxGlissadeVelocity=%f\n',MaxGlissadeVelocity)
        MaxGlissadeVelocityIndex=find(V(GlissadeStartIndex:glissadeEndStrongIdx)==MaxGlissadeVelocity)+GlissadeStartIndex;
        fprintf('MaxGlissadeVelocityIndex=%d\n',MaxGlissadeVelocityIndex)
        glissadeIdx = (GlissadeStartIndex+1):glissadeEndStrongIdx;
        glissadeDuration = (length(glissadeIdx))/[Scalers.samplingFreq]; 
        ETparams(i,j).glisinfo(kk).glissadeInfo.type = 2;
        ETparams(i,j).glisinfo(kk).glissadeInfo.duration = glissadeDuration;
        ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 1;
        ETparams(i,j).data.Classification(glissadeIdx)=3;
        ETparams(i,j).data.SubType(glissadeIdx)=10;
        GlissadeEndIndex=glissadeEndStrongIdx;
    end;  
    % Test if this is a Weak Glissade
    if ~IsStrongGlissade && sum(glissadePeakGT200) == 0;
       if VerboseTF, fprintf('\nChecking For Weak Glissade for from %d to %d, For Good Saccade # %d\n',GlissadeStartIndex,GlissadeEndIndex,kk), end; 
        glissadePeakIdxW = GlissadeVelocity >= Scalers.WeakGlissadeVelocityThreshold;
        glissadeEndWeakIdx = find(glissadePeakIdxW,1,'last');
        glissadeEndWeakIdx = saccadeEndIdx + 1 + glissadeEndWeakIdx;
        % Detect only 'complete' peaks (those with a beginning and an end)
        endIdx = find(abs(diff(glissadePeakIdxW)));
        % added by Lee - "complete": peaks criteria is too strict
        if length(endIdx) == 1;
            %find peak velocity during potential glissade
            MaxGlissadeVelocity = max(V(GlissadeStartIndex:glissadeEndWeakIdx));
            fprintf('MaxGlissadeVelocity=%f\n',MaxGlissadeVelocity)
            %find index of MaxGlissadeVelocity
            MaxGlissadeVelocityIndex=find(V(GlissadeStartIndex:glissadeEndWeakIdx)==MaxGlissadeVelocity)+GlissadeStartIndex;
            fprintf('MaxGlissadeVelocityIndex=%d\n',MaxGlissadeVelocityIndex)
           %find if there is a peak
            for q = MaxGlissadeVelocityIndex:-1:saccadeEndIdx;
                if V(q) < MaxGlissadeVelocity;
                    NewStart=q;
                else
                    NewStart=q-1;
                    continue
                end
            end;
            fprintf('New Start = %d\n',NewStart)
            endIdx=[NewStart endIdx];
        end
        if length(endIdx)>1
            if VerboseTF, fprintf('This is a Weak Glissade, Glissade Starts at %d\n',saccadeEndIdx + 1), end;
            IsGlissade=true;IsStrongGlissade=false;IsWeakGlissade=true;
            endIdx = endIdx(2:2:end);
            glissadeEndWeakIdx = endIdx(end);
            nGlissadesWeak = length(endIdx);
            glissadeEndWeakIdx = GlissadeStartIndex + 1 + glissadeEndWeakIdx + 1; 
            glissadeEndWeakIdx = glissadeEndWeakIdx + find(diff(V(glissadeEndWeakIdx:end)) >= 0,1,'first') - 1; 
            glissadeIdx = (GlissadeStartIndex+1):glissadeEndWeakIdx;
            glissadeDuration = (length(glissadeIdx))/[Scalers.samplingFreq]; 
            ETparams(i,j).glisinfo(kk).glissadeInfo.type = 1;
            ETparams(i,j).glisinfo(kk).glissadeInfo.duration = glissadeDuration;
            ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 1;
            ETparams(i,j).data.Classification(glissadeIdx)=3;
            ETparams(i,j).data.SubType(glissadeIdx)=11;
            GlissadeEndIndex=glissadeEndWeakIdx;
            %find peak velocity during potential glissade
            MaxGlissadeVelocity = max(V(GlissadeStartIndex:glissadeEndWeakIdx));
            fprintf('MaxGlissadeVelocity=%f\n',MaxGlissadeVelocity)
            %find index of MaxGlissadeVelocity
            MaxGlissadeVelocityIndex=find(V(GlissadeStartIndex:glissadeEndWeakIdx)==MaxGlissadeVelocity)+GlissadeStartIndex;
            fprintf('MaxGlissadeVelocityIndex=%d\n',MaxGlissadeVelocityIndex)
        end;
    end;
    if ~IsGlissade;
        fprintf('For this saccade, there is no glissade, potential glissade start = %d\n',saccadeEndIdx+1)
    end;
    % Make sure that the saccade amplitude is larger than the glissade
    % amplituded, otherwise no glissade is detected.
    if IsGlissade && max(V(GlissadeStartIndex:GlissadeEndIndex)) > max(V(saccadeStartIdx:saccadeEndIdx));
        if VerboseTF, fprintf('REJECT> This glissade has velocities greater than the prior saccade\n'), end;
        IsGlissade=false;IsStrongGlissade=false;IsWeakGlissade=false;
        glissadeEndWeakIdx = [];
        glissadeEndStrongIdx = [];
        ETparams(i,j).glisinfo(kk).glissadeInfo.type = 0;
        ETparams(i,j).glisinfo(kk).glissadeInfo.duration = 0;
        ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 0;
        ETparams(i,j).data.Classification(glissadeIdx)=0;
        ETparams(i,j).data.SubType(glissadeIdx)=0;
    end
    % Check if Glissade is longer than max glissade duration
    if IsGlissade && glissadeDuration > 2*[Scalers.minFixDur];
        if VerboseTF, fprintf('Reject> Glissage is too long (%f), max = (%f)',glissadeDuration,2*Scalers.minFixDur),end;
        IsGlissade=false;IsStrongGlissade=false;IsWeakGlissade=false;
        ETparams(i,j).glisinfo(kk).glissadeInfo.type = 0;
        ETparams(i,j).glisinfo(kk).glissadeInfo.duration = 0;
        ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 0;
        ETparams(i,j).data.Classification(glissadeIdx)=0;
        ETparams(i,j).data.SubType(glissadeIdx)=0;
    end;
    %Check if any samples during the Glissade is a NaN
    if IsGlissade && any(ETparams(i,j).data.nanIdx.Idx(glissadeIdx))
        if VerboseTF, fprintf('Reject> Glissage contains NaNs\n'), end;
        IsGlissade=false;IsStrongGlissade=false;IsWeakGlissade=false;
        ETparams(i,j).glisinfo(kk).glissadeInfo.type = 0; 
        ETparams(i,j).glisinfo(kk).glissadeInfo.duration = 0;
        ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 0;
        ETparams(i,j).data.Classification(glissadeIdx)=0;
        ETparams(i,j).data.SubType(glissadeIdx)=0;
    end;
   % If no glissade detected
   if ~IsGlissade; 
        IsGlissade=false;IsStrongGlissade=false;IsWeakGlissade=false;
        ETparams(i,j).glisinfo(kk).glissadeInfo.type = 0; 
        ETparams(i,j).glisinfo(kk).glissadeInfo.duration = 0;
        ETparams(i,j).glissadeIdx.Idx(glissadeIdx) = 0;
        ETparams(i,j).data.Classification(glissadeIdx)=0;
        ETparams(i,j).data.SubType(glissadeIdx)=0;
   end;
 
    fprintf('Is this a glissade (%s), Is this a Strong glissade (%s), Is this a Weak glissade (%s), Duration = %5.3f\n',...
            logical2str(IsGlissade),logical2str(IsStrongGlissade),logical2str(IsWeakGlissade),ETparams(i,j).glisinfo(kk).glissadeInfo.duration);
%     if IsGlissade, pause, end;
    kk = kk+1;
end
ETparams(i,j).kk = kk-1;
