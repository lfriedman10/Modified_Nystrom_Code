function eventDetection
global ETparams
global Scalers
global this_user
global DrawFiguresTF
global OutPathStr
global FileName
mydir=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\EventDetector1.0\');
%--------------------------------------------------------------------------
% Process eye-movement data for file (participant) and trial separately, i - files, j -
% trials
%--------------------------------------------------------------------------
fprintf('%s\n','Detecting events')
InPathStr=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementRawData\TEX_ONLY_FOR_EVGENY\');
% GoodDataVector=[1:27 29:35 37:49 51:55 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
% GoodDataVector=[45];
% GoodDataVector=[1:27 29:35 37:49 51:55];
% GoodDataVector=[47:49 51:55];
% LowSlopeSet = [ 3 32 51];
% HighSlopeSet= [10 30 45];
% GoodDataVector=[LowSlopeSet HighSlopeSet];
% RanSample=csvread('RandomSamples.csv',1,0);
% GoodDataVector=RanSample(:,1);
% whereis127=find(GoodDataVector==127);
% GoodDataVector=GoodDataVector(whereis127:end);
GoodDataVector=[1:10];
for GoodDataIndex = 1:length(GoodDataVector)
    Subject = GoodDataVector(GoodDataIndex);
    for Session = 1:1%2
        FileName = strcat('S_',num2str(Subject,'%03d'),'_S',num2str(Session),'_TEX.csv');
        FullPath=char(strcat(InPathStr,FileName));
        fprintf('\nInput File: %s\n',FullPath)
        DataArray=csvread(FullPath,2);
        Msec=DataArray(:,1);
        X=DataArray(:,2);
        Y=DataArray(:,3);
        Pupil=DataArray(:,4);
        signals=[Msec X Y Pupil];
        NaNList=isnan(X);
%       fprintf('Number Of NaNs in Raw Data = %d\n',sum(NaNList));
%       fprintf('Length Of Data = %d\n',length(X));
        ETparams.N_original_NaNs=sum(NaNList);
        ETparams.Percent_NaN=100*sum(NaNList)/length(X);
 
        clear DataArray Msec X Y Pupil
        % Calculate velocity and acceleration
        %-------------------------------------
        OutPathStr=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\EventDetector1.0\Results\',FileName(1:12),'\');
        fprintf('OutPathStr = \n%s\n',OutPathStr);
        if ~exist(OutPathStr,'dir'), mkdir(OutPathStr),end;
        if exist(OutPathStr,'dir');cd(OutPathStr);delete('*.csv','*.jpg');cd(mydir);end;
        calVelAcc_sgolay(signals)
        % Characterize Fixation Noise prior to Classification
        %-------------------------------------
        GetPreliminaryNoiseStatistics(Subject,Session);
        % Detect blinks and noise
        %-------------------------------------
        detectAndRemoveNoise()
        % iteratively find the optimal noise threshold
        %-------------------------------------
        ETparams.data.peakDetectionThreshold = Scalers.peakDetectionThreshold;
        % Detect saccades and glissades
        %-------------------------------------  
        detectSaccades();
        fprintf('After Call to detectSaccades ETparams.kk = %d\n',ETparams.kk)
        % Implicitly detect fixations
        %-------------------------------------            
        detectFixations()
        extractFeatures(Subject,Session)
        % Calculate basic parameters
        nsac=[ETparams.kk];
        nsac_small=0;
        for m = 1:nsac;
            SacDurInSamples=[ETparams.sacinfo(m).saccadeInfo.duration]*[Scalers.samplingFreq];
            SacAmpPred=SacDurInSamples*Scalers.AmpDurSlope+Scalers.AmpDurIntercept;
            SacAmpActual=[ETparams.sacinfo(m).saccadeInfo.amplitude];
            SacPkVPred=log10(SacAmpActual)*Scalers.PkVAmpSlope+Scalers.PkVAmpIntercept;
            SacPkVActual=log10(ETparams.sacinfo(m).saccadeInfo.peakVelocity);
            if abs(SacPkVActual-SacPkVPred) > 0.5;
                fprintf('abs(SacPkVActual-SacPkVPred) > 0.5, Act = %f, Prd = %f, Dif = %f\n',SacPkVActual,SacPkVPred,SacPkVActual-SacPkVPred);
            end
%             if [ETparams.sacinfo(m).saccadeInfo.amplitude] <= [Scalers.maxSaccadeAmplitude] &&...
%                [ETparams.sacinfo(m).saccadeInfo.duration]  <= [Scalers.maxSaccadeDuration] && ...
%                abs(SacPkVActual-SacPkVPred) <= [Scalers.maxDistancePkvAmp];%abs(SacAmpActual-SacAmpPred) <= [Scalers.maxDistanceAmpDur] &&...
%                     nsac_small=nsac_small+1;
%             end;
        end
        fprintf('Total Number of Saccades = %d, Total Number of Small Saccades = %d, Number of Large Saccades = %d\n',nsac,nsac_small,nsac-nsac_small);
        sac_start=zeros(nsac_small,1);
        sac_end=zeros(nsac_small,1);
        sac_dur=zeros(nsac_small,1);
        sac_amp=zeros(nsac_small,1);
        sac_local_vel_Thrsh=zeros(nsac_small,1);
        sac_pk_vel=zeros(nsac_small,1);
        sac_pk_acc=zeros(nsac_small,1);
        gliss_dur=zeros(nsac_small,1);
        gliss_type=zeros(nsac_small,1);
%       sac_and_glis_dur=zeros(nsac_small,1);
        kk=1;
        for k = 1:nsac
            if [ETparams.sacinfo(k).saccadeInfo.amplitude] > [Scalers.maxSaccadeAmplitude];continue;end;
            if [ETparams.sacinfo(k).saccadeInfo.duration]  > [Scalers.maxSaccadeDuration];continue;end;
%             SacDurInSamples=[ETparams.sacinfo(k).saccadeInfo.duration]*[Scalers.samplingFreq];
%             SacAmpPred=SacDurInSamples*Scalers.AmpDurSlope+Scalers.AmpDurIntercept;
%             SacAmpActual=[ETparams.sacinfo(k).saccadeInfo.amplitude];       
%             if abs(SacAmpActual-SacAmpPred) > [Scalers.maxDistanceAmpDur];
%                 fprintf(' Removing a saccade that is too far from ideal. Amp = %f, Ideal = %f, Diff = %f\n',...
%                     SacAmpActual,SacAmpPred,SacAmpActual-SacAmpPred);
%                 continue;
%             end;
%             SacPkVPred=log10(SacAmpActual)*Scalers.PkVAmpSlope+Scalers.PkVAmpIntercept;
%             SacPkVActual=log10(ETparams.sacinfo(k).saccadeInfo.peakVelocity);
%             if abs(SacPkVActual-SacPkVPred) > 0.5;
%                 fprintf('abs(SacPkVActual-SacPkVPred) > 0.6, Act = %f, Prd = %f, Dif = %f\n',SacPkVActual,SacPkVPred,SacPkVActual-SacPkVPred);
%                 continue
%             end 
            % Saccade Measures
            sac_start(kk)          =[ETparams.sacinfo(k).saccadeInfo.start    ];%in seconds
            sac_end(kk)            =[ETparams.sacinfo(k).saccadeInfo.end      ];%in second
            sac_dur(kk)            =[ETparams.sacinfo(k).saccadeInfo.duration ]*1000;%in msec
            sac_amp(kk)            =[ETparams.sacinfo(k).saccadeInfo.amplitude];
            sac_local_vel_Thrsh(kk)=[ETparams.sacinfo(k).localSaccadeVelocityThreshold];
            sac_pk_vel(kk)         =[ETparams.sacinfo(k).saccadeInfo.peakVelocity];
            sac_pk_acc(kk)         =[ETparams.sacinfo(k).saccadeInfo.peakAcceleration];
            % Glissade Measures          
            gliss_dur(kk)           =[ETparams.glisinfo(k).glissadeInfo.duration]*Scalers.samplingFreq;%in seconds
            gliss_type(kk)          =[ETparams.glisinfo(k).glissadeInfo.type];
%           sac_and_glis_dur(kk) = sac_dur(kk)+gliss_dur(kk);
            kk=kk+1;
        end;
        gliss_dur=gliss_dur(gliss_dur>0);
        Ngliss=length(gliss_type(gliss_type > 0)); 
        Ngliss_type_1=length(gliss_type(gliss_type == 1));
        Ngliss_type_2=length(gliss_type(gliss_type == 2));
        fprintf('Ngliss = %d, Ngliss_type_1 = %d,Ngliss_type_2 = %d, 1+2= %d\n',Ngliss,Ngliss_type_1,Ngliss_type_2,Ngliss_type_1+Ngliss_type_2);
        Ngliss_type_GE_3=length(gliss_type(gliss_type >= 3));
        if (Ngliss_type_GE_3 > 0),fprintf('...found at least 1 Ngliss_type_GE_3 = %d\n',Ngliss_type_GE_3),pause,end;
        %
        % Process fixations
        %       
        nfix=[ETparams.ff];
        fix_dur=zeros(nfix,1);
        fix_Vpos=zeros(nfix,1);
        fix_Msec=zeros(nfix,1);
        for k = 1:nfix
            fix_dur(k)=[ETparams.fixinfo(k).fixationInfo.duration]*Scalers.samplingFreq;
            fix_Vpos(k)=ETparams.fixinfo(k).fixationInfo.meanYSmoPos;
            fix_Msec(k)=ETparams.fixinfo(k).fixationInfo.start;
        end;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_VposFixations.jpg');plot(fix_Msec,fix_Vpos);xlabel('Seconds');ylabel('Vert Pos of Fixation');title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Vertical Position of Fixation']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        %      Create Histograms
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_sac_dur.jpg');histogram(sac_dur,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Saccade Duration (msec)']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_sac_amp.jpg');histogram(sac_amp,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Saccade Radial Amplitude (deg)']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        sac_lvt=sac_local_vel_Thrsh;clear sac_local_vel_Thrsh;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_sac_lvt.jpg');histogram(sac_lvt,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Saccade LocVelThreshold (deg/sec)']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        sac_pkv=sac_pk_vel;clear sac_pk_vel;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_sac_pkv.jpg');histogram(sac_pkv,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Saccade Peak Velocity (deg/sec) ']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        sac_pka=sac_pk_acc;clear sac_pk_acc;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_sac_pka.jpg');histogram(sac_pka,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Saccade Peak Accelerat. (deg/sec^2)']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        gls_dur=gliss_dur;clear gliss_dur;
        if DrawFiguresTF;SetUpScreen();ImgFileName=strcat(FileName(1:12),'_gls_dur.jpg');histogram(gls_dur,100);title(['Subject = ',num2str(Subject),', Session = ',num2str(Session),' Glissade Duration (msec)']);saveas(gcf,[OutPathStr ImgFileName]);close all;end;
        ImgFileName=strcat(FileName(1:12),'_Amp_vs_Dur.jpg');
        [amp_dur_intercept,amp_dur_slope,amp_dur_rsqr]=PlotXYwithRegression(sac_dur',sac_amp','Saccade Duration (msec)','Saccade Amplitude (deg)',OutPathStr,ImgFileName,1);
        ImgFileName=strcat(FileName(1:12),'_pkv_vs_amp.jpg');
        [pkv_amp_intercept,pkv_amp_slope,pkv_amp_rsqr]=PlotXYwithRegression(log10(sac_amp'),log10(sac_pkv'),'log10 Saccade Amplitude (msec)','log10 Saccade Peak Velocity (deg/sec)',OutPathStr,ImgFileName,2);

%       Create output table
        
        fprintf('\nSubject = %d, Session = %d\n',Subject,Session)
        fprintf('----------------------------------------------------------------------------------\n');
        fprintf('Mode of Noise                  = %9.4f\n',ETparams.data.ModeNoise)
        fprintf('Median Saccade Duration        = %9.4f, N = %d \n',median(sac_dur),nsac_small)
        fprintf('Minumum Saccade Duration       = %9.4f, N = %d \n',min(sac_dur),nsac_small)
        fprintf('Saccade Duration - 10thprctile = %9.4f, N = %d \n',prctile(sac_dur,10),nsac_small)
        fprintf('Median Saccade Amplitude       = %9.4f, N = %d \n',median(sac_amp),nsac_small)
        fprintf('Minimum Saccade Amplitude      = %9.4f, N = %d \n',min(sac_amp),nsac_small)
        fprintf('Saccade Amplitude - 10thprctile= %9.4f, N = %d \n',prctile(sac_amp,10),nsac_small)
        fprintf('Median Saccade Local Threshold = %9.4f, N = %d \n',median(sac_lvt),nsac_small)
        fprintf('Median Saccade Pk Velocity     = %9.4f, N = %d \n',median(sac_pkv),nsac_small)
        fprintf('Median Saccade Pk Acceler.     = %9.4f, N = %d \n',median(sac_pka),nsac_small)
        fprintf('Median Fixation Duration       = %9.4f, N = %d \n',median(fix_dur),nfix)
        fprintf('Median Glissade Duration       = %9.4f, N = %d, Percent glissadic saccades = %5.2f \n',median(gls_dur),Ngliss,100*Ngliss/nsac_small)
        fprintf('Amplit. vs Duration, Intercept = %9.4f\n',amp_dur_intercept);
        fprintf('Amplit. vs Duration, Slope     = %9.4f\n',amp_dur_slope);
        fprintf('Amplit. vs Duration, r-squared = %9.4f\n',amp_dur_rsqr);
        fprintf('PeakVel vs Amplit.,  Intercept = %9.4f\n',pkv_amp_intercept);
        fprintf('PeakVel vs Amplit.,  Slope     = %9.4f\n',pkv_amp_slope);
        fprintf('PeakVel vs Amplit.,  r-squared = %9.4f\n',pkv_amp_rsqr);
        fprintf('Prcnt Original Data that is NaN= %9.4f\n',[ETparams.Percent_NaN])
        fprintf('Prcnt Process Data that is NaN = %9.4f\n',[ETparams.Percent_NaNs_with_All_Filters])
        fprintf('Number of NaN Periods          = %9.4f\n',[ETparams.NumBlinks]); 
        fprintf('Median Pupil Size              = %9.4f\n',median(ETparams.data.Pupil,'omitnan'))   
        fprintf('Nglissade_type_1 = %d, Nglissade_type_2 = %d, sum = %d\n\n\n',Ngliss_type_1,Ngliss_type_2,Ngliss_type_1+Ngliss_type_2);        
        heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
        heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
        fprintf(' Before GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
        clear ETparams
        global ETparams;
        java.lang.Runtime.getRuntime.gc;
        heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
        fprintf(' After  GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
    end    
end
return
