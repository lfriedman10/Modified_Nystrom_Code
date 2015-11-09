function GetPreliminaryNoiseStatistics(i,j)
global ETparams
global Scalers
global OutPathStr
global FileName

possibleFixationIdx = ETparams(i,j).data.vel < Scalers.peakDetectionThreshold;
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
maxbin=max(edges);
BinWidth=edges(2)-edges(1);
ModeNoise=edges(N==max(N))+BinWidth/2;
ETparams(i,j).data.ModeNoise = ModeNoise;
ETparams(i,j).data.peakDetectionThreshold        = Scalers.PeakVelocityThreshold;
ETparams(i,j).data.saccadeVelocityThreshold      = Scalers.SacOnOffThresh;
ETparams(i,j).data.WeakGlissadeVelocityThreshold = Scalers.WeakGlissadeVelocityThreshold;
ThisFileName=strcat(FileName(1:12),'_Noise.csv');
fprintf('FileName = %s\n',ThisFileName)
out=[ETparams(i,j).data.ModeNoise Scalers.PeakVelocityThreshold Scalers.SacOnOffThresh Scalers.WeakGlissadeVelocityThreshold];
csvwrite(strcat(OutPathStr,ThisFileName),out)
clear out

SetUpScreen();
h=histogram(fixNoise,40);
ylabel('Frequency (counts)')
xlim([0 Scalers.PeakVelocityThreshold*1.05])
xlabel('Velocity Noise In Fixation');
set(h,'FaceColor',[0.8 0.8 0.8]);
hold on;
PeakThreshold=Scalers.PeakVelocityThreshold;
SacOnOffThresh=Scalers.SacOnOffThresh;
ETparams(i,j).data.ModeNoise = ModeNoise;
x=[ModeNoise ModeNoise];
y=[0 MaxFreq*1.2];
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
ETparams(i,j).data.velPeakIdx  = ETparams(i,j).data.vel > Scalers.PeakVelocityThreshold;

