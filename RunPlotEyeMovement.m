function RunPlotEyeMovement()
    clc
    clear all
    close all
    WhichUser=1;user=['l_f96';'leef ';'lee  '];CS=cellstr(user);this_user=char(CS(WhichUser));
    PathStr=strcat('C:\Users\',this_user,'\Dropbox\TRACS_Downloads\Framework+Demo\Framework Demo\Biometric Framework\@Output\TEX\20150518T165226\');
    GoodDataVector=[1:27 29:35 37:49];
%   GoodDataVector=[1:11];
%   GoodDataVector=[1];
    for GoodDataIndex = 1:length(GoodDataVector)
        Subject = GoodDataVector(GoodDataIndex);
        for Run = 1:2
            PlotEyeMovement(PathStr,Subject,Run,this_user)
%             pause
        end
    end
end

function PlotEyeMovement(PathStr,Subject,Run,this_user)

% TEX_001_S1.csv
FileName = strcat('TEX_',num2str(Subject,'%03d'),'_S',num2str(Run),'.csv');
FullPath=char(strcat(PathStr,FileName));
fprintf('Input File: %s\n',FullPath)
DataArray=csvread(FullPath);

% FileName = ['TEX_' num2str(Subject,'%03d') '_S' num2str(Run) '_Fixations.csv'];
% FullPath=[PathStr FileName];
% fprintf('Input File: %s\n',FullPath)
% InpFixations=csvread(FullPath);
% 
% FileName = ['TEX_' num2str(Subject,'%03d') '_S' num2str(Run) '_Saccades.csv'];
% FullPath=[PathStr FileName];
% fprintf('Input File: %s\n',FullPath)
% InpSaccades=csvread(FullPath);

[pathstr, NameOnly, ext]=fileparts(FullPath);

commandwindow;

asize=size(DataArray);
Nchannels=asize(2);
NSamples=asize(1);

Msec         =DataArray(:,1);
Horiz        =DataArray(:,2);
Vert         =DataArray(:,3);
HorizVelocity=DataArray(:,4);
VertVelocity =DataArray(:,5);
Type         =DataArray(:,8);
clear DataArray

signals=[Msec Horiz Vert HorizVelocity VertVelocity Type];
varlist = {'Msec', 'Horiz', 'Vert', 'HorizVelocity', 'VertVelocity', 'Type'};
clear(varlist{:})
% save signals
% pause
NameOnly=strrep(NameOnly,'_','-');
%
% Plot Each Second of DATA
%
[MsecJumpStart,MsecJumpEnd]=FindExcludedDataStartStop(signals(:,1));
[Fixations, Saccades] = MeasureFeatures(signals);

% for i = 1:1000:signals(NSamples,1)
%     
%     ImageFileName=[NameOnly '-' num2str(i,'%06d') '-' num2str(i+999,'%06d') '.jpg'];
%     StartMsec=i;
%     EndMsec=i+1000;
%     MyTitle=[NameOnly ' |Start Msec = ' num2str(i,'%06d') ' | End Msec = ' num2str(i+999,'%06d') ' |'];
%     fprintf('%s\n',MyTitle)
%     PlotMyData(signals,StartMsec,EndMsec,MyTitle,ImageFileName,Fixations,Saccades,MsecJumpStart,MsecJumpEnd)
% end
% 
% FilteredYesNo=0;
% PlotSacAmpVsDur(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)
% PlotMainSequence(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)
[Fixations,Saccades] = LeesFilters(Fixations, Saccades, MsecJumpStart, MsecJumpEnd, Subject, Run,this_user);
FilteredYesNo=1;
PlotSacAmpVsDur(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)
PlotMainSequence(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)

return
end

function PlotMyData(signals,StartMsec,EndMsec,MyTitle,ImageFileName,Fixations,Saccades,MsecJumpStart,MsecJumpEnd)

SacDur=0;
Height=685;
Width=1100;
myposition=[1 25 Width Height];

FigHandle=figure(1);
set(FigHandle,'units','pixels','position',myposition);
set(FigHandle,'visible','off');
% set(FigHandle,'visible','on');

s=StartMsec;
e=EndMsec;
% fprintf('Start Sample= %d, End Sample = %d\n',s,e)
BadCount=0;
for i = 2:3
    SubPlot=i-1;
    subplot(2,1,SubPlot);
    hold on
     if i == 2;ylim([-17 17]);end
     if i == 3;ylim([-17 17]);end
%     if i == 1;ylim();end
%     if i == 2;ylim();end
    StartCount=0;
    SacDur=0;
    for j = 1:length(signals(:,1))
        if signals(j,1)>=s && signals(j,1)<=e;
            if StartCount==0;
                plot(s-1+1000,0,'.w');
                StartCount=StartCount+1;
            end
            if signals(j,6)==0
                plot(signals(j,1),signals(j,i),'.g');
            elseif signals(j,6)==1
                plot(signals(j,1),signals(j,i),'.b');            
            end
            for k = 1:length(Fixations)
                if signals(j,1) == Fixations(k,1);
                    GoodFixation=LabelFixation(Fixations(k,:),SubPlot);
                    if ~GoodFixation,BadCount=BadCount+1;end;
                end;
            end
            for k = 1:length(Saccades)
                if signals(j,1) == Saccades(k,1);
                    [GoodSaccade]=LabelSaccade(Saccades(k,:),SubPlot,MsecJumpStart,MsecJumpEnd);
                    if ~GoodSaccade,BadCount=BadCount+1;end;
%                     if Saccades(k,2) >= 70 && Saccades(k,2) <= 100;
%                         BadCount=BadCount+1;
%                         SacDur=Saccades(k,2);
%                     end
%                     StartMin=inf;
%                     SaccadeEnd=Saccades(k,1)+ Saccades(k,2);
%                     for m = 1:length(MsecJumpStart)
%                         StartDiff=MsecJumpStart(m)-SaccadeEnd;
% %                         if StartDiff < StartMin;StartMin=StartDiff;end;
%                         if StartDiff >= 0 && StartDiff < 30 && Saccades(k,9) <= 1.0 && Saccades(k,12) <= 1.0 && Saccades(k,2) <= 85 && Saccades(k,2) >= 8 && (abs(Saccades(k,3)) >= 0.4 || abs(Saccades(k,4)) >= 0.4); 
%                             fprintf('Found a saccade that ends near the start of a data jump at Msec=%d\n',MsecJumpStart(m))
%                             GoodSaccade=false;
%                             ThisStartDiff=StartDiff;
%                             break;
%                         end
%                     end
%                     EndMin=inf;
%                     for m = 1:length(MsecJumpEnd)
%                         EndDiff=Saccades(k,1) - MsecJumpEnd(m);
%                         if EndDiff > 0 && EndDiff < EndMin;EndMin=EndDiff;end;
%                     end
%                     if EndMin > 4 && EndMin < 30 && Saccades(k,9) <= 1.0 && Saccades(k,12) <= 1.0 && Saccades(k,2) <= 85 && Saccades(k,2) >= 8 && (abs(Saccades(k,3)) >= 0.4 || abs(Saccades(k,4)) >= 0.4);
%                             fprintf('Found a saccade that occurs after a data jump at Msec=%d\n',MsecJumpEnd(m))
%                             GoodSaccade=false;
%                             ThisEndDiff=EndMin;
%                     end
                    if ~GoodSaccade,BadCount=BadCount+1;end;
                end;
            end
            
            if signals(j,1)>e,break;end
        end
    end
    LabelParams(e,SubPlot)
    xlabel('Time (msec)');
    if SubPlot==1;ylabel('Horizontal Eye Movements');end
    if SubPlot==2;ylabel('Vertical Eye Movements');end
    ax=gca;
    ax.XLim=[s-1 s-1+1000];
    ax.XLimMode='manual';
    ax.XTickLabelMode='manual';
    ax.XTick = [s-1:200:s-1+1000];
    ax.XTickLabel={num2str(s-1,'%05d'),num2str(s-1+200,'%05d'),num2str(s-1+400,'%05d'),num2str(s-1+600,'%05d'),num2str(s-1+800,'%05d'),num2str(s-1+1000,'%05d')};
    ax.XTickLabelRotation=90;

end
hold off

suplabel(MyTitle,'t');

% if BadCount == 0;  %ImageFileFullPath=[PathName ImageFileName];
%     ImageFileFullPath=['C:\Users\leef\Dropbox' ImageFileName(1:10) '\' ];
%     if ~exist(ImageFileFullPath, 'dir');
%         mkdir(ImageFileFullPath);
%         beep
%         beep
%         beep
%     end;
% else


if BadCount > 0;
    ImageFileFullPath=['C:\EyeMovementClassification\DataJumpEnds\' ImageFileName(1:10) '\' ];
    fprintf('Output File: %s\n',ImageFileFullPath)
    if ~exist(ImageFileFullPath, 'dir');
        mkdir(ImageFileFullPath);
    end;
    ImageFileFullPath=[ImageFileFullPath num2str(ThisEndDiff,'%3.3d') '-' ImageFileName];
    %fprintf('Output File: %s\n',ImageFileFullPath)
    tic;saveas(gcf,ImageFileFullPath);ElapsedTime=toc;

    handel
    
end;

% ImageFileFullPath=[ImageFileFullPath ImageFileName];
% %fprintf('Output File: %s\n',ImageFileFullPath)
% tic;saveas(gcf,ImageFileFullPath);ElapsedTime=toc;
%fprintf('Time to save the file is %f\n',ElapsedTime)
heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
% fprintf(' Before GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
java.lang.Runtime.getRuntime.gc;
heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
% fprintf(' After  GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
close all
return
end

function [Fixations, Saccades] = MeasureFeatures(signals)

	% Processing variables
	Fixation = 0;%Count Fixations
	Saccade  = 0;%Count Saccades

	% Pre-allocate variables, guess approximate size
	Fixations = zeros(round(sqrt(size(signals, 1))), 4+6);
	Saccades = zeros(round(sqrt(size(signals, 1))), 8+6);

	% Merge fixation and saccade groups
	for i = 1:size(signals, 1)
		if (i == 1)
			j = i;%Starting point of a fixation
			k = i;%Starting point of a saccade
		elseif (signals(i,6) == 0 && signals(i-1,6) == 1)
            %If current point is the start of a fixation and the previous point was a saccade,
            %then j = the start of the next fixation.
			j = i; %j is the start of the next fixation
			Saccade = Saccade + 1;%increment Saccade count
            %k is the start of the saccade, i-1 is the end of the saccade
%             fprintf('%d:%d\n',k,i-1);
            H=abs(diff(signals(k:i-1,2)));%H=Absolute Value of the Differences in Horizontal Amplitude Betweem 2 Adjacent Points
            V=abs(diff(signals(k:i-1,3)));%;V=Absolute Value of the Differences in Vertical Amplitude Betweem 2 Adjacent Points
			Saccades(Saccade, :) = [signals(k, 1), sum(diff(signals(k:i-1, 1))), sum(diff(signals(k:i-1, 2))), sum(diff(signals(k:i-1, 3))), mean(signals(k:i-1, 4:5)), sign(mean(signals(k:i-1, 4:5))).* max(abs(signals(k:i-1, 4:5))),max(H),prctile(H,75),max(H)-prctile(H,75),max(V),prctile(V,75),max(V)-prctile(V,75)];
%                 Saccades(Saccade, :) = 
%                 [signals(k, 1),               %(1) Sample Number for the start of a saccade. 
%                  sum(diff(signals(k:i-1, 1))),%(2) Duration of Saccade
%                  sum(diff(signals(k:i-1, 2))),%(3) Horizontal Amplitude
%                  sum(diff(signals(k:i-1, 3))),%(4) Vertical Amplitude 
%                  mean(signals(k:i-1, 4:5)),   %(5) Horizontal Mean Velocity
%                                                 %(6) Vertical Mean Velocity
%                  sign(mean(signals(k:i-1,4:5))).*max(abs(signals(k:i-1, 4:5)))
%                                                 %(7) Horizontal Peak Velocity
%                                                 %(8) Vertical Peak Velocity
%                  max(abs(diff(signals(k:i-1,2:3))))];%(9)Max Ampl Diff between any 2 points
		elseif (signals(i,6) == 1 && signals(i-1,6) == 0)
            % If the current point is a start of a saccade and the previous point is the end of a 
            % fixation, k = the start of a saccade
			k = i;%The Start of a Saccade.
			Fixation = Fixation + 1;
            %j is the start of a fixation, i-1 is the end of a fixation
            H=abs(diff(signals(j:i-1,2)));%A=Absolute Value of the Differences in Horizontal Amplitude Betweem 2 Adjacent Points
            V=abs(diff(signals(j:i-1,3)));%A=Absolute Value of the Differences in Vertical Amplitude Betweem 2 Adjacent Points
			Fixations(Fixation, :) = [signals(j, 1), sum(diff(signals(j:i-1, 1))), mean(signals(j:i-1, 2:3)),max(H),prctile(H,75),max(H)-prctile(H,75),max(V),prctile(V,75),max(V)-prctile(V,75)];
%			       Fixations(Fixation, :) = [
%                  signals(j, 1),%              %(1) Start Time of Fixation
%                  sum(diff(signals(j:i-1, 1))),%(2) Duration of fixation 
%                  mean(signals(j:i-1, 2:3))];  %(3,4) Mean Horiz, Mean Vertical
		elseif (i == size(signals, 1) && signals(i,6) == 0)
			Fixation = Fixation + 1;
            H=abs(diff(signals(j:i-1,2)));%A=Absolute Value of the Differences in Horizontal Amplitude Betweem 2 Adjacent Points
            V=abs(diff(signals(j:i-1,3)));%A=Absolute Value of the Differences in Vertical Amplitude Betweem 2 Adjacent Points
			Fixations(Fixation, :) = [signals(j, 1), sum(diff(signals(j:i-1, 1))), mean(signals(j:i-1, 2:3)),max(H),prctile(H,75),max(H)-prctile(H,75),max(V),prctile(V,75),max(V)-prctile(V,75)];
		elseif (i == size(signals, 1) && signals(i,6) == 1 && i-k > 1)
			Saccade = Saccade + 1;
            H=abs(diff(signals(k:i-1,2)));%A=Absolute Value of the Differences in Horizontal Amplitude Betweem 2 Adjacent Points
            V=abs(diff(signals(k:i-1,3)));%A=Absolute Value of the Differences in Vertical Amplitude Betweem 2 Adjacent Points
            %fprintf('k = %d, i = %d\n',k,i) 
			Saccades(Saccade, :) = [signals(k, 1), sum(diff(signals(k:i, 1))), sum(diff(signals(k:i, 2))), sum(diff(signals(k:i, 3))), mean(signals(k:i, 4:5)), sign(mean(signals(k:i, 4:5))).* max(abs(signals(k:i, 4:5))),max(H),prctile(H,75),max(H)-prctile(H,75),max(V),prctile(V,75),max(V)-prctile(V,75)];
		end
    end
	% De-allocate extraneous memory
    %fprintf(' size of Fixations (%d,%d) and Saccades (%d,%d) before De-Allocation.\n',size(Fixations(:,1)),size(Saccades(:,1)));
    Fixations(Fixations(:, 2) == 0, :) = [];
	Saccades(Saccades(:, 2) == 0, :) = [];
    %fprintf(' size of Fixations (%d,%d) and Saccades (%d,%d) after  De-Allocation.\n',size(Fixations(:,1)),size(Saccades(:,1)));
%  	De-allocate extraneous memory
%     for i = 1:length(Fixations)
%         if Fixations(i,2) == 0;
%             fprintf('Erasing a row (%5d) with zero duration from Fixations\n',i);
%             Fixations(i,:) = [];
%         end;
%     end;
%     for i = 1:length(Saccades)
%         if Saccades(i, 2) == 0;
%             fprintf('Erasing a row (%5d) with zero duration from Saccades\n',i);
%             Saccades(i,:) = [];
%         end;
%     end;
end

function [GoodFixation] = LabelFixation(ThisFixation,SubPlot)%Start,Duration,HMean,VMean)
    if SubPlot == 1;
        if ThisFixation(5) > 1.0;
            color='m';
%             GoodFixation=false;
             GoodFixation=true;
        else
            color='g';
            GoodFixation=true;
        end
        
        text(ThisFixation(1), -7,num2str(ThisFixation( 2))        ,'HorizontalAlignment','Left','Color',color)
        text(ThisFixation(1), -9,num2str(ThisFixation( 3),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisFixation(1),-11,num2str(ThisFixation( 5), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisFixation(1),-13,num2str(ThisFixation( 6), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisFixation(1),-15,num2str(ThisFixation( 7), '%.2f'),'HorizontalAlignment','Left','Color',color)
    else
        if ThisFixation(8) > 1.0;
            color='m';
%             GoodFixation=false;
             GoodFixation=true;
        else
            color='g';
            GoodFixation=true;
        end
        text(ThisFixation(1), -7,num2str(ThisFixation( 2))        ,'HorizontalAlignment','Left','Color',color)
        text(ThisFixation(1), -9,num2str(ThisFixation( 4),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisFixation(1),-11,num2str(ThisFixation( 8), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisFixation(1),-13,num2str(ThisFixation( 9), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisFixation(1),-15,num2str(ThisFixation(10), '%.2f'),'HorizontalAlignment','Left','Color',color)
    end;
    return
end
function [GoodSaccade] = LabelSaccade(ThisSaccade,SubPlot,MsecJumpStart,MsecJumpEnd);%Start,Duration,HAmpl,VAmpl,HmeanVel,VmeanVel,HpkVel,VpkVel)
    GoodSaccade=true;
    color='b';
    if SubPlot == 1;
        if ThisSaccade(9) > 1.0 || ThisSaccade(2) > 85;%Max2pt > 1 or duration > 100
            color='m';
%             GoodSaccade=false;
             GoodSaccade=true;
        elseif ThisSaccade(2) < 8
            color='m';
            GoodSaccade=true;
        elseif abs(ThisSaccade(3)) < 0.4 && abs(ThisSaccade(4)) < 0.4  
            color='m';
            GoodSaccade=true;            
        else
            color='b';
            GoodSaccade=true;
        end
        StartMin=inf;
        ThisSaccadeEnd=ThisSaccade(1)+ ThisSaccade(2);
        for i = 1:length(MsecJumpStart)
            StartDiff=MsecJumpStart(i)-ThisSaccadeEnd;
            if StartDiff > 0 && StartDiff < StartMin;StartMin=StartDiff;end;
            if StartMin <= 5 && color == 'b';
%                 fprintf('\n\nFound a saccade that ends near the start of a data jump at Msec=%d\n',MsecJumpStart(i))
%                 fprintf('ThisSaccade(1) = %d, ThisSaccade(2) = %d, ThisSaccadeEnd = %d, StartMin = %d\n\n',ThisSaccade(1),ThisSaccade(2),ThisSaccadeEnd,StartMin)
                color='m';
                GoodSaccade=true;
            end
        end
        EndMin=inf;
        for i = 1:length(MsecJumpEnd)
            EndDiff=ThisSaccade(1) - MsecJumpEnd(i);
            if EndDiff > 0 && EndDiff < EndMin;EndMin=EndDiff;end;
            if EndMin <=20 && color == 'b';
                fprintf('Found a saccade that occurs after a data jump at Msec=%d\n',MsecJumpEnd(i))
                color='m';
                GoodSaccade=true;
            end
        end
 
        text(ThisSaccade(1),15,num2str(ThisSaccade( 2))        ,'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1),13,num2str(ThisSaccade( 3),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1),11,num2str(ThisSaccade( 5),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 9,num2str(ThisSaccade( 7),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 7,num2str(ThisSaccade( 9), '%.2f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 5,num2str(StartMin       , '%d')  ,'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 3,num2str(EndMin         , '%d')  ,'HorizontalAlignment','Left','Color',color)
%         text(ThisSaccade(1), 5,num2str(ThisSaccade(10), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisSaccade(1), 3,num2str(ThisSaccade(11), '%.2f'),'HorizontalAlignment','Left','Color',color)
    else
        if ThisSaccade(12) > 1.0 || ThisSaccade(2) > 85;
            color='m';
%             GoodSaccade=false;
             GoodSaccade=true;
        elseif ThisSaccade(2) < 8
            color='m';
            GoodSaccade=true;            
        else
            color='b';
            GoodSaccade=true;
        end
        text(ThisSaccade(1),15,num2str(ThisSaccade( 2))        ,'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1),13,num2str(ThisSaccade( 4),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1),11,num2str(ThisSaccade( 6),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 9,num2str(ThisSaccade( 8),'%5.1f'),'HorizontalAlignment','Left','Color',color)
        text(ThisSaccade(1), 7,num2str(ThisSaccade(12), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisSaccade(1), 5,num2str(ThisSaccade(13), '%.2f'),'HorizontalAlignment','Left','Color',color)
%         text(ThisSaccade(1), 3,num2str(ThisSaccade(14), '%.2f'),'HorizontalAlignment','Left','Color',color)
    end;
    return
end
function LabelParams(EndMsec,SubPlot)
    Offset=25;
    if SubPlot == 1;
        
        text(EndMsec+Offset, 19,'Saccade' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 17,'-------' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 15,'Duration','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 13,'HAmpl'   ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 11,'HMnVel'  ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,  9,'HpkVel'  ,'HorizontalAlignment','Left','Color','k')       
        text(EndMsec+Offset,  7,'Max2Pt'  ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,  5,'StartMin ','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,  3,'EndMin   ','HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,  5,'75th2pt' ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,  3,'Diff'    ,'HorizontalAlignment','Left','Color','k')
        
        text(EndMsec+Offset, -3,'Fixation','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -5,'--------','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -7,'Duration','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -9,'Hmean'   ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,-11,'Max2Pt'  ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,-13,'75th2pt' ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,-15,'Diff'    ,'HorizontalAlignment','Left','Color','k')
        
    else
        text(EndMsec+Offset, 19,'Saccade' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 17,'-------' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 15,'Duration','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 13,'VAmpl'   ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, 11,'VMnVel'  ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,  9,'VpkVel'  ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,  7,'Max2Pt'  ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,  5,'75th2pt' ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,  3,'Diff'    ,'HorizontalAlignment','Left','Color','k')

        text(EndMsec+Offset, -3,'Fixation' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -5,'--------' ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -7,'Duration','HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset, -9,'Vmean'   ,'HorizontalAlignment','Left','Color','k')
        text(EndMsec+Offset,-11,'Max2Pt'  ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,-13,'75th2pt' ,'HorizontalAlignment','Left','Color','k')
%         text(EndMsec+Offset,-15,'Diff'    ,'HorizontalAlignment','Left','Color','k')

    end
    return
end

function [Fixations,Saccades] = LeesFilters(Fixations, Saccades, MsecJumpStart, MsecJumpEnd, Subject, Run,this_user)
    % FILTER SACCADES
    NumSaccadesBeforeFilter=length(Saccades);
    Saccades (Saccades (:, 2) >  85, :) = [];%Saccade Duration > 85 msec
	Saccades (Saccades (:, 2) <   8, :) = [];%Saccade Duration < 8 msec
	Saccades (Saccades (:, 9) >   1, :) = [];%Max2pt > 1 deg - Horiz
	Saccades (Saccades (:,10) >   1, :) = [];%Max2pt > 1 deg - Vertical
    SaccadeEnd=Saccades(:,1)+ Saccades(:,2);
    BadSaccadeCount=0;
    for i = 1:length(Saccades)
        for j = 1:length(MsecJumpStart)
            Diff=abs(SaccadeEnd(i) - MsecJumpStart(j));
            if Diff <= 5 
                %fprintf('In Filter: Found a saccade that ends near the start of a data jump at Msec=%d\n',MsecJumpStart(j))
                BadSaccadeCount=BadSaccadeCount+1;
                BadSaccade(BadSaccadeCount) = i;
            end
        end
        for j = 1:length(MsecJumpEnd)
            Diff=abs(Saccades(i,1) - MsecJumpEnd(j));
            if Diff <= 20 ;
                %fprintf('In Filter: Found a saccade that occurs after a data jump at Msec=%d\n',MsecJumpEnd(j))
                BadSaccadeCount=BadSaccadeCount+1;
                BadSaccade(BadSaccadeCount) = i;
            end
        end
    end
    fprintf('In Filter: BadSaccade Count = %d\n',BadSaccadeCount);
    if BadSaccadeCount>0
        Saccades(BadSaccade(:),:)= [];
    end
    BadSaccadeCount=0;
    clear BadSaccade;
    for i = 1:length(Saccades)
        if abs(Saccades (i, 3)) < 0.4 && abs(Saccades(i,4)) < 0.4;
            BadSaccadeCount=BadSaccadeCount+1;
            BadSaccade(BadSaccadeCount) = i;
        end
    end
    if BadSaccadeCount>0
        Saccades(BadSaccade(:),:)= [];
    end
    NumSaccadesAfterFilter=length(Saccades);
    Diff = NumSaccadesBeforeFilter - NumSaccadesAfterFilter;
    DiffPercent=100*Diff/NumSaccadesBeforeFilter;
%     fprintf('Saccade Filtering Report:\n N Saccades Before Filter = %d\n N Saccades After Filter = %d\n Number of Saccades Filtered = %d\n Percent Filtered = %.2f\n',NumSaccadesBeforeFilter,NumSaccadesAfterFilter,Diff,DiffPercent)

    
    % FILTER FIXATIONS
    NumFixationsBeforeFilter=length(Fixations);
  	Fixations(Fixations(:, 5) >   1, :) = [];%Max2pt > 1 deg - Horiz
	Fixations(Fixations(:, 6) >   1, :) = [];%Max2pt > 1 deg - Vertical
    NumFixationsAfterFilter=length(Fixations);
    Diff = NumFixationsBeforeFilter - NumFixationsAfterFilter;
    DiffPercent=100*Diff/NumFixationsBeforeFilter;
%     fprintf('Fixation Filtering Report:\n N Fixations Before Filter = %d\n N Fixations After Filter = %d\n Number of Fixations Filtered = %d\n Percent Filtered = %.2f\n',NumFixationsBeforeFilter,NumFixationsAfterFilter,Diff,DiffPercent)
    % Write Statistics to File
    AccountingFileName=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\FilteringResults_TEX.csv');
    OutputVector(1) = Subject;
    OutputVector(2) = Run;
    OutputVector(3) = NumSaccadesBeforeFilter;
    OutputVector(4) = NumSaccadesAfterFilter;
    OutputVector(5) = NumSaccadesBeforeFilter - NumSaccadesAfterFilter;
    OutputVector(6) = 100*(NumSaccadesBeforeFilter - NumSaccadesAfterFilter)/NumSaccadesBeforeFilter;
    OutputVector(7) = NumFixationsBeforeFilter;
    OutputVector(8) = NumFixationsAfterFilter;
    OutputVector(9) = NumFixationsBeforeFilter - NumFixationsAfterFilter;
    OutputVector(10) = 100*(NumFixationsBeforeFilter - NumFixationsAfterFilter)/NumFixationsBeforeFilter;
    dlmwrite(AccountingFileName,OutputVector,'-append')
    AccountingFileName=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\FilteringResults_TEX_headers.csv');
    headers='Subject,Run,NumSaccadesBeforeFilter,NumSaccadesAfterFilter,Before-After,PercentChange,NumFixationsBeforeFilter,NumFixationsAfterFilter,Before-After,PercentChange';
    fid=fopen(AccountingFileName,'w');
    fprintf(fid,'%s',headers);
    fclose(fid);
end

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

function PlotSacAmpVsDur(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)
    Height=685;
    Width=1100;
    myposition=[1 25 Width Height];
    FigHandle=figure(1);
    set(FigHandle,'units','pixels','position',myposition);
    set(FigHandle,'visible','on');
%     Saccades (Saccades (:, 2) > 40, :) = [];
    x = Saccades(:,2);% Saccade duration
    y = abs(Saccades(:,3)); %Horiz Saccade amplitude (absval)
    short_count=0;
    long_count=0;
    for i = 1:length(x)
        if x(i) <= 23;
            short_count=short_count+1;
            xshort(short_count)=x(i);
            yshort(short_count)=y(i);
        elseif x(i)> 23 && x(i) < 50;
            long_count = long_count+1;
            xlong(long_count)=x(i);
            ylong(long_count)=y(i);
        end;
    end;
%   transpose vectors
    xshort=xshort';
    yshort=yshort';
    xlong=xlong';
    ylong=ylong';
%   fit the short durations
    X = [ones(size(xshort)) xshort];
    [b_short,bint,r,rint,stats_short] = regress(yshort,X); 
    scatter(xshort,yshort,'filled')
    hold on
    XFIT = min(xshort):1:max(xshort);
    YFIT = b_short(1) + b_short(2).*XFIT;
    plot(XFIT,YFIT,'-r')
%   label axes   
    xlabel(XLabel)
    ylabel(YLabel)
        title({['Saccade Duration vs Saccade Amplitude (Horizontal) - ' NameOnly '  Filtered  -  N = ' num2str(length(x),'%d')];
               [' Short: Slope = ' num2str(b_short(2),'%6.3f') ',  F = ' num2str(stats_short(2),'%5.1f') ',  p = ' num2str(stats_short(3),'%8.7f') ',  R-sqr = ' num2str(stats_short(1),'%3.2f') ', Err Var = ' num2str(stats_short(4),'%6.2f')]
               [' Long : Slope = ' num2str(b_long(2) ,'%6.3f') ',  F = ' num2str(stats_long(2) ,'%5.1f') ',  p = ' num2str(stats_long(3) ,'%8.7f') ',  R-sqr = ' num2str(stats_long(1) ,'%3.2f') ', Err Var = ' num2str(stats_long(4) ,'%6.2f')]})
        FileName = [NameOnly '_SacAmplvsDurFiltered.jpg']; 
        FullPath=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\AnalysisPlots\AmpVsDuration\',FileName);
    else
        title({['Saccade Duration vs Saccade Amplitude (Horizontal) - ' NameOnly '  UnFiltered  -  N = ' num2str(length(x),'%d')];
               [' Short: Slope = ' num2str(b_short(2),'%6.3f') ',  F = ' num2str(stats_short(2),'%5.1f') ',  p = ' num2str(stats_short(3),'%8.7f') ',  R-sqr = ' num2str(stats_short(1),'%3.2f') ', Err Var = ' num2str(stats_short(4),'%6.2f')]
               [' Long : Slope = ' num2str(b_long(2) ,'%6.3f') ',  F = ' num2str(stats_long(2) ,'%5.1f') ',  p = ' num2str(stats_long(3) ,'%8.7f') ',  R-sqr = ' num2str(stats_long(1) ,'%3.2f') ', Err Var = ' num2str(stats_long(4) ,'%6.2f')]})
        FileName = [NameOnly '_SacAmplvsDurUnFiltered.jpg'];
        FullPath=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\AnalysisPlots\AmpVsDuration\',FileName);
    end  
    %Save this analysis image
    saveas(gcf,FullPath)
    close all
    k = strfind(FullPath,'jpg');
    FullPath(k:k+2)='csv'
    M=[Subject Run FilteredYesNo length(x) b_short' stats_short b_long' stats_long];
    headers = {'Subject','Run','Filtered','N','Intercept','Slope','r-sqr','F','p','ErrVar','Intercept','Slope','r-sqr','F','p','ErrVar'};
    csvwrite_with_headers(FullPath,M,headers)
    return
end
function PlotMainSequence(Saccades,NameOnly,FilteredYesNo,Subject,Run,this_user)

    if FilteredYesNo == 1;
        FileName = [NameOnly '_MainSequenceFiltered.jpg']; 
        FullPath=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\AnalysisPlots\AmpVsPkVel\',FileName);
    else
        FileName = [NameOnly '_MainSequenceUnFiltered.jpg']; 
        FullPath=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementClassification\AnalysisPlots\AmpVsPkVel\',FileName);
    end  

    Height=685;
    Width=1100;
    myposition=[1 25 Width Height];
    FigHandle=figure(1);
    set(FigHandle,'units','pixels','position',myposition);
    set(FigHandle,'visible','on');
%     Saccades (Saccades (:, 2) > 40, :) = [];
    Saccades (Saccades (:, 3) < 0.5, :) = [];
    x = log10(abs(Saccades(:,3))); %Horiz Saccade amplitude (absval)
%   x = (abs(Saccades(:,3))); %Horiz Saccade amplitude (absval)
    X = [ones(size(x)) x];
    y=log10(abs(Saccades(:,7)));
%   y=(abs(Saccades(:,7)));
    scatter(x,y,'filled')
%   loglog(x,y,'d')
    hold on
    [b,bint,r,rint,stats] = regress(y,X);
    XFIT = min(x):.1:max(x);
    YFIT = b(1) + b(2)*XFIT;
    plot(XFIT,YFIT,'-r')
    xlabel('Log10 - Saccade Amplitude (deg)')
    ylabel('Log10 - Hor Saccade Peak Velocity (deg^2/sec)')

%      set(gca, 'XScale', 'log')
%      set(gca, 'YScale', 'log')
%     modelFun = @(b,x) b(1).*(1-exp(-b(2).*x));
%     modelFun = @(b,x) b(1).*(1-exp(-x/b(2)));
%     start = [500; .5];
%     try
%         nlm = fitnlm(x,y,modelFun,start);
%     catch
%         M=[Subject Run FilteredYesNo length(x) NaN NaN NaN NaN];
%         headers = {'Subject','Run','Filtered','N','b1','b2','R-sqr','RMSE'};
%         k = strfind(FullPath,'jpg');
%         FullPath(k:k+2)='csv';
%         csvwrite_with_headers(FullPath,M,headers)
%         return        
%     end

    hold off
    if FilteredYesNo == 1;
        title({['log10 Saccade Amplitude vs Log10 Peak Velocity (Horizontal) - ' NameOnly '  Filtered  -  N = ' num2str(length(x),'%d')];
               [' Slope = ' num2str(b(2),'%6.3f') ',  F = ' num2str(stats(2),'%5.1f') ',  p = ' num2str(stats(3),'%8.7f') ',  R-sqr = ' num2str(stats(1),'%3.2f') ', Err Var = ' num2str(stats(4),'%6.2f')]})
%                [' Model = y ~ b1*(1 - exp(-x/b(2))), b1 = ' num2str(nlm.Coefficients.Estimate(1),'%.2f') ', b2 = ' num2str(nlm.Coefficients.Estimate(2),'%5.2f') ', R-sqr = ' num2str(nlm.Rsquared.Ordinary,'%4.2f') ', RMSE = ' num2str(nlm.RMSE,'%5.2f') ]})
%      modelFun = @(b,x) b(1).*(1-exp(-x/b(2)));
    else
        title({['Saccade Amplitude vs Peak Velocity (Horizontal) - ' NameOnly '  UnFiltered  -  N = ' num2str(length(x),'%d')];
               [' Slope = ' num2str(b(2),'%6.3f') ',  F = ' num2str(stats(2),'%5.1f') ',  p = ' num2str(stats(3),'%8.7f') ',  R-sqr = ' num2str(stats(1),'%3.2f') ', Err Var = ' num2str(stats(4),'%6.2f')]})
%                [' Model = y ~ b1*(1 - exp(-x/b(2))), b1 = ' num2str(nlm.Coefficients.Estimate(1),'%.2f') ', b2 = ' num2str(nlm.Coefficients.Estimate(2),'%5.2f') ', R-sqr = ' num2str(nlm.Rsquared.Ordinary,'%4.2f') ', RMSE = ' num2str(nlm.RMSE,'%5.2f') ]})
    end  
    %Save this analysis image
    saveas(gcf,FullPath)
    close all
    k = strfind(FullPath,'jpg');
    FullPath(k:k+2)='csv';
%     M=[Subject Run FilteredYesNo length(x) nlm.Coefficients.Estimate(1) nlm.Coefficients.Estimate(2) nlm.Rsquared.Ordinary nlm.RMSE];
    M=[Subject Run FilteredYesNo length(x) b(1) b(2) stats(2) stats(3) stats(1)];
    headers = {'Subject','Run','Filtered','N','intercept','slope','F','pvalue','R-sqr'};
    csvwrite_with_headers(FullPath,M,headers)
    return
end