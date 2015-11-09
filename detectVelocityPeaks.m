function detectVelocityPeaks(i,j)
global ETparams
 

 % Find peaks larger than a threshold ('ETparams.peakDetectionThreshold')
 % Sets a '1' where the velocity is larger than the threshold and '0'
 % otherwise
ETparams(i,j).data.InitialVelPeakIdx  = (ETparams(i,j).data.vel > ETparams(i,j).data.peakDetectionThreshold);
 
 
