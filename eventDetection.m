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
InPathStr=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementRawData\');
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
GoodDataVector=[1:30];
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
%         fprintf('Number Of NaNs in Raw Data = %d\n',sum(NaNList));
%         fprintf('Length Of Data = %d\n',length(X));
        ETparams(Subject,Session).N_original_NaNs=sum(NaNList);
        ETparams(Subject,Session).Percent_NaN=100*sum(NaNList)/length(X);
 
        clear DataArray Msec X Y Pupil
        % Calculate velocity and acceleration
        %-------------------------------------
        OutPathStr=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\EventDetector1.0\Results\',FileName(1:12),'\');
        fprintf('OutPathStr = \n%s\n',OutPathStr);
        if ~exist(OutPathStr,'dir'), mkdir(OutPathStr),end;
        if exist(OutPathStr,'dir');cd(OutPathStr);delete('*.csv','*.jpg');cd(mydir);end;
        calVelAcc_sgolay(Subject,Session,signals)
        % Detect blinks and noise
        %-------------------------------------
        detectAndRemoveNoise(Subject,Session)
        % iteratively find the optimal noise threshold
        %-------------------------------------
        ETparams(Subject,Session).data.peakDetectionThreshold = Scalers.peakDetectionThreshold;
        GetPreliminaryNoiseStatistics(Subject,Session);
        % Detect saccades and glissades
        %-------------------------------------            
        detectSaccades(Subject,Session);
        % Implicitly detect fixations
        %-------------------------------------            
        detectFixations(Subject,Session)
        ExtractFeatures('T')
        % Calculate basic parameters
        nsac=[ETparams(Subject,Session).kk];
        nsac_small=0;
        for m = 1:nsac;
            SacDurInSamples=[ETparams(Subject,Session).sacinfo(m).saccadeInfo.duration]*[Scalers.samplingFreq];
            SacAmpPred=SacDurInSamples*Scalers.AmpDurSlope+Scalers.AmpDurIntercept;
            SacAmpActual=[ETparams(Subject,Session).sacinfo(m).saccadeInfo.amplitude];
            SacPkVPred=log10(SacAmpActual)*Scalers.PkVAmpSlope+Scalers.PkVAmpIntercept;
            SacPkVActual=log10(ETparams(Subject,Session).sacinfo(m).saccadeInfo.peakVelocity);
            if abs(SacPkVActual-SacPkVPred) > 0.5;
                fprintf('abs(SacPkVActual-SacPkVPred) > 0.5, Act = %f, Prd = %f, Dif = %f\n',SacPkVActual,SacPkVPred,SacPkVActual-SacPkVPred);
            end
            if [ETparams(Subject,Session).sacinfo(m).saccadeInfo.amplitude] <= [Scalers.maxSaccadeAmplitude] &&...
               [ETparams(Subject,Session).sacinfo(m).saccadeInfo.duration]  <= [Scalers.maxSaccadeDuration] && ...
               abs(SacPkVActual-SacPkVPred) <= [Scalers.maxDistancePkvAmp];%abs(SacAmpActual-SacAmpPred) <= [Scalers.maxDistanceAmpDur] &&...
                    nsac_small=nsac_small+1;
            end;
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
            if [ETparams(Subject,Session).sacinfo(k).saccadeInfo.amplitude] > [Scalers.maxSaccadeAmplitude];continue;end;
            if [ETparams(Subject,Session).sacinfo(k).saccadeInfo.duration]  > [Scalers.maxSaccadeDuration];continue;end;
%             SacDurInSamples=[ETparams(Subject,Session).sacinfo(k).saccadeInfo.duration]*[Scalers.samplingFreq];
%             SacAmpPred=SacDurInSamples*Scalers.AmpDurSlope+Scalers.AmpDurIntercept;
%             SacAmpActual=[ETparams(Subject,Session).sacinfo(k).saccadeInfo.amplitude];       
%             if abs(SacAmpActual-SacAmpPred) > [Scalers.maxDistanceAmpDur];
%                 fprintf(' Removing a saccade that is too far from ideal. Amp = %f, Ideal = %f, Diff = %f\n',...
%                     SacAmpActual,SacAmpPred,SacAmpActual-SacAmpPred);
%                 continue;
%             end;
%             SacPkVPred=log10(SacAmpActual)*Scalers.PkVAmpSlope+Scalers.PkVAmpIntercept;
%             SacPkVActual=log10(ETparams(Subject,Session).sacinfo(k).saccadeInfo.peakVelocity);
%             if abs(SacPkVActual-SacPkVPred) > 0.5;
%                 fprintf('abs(SacPkVActual-SacPkVPred) > 0.6, Act = %f, Prd = %f, Dif = %f\n',SacPkVActual,SacPkVPred,SacPkVActual-SacPkVPred);
%                 continue
%             end 
            % Saccade Measures
            sac_start(kk)          =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.start    ];%in ms
            sac_end(kk)            =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.end      ];%in ms
            sac_dur(kk)            =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.duration ]*[Scalers.samplingFreq];%in ms
            sac_amp(kk)            =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.amplitude];
            sac_local_vel_Thrsh(kk)=[ETparams(Subject,Session).sacinfo(k).localSaccadeVelocityThreshold];
            sac_pk_vel(kk)         =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.peakVelocity];
            sac_pk_acc(kk)         =[ETparams(Subject,Session).sacinfo(k).saccadeInfo.peakAcceleration];
            % Glissade Measures          
            gliss_dur(kk)           =[ETparams(Subject,Session).glisinfo(k).glissadeInfo.duration]*Scalers.samplingFreq;%in seconds
            gliss_type(kk)          =[ETparams(Subject,Session).glisinfo(k).glissadeInfo.type];
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
        nfix=[ETparams(Subject,Session).ff];
        fix_dur=zeros(nfix,1);
        fix_Vpos=zeros(nfix,1);
        fix_Msec=zeros(nfix,1);
        for k = 1:nfix
            fix_dur(k)=[ETparams(Subject,Session).fixinfo(k).fixationInfo.duration]*Scalers.samplingFreq;
            fix_Vpos(k)=ETparams(Subject,Session).fixinfo(k).fixationInfo.meanYSmoPos;
            fix_Msec(k)=ETparams(Subject,Session).fixinfo(k).fixationInfo.start;
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
        [amp_dur_intercept,amp_dur_slope,amp_dur_rsqr]=PlotXYwithRegression(sac_dur,sac_amp,'Saccade Duration (msec)','Saccade Amplitude (deg)',OutPathStr,ImgFileName,1);
        ImgFileName=strcat(FileName(1:12),'_pkv_vs_amp.jpg');
        [pkv_amp_intercept,pkv_amp_slope,pkv_amp_rsqr]=PlotXYwithRegression(log10(sac_amp),log10(sac_pkv),'log10 Saccade Amplitude (msec)','log10 Saccade Peak Velocity (deg/sec)',OutPathStr,ImgFileName,2);

%       Create output table
        
        fprintf('\nSubject = %d, Session = %d\n',Subject,Session)
        fprintf('----------------------------------------------------------------------------------\n');
        fprintf('Mode of Noise                  = %9.4f\n',ETparams(Subject,Session).data.ModeNoise)
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
        fprintf('Prcnt Original Data that is NaN= %9.4f\n',[ETparams(Subject,Session).Percent_NaN])
        fprintf('Prcnt Process Data that is NaN = %9.4f\n',[ETparams(Subject,Session).Percent_NaNs_with_All_Filters])
        fprintf('Number of NaN Periods          = %9.4f\n',[ETparams(Subject,Session).NumBlinks]); 
        fprintf('Median Pupil Size              = %9.4f\n',median(ETparams(Subject,Session).data.Pupil,'omitnan'))   
        fprintf('Nglissade_type_1 = %d, Nglissade_type_2 = %d, sum = %d\n\n\n',Ngliss_type_1,Ngliss_type_2,Ngliss_type_1+Ngliss_type_2); 
%       Create .csv output file        
        NglisTypeSum=(Ngliss_type_1+Ngliss_type_2);
        out=[Subject Session ...
             nfix ...
             nsac_small ...
             Ngliss ...
             100*Ngliss/nsac_small ...
             Ngliss_type_1 ...
             Ngliss_type_2 ...
             NglisTypeSum ...
             amp_dur_intercept ...
             amp_dur_slope ...
             amp_dur_rsqr ...
             pkv_amp_intercept ...
             pkv_amp_slope ...
             pkv_amp_rsqr ...
             [ETparams(Subject,Session).Percent_NaN] ...
             [ETparams(Subject,Session).Percent_NaNs_with_All_Filters] ...
             [ETparams(Subject,Session).NumBlinks] ...
             median(ETparams(Subject,Session).data.Pupil,'omitnan') ...
             [ETparams(Subject,Session).data.ModeNoise] ...
             median(fix_dur) ...
             median(sac_dur) ...
             min(sac_dur) ...
             prctile(sac_dur,10) ...
             median(sac_amp) ...
             min(sac_amp) ...
             prctile(sac_amp,10) ...
             nanmedian(sac_lvt) ...
             median(sac_pkv) ...
             median(sac_pka) ...
             median(gls_dur) ...
             mean(fix_dur) ...
             mean(sac_dur) ...
             mean(sac_amp) ...
             nanmean(sac_lvt) ...
             mean(sac_pkv) ...
             mean(sac_pka) ...
             mean(gls_dur)];
%   Define Headers:
headers = { 'Subject','Session','Nfix','Nsac','Ngliss','GlisPrcnt','NglsType1','NglsType2', ...
            'Typ1+Typ2','amp_dur_int','amp_dur_slp','amp_dur_rsqr','pkv_amp_int', ...
            'pkv_amp_slp','pkv_amp_rsqr','Percent_NaN_O','Percent_NaN_P','N_Blinks',...
            'Pupil','ModeNoise', ...
            'MdnFixDur','MdnSacDur','MinSacDur','Sac_Dur_10', ...
            'MdnSacAmp','MinSacAmp','Sac_Amp_10', ...
            'MdnSacLVT','MdnSacPkV', ...
            'MdnSacPkA','MdnGlisDur', ...
            'MnFixDur','MnSacDur','MnSacAmp','MnSacLVT','MnSacPkV', ...
            'MnSacPkA','MnGlisDur'};
             csvwrite_with_headers([OutPathStr FileName(1:12) '.csv'],out,headers)
    end
    heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
    heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
    clear ETparams(Subject,Session).data.Xorg
    clear ETparams(Subject,Session).data.Yorg
%     clear ETparams(Subject,Session).data.velXorg
%     clear ETparams(Subject,Session).data.velYorg
%     clear ETparams(Subject,Session).data.velOrg
%     clear ETparams(Subject,Session).data.X
%     clear ETparams(Subject,Session).data.Y
    clear ETparams(Subject,Session).data.RawRadialPos
    clear ETparams(Subject,Session).data.SmoothRadialPos
%     clear ETparams(Subject,Session).data.velX
%     clear ETparams(Subject,Session).data.velY
    clear ETparams(Subject,Session).data.vel
%     clear ETparams(Subject,Session).data.accX
%     clear ETparams(Subject,Session).data.accY
    clear ETparams(Subject,Session).data.acc
    fprintf(' Before GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
    java.lang.Runtime.getRuntime.gc;
    heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
    fprintf(' After  GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))

end    
end
