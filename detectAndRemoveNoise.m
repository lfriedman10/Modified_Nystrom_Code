function detectAndRemoveNoise(i,j)
% Detects and removes un-physiological movement (which derives from noise
% and blinks)
global ETparams
global Scalers

global OutPathStr

Verbose_TF=0;
% Verbose_TF=1;

V = ETparams(i,j).data.vel;
V_threshold = median(ETparams(i,j).data.vel,'omitnan')*2;
len=length(V);

% fprintf('V_threshold = %f\n',V_threshold);

% Detect possible blinks and noise (where XY-coords are 0  or if the eyes move too fast)
% blinkIdx = (ETparams(i,j).data.X <= 0 & ETparams(i,j).data.Y <= 0) |...
%         ETparams(i,j).data.vel > Scalers.blinkVelocityThreshold |...
%         abs(ETparams(i,j).data.acc) > Scalers.blinkAccThreshold;
% Scalers.blinkVelocityThreshold
% Classify NaNs due to blink Velocity Threshold = 6
for q = 1:len;
    if [ETparams(i,j).data.Classification(q)] <= 3 && V(q) > Scalers.blinkVelocityThreshold;
        ETparams(i,j).data.Classification(q) = 6;
    end;
 end;
ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 6)=6;
ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 6)=6;
ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 6)=6;
ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 6)=6;
for q = 1:len;
    if ETparams(i,j).data.Classification(q) <= 3 && ETparams(i,j).data.acc(q) > Scalers.blinkAccThreshold;
        ETparams(i,j).data.Classification(q) = 7;
    end;
end;

ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 7)=7;
ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 7)=7;
ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 7)=7;
ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 7)=7;
ETparams(i,j).data.nanIdx.Idx(ETparams(i,j).data.Classification > 3)=1;
% csvwrite('CheckClassification.csv',[ETparams(i,j).data.Msec' ETparams(i,j).data.Classification']);
blinkIdx =  ETparams(i,j).data.Classification>3;
% Set possible blink and noise index to '1'
ETparams(i,j).data.nanIdx.Idx(blinkIdx) = 1;   

% Label blinks or noise
blinkLabeled = bwlabel(blinkIdx);
% out=[blinkIdx' ETparams(i,j).data.X' blinkLabeled'];
% csvwrite([OutPathStr,'blinkIdx.csv'],out);
% Process one blink or noise period at the time
ETparams(i,j).NumBlinks=max(blinkLabeled);
for k = 1:max(blinkLabeled)

    if(Verbose_TF),fprintf('\nProcessing blink %d\n',k);end;
    % The samples related to the current event
    b = find(blinkLabeled == k);   
      
    % Go back in time to see where the blink (noise) started
    if(Verbose_TF),fprintf('This blink originally starts at %d\n',b(1));end;
    sEventIdx=[];
    if(b(1)>1);
        sEventIdx = find(V(b(1):-1:1) <= V_threshold);
        if(~isempty(sEventIdx));
            if(Verbose_TF),fprintf('The length before this to exclude on velocity grounds = %d\n',sEventIdx(1));end;
            sEventIdx = b(1) - sEventIdx(1) + 1;
%             fprintf('sEventIdx(1) = %d\n',sEventIdx(1))
%             fprintf('(b(1)+1) = %d\n',(b(1)-1))
%             pause
              for m = sEventIdx(1):(b(1)-1);
                 if ETparams(i,j).data.Classification(m) <3, ETparams(i,j).data.Classification(m)=8;end
              end;
            ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 8)=8;
            ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 8)=8;
            ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 8)=8;
            ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 8)=8;
            if(Verbose_TF),fprintf('Therefore, this blink starts at %d\n',sEventIdx(1));end; 
        else
            if(Verbose_TF),fprintf('The length before this to exclude on velocity grounds = %d\n',0);end;
            sEventIdx = b(1);
            if(Verbose_TF),fprintf('Therefore, this blink starts at %d\n',sEventIdx(1));end;  
        end;
    end;
%   if isempty(sEventIdx), continue, end
    if not(isempty(sEventIdx)),ETparams(i,j).data.nanIdx.Idx(sEventIdx:b(1)) = 1;end;
    
    % Go forward in time to see where the blink (noise) ends
    if(Verbose_TF),fprintf('This blink originally ends at %d\n',b(end));end;
    eEventIdx = find(V(b(end):end) <= V_threshold);
    if numel(eEventIdx)> 0
        if(Verbose_TF),fprintf('The length beyond this to exclude on velocity grounds = %d\n',eEventIdx(1));end;
        eEventIdx(1) = (b(end) + eEventIdx(1) - 1);
%         fprintf('eEventIdx(1) = %d\n',eEventIdx(1))
%         fprintf('(b(end)+1) = %d\n',(b(end)+1))
%         pause
        for m = (b(end)+1):eEventIdx(1)
            if ETparams(i,j).data.Classification(m) <3,ETparams(i,j).data.Classification(m)=9;end
        end;
        
        ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 9)=9;
        ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 9)=9;
        ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 9)=9;
        ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 9)=9;
        if(Verbose_TF),fprintf('Therefore, this blink ends at %d\n',eEventIdx(1));end;
    else
        if(Verbose_TF),fprintf('There are no points beyond this point that meet low velocity criteria.\n');end;
        if(Verbose_TF),fprintf('Data length = %d\n',length(V));end;
        eEventIdx(1) = length(V);
        if(Verbose_TF),fprintf('Therefore, this blink ends a end of trial = %d\n',eEventIdx(1));end;        
        PercentOfTrial=100*b(end)/length(V);
        if(Verbose_TF),fprintf('The end of this blink occurs at %5.4f percent of the trial.\n',PercentOfTrial);end;
        if PercentOfTrial < 80;
            fprintf('Blink occurs at less than 90 percent of trial.\n')
            pause
        end;
    end
    if isempty(eEventIdx), continue, end    
    ETparams(i,j).data.nanIdx.Idx(b(end):eEventIdx(1)) = 1;
    ETparams(i,j).data.nanIdx.Idx(ETparams(i,j).data.Classification > 3)=1;
end

temp_idx = find(ETparams(i,j).data.Classification > 3);
ETparams(i,j).Percent_NaNs_with_All_Filters = 100*length(temp_idx)/length(V);
if length(temp_idx)/length(V) > 0.20
    disp('Warning: This trial contains > 20 % noise+blinks samples')
    ETparams(i,j).data.NoiseTrial = 0;
else
    ETparams(i,j).data.NoiseTrial = 1;
end
% ETparams(i,j).data.vel(temp_idx) = NaN;
% ETparams(i,j).data.acc(temp_idx) = NaN;
Count=zeros(9,1);
for q=4:9
    Count(q)=length(find(ETparams(i,j).data.Classification==q));
end;
fprintf('\nN Samples Omitted by EyeLink 100          = %4.4d, Percent = %5.3f\n',Count(4),100*Count(4)/len);
fprintf('N Samples Omitted by SG Filter            = %4.4d, Percent = %5.3f\n',Count(5),100*Count(5)/len);
fprintf('N Samples Omitted - Velocity too fast     = %4.4d, Percent = %5.3f\n',Count(6),100*Count(6)/len);
fprintf('N Samples Omitted - Acceleration too fast = %4.4d, Percent = %5.3f\n',Count(7),100*Count(7)/len);
fprintf('N Samples Omitted - Before a NaN Block    = %4.4d, Percent = %5.3f\n',Count(8),100*Count(8)/len);
fprintf('N Samples Omitted - After a NaN Block     = %4.4d, Percent = %5.3f\n',Count(9),100*Count(9)/len);
Total = sum(Count);
fprintf('Total Samples Omitted =                   = %4.4d, Percent = %5.3f\n\n',Total,100*Total/len);
% csvwrite('CheckClassification.csv',[ETparams(i,j).data.Msec' ETparams(i,j).data.Classification']);
% pause
