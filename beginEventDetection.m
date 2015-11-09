%--------------------------------------------------------------------------
% For usage, see the README-file.
%--------------------------------------------------------------------------
clear all, close all, clc
global ETparams;
global Scalers;
WhichUser=1;user=['l_f96';'leef ';'lee  '];CS=cellstr(user);
global this_user
this_user=char(CS(WhichUser));
global DrawFiguresTF
DrawFiguresTF=true;
global FileName
%--------------------------------------------------------------------------
% Create Log File
%--------------------------------------------------------------------------
PathForLogFile=strcat('C:\Users\',this_user,'\Dropbox\NYSTROM_MATLAB_CODE\Nystom_Modified_Method\');
[logname] = CreateLogFile(PathForLogFile);
%--------------------------------------------------------------------------
% Init parameters
%--------------------------------------------------------------------------
% ETparams.data = ETdata;
Scalers.samplingFreq = 1000;
Scalers.blinkVelocityThreshold = 1500;             % if vel > 1000 degrees/s, it is noise or blinks
Scalers.blinkAccThreshold = 100000;                % if acc > 100000 degrees/s^2, it is noise or blinks
Scalers.peakDetectionThreshold = 100;              % Initial value of the peak detection threshold. 

Scalers.PeakVelocityThreshold=65;
Scalers.SacOnOffThresh=55;
Scalers.WeakGlissadeVelocityThreshold=35;

% Scalers.NsigmaPeak = 18;
% Scalers.NsigmaOnOff = Scalers.NsigmaPeak*.80;
Scalers.minFixDur = 0.030; % in seconds
Scalers.minSaccadeDur = 0.010; % in seconds
Scalers.maxSaccadeAmplitude = 6; % in degrees
Scalers.maxSaccadeDuration = 0.070;% in seconds
Scalers.maxDistanceAmpDur = 3.0;% in degrees
Scalers.maxDistancePkvAmp = 0.5;

Scalers.AmpDurIntercept=-1.1359;
Scalers.AmpDurSlope    = 0.1233;
Scalers.PkVAmpIntercept= 1.9915;
Scalers.PkVAmpSlope    = 0.62549;
%--------------------------------------------------------------------------
% Begin detection
%--------------------------------------------------------------------------

% Process data
eventDetection
fprintf('Log File Name = \n%s\n',logname)
close all
fclose('all');