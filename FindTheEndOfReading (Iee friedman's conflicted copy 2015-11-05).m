function FindTheEndOfReading()

clear all, close all, clc
WhichUser=2;user=['l_f96';'leef ';'lee  '];CS=cellstr(user);this_user=char(CS(WhichUser));
%--------------------------------------------------------------------------
% Create Log File
%--------------------------------------------------------------------------
PathForLogFile=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\');
[logname] = CreateLogFile(PathForLogFile);
InPathStr=strcat('C:\Users\',this_user,'\Dropbox\EyeMovementRawData\');
OutPathStr=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\EventDetector1.0\Results\FindTheEndOfReading\');
fprintf('OutPathStr = \n%s\n',OutPathStr);
if ~exist(OutPathStr,'dir'), mkdir(OutPathStr),end;
if exist(OutPathStr,'dir');cd(OutPathStr);end;
% GoodDataVector=[1:27 29:35 37:49 51:55 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
GoodDataVector=[19:27 29:35 37:49 51:55 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
% GoodDataVector=[1:10];
for GoodDataIndex = 1:length(GoodDataVector)
    Subject = GoodDataVector(GoodDataIndex);
    for Session = 1:2
        FileName = strcat('S_',num2str(Subject,'%03d'),'_S',num2str(Session),'_TEX.csv');
        FullPath=char(strcat(InPathStr,FileName));
        fprintf('\nInput File: %s\n',FullPath)
        DataArray=csvread(FullPath,2);
        Msec=DataArray(:,1);
        Y=DataArray(:,3);
        [MsecEndOfReading]=PlotIT(Msec,Y,OutPathStr,FileName,this_user);
        clear DataArray
%       fprintf('Number Of NaNs in Raw Data = %d\n',sum(NaNList));
%       fprintf('Length Of Data = %d\n',length(X));
    end;
end
return;

function [MsecEndOfReading]=PlotIT(Msec,Y,OutPathStr,FileName,this_user)
MsecEndOfReading=length(Msec);
newFileName = strrep(FileName,'_','-');

%   Extend NaN Periods

YisNaN=zeros(length(Msec),1);
YisNaN_Index=find(isnan(Y));
YisNaN(YisNaN_Index)=1;
NaNLabels=bwlabel(YisNaN);
offset=100;
for i = 1:max(NaNLabels)
    Start_Index=find(NaNLabels==i,1,'first');
    for j = Start_Index:-1:max(Start_Index-offset,1);
        Y(j)=NaN;
        Msec(j)=NaN;
    end
    End_Index=find(NaNLabels==i,1,'last');
    for j = End_Index:1:min(End_Index+offset,length(Msec));
        Y(j)=NaN;
        Msec(j)=NaN;
    end
%     fprintf('NanPeriod # %d, Length = %d, NewStart = %d, Start = %d, End = %d, NewEnd = %d\n',...
%             i,End_Index-Start_Index+1,Start_Index-offset,Start_Index,End_Index,End_Index+offset);
end;

first_good_index = find(~isnan(Y),1,'first');
last_good_index  = find(~isnan(Y),1,'last');
fprintf('original start = %d, first good index = %d, last good index = %d, original end = %d\n', ...
        1,first_good_index,last_good_index,length(Msec)) 
    
%   regression

s=5000;e=25000;
X1=Msec(s:e);
len=length(X1);
X=[ones(len,1) Msec(s:e)];
[b,bint,~,~,stats] = regress(Y(s:e),X,0.0001);
% out=[Msec(s:e),Y(s:e)];
% OutNaNIndexs=find(isnan(out(:,2)));
% out(OutNaNIndexs,:)=[];
% csvwrite(strrep(FileName,'.csv','_regr.csv'),out)
INIT_intercept=b(1);
INIT_slope = b(2);
INIT_UpperLimit=bint(2,2);
% fprintf('R-sqr = %5.2f\n',stats(1));
predicted = INIT_slope*Msec(:)+INIT_intercept;
resid = Y-predicted;

%   Find first break point - residuals

BigResidIndex=find(resid>10);
resid(BigResidIndex)=11;
m=450;
resid_thresh=10;
MsecEndOfReading_1=0;
FirstThird=round((last_good_index-first_good_index)/3.)+first_good_index;
residsum=zeros(length(Msec),1);
ResidThreshold=resid_thresh*m;
for i = FirstThird:last_good_index-m;
    residsum(i)=nansum(resid(i:i+m-1));
    if residsum(i) > ResidThreshold && MsecEndOfReading_1 == 0;
        MsecEndOfReading_1=i;
    end;
end

%   Find Second Break Point - NaNs

MsecEndOfReading_2=[];
NaNPeriod=3000;
NaNThreshold=2300;
StartIndex=round(length(Msec)*.7)-NaNPeriod;
ThresholdSum=0;
YisNaN(1:StartIndex)=0;
YisNaN_Sum=zeros(length(Msec),1);
for i = StartIndex:length(Msec)-NaNPeriod
    YisNaN_Sum(i)=sum(YisNaN(i:min(i+NaNPeriod-1,length(Msec))));
    if YisNaN_Sum(i)>NaNThreshold && isempty(MsecEndOfReading_2);MsecEndOfReading_2=i+NaNPeriod-1;ThresholdSum=YisNaN_Sum(i);end;
end
if ~isempty(MsecEndOfReading_2);
    Str=nanmax(MsecEndOfReading_2-2000,first_good_index);
    End=nanmin(MsecEndOfReading_2+2000,last_good_index);
    fprintf('Local Max YisNaN_sum = %d\n',max(YisNaN_Sum(Str:End)));
end;

%   Find Third Break Point - Slope

MsecEndOfReading_3=[];
Slope=zeros(length(Msec),1);
Rsqr=zeros(length(Msec),1);
LineLength=5000;
for i = first_good_index:50:last_good_index-LineLength;
%     fprintf('Calculating Slopes, i = %d , End = %d, Percent = %5.2f\n',i,last_good_index,100*i/last_good_index)
    X1=Msec(i:i+LineLength-1);
    Y1=Y(i:i+LineLength-1);
    len=length(X1);
    X=[ones(len,1) X1];
    [b,~,~,~,stats] = regress(Y1,X);
    Slope(i) = b(2);
    Rsqr(i) = stats(1);
end;
SlopeIsZeroIndex=find(Slope == 0);
Slope(SlopeIsZeroIndex)=[];
SlopeMsec=Msec;
SlopeMsec(SlopeIsZeroIndex)=[];
Slope=Slope*100000;
NaNIndex = find(isnan(SlopeMsec) | isnan(Slope));
SlopeMsec(NaNIndex)=[];
Slope(NaNIndex)=[];
% out=[SlopeMsec Slope];
% csvwrite(strrep(FileName,'.csv','_slope.csv'),out)

SlopeThreshold=0;
IndexOfSlopeOverLimit=find(Slope>SlopeThreshold);
if isempty(IndexOfSlopeOverLimit);
    MsecEndOfReading_3=Msec(last_good_index);
else
    ii=IndexOfSlopeOverLimit;
    for i = 1:length(IndexOfSlopeOverLimit)
%         fprintf('i=%d,SlopeMsec(Index)=%d,Slope(Index)=%6.2f\n',i,SlopeMsec(ii(i)),Slope(ii(i)))
        if SlopeMsec(ii(i)) > FirstThird;
             MsecEndOfReading_3=SlopeMsec(ii(i))+5000;
             break;
        end
    end;
end

% Check for Missing Thresholds

if isempty(MsecEndOfReading_1) || MsecEndOfReading_1 == 0 || isnan(MsecEndOfReading_1);MsecEndOfReading_1=Msec(last_good_index);end;
if isempty(MsecEndOfReading_2) || MsecEndOfReading_2 == 0 || isnan(MsecEndOfReading_2);MsecEndOfReading_2=Msec(last_good_index);end;
if isempty(MsecEndOfReading_3) || MsecEndOfReading_3 == 0 || isnan(MsecEndOfReading_3);MsecEndOfReading_3=Msec(last_good_index);end;

%   Find a good stretch of data without NaNs

fprintf('MsecEndOfReading_1 = %d, MsecEndOfReading_2 = %d, MsecEndOfReading_3 = %d\n',MsecEndOfReading_1,MsecEndOfReading_2,MsecEndOfReading_3)
[MsecEndOfReading_1]=FindLastGoodStretchOfData(Y,MsecEndOfReading_1);
[MsecEndOfReading_2]=FindLastGoodStretchOfData(Y,MsecEndOfReading_2);
[MsecEndOfReading_3]=FindLastGoodStretchOfData(Y,MsecEndOfReading_3);
fprintf('MsecEndOfReading_1 = %d, MsecEndOfReading_2 = %d, MsecEndOfReading_3 = %d\n',MsecEndOfReading_1,MsecEndOfReading_2,MsecEndOfReading_3)

% if MsecEndOfReading_1 < MsecEndOfReading_2;
%     MsecEndOfReading=MsecEndOfReading_1;
%     which_one=1;
% elseif MsecEndOfReading_1 > MsecEndOfReading_2;
%     MsecEndOfReading=MsecEndOfReading_2;
%     which_one=2;
% else
%     MsecEndOfReading = MsecEndOfReading_1; 
%     which_one=1;
% end;
% 
%   Figure 1: Plot VertPos

FigureHandle=SetUpFigure(this_user);
ax=subplot(1,1,1);
plot(Msec/1000,Y,'-k','LineWidth',1);hold on;
Y1=INIT_intercept;Y2=Msec(last_good_index)*INIT_slope+INIT_intercept;plot([0 last_good_index/1000],[Y1 Y2],':r','LineWidth',1);hold on;
xlim([Msec(first_good_index)/1000 Msec(last_good_index)/1000]);
MarkThresholds(nanmin(Y),nanmax(Y),MsecEndOfReading_1,MsecEndOfReading_2,MsecEndOfReading_3)
y=[nanmin(Y) nanmax(Y)];
ylim(y);
x=[ 5  5];plot(x,y,'-r','linewidth',2);hold on;
x=[25 25];plot(x,y,'-r','linewidth',2);hold on;
xlabel('sec');ylabel('VertPos');
whitebg([0.5 0.5 0.5])
mytitle=strcat(newFileName(1:12), ' - Estimate #1: Reading Ends at = ',...
               num2str(MsecEndOfReading_1/1000,'%5.2f'),...
               ' Seconds, Model r-sqr = ',num2str(stats(1),'%4.2f'),...
               ', Slope = ',num2str(INIT_slope*100000,'%6.1f'),' Intrcpt = ',num2str(INIT_intercept,'%5.1f'));
title(mytitle);
FileNameImg1=strrep(FileName,'.csv','_VPOS.jpg');
FigureHandle.InvertHardcopy = 'off';
saveas(gcf,[OutPathStr FileNameImg1])

%   Figure 2: Plot YisNaN_sum

FigureHandle=SetUpFigure(this_user);

%   Top Plot - Residuals

ax1=subplot(3,1,1);
plot(Msec/1000,residsum,'-m','linewidth',2);
hold on
x=[0 Msec(last_good_index)/1000];
y=[ResidThreshold ResidThreshold];
plot(x,y,':k','linewidth',2)
xlim([Msec(first_good_index)/1000 Msec(last_good_index)/1000]);
ylim([0 6000]);
y=[0 6000];
x=[MsecEndOfReading_1/1000 MsecEndOfReading_1/1000];
plot(x,y,'-g','linewidth',2);
xlabel('sec');ylabel('Sum Of Residuals');
whitebg([0.5 0.5 0.5])
mytitle=strcat(newFileName(1:12), ' - Estimate #1: Sum Of Residuals, Reading Ends at = ',...
               num2str(MsecEndOfReading_1/1000,'%5.2f'),' Seconds.');
title(mytitle);

%   Middle Plot - NaNs

ax2=subplot(3,1,2);
plot(Msec/1000,YisNaN_Sum,'-m','linewidth',2);
hold on
x=[0 Msec(last_good_index)/1000];
y=[NaNThreshold NaNThreshold];
plot(x,y,':k','linewidth',2)
xlim([Msec(first_good_index)/1000 Msec(last_good_index)/1000]);
ylim([0 NaNPeriod*1.1]);
y=[0 2500];
x=[MsecEndOfReading_2/1000 MsecEndOfReading_2/1000];
plot(x,y,'-b','linewidth',2);
xlabel('sec');ylabel('Sum Of NaNs');
whitebg([0.5 0.5 0.5])
mytitle=strcat(newFileName(1:12), ' - Estimate #2: Many NaNs, Reading Ends at = ',...
               num2str(MsecEndOfReading_2/1000,'%5.2f'),' Seconds.');
title(mytitle);


%   Bottom Plot - Slopes

ax3=subplot(3,1,3);
plot(SlopeMsec/1000,Slope,'-m','linewidth',2);
hold on
x=[0 Msec(last_good_index)/1000];y=[SlopeThreshold SlopeThreshold];plot(x,y,':k','linewidth',2);hold on
x=[(MsecEndOfReading_3/1000)-5 (MsecEndOfReading_3/1000)-5];y=[-2000 2000];plot(x,y,':y','linewidth',2);hold on;
x=[(MsecEndOfReading_3/1000)   (MsecEndOfReading_3/1000)  ];y=[-2000 2000];plot(x,y,'-y','linewidth',2);hold on;
xlim([Msec(first_good_index)/1000 Msec(last_good_index)/1000]);
ylim([-2000 2000]);
xlabel('sec');ylabel('Slopes');
whitebg([0.5 0.5 0.5])

mytitle=strcat(newFileName(1:12), ' - Estimate #3: Slope Change, Reading Ends at = ',...
               num2str(MsecEndOfReading_3/1000,'%5.2f'),' Seconds.');
title(mytitle);
% ['Slope = ' num2str(slope_rob,'%6.3f') ', Intercept =  ' num2str(intercept_rob,'%6.3f') ',  R-sqr = ' num2str(rsquare_robustfit,'%3.2f')]})
% suptitle(mytitle);
FileNameImg2=strrep(FileName,'.csv','_CRIT.jpg');
FigureHandle.InvertHardcopy = 'off';
saveas(gcf,[OutPathStr FileNameImg2])
% if MsecEndOfReading_2 < MsecEndOfReading_1-1000;
%     myhandel
% end;
close all
% heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
% heapFreeMemory  = java.lang.Runtime.getRuntime.freeMemory;
% fprintf(' Before GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))
java.lang.Runtime.getRuntime.gc;
% heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
% fprintf(' After  GC: Total Heap Memory = %s, Free Heap Memory = %s\n',ThousandSep(heapTotalMemory),ThousandSep(heapFreeMemory))

return
function [EventTime]=FindLastGoodStretchOfData(Y,EventTime)
for i = EventTime:-1:1
    NaNVector=find(isnan(Y(i-500:i)));
    length(NaNVector);
%   fprintf('EventTime=%d, i = %d, Length NaNVector = %d\n',EventTime,i,length(NaNVector))
    if isempty(NaNVector);
       Diff=EventTime-i;
       if Diff >= 0;
           fprintf('Based on Looking for 500 not NaN points, MsecEndOfReading = %d Set to %d. Diff = %d\n',...
                    EventTime,i,Diff)
           EventTime=i;
           return
       else
           myhandel;
           pause; 
       end;
    end
end;
return
function [FigHandle]=SetUpFigure(this_user)
close all;
Height=500;
Width=1000;
if strcmp(this_user,'l_f96');
    myposition=[1300 100 Width Height];
else
    myposition=[25 100 Width Height];
end
FigHandle=figure(1);
set(FigHandle,'units','pixels','position',myposition);
set(FigHandle,'visible','off');
return
function MarkThresholds(minY,maxY,End_1,End_2,End_3)

One_Third=(maxY-minY)/3.;
% fprintf('minY=%5.2f, maxY=%5.2f, range=%5.2f, 1/3 range=%5.2f\n',minY,maxY,maxY-minY,One_Third)

FirstThird=minY+One_Third;
SecondThird=minY+(2*One_Third);

x=[End_1/1000 End_1/1000];y=[FirstThird  maxY];plot(x,y,':w','linewidth',2);hold on;
x=[End_2/1000 End_2/1000];y=[minY  FirstThird];plot(x,y,':w','linewidth',2);hold on;
x=[End_2/1000 End_2/1000];y=[SecondThird maxY];plot(x,y,':w','linewidth',2);hold on;
x=[End_3/1000 End_3/1000];y=[minY SecondThird];plot(x,y,':w','linewidth',2);hold on;

y=[minY       FirstThird ];x=[End_1/1000 End_1/1000];plot(x,y,'-g','linewidth',4);hold on;
y=[FirstThird SecondThird];x=[End_2/1000 End_2/1000];plot(x,y,'-b','linewidth',4);hold on;
y=[SecondThird       maxY];x=[End_3/1000 End_3/1000];plot(x,y,'-y','linewidth',4);hold on;

return