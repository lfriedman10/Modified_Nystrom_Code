function calVelAcc_sgolay(signals) %i=Subject,j=Session
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

ETparams.data.Xorg=signals(:,2)';
ETparams.data.Yorg=signals(:,3)';
ETparams.data.Msec=signals(:,1)';
ETparams.data.Pupil=signals(:,4)';
% ETparams.data.RawRadialPos=sqrt(ETparams.data.Xorg.^2 + ETparams.data.Yorg.^2);
mylen=length(ETparams.data.Xorg);
% Create Classification Vector
ETparams.data.Classification=zeros(1,mylen);
ETparams.data.SubType=zeros(1,mylen);
% Eyelink NaNs = 4; 
ETparams.data.Classification(isnan(ETparams.data.Xorg))=4;

clear signals

% ETparams.data.velXorg = [0 diff(ETparams.data.Xorg)]*[Scalers.samplingFreq];
% ETparams.data.velYorg = [0 diff(ETparams.data.Yorg)]*[Scalers.samplingFreq];
% ETparams.data.velOrg  = sqrt(ETparams.data.velXorg.^2 + ETparams.data.velYorg.^2);

% velocities, and accelerations
%--------------------------------------------------------------------------
N = 2;                 % Order of polynomial fit
F = 2*ceil(span)-1;    % Window length
F=7;
% fprintf(' the window length of the SG filter is %d\n',F)
[b,g] = sgolay(N,F);   % Calculate S-G coefficients

% Extract relevant gaze coordinates for the current trial.

% Calculate the velocity and acceleration
% ETparams.data.SmoothRadialPos = filter(g(:,1),1,ETparams.data.RawRadialPos);
ETparams.data.Xsmo = filter(g(:,1),1,ETparams.data.Xorg);
ETparams.data.Classification((ETparams.data.Classification~=4) & isnan(ETparams.data.Xsmo))=5;

% csvwrite('CheckClassification.csv',[ETparams.data.Msec' ETparams.data.Classification']);
ETparams.data.Ysmo = filter(g(:,1),1,ETparams.data.Yorg);
ETparams.data.velX = filter(g(:,2),1,ETparams.data.Xorg)*[Scalers.samplingFreq];
ETparams.data.velY = filter(g(:,2),1,ETparams.data.Yorg)*[Scalers.samplingFreq];
ETparams.data.vel = sqrt(ETparams.data.velX.^2 + ETparams.data.velY.^2);
ETparams.data.accX = filter(g(:,3),1,ETparams.data.Xorg);
ETparams.data.accY = filter(g(:,3),1,ETparams.data.Yorg);
ETparams.data.acc = sqrt(ETparams.data.accX.^2 + ETparams.data.accY.^2)*[Scalers.samplingFreq]^2;

ETparams.data.nanIdx.Idx = zeros(1,length(ETparams.data.Xorg));
ETparams.data.nanIdx.Idx(ETparams.data.Classification > 3)=1;

clear ETparams.data.velX ETparams.data.velY ETparams.data.accX ETparams.data.accY
ETparams.data.Xorg(ETparams.data.Classification == 4)=4;
ETparams.data.Yorg(ETparams.data.Classification == 4)=4;
ETparams.data.Xsmo(ETparams.data.Classification == 4)=4;
ETparams.data.Ysmo(ETparams.data.Classification == 4)=4;
ETparams.data.Xorg(ETparams.data.Classification == 5)=5;
ETparams.data.Yorg(ETparams.data.Classification == 5)=5;
ETparams.data.Xsmo(ETparams.data.Classification == 5)=5;
ETparams.data.Ysmo(ETparams.data.Classification == 5)=5;

close all

