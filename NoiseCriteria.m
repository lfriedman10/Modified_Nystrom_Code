function NoiseCriteria(i,j)

V = velocity;
V_threshold = median(V,'omitnan')*2;
len=length(V);
A = Acceleration;
NaNindex=zeros(len,1);

EyeLinkNaNs=find(isnan(V));
NaNindex(EyeLinkNaNs)=1;

% Classify NaNs due to blink Velocity Threshold, Scalers.blinkVelocityThreshold = 1500;
for q = 1:len;
    if V(q) > 1500;NaNindex(q)=1;=end;% isnan
end;

 % Classify NaNs due to blink Acceleration Threshold, Scalers.blinkAccThreshold = 100000; 
for q = 1:len;
   if A(q) > 100000;NaNindex(q)=1;end;
end;

% Label blinks or noise
NaNLabeled = bwlabel(NaNindex);
TotalNumberNaNs=max(NaNLabeled)

for k = 1:max(NaNLabeled)

     b = find(NaNLabeled == k);   
      
    % Go back in time to see where the blink (noise) started
    TrueStartOfNaN=[];
    if(b(1)>1);
        TrueStartOfNaN = find(V(b(1):-1:1) <= V_threshold);
        if(~isempty(TrueStartOfNaN));
            TrueStartOfNaN = b(1) - TrueStartOfNaN(1) + 1;
        else
            TrueStartOfNaN = b(1);
        end;
    end;
    if ~isempty(TrueStartOfNaN),NaNindex(TrueStartOfNaN:b(1)) = 1;end;
    
    % Go forward in time to see where the blink (noise) ends
    TrueEndOfNaN = find(V(b(end):end) <= V_threshold);
    if numel(TrueEndOfNaN)> 0
        TrueEndOfNaN(1) = (b(end) + TrueEndOfNaN(1) - 1);
    else
        TrueEndOfNaN(1) = b(end);
    end
    if ~isempty(TrueEndOfNaN),NaNindex(b(end):TrueEndOfNaN(1)) = 1;
end

