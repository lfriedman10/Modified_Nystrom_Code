function [] = extractFeatures(i, j)
% Extract features from the classified fixations, saccades, and glissades

global ETparams
global Scalers
global FileName
global OutPathStr

% Get initial total number of fixations and saccades
initFixNum = ETparams.ff;
initSacNum = ETparams.kk;


% -- Initialize empty 'features' vector and 'headers' cell ----------------
% -------------------------------------------------------------------------
features = [];
headers = cell(1, 1);


% -- Extract Basic information features -----------------------------------
% -------------------------------------------------------------------------
currFeature = i;                            % #Feature: Subject Number (ID)
features(1, 1) = currFeature;
headers{1, 1} = 'Subject';

currFeature = j;                            % #Feature: Session Number
features(1, 2) = currFeature;
headers{1, 2} = 'Session';

features(1, 3) = NaN;  % Reserved place for % #Feature: Number of Fixations
headers{1, 3} = 'N_Fix';  

features(1, 4) = NaN;  % Reserved place for % #Feature: Number of Saccades
headers{1, 4} = 'N_Sac';  

features(1, 5) = NaN;  % Reserved place for % #Feature: Number of Glissades
headers{1, 5} = 'N_Gls';  

currFeature = ETparams.NumBlinks;     % #Feature: Number of NaN Blocks
features(1, 6) = currFeature;
headers{1, 6} = 'N_NaN';


% -- Extract Fixation features --------------------------------------------
% -------------------------------------------------------------------------

% Prepare profiles: position, velocity, acceleration
fixStart = zeros(initFixNum, 1);
fixEnd = zeros(initFixNum, 1);
fixPosXProf = cell(initFixNum, 1);
fixPosYProf = cell(initFixNum, 1);
fixVelXProf = cell(initFixNum, 1);
fixVelYProf = cell(initFixNum, 1);
fixVelProf = cell(initFixNum, 1);
fixAccXProf = cell(initFixNum, 1);
fixAccYProf = cell(initFixNum, 1);
fixAccProf = cell(initFixNum, 1);

for k = 1:initFixNum
        % Convert from time to samples
        fixStart(k) = round([ETparams.fixinfo(k).fixationInfo.start]*Scalers.samplingFreq);
        fixEnd(k) = round([ETparams.fixinfo(k).fixationInfo.end]*Scalers.samplingFreq);
        % Extract profiles
        fixPosXProf{k} = ETparams.data.Xsmo(fixStart(k):fixEnd(k));
        fixPosYProf{k} = ETparams.data.Ysmo(fixStart(k):fixEnd(k));
        fixVelXProf{k} = ETparams.data.velX(fixStart(k):fixEnd(k));
        fixVelYProf{k} = ETparams.data.velY(fixStart(k):fixEnd(k));
        fixVelProf{k} = ETparams.data.vel(fixStart(k):fixEnd(k));
        fixAccXProf{k} = ETparams.data.accX(fixStart(k):fixEnd(k));
        fixAccYProf{k} = ETparams.data.accY(fixStart(k):fixEnd(k)); 
        fixAccProf{k} = ETparams.data.acc(fixStart(k):fixEnd(k));
end

% Calculate distribution features (i.e. profile modeling)
fixDur = zeros(initFixNum, 1);
fixCentroidX = zeros(initFixNum, 1);
fixCentroidY = zeros(initFixNum, 1);
for k = 1:initFixNum
        % Duration (ms)
        fixDur(k) = 1000*(fixEnd(k) - fixStart(k))/[Scalers.samplingFreq];
        % Centroid X (deg)
        fixCentroidX(k) = mean(fixPosXProf{k});
        % Centroid Y (deg)
        fixCentroidY(k) = mean(fixPosXProf{k});
end

% Apply filters on fixations. No filter currently applied.
fIdx = true(initFixNum, 1);

% Store number of fixations (fIdx) to reserved place
features(1, 3) = length(find(fIdx));

% Calculate final fixation (fIdx) features (i.e. distribution modeling)
currFeature = min(fixDur(fIdx));                      % #Feature: Fixation Duration (minimum)
features = [features, currFeature];
headers = [headers, 'F_Mn_Dur'];

currFeature = median(fixDur(fIdx));                   % #Feature: Fixation Duration (median)
features = [features, currFeature];
headers = [headers, 'F_Md_Dur'];

currFeature = std(fixDur(fIdx));                      % #Feature: Fixation Duration (standard deviation)
features = [features, currFeature];
headers = [headers, 'F_Sd_Dur'];

currFeature = skewness(fixDur(fIdx));                 % #Feature: Fixation Duration (skewness)
features = [features, currFeature];
headers = [headers, 'F_Sk_Dur'];

