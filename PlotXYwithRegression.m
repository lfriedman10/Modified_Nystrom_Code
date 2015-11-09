function [intercept_rob,slope_rob,rsquare_robustfit]=PlotXYwithRegression(X,Y,XLabel,YLabel,Path,FileName,Type)
global DrawFiguresTF;
global Scalers;

if Type == 1;
    GlobalIntercept=Scalers.AmpDurIntercept;
    GlobalSlope=Scalers.AmpDurSlope;
elseif Type == 2;
    GlobalIntercept=Scalers.PkVAmpIntercept;
    GlobalSlope=Scalers.PkVAmpSlope;
end;    

%   set up figure

    if DrawFiguresTF;
        Height=685;
        Width=1100;
        myposition=[1 25 Width Height];
        FigHandle=figure(1);
        set(FigHandle,'units','pixels','position',myposition);
        set(FigHandle,'visible','on');
    end;
%   Prep for regression

    XX = [ones(size(X)) X];
%     size(XX)
%     size(Y)
%     out=[XX Y]
    
%   Regression
    [b,bint,r,rint,stats] = regress(Y,XX); 
    intercept=b(1);
    slope = b(2);
    rsqr = stats(1);
    % stats=R2 statistic, the F statistic and its p value, and an estimate of the error variance.

%   Draw Graph  
    if ~DrawFiguresTF;return;end;
    scatter(X,Y,'filled')
    hold on
    XFIT = min(X):.01:max(X);
    YFIT = intercept + slope.*XFIT;
    plot(XFIT,YFIT,'-r')
%   Computer Global Line
    minX=min(XFIT);
    Y1=minX*GlobalSlope+GlobalIntercept;
    maxX=max(XFIT);
    Y2=maxX*GlobalSlope+GlobalIntercept;
    plot([minX maxX],[Y1 Y2],':k','LineWidth',3)
%     for i = 1:length(X);
%         Y1 =X(i)*GlobalSlope+GlobalIntercept;
%         if Type == 1 && abs(Y1 - Y(i)) > 3.0;
%             plot(X(i),Y(i),'.r','MarkerSize',40)
%         end;
%     end;
%     Decreasing the tuning constant increases the downweight assigned to large residuals;
%     increasing the tuning constant decreases the downweight assigned to large residuals.
%     'welsch',default=2.985
    [b_rob,stats_rob] = robustfit(X,Y,'welsch',1.5);
    intercept_rob=b_rob(1);
    slope_rob = b_rob(2);
%     sse = stats_rob.dfe * stats_rob.robust_s^2;
%     phat = b_rob(1) + b_rob(2)*X;
%     ssr = norm(phat-mean(phat))^2;
%     possible_rsquare_robustfit = 1 - sse / (sse + ssr);
    rsquare_robustfit = corr(Y,intercept_rob+slope_rob*X)^2;
    Y1=minX*slope_rob+intercept_rob;
    Y2=maxX*slope_rob+intercept_rob;
    plot([minX maxX],[Y1 Y2],':m','LineWidth',3)
    hold off
    xlabel(XLabel);ylabel(YLabel);
    newFileName = strrep(FileName,'_','-');
    title({[YLabel ' vs ' XLabel ' - ' newFileName(1:12) ' -  N = ' num2str(length(X),'%d')];
           ['Slope = ' num2str(slope_rob,'%6.3f') ', Intercept =  ' num2str(intercept_rob,'%6.3f') ',  R-sqr = ' num2str(rsquare_robustfit,'%3.2f')]})
    saveas(gcf,[Path FileName])
    close all

    end