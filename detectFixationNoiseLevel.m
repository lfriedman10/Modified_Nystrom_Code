function GetPreliminaryNoiseStatistics(i,j)
global ETparams
global Scalers
global OutPathStr
global FileName

possibleFixationIdx = ~ETparams(i,j).data.InitialVelPeakIdx;
fixLabeled = bwlabel(possibleFixationIdx);

% Process one inter-peak-saccadic periods (called fixations below,
% although they are not identified as fixations yet). 
fixNoise = [];
for k = 1:max(fixLabeled)

    % The samples related to the current fixation
    fixIdx = find(fixLabeled == k);
    
    % Check that the fixation duration exceeds the minimum duration criteria. 
    if length(fixIdx)/[Scalers.samplingFreq] < [Scalers.minFixDur]
        continue    
    end
    
    % Extract the samples from the center of the fixation
    centralFixSamples = [Scalers.minFixDur]*[Scalers.samplingFreq]/6;
    fNoise = ETparams(i,j).data.vel(floor(fixIdx(1)+centralFixSamples):ceil(fixIdx(end)-centralFixSamples));
    fixNoise = [fixNoise fNoise];
end
[N,edges] = histcounts(fixNoise,40);
MaxFreq=max(N);
y=[0 MaxFreq*1.2];
maxbin=max(edges);
BinWidth=edges(2)-edges(1);
ModeNoise=edges(N==max(N))+BinWidth/2;
ETparams(Subject,Session).data.ModeNoise=ModeNoise;
if ~exist('PreviousModeNoise','var');PreviousModeNoise=Inf;end;
fprintf('Before Test: Subject=%d,Sess=%d,ModeNoise=%f,PreviousModeNoise=%f\n',i,j,ModeNoise,PreviousModeNoise);
% if ModeNoise > PreviousModeNoise;
if ModeNoise == ModeNoise;
    fprintf('Test Passed: Subject=%d,Sess=%d,ModeNoise=%f,PreviousModeNoise=%f\n',i,j,ModeNoise,PreviousModeNoise);
    ModeNoise=PreviousModeNoise;
    fprintf('Setting ModeNoise to PreviousModeNoise, Subject=%d,Sess=%d,ModeNoise=%f\n',i,j,ModeNoise);
    ETparams(i,j).data.ModeNoise = ModeNoise;
    ETparams(i,j).data.peakDetectionThreshold        = Scalers.PeakVelocityThreshold;
    ETparams(i,j).data.saccadeVelocityThreshold      = Scalers.SacOnOffThresh;
    ETparams(i,j).data.WeakGlissadeVelocityThreshold = Scalers.WeakGlissadeVelocityThreshold;
    ThisFileName=strcat(FileName(1:12),'_Noise.csv');
    fprintf('FileName = %s\n',ThisFileName)
    out=[ETparams(i,j).data.ModeNoise Scalers.PeakVelocityThreshold Scalers.SacOnOffThresh Scalers.WeakGlissadeVelocityThreshold];
    csvwrite(strcat(OutPathStr,ThisFileName),out)
    clear out
    Finished=true;
    ETparams(i,j).data.velPeakIdx  = ETparams(i,j).data.vel > Scalers.PeakVelocityThreshold;
    return
end;
PreviousModeNoise=ModeNoise;
SetUpScreen();
h=histogram(fixNoise,40);
ylabel('Frequency (counts)')
xlabel('Velocity Noise In Fixation');
set(h,'FaceColor',[0.8 0.8 0.8]);
hold on;
PeakThreshold=ModeNoise*Scalers.NsigmaPeak;
SacOnOffThresh=ModeNoise*Scalers.NsigmaOnOff;
ETparams(i,j).data.ModeNoise = ModeNoise;
ETparams(i,j).data.saccadeVelocityThreshold = SacOnOffThresh;
ETparams(i,j).data.peakDetectionThreshold   = PeakThreshold;
x=[ModeNoise ModeNoise];
plot(x,y,'-g','linewidth',4)
text(maxbin*0.25,MaxFreq*0.5,['Mode = ' num2str(ModeNoise,'%5.2f')]);
x=[SacOnOffThresh SacOnOffThresh];
plot(x,y,'-b','linewidth',4)
text(SacOnOffThresh*0.96,MaxFreq*0.5,'Sac On/Off Thresh','rotation',90)
x=[PeakThreshold PeakThreshold];
plot(x,y,'-r','linewidth',4)
text(PeakThreshold*0.97,MaxFreq*0.5,'Sac Peak Thresh','rotation',90)
fprintf('Mode Noise = %f\n',ETparams(i,j).data.ModeNoise);
title([' Velocity Noise in Fixation' ' | Subject = ',num2str(i),' | Session = ',num2str(j)])
ImgFileName=strcat(OutPathStr,FileName(1:12),'_Noise.jpg');
saveas(gcf,ImgFileName);
ETparams(i,j).data.velPeakIdx  = ETparams(i,j).data.vel > [ETparams(i,j).data.peakDetectionThreshold];
Finished=false;