currFeature = kurtosis(fixDur(fIdx));                 % #Feature: Fixation Duration (kurtosis)
features = [features, currFeature];
headers = [headers, 'F_Ku_Dur'];

currFeature = iqr(fixDur(fIdx));                      % #Feature: Fixation Duration (interquartile range)
features = [features, currFeature];
headers = [headers, 'F_Iq_Dur'];


% -- Extract Saccade features ---------------------------------------------
% -------------------------------------------------------------------------

% Prepare profiles: position, velocity, acceleration
sacStart = zeros(initSacNum, 1);
sacEnd = zeros(initSacNum, 1);
sacPosXProf = cell(initSacNum, 1);
sacPosYProf = cell(initSacNum, 1);
sacVelXProf = cell(initSacNum, 1);
sacVelYProf = cell(initSacNum, 1);
sacVelProf = cell(initSacNum, 1);
sacAccXProf = cell(initSacNum, 1);
sacAccYProf = cell(initSacNum, 1);
sacAccProf = cell(initSacNum, 1);
for k = 1:initSacNum
        % Convert from time to samples
        sacStart(k) = round([ETparams.sacinfo(k).saccadeInfo.start]*Scalers.samplingFreq);
        sacEnd(k) = round([ETparams.sacinfo(k).saccadeInfo.end]*Scalers.samplingFreq);
        % Extract profiles
        sacPosXProf{k} = ETparams.data.Xsmo(sacStart(k):sacEnd(k));
        sacPosYProf{k} = ETparams.data.Ysmo(sacStart(k):sacEnd(k));
        sacVelXProf{k} = ETparams.data.velX(sacStart(k):sacEnd(k));
        sacVelYProf{k} = ETparams.data.velY(sacStart(k):sacEnd(k));
        sacVelProf{k} = ETparams.data.vel(sacStart(k):sacEnd(k));
        sacAccXProf{k} = ETparams.data.accX(sacStart(k):sacEnd(k));
        sacAccYProf{k} = ETparams.data.accY(sacStart(k):sacEnd(k)); 
        sacAccProf{k} = ETparams.data.acc(sacStart(k):sacEnd(k));
end

% Calculate distribution features (i.e. profile modeling)
sacDur = zeros(initSacNum, 1);
sacAmpX = zeros(initSacNum, 1);
sacAmpY = zeros(initSacNum, 1);
sacAmp = zeros(initSacNum, 1);
for k = 1:initSacNum
        % Duration (ms)
        sacDur(k) = 1000*(sacEnd(k) - sacStart(k))/[Scalers.samplingFreq];
        % Amplitude X (deg)
        sacAmpX(k) = sacPosXProf{k}(end) - sacPosXProf{k}(1);
        % Amplitude Y (deg)
        sacAmpY(k) = sacPosYProf{k}(end) - sacPosYProf{k}(1); 
        % Amplitude (deg)
        sacAmp(k) = sqrt(sacAmpX(k).^2 + sacAmpY(k).^2); 
end

% Apply filters on saccades
sIdx = false(initSacNum, 1);
for k = 1:initSacNum
    if(sacAmp(k) > Scalers.maxSaccadeAmplitude), continue, end;
    if(sacDur(k) > (Scalers.maxSaccadeDuration*1000)), continue, end;
    sIdx(k) = true;
end

% Store number of final saccades (sIdx) to reserved place
features(1, 4) = length(find(sIdx));

% Calculate final saccade (sIdx) features (i.e. distribution modeling)
currFeature = min(sacDur(sIdx));                      % #Feature: Saccade Duration (minimum)
features = [features, currFeature];
headers = [headers, 'S_Mn_Dur'];

currFeature = median(sacDur(sIdx));                   % #Feature: Saccade Duration (median)
features = [features, currFeature];
headers = [headers, 'S_Md_Dur'];

currFeature = std(sacDur(sIdx));                      % #Feature: Saccade Duration (standard deviation)
features = [features, currFeature];
headers = [headers, 'S_Sd_Dur'];

currFeature = skewness(sacDur(sIdx));                 % #Feature: Saccade Duration (skewness)
features = [features, currFeature];
headers = [headers, 'S_Sk_Dur'];

currFeature = kurtosis(sacDur(sIdx));                 % #Feature: Saccade Duration (kurtosis)
features = [features, currFeature];
headers = [headers, 'S_Ku_Dur'];

currFeature = iqr(sacDur(sIdx));                      % #Feature: Saccade Duration (interquartile range)
features = [features, currFeature];
headers = [headers, 'S_Iq_Dur'];


% -- Extract Glissade features --------------------------------------------
% -------------------------------------------------------------------------

% Prepare profiles: position, velocity, acceleration
glissStart = zeros(initSacNum, 1);
glissEnd = zeros(initSacNum, 1);
glissPosXProf = cell(initSacNum, 1);
glissPosYProf = cell(initSacNum, 1);
glissVelXProf = cell(initSacNum, 1);
glissVelYProf = cell(initSacNum, 1);
glissVelProf = cell(initSacNum, 1);
glissAccXProf = cell(initSacNum, 1);
glissAccYProf = cell(initSacNum, 1);
glissAccProf = cell(initSacNum, 1);
for k = 1:initSacNum
        if(ETparams.glisinfo(k).glissadeInfo.type == 0), continue, end;
        % Convert from time to samples
        fprintf('Working On Saccade # = %d\n',k)
        glissStart(k) = round([ETparams.glisinfo(k).glissadeInfo.start]*Scalers.samplingFreq);
        glissEnd(k) = round([ETparams.glisinfo(k).glissadeInfo.end]*Scalers.samplingFreq);
        % Extract profiles
        glissPosXProf{k} = ETparams.data.Xsmo(glissStart(k):glissEnd(k));
        glissPosYProf{k} = ETparams.data.Ysmo(glissStart(k):glissEnd(k));
        glissVelXProf{k} = ETparams.data.velX(glissStart(k):glissEnd(k));
        glissVelYProf{k} = ETparams.data.velY(glissStart(k):glissEnd(k));
        glissVelProf{k} = ETparams.data.vel(glissStart(k):glissEnd(k));
        glissAccXProf{k} = ETparams.data.accX(glissStart(k):glissEnd(k));
        glissAccYProf{k} = ETparams.data.accY(glissStart(k):glissEnd(k)); 
        glissAccProf{k} = ETparams.data.acc(glissStart(k):glissEnd(k));
end

% Calculate distribution features (i.e. profile modeling)
glissDur = zeros(initSacNum, 1);
for k = 1:initSacNum
        % Duration (ms)
        glissDur(k) = 1000*(glissEnd(k) - glissStart(k))/[Scalers.samplingFreq];
end

% Apply filters on saccades
gIdx = false(initSacNum, 1);
for k = 1:initSacNum
    if(~sIdx), continue, end;
    if(ETparams.glisinfo(k).glissadeInfo.type == 0), continue, end;
    gIdx(k) = true;
end

% Store number of final glissades (gIdx) to reserved place
features(1, 5) = length(find(gIdx));

% Calculate final glissade (gIdx) features (i.e. distribution modeling)
currFeature = min(glissDur(gIdx));                      % #Feature: Glissade Duration (minimum)
features = [features, currFeature];
headers = [headers, 'G_Mn_Dur'];

currFeature = median(glissDur(gIdx));                   % #Feature: Glissade Duration (median)
features = [features, currFeature];
headers = [headers, 'G_Md_Dur'];

currFeature = std(glissDur(gIdx));                      % #Feature: Glissade Duration (standard deviation)
features = [features, currFeature];
headers = [headers, 'G_Sd_Dur'];

currFeature = skewness(glissDur(gIdx));                 % #Feature: Glissade Duration (skewness)
features = [features, currFeature];
headers = [headers, 'G_Sk_Dur'];

currFeature = kurtosis(glissDur(gIdx));                 % #Feature: Glissade Duration (kurtosis)
features = [features, currFeature];
headers = [headers, 'G_Ku_Dur'];

currFeature = iqr(glissDur(gIdx));                      % #Feature: Glissade Duration (interquartile range)
features = [features, currFeature];
headers = [headers, 'G_Iq_Dur'];


% -- Append stimulus suffix (TEX, RAN, HSS) and write .csv file -----------
% -------------------------------------------------------------------------
if(strcmp(FileName(10:12), 'TEX'))
    for k = 3:length(headers)
        headers{k} = [headers{k}, '_T'];
    end
    csvwrite_with_headers([OutPathStr FileName(1:12) '.csv'], features, headers);
elseif(strcmp(FileName(10:12), 'RAN'))
    for k = 3:length(headers)
        headers{k} = [headers{k}, '_R'];
    end
    csvwrite_with_headers([OutPathStr FileName(1:12) '.csv'], features, headers);
elseif(strcmp(FileName(10:12), 'HSS'))
    for k = 3:length(headers)
        headers{k} = [headers{k}, '_H'];
    end
    csvwrite_with_headers([OutPathStr FileName(1:12) '.csv'], features, headers);
else
    error('ERROR: No valid input filename found. No information was written to output');
end
    
end