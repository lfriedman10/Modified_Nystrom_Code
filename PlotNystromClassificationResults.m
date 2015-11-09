function PlotNystromClassificationResults()
    clc
    clear all
    close all
    WhichUser=2;user=['l_f96';'leef ';'lee  '];CS=cellstr(user);this_user=char(CS(WhichUser));
%    mypiece='Nystom_Modified_Method (1)';
    mypiece='Nystom_Modified_Method';
    PathStr=strcat('C:\Users\',this_user,'\Google Drive\',mypiece,'\EventDetector1.0\Results\');
%     if WhichUser == 1;PathStr=strcat('C:\Users\',this_user,'\Google Drive\Nystom_Modified_Method\EventDetector1.0\Results\');end;
%     if WhichUser >  1;PathStr=strcat('C:\Users\',this_user,'\Google Drive\Nystom_Modified_Method (1)\EventDetector1.0\Results\');end;
%  GoodDataVector=[1:27 29:35 37:49 51:55];
%  GoodDataVector=[1:27 29:35 37:49 51:56 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
LowSlopeSet = [ 3 32 51];
HighSlopeSet= [10 30 45];
GoodDataVector=[LowSlopeSet HighSlopeSet];
GoodDataVector=3;
    for GoodDataIndex = 1:length(GoodDataVector)
        Subject = GoodDataVector(GoodDataIndex);
        for Session = 1:2
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
MeanNoise=NoiseData(1);
SDNoise=NoiseData(2);
PkThresh=NoiseData(3);
OnOffThreshold=NoiseData(4);
fprintf('PkThresh=%f,OnOffThreshold=%f\n',PkThresh,OnOffThreshold)

[pathstr, NameOnly, ext]=fileparts(FullPath);

commandwindow;
NSamples=length(DataArray);
fprintf('The total number of samples is %d\n',NSamples)
%
% plot Each Second of DATA
%
for i = 1:1000:20000; % NSamples
    tic
    ImageFileName=[NameOnly(1:12) '-' num2str(i,'%06d') '-' num2str(i+999,'%06d') '.jpg'];
    StartMsec=i;
    EndMsec=i+1000;
    MyTitle=[NameOnly ' |Start Msec = ' num2str(i,'%06d') ' | End Msec = ' num2str(i+999,'%06d') ' |'];
    fprintf('%s\n',MyTitle)
    [TimeToSaveFile]=plotMyData(DataArray,StartMsec,EndMsec,MyTitle,PathStr,SubDirName,ImageFileName,NSamples,PkThresh,OnOffThreshold);
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

function [TimeToSaveFile]=plotMyData(DataArray,StartMsec,EndMsec,MyTitle,PathStr,SubDirName,ImageFileName,NSamples,PkThresh,OnOffThreshold)

Height=685;
Width=1100;
% myposition=[1288  2 Width Height];
myposition=[  16 -3 Width Height]; 
FigHandle=figure(1);
set(FigHandle,'units','pixels','position',myposition);% ,'Color',[0.8 0.8 0.8]);
set(FigHandle,'visible','off');
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
VelIsNaN=find(isnan(Vel));
Vel(VelIsNaN)=1000;
Acc  =DataArray(:,7);
Pupil=DataArray(:,8);
Class=DataArray(:,9);
SubType=DataArray(:,10);

for Nsubplot = 1:3
    ax = subplot(3,1,Nsubplot);
    ax.Color=[0.8 0.8 0.8];
    ax.XLimMode='manual';
    ax.YLimMode='manual';
    ax.XLim=[s-1 s-1+1000];
    if Nsubplot == 1;
%       if min(Xsmo(s:e)) < max(Xsmo(s:e)),ax.YLim=[min(Xsmo(s:e)) max(Xsmo(s:e))];end;
        LowLim=-10;UpLim=10;
        if min(Ysmo(s:e)) < -10,LowLim = min(Ysmo(s:e));end
        if max(Ysmo(s:e)) >  10,UpLim  = max(Ysmo(s:e));end
        ax.YLim=[LowLim UpLim];
    end;
    if Nsubplot == 2;
%       if min(Ysmo(s:e)) < max(Ysmo(s:e));ax.YLim=[min(Ysmo(s:e)) max(Ysmo(s:e))];end;
        LowLim=-10;UpLim=10;
        if min(Ysmo(s:e)) < -10,LowLim = min(Ysmo(s:e));end
        if max(Ysmo(s:e)) >  10,UpLim  = max(Ysmo(s:e));end
        ax.YLim=[LowLim UpLim];
    end;
    if Nsubplot == 3;ax.YLim=[0 1.5*PkThresh];end;
    hold on
    if Nsubplot == 1;
        plot(s,Xsmo(s),'.w');
        plot(e,Xsmo(e),'.w');
        ylabel('Hor Pos');
%       ax.YLim=[0 20];
        Y_Event_Labels = (min(Xsmo(s:e))+max(Xsmo(s:e)))/2.;
        text(s+100,Y_Event_Labels,'FIX','color','green')
        text(s+200,Y_Event_Labels,'SAC','color','red')
        text(s+300,Y_Event_Labels,'GLS','color','blue')
        text(s+400,Y_Event_Labels,'ONaN','color','cyan')
        text(s+500,Y_Event_Labels,'SGNaN','color','magenta')
        text(s+600,Y_Event_Labels,'NaN','color','yellow')
        text(s+700,Y_Event_Labels,'NoClass','color','black') 
    elseif  Nsubplot == 2;
        plot(s,Ysmo(s),'.w');
        plot(e,Ysmo(e),'.w'); 
        ylabel('Vert Pos');
    elseif  Nsubplot == 3;
        plot(s,Vel(s),'.w');
        plot(e,Vel(e),'.w');
        ylabel('Velocity');
    end     
    minpos=1000;
    maxpos=-1000;
%     fprintf('NSamples = %d\n',NSamples);
%     fprintf('Init: minpos = %f, maxpos=%f \n',minpos,maxpos)
    for j = s:max(e,s+1);
           if SubType(j) == 0;Msize= 4;Mtype='.';end;
           if SubType(j) == 1;Msize= 6;Mtype='o';end;
           if SubType(j) == 2;Msize= 6;Mtype='x';end;
           if SubType(j) == 3;Msize= 6;Mtype='d';end;

%        if mod(j,100) == 0;
%            fprintf('Nsubplot = %d, j=%d\n',Nsubplot,j);
%        end;
       if Nsubplot == 1;
           % Xorg
%            if Class(j) == 0;plot(Msec(j),Xorg(j),'.k');end;
%            if Class(j) == 1;plot(Msec(j),Xorg(j),'.g');end;
%            if Class(j) == 2;plot(Msec(j),Xorg(j),'.r');end;
%            if Class(j) == 3;plot(Msec(j),Xorg(j),'.b');end;
%            if Class(j) == 4;plot(Msec(j),Xorg(j),'.c');end;
%            if Class(j) == 5;plot(Msec(j),Xorg(j),'.m');end;
%            if Class(j) >  5;plot(Msec(j),Xorg(j),'.y');end;
           % Smooth
           
           if Class(j) == 0;plot(Msec(j),Xsmo(j),[Mtype 'k'],'MarkerSize',Msize);end;
           if Class(j) == 1;plot(Msec(j),Xsmo(j),[Mtype 'g'],'MarkerSize',Msize);end;
           if Class(j) == 2;plot(Msec(j),Xsmo(j),[Mtype 'r'],'MarkerSize',Msize);end;
           if Class(j) == 3;plot(Msec(j),Xsmo(j),[Mtype 'b'],'MarkerSize',Msize);end;
           if Class(j) == 4;plot(Msec(j),Xsmo(j),[Mtype 'c'],'MarkerSize',Msize);end;
           if Class(j) == 5;plot(Msec(j),Xsmo(j),[Mtype 'm'],'MarkerSize',Msize);end;
           if Class(j) >  5;plot(Msec(j),Xsmo(j),[Mtype 'y'],'MarkerSize',Msize);end;

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
           % Yorg
%            if Class(j) == 0;plot(Msec(j),Yorg(j),'.k','MarkerSize',Msize);end;
%            if Class(j) == 1;plot(Msec(j),Yorg(j),'.g','MarkerSize',Msize);end;
%            if Class(j) == 2;plot(Msec(j),Yorg(j),'.r','MarkerSize',Msize);end;
%            if Class(j) == 3;plot(Msec(j),Yorg(j),'.b','MarkerSize',Msize);end;
%            if Class(j) == 4;plot(Msec(j),Yorg(j),'.c','MarkerSize',Msize);end;
%            if Class(j) == 5;plot(Msec(j),Yorg(j),'.m','MarkerSize',Msize);end;
%            if Class(j) >  5;plot(Msec(j),Yorg(j),'.y','MarkerSize',Msize);end;
           % Ysmo
           if Class(j) == 0;plot(Msec(j),Ysmo(j),[Mtype 'k'],'MarkerSize',Msize);end;
           if Class(j) == 1;plot(Msec(j),Ysmo(j),[Mtype 'g'],'MarkerSize',Msize);end;
           if Class(j) == 2;plot(Msec(j),Ysmo(j),[Mtype 'r'],'MarkerSize',Msize);end;
           if Class(j) == 3;plot(Msec(j),Ysmo(j),[Mtype 'b'],'MarkerSize',Msize);end;
           if Class(j) == 4;plot(Msec(j),Ysmo(j),[Mtype 'c'],'MarkerSize',Msize);end;
           if Class(j) == 5;plot(Msec(j),Ysmo(j),[Mtype 'm'],'MarkerSize',Msize);end;
           if Class(j) >  5;plot(Msec(j),Ysmo(j),[Mtype 'y'],'MarkerSize',Msize);end;
       else
%            if SubType(j) == 0;Msize= 4;Mtype='.';end;
%            if SubType(j) == 1;Msize= 5;Mtype='o';end;
%            if SubType(j) == 2;Msize= 5;Mtype='x';end;
%            if SubType(j) == 3;Msize= 5;Mtype='d';end;
%          fprintf('j,Msec(j)=%d,Vel(j)=%f\n',Msec(j),Vel(j));
           if Class(j) == 0;plot(Msec(j),Vel(j),[Mtype 'k'],'MarkerSize',Msize);end;
           if Class(j) == 1;plot(Msec(j),Vel(j),[Mtype 'g'],'MarkerSize',Msize);end;
           if Class(j) == 2;plot(Msec(j),Vel(j),[Mtype 'r'],'MarkerSize',Msize);end;
           if Class(j) == 3;plot(Msec(j),Vel(j),[Mtype 'b'],'MarkerSize',Msize);end;
           if Class(j) == 4;plot(Msec(j),Vel(j),[Mtype 'c'],'MarkerSize',Msize);end;
           if Class(j) == 5;plot(Msec(j),Vel(j),[Mtype 'm'],'MarkerSize',Msize);end;
           if Class(j) >  5;plot(Msec(j),Vel(j),[Mtype 'y'],'MarkerSize',Msize);end;
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
        my_x=[s e];my_y=[PkThresh PkThresh];plot(my_x,my_y,'-k')
        my_x=[s e];my_y=[OnOffThreshold OnOffThreshold];plot(my_x,my_y,'-r')
    end;
end
MyTitle=strrep(MyTitle,'_','-');
fprintf('MyTitle = %s\n',MyTitle);
suplabel(MyTitle,'t');

ImageFileFullPath=strcat(PathStr,SubDirName,ImageFileName);
if exist(ImageFileFullPath,'file') == 2;delete(ImageFileFullPath);end;
fprintf('Output File: %s\n',ImageFileFullPath)
t_tic_save=tic;saveas(gcf,ImageFileFullPath);TimeToSaveFile=toc(t_tic_save);
fprintf('Time to save the file is %f\n',TimeToSaveFile)
return
end
