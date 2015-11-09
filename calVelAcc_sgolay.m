function calVelAcc_sgolay(i,j,signals) %i=Subject,j=Session
global ETparams
global Scalers
global DrawFiguresTF;
global OutPathStr;

% Lowpass filter window length
smoothInt = Scalers.minSaccadeDur; % in seconds

% Span of filter
span = ceil(smoothInt*[Scalers.samplingFreq]);
% fprintf(' the filter span is %d points\n',span)

% Calculate unfiltered data
%--------------------------------------------------------------------------

ETparams(i,j).data.Xorg=signals(:,2)';
ETparams(i,j).data.Yorg=signals(:,3)';
ETparams(i,j).data.Msec=signals(:,1)';
ETparams(i,j).data.Pupil=signals(:,4)';
% ETparams(i,j).data.RawRadialPos=sqrt(ETparams(i,j).data.Xorg.^2 + ETparams(i,j).data.Yorg.^2);
mylen=length(ETparams(i,j).data.Xorg);
% Create Classification Vector
ETparams(i,j).data.Classification=zeros(1,mylen);
ETparams(i,j).data.SubType=zeros(1,mylen);
% Eyelink NaNs = 4; 
ETparams(i,j).data.Classification(isnan(ETparams(i,j).data.Xorg))=4;

clear signals

% ETparams(i,j).data.velXorg = [0 diff(ETparams(i,j).data.Xorg)]*[Scalers.samplingFreq];
% ETparams(i,j).data.velYorg = [0 diff(ETparams(i,j).data.Yorg)]*[Scalers.samplingFreq];
% ETparams(i,j).data.velOrg  = sqrt(ETparams(i,j).data.velXorg.^2 + ETparams(i,j).data.velYorg.^2);

% velocities, and accelerations
%--------------------------------------------------------------------------
N = 2;                 % Order of polynomial fit
F = 2*ceil(span)-1;    % Window length
F=7;
% fprintf(' the window length of the SG filter is %d\n',F)
[b,g] = sgolay(N,F);   % Calculate S-G coefficients

% Extract relevant gaze coordinates for the current trial.

% Calculate the velocity and acceleration
% ETparams(i,j).data.SmoothRadialPos = filter(g(:,1),1,ETparams(i,j).data.RawRadialPos);
ETparams(i,j).data.Xsmo = filter(g(:,1),1,ETparams(i,j).data.Xorg);
ETparams(i,j).data.Classification((ETparams(i,j).data.Classification~=4) & isnan(ETparams(i,j).data.Xsmo))=5;

% csvwrite('CheckClassification.csv',[ETparams(i,j).data.Msec' ETparams(i,j).data.Classification']);
ETparams(i,j).data.Ysmo = filter(g(:,1),1,ETparams(i,j).data.Yorg);
ETparams(i,j).data.velX = filter(g(:,2),1,ETparams(i,j).data.Xorg)*[Scalers.samplingFreq];
ETparams(i,j).data.velY = filter(g(:,2),1,ETparams(i,j).data.Yorg)*[Scalers.samplingFreq];
ETparams(i,j).data.vel = sqrt(ETparams(i,j).data.velX.^2 + ETparams(i,j).data.velY.^2);
ETparams(i,j).data.accX = filter(g(:,3),1,ETparams(i,j).data.Xorg);
ETparams(i,j).data.accY = filter(g(:,3),1,ETparams(i,j).data.Yorg);
ETparams(i,j).data.acc = sqrt(ETparams(i,j).data.accX.^2 + ETparams(i,j).data.accY.^2)*[Scalers.samplingFreq]^2;

ETparams(i,j).data.nanIdx.Idx = zeros(1,length(ETparams(i,j).data.Xorg));
ETparams(i,j).data.nanIdx.Idx(ETparams(i,j).data.Classification > 3)=1;

clear ETparams(i,j).data.velX ETparams(i,j).data.velY ETparams(i,j).data.accX ETparams(i,j).data.accY
ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 4)=4;
ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 4)=4;
ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 4)=4;
ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 4)=4;
ETparams(i,j).data.Xorg(ETparams(i,j).data.Classification == 5)=5;
ETparams(i,j).data.Yorg(ETparams(i,j).data.Classification == 5)=5;
ETparams(i,j).data.Xsmo(ETparams(i,j).data.Classification == 5)=5;
ETparams(i,j).data.Ysmo(ETparams(i,j).data.Classification == 5)=5;

% Plot Horizontal Position, Velocity and Acceleration

if ~DrawFiguresTF;return;end;
Height=685;
Width=1100;
myposition=[1 25 Width Height];

FigHandle=figure(1);
set(FigHandle,'units','pixels','position',myposition);
set(FigHandle,'visible','off');

subplot(3,1,1)
plot(ETparams(i,j).data.Msec(1:1000),ETparams(i,j).data.Xsmo(1:1000))
xlabel('msec');
ylabel('Hor Position');
ax.XLim=[1 1000];
ax.XLimMode='manual';
ax.XTickLabelMode='manual';
ax.XTick = [1:200:1000];
ax.XTickLabel={num2str(1,'%05d'),num2str(200,'%05d'),num2str(400,'%05d'),num2str(600,'%05d'),num2str(800,'%05d'),num2str(1000,'%05d')};
ax.XTickLabelRotation=90;

subplot(3,1,2)
% semilogy(ETparams(i,j).data.Msec(1:1000),ETparams(i,j).data.vel(1:1000))
plot(ETparams(i,j).data.Msec(1:1000),ETparams(i,j).data.vel(1:1000))
% ylim([10^-1 10^5]);
xlabel('msec');
ylabel('Radial Velocity');
% ylim([-17 17]);
ax.XLim=[1 1000];
ax.XLimMode='manual';
ax.XTickLabelMode='manual';
ax.XTick = (1:200:1000);
ax.XTickLabel={num2str(1,'%05d'),num2str(200,'%05d'),num2str(400,'%05d'),num2str(600,'%05d'),num2str(800,'%05d'),num2str(1000,'%05d')};
ax.XTickLabelRotation=90;

subplot(3,1,3)
% semilogy(ETparams(i,j).data.Msec(1:1000),ETparams(i,j).data.acc(1:1000))
plot(ETparams(i,j).data.Msec(1:1000),ETparams(i,j).data.acc(1:1000))
xlabel('msec');
ylabel('Radial Accleration');
ylim([10^-1 10^5]);
ax.XLim=[1 1000];
ax.XLimMode='manual';
ax.XTickLabelMode='manual';
ax.XTick = [1:200:1000];
ax.XTickLabel={num2str(1,'%05d'),num2str(200,'%05d'),num2str(400,'%05d'),num2str(600,'%05d'),num2str(800,'%05d'),num2str(1000,'%05d')};
ax.XTickLabelRotation=90;

MyTitle=['Radial Signals, Subj = ' num2str(i) ', Sess = ' num2str(j) ' | Start = ' num2str(1,'%06d') ' | End  = ' num2str(1000,'%06d') ' |'];
suplabel(MyTitle,'t');

ImageFileName=['TEX_' num2str(i,'%3.3d') '_S' num2str(j) '_' num2str(1,'%06d') '_' num2str(1000,'%06d') '.jpg'];
ImageFileFullPath=[OutPathStr ImageFileName];
saveas(gcf,ImageFileFullPath);
close all

