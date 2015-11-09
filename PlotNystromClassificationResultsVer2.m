function PlotNystromClassificationResultsVer2()
    clc
    clear all
    close all
    WhichUser=2;user=['l_f96';'leef ';'lee  '];CS=cellstr(user);this_user=char(CS(WhichUser));
    PathStr=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\EventDetector1.0\Results\');
    %  GoodDataVector=[1:27 29:35 37:49 51:55];
    %  GoodDataVector=[1:27 29:35 37:49 51:56 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
%     LowSlopeSet = [3 32 51];
%     HighSlopeSet= [10 30 45];
%     GoodDataVector=[LowSlopeSet HighSlopeSet];
% %     GoodDataVector=3;
%      GoodDataVector=45;
    RanSample=csvread('RandomSamples.csv',1,0);
    GoodDataVector=RanSample(:,1);
    for GoodDataIndex = 1:length(GoodDataVector)
        Subject = GoodDataVector(GoodDataIndex);
        for Session = 1:1%2
            plotEyeMovement(PathStr,Subject,Session,this_user)
%             pause
        end
    end
end

function plotEyeMovement(PathStr,Subject,Session,this_user)

% TEX_001_S1.csv
% Get Classification csv file
% SubDirName=strcat('S_',num2str(Subject,'%03d'),'_S',num2str(Session),'_TEX (1)\');
SubDirName=strcat('S_',num2str(Subject,'%03d'),'_S',num2str(Session),'_TEX\');
[ColorSet,ColorCode]=LoadColors(strcat(PathStr,SubDirName));
FileName=strcat(SubDirName(1:12),'_Class.csv');
FullPath=char(strcat(PathStr,SubDirName,FileName));
fprintf('Input File: %s\n',FullPath)
DataArray=csvread(FullPath);
NSamples=length(DataArray);
% fprintf('The total number of samples is %d\n',NSamples)
% Get Noise and Velocity Threshold File
FileName=strcat(SubDirName(1:12),'_Noise.csv');
FullPath=char(strcat(PathStr,SubDirName,FileName));
% fprintf('Input File: %s\n',FullPath)
NoiseData=csvread(FullPath);
ModeNoise=NoiseData(1);
PkThresh=NoiseData(2);
OnOffThreshold=NoiseData(3);
WeakGlissadeThreshold=NoiseData(4)
fprintf('PkThresh=%f,OnOffThreshold=%f\n',PkThresh,OnOffThreshold)

[pathstr, NameOnly, ext]=fileparts(FullPath);

commandwindow;
NSamples=length(DataArray);
fprintf('The total number of samples is %d\n',NSamples)
%
% plot Each Second of DATA
%
for i = 1:1000:NSamples
    tic
    ImageFileName=[NameOnly(1:12) '-' num2str(i,'%06d') '-' num2str(i+999,'%06d') '.jpg'];
    StartMsec=i;
    EndMsec=i+1000;
    MyTitle=[NameOnly ' |Start Msec = ' num2str(i,'%06d') ' | End Msec = ' num2str(i+999,'%06d') ' |'];
    fprintf('%s\n',MyTitle)
    [TimeToSaveFile]=plotMyData(DataArray,StartMsec,EndMsec,MyTitle,PathStr,SubDirName,ImageFileName,NSamples,PkThresh,OnOffThreshold,WeakGlissadeThreshold,ColorSet);
    ElapsedTime=toc-TimeToSaveFile;
    fprintf('Time to plot 1 sec of data is %f\n',ElapsedTime);
    % Clear java memoty
    heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
    heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
    fprintf(' Before Clear and GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
%     clear java
    java.lang.System.gc
    java.lang.System.gc()
    close all
    heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
    heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
    fprintf(' After  Clear and GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
end
return
end

function [TimeToSaveFile]=plotMyData(DataArray,StartMsec,EndMsec,MyTitle,PathStr,SubDirName,ImageFileName,NSamples,PkThresh,OnOffThreshold,WeakGlissadeThreshold,ColorSet)
Height=685;
Width=1100;
% myposition=[1288  2 Width Height];
% myposition=[1360 210 Width Height]; 
myposition=[10 25 Width Height]; 
FigHandle=figure(1);
set(FigHandle,'units','pixels','position',myposition);% ,'Color',[0.8 0.8 0.8]);
set(FigHandle,'visible','on');
% set(FigHandle,'visible','on');
set(FigHandle,'GraphicsSmoothing','off','Renderer','zbuffer');
s=StartMsec;
e=min(EndMsec,NSamples);
if e-s < 100,return,end;
% fprintf('Start Sample= %d, End Sample = %d\n',s,e)

Msec =DataArray(:,1);
Xorg =DataArray(:,2)+1;
Xsmo =DataArray(:,3);
Yorg =DataArray(:,4)+1;
Ysmo =DataArray(:,5);
Vel  =DataArray(:,6);
% VelIsNaN=find(isnan(Vel));
% Vel(VelIsNaN)=1000;
Acc  =DataArray(:,7);
Pupil=DataArray(:,8);
Class=DataArray(:,9);
SubType=DataArray(:,10);

XsmoClass=NaN(NSamples,12);YsmoClass=NaN(NSamples,12);Vel_Class=NaN(NSamples,12);
for i = 1:11
    ClassType=find(Class==i);
    XsmoClass(ClassType,i)=Xsmo(ClassType);
    YsmoClass(ClassType,i)=Ysmo(ClassType);
    Vel_Class(ClassType,i)=Vel(ClassType);
    ClassLength=length(ClassType);
    fprintf('Class = %d, Total = %d\n',i,ClassLength)
end;
ClassType=find(Class==0);
XsmoClass(ClassType,12)=Xsmo(ClassType);
YsmoClass(ClassType,12)=Ysmo(ClassType);
Vel_Class(ClassType,12)=Vel(ClassType);
for Nsubplot = 1:3
    ax = subplot(3,1,Nsubplot);
    ax.Color=[0.5 0.5 0.5];
    ax.XLimMode='manual';
    ax.YLimMode='manual';
    ax.XLim=[s-1 s-1+1000];
    if Nsubplot ==1;
          ax.Color=[0.5 0.5 0.5];
%         if min(Xsmo(s:e)) < max(Xsmo(s:e));
%             mymin=min(Xsmo(s:e));mymax=max(Xsmo(s:e));increment=(mymax-mymin)*.10;
%             ax.YLim=[mymin-increment mymax+increment];
%         end;
        LowLim=-10;UpLim=10;
        if min(Xsmo(s:e)) < -10,LowLim = min(Xsmo(s:e));end
        if max(Xsmo(s:e)) >  10,UpLim  = max(Xsmo(s:e));end
        ax.YLim=[LowLim UpLim];
    end;
    if Nsubplot == 2;
          ax.Color=[0.5 0.5 0.5];
%         if min(Ysmo(s:e)) < max(Ysmo(s:e));
%             mymin=min(Ysmo(s:e));mymax=max(Ysmo(s:e));increment=(mymax-mymin)*.10;
%             ax.YLim=[mymin-increment mymax+increment];
%         end;
        LowLim=-10;UpLim=10;
        if min(Ysmo(s:e)) < -10,LowLim = min(Ysmo(s:e));end
        if max(Ysmo(s:e)) >  10,UpLim  = max(Ysmo(s:e));end
        ax.YLim=[LowLim UpLim];
    end;
%     if Nsubplot == 3;ax.YLim=[0 2.0*PkThresh];end;
    if Nsubplot == 3;ax.Color=[0.5 0.5 0.5];ax.YLim=[0 90];end;
    hold on
    if Nsubplot == 1;
        ylabel('Hor Pos');
%       ax.YLim=[0 20];
%         Y_Event_Labels = (min(Xsmo(s:e))+max(Xsmo(s:e)))/2.;
%         text(s+100,Y_Event_Labels,'FIX','color','green')
%         text(s+200,Y_Event_Labels,'SAC','color','red')
%         text(s+300,Y_Event_Labels,'GLS','color','blue')
%         text(s+400,Y_Event_Labels,'ONaN','color','cyan')
%         text(s+500,Y_Event_Labels,'SGNaN','color','magenta')
%         text(s+600,Y_Event_Labels,'NaN','color','yellow')
%         text(s+700,Y_Event_Labels,'NoClass','color','black') 
    elseif  Nsubplot == 2;
%         plot(s,Ysmo(s),'.w');
%         plot(e,Ysmo(e),'.w'); 
        ylabel('Vert Pos');
    elseif  Nsubplot == 3;
%         plot(s,Vel(s),'.w');
%         plot(e,Vel(e),'.w');
        ylabel('Velocity');
    end     
    minpos=1000;
    maxpos=-1000;
%     fprintf('NSamples = %d\n',NSamples);
%     fprintf('Init: minpos = %f, maxpos=%f \n',minpos,maxpos)
%              123456789012
    for j = s:1000:max(e,s+1);
       if Nsubplot == 1;
           for m = 1:12
               plot(Msec(s:e),XsmoClass(s:e, m),'LineStyle','-','Color',ColorSet(m,:),'linewidth',2);
           end
           text(s+1000-110,4,'EyeLink NaNs'  ,'color',ColorSet(4,:),'fontsize',7)
           text(s+1000-225,5,'SG NaNs'       ,'color',ColorSet(5,:),'fontsize',7)
           text(s+1000-110,6,'Vel Too Fast'  ,'color',ColorSet(6,:),'fontsize',7)
           text(s+1000-225,7,'Acc too Fast'  ,'color',ColorSet(7,:),'fontsize',7)
           text(s+1000-110,8,'Pre NaN Block' ,'color',ColorSet(8,:),'fontsize',7)
           text(s+1000-225,9,'Post NaN Block','color',ColorSet(9,:),'fontsize',7)
           if Xorg(j) < minpos;
               minpos=Xorg(j);
           end;
%            fprintf('j=%d,RadPos(j)=%f,maxpos = %f \n',j,RadPos(j),maxpos);
           if Xorg(j) > maxpos;
%                fprintf('setting maxpos\n');
               maxpos=Xorg(j);
           end;
       elseif Nsubplot == 2;
           subplot(3,1,Nsubplot)
           for m = 1:12
               plot(Msec(s:e),YsmoClass(s:e, m),'LineStyle','-','Color',ColorSet(m,:),'linewidth',2);
           end
           text(s+1000-110,4,'EyeLink NaNs'  ,'color',ColorSet(4,:),'fontsize',7)
           text(s+1000-225,5,'SG NaNs'       ,'color',ColorSet(5,:),'fontsize',7)
           text(s+1000-110,6,'Vel Too Fast'  ,'color',ColorSet(6,:),'fontsize',7)
           text(s+1000-225,7,'Acc too Fast'  ,'color',ColorSet(7,:),'fontsize',7)
           text(s+1000-110,8,'Pre NaN Block' ,'color',ColorSet(8,:),'fontsize',7)
           text(s+1000-225,9,'Post NaN Block','color',ColorSet(9,:),'fontsize',7)
       elseif Nsubplot == 3;
           subplot(3,1,Nsubplot)
           for m = 1:12
               plot(Msec(s:e),Vel_Class(s:e, m),'LineStyle','-','Color',ColorSet(m,:),'linewidth',2);
           end
% 
%            plot(Msec(s:e),Vel_Class(s:e,1),'color',ColorSet(1,:),'linewidth',2);
%            plot(Msec(s:e),Vel_Class(s:e,2),'color',ColorSet(2,:),'linewidth',2);
%            plot(Msec(s:e),Vel_Class(s:e,3),'color',ColorSet(3,:),'linewidth',2);
       end;
       xlabel('Time (msec)');
       ax=gca;
       ax.XTickLabelMode='manual';
       ax.XTick = [s-1:200:s-1+1000];
       ax.XTickLabel={num2str(s-1,'%05d'),num2str(s-1+200,'%05d'),num2str(s-1+400,'%05d'),num2str(s-1+600,'%05d'),num2str(s-1+800,'%05d'),num2str(s-1+1000,'%05d')};
       ax.XTickLabelRotation=90;
    end
%     fprintf('End: minpos = %f, maxpos=%f \n',minpos,maxpos)
%     if Nsubplot == 1;ax.YLim=[minpos maxpos];end;
    if Nsubplot == 1;
%         if maxpos>15;                uplim=20;end;
%         if maxpos>10 && maxpos <= 15;uplim=15;end;
%         if maxpos> 5 && maxpos <= 10;uplim=10;end;
%         if maxpos<= 5;               uplim= 5;end;
%         ax.YLim=[0 uplim];
    end;
    if Nsubplot == 3;
        my_x=[s e];
        my_y=[PkThresh PkThresh];                          plot(my_x,my_y,'-w')
        my_y=[OnOffThreshold OnOffThreshold];              plot(my_x,my_y,'-c')
        my_y=[WeakGlissadeThreshold WeakGlissadeThreshold];plot(my_x,my_y,'-y')
    end;
end
MyTitle=strrep(MyTitle,'_','-');
fprintf('MyTitle = %s\n',MyTitle);
suplabel(MyTitle,'t');

ImageFileFullPath=strcat(PathStr,SubDirName,ImageFileName);
if exist(ImageFileFullPath,'file') == 2;delete(ImageFileFullPath);end;
fprintf('Output File: %s\n',ImageFileFullPath)
FigHandle.InvertHardcopy = 'off';
t_tic_save=tic;saveas(gcf,ImageFileFullPath);TimeToSaveFile=toc(t_tic_save);
fprintf('Time to save the file is %f\n',TimeToSaveFile)
return
end
