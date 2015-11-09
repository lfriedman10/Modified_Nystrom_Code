function [ColorSet,ColorCode]=LoadColors(PathStr)
close all;
ColorSet=zeros(12,3);
ColorSet( 1,:)=[1 ,0 , 0];ColorCode( 1,:)='red';Meaning( 1,:)='Fixation       ';
ColorSet( 2,:)=[0 ,1 , 0];ColorCode( 2,:)='grn';Meaning( 2,:)='Saccades       ';
ColorSet( 3,:)=[0 ,0 , 1];ColorCode( 3,:)='blu';Meaning( 3,:)='Glissades      ';
ColorSet( 4,:)=[1 ,.5, 0];ColorCode( 4,:)='org';Meaning( 4,:)='EyeLink NaNs   ';
ColorSet( 5,:)=[1 ,1 , 1];ColorCode( 5,:)='wht';Meaning( 5,:)='SG NaNs        ';
ColorSet( 6,:)=[1 ,1 , 0];ColorCode( 6,:)='yel';Meaning( 6,:)='Vel Too Fast   ';
ColorSet( 7,:)=[1 ,0 , 1];ColorCode( 7,:)='mag';Meaning( 7,:)='Acc Too Fast   ';
ColorSet( 8,:)=[0 ,1 , 1];ColorCode( 8,:)='cyn';Meaning( 8,:)='Pre NaN Block  ';
ColorSet( 9,:)=[1 ,.6,.6];ColorCode( 9,:)='pnk';Meaning( 9,:)='Post NaN Block ';
ColorSet(10,:)=[.4,.2, 0];ColorCode(10,:)='brn';Meaning(10,:)='Short Fix      ';
ColorSet(11,:)=[.5,.7,.2];ColorCode(11,:)='olv';Meaning(11,:)='Fix Max Pos Chg';
ColorSet(12,:)=[0 ,0 , 0];ColorCode(12,:)='blk';Meaning(12,:)='No Class       ';
h=figure(1);
h.InvertHardcopy = 'off';
ax=subplot(1,1,1);
myones=ones(21,1);
for i = 1:12
    plot(20:40,i*myones,'Color',ColorSet( i,:),'linewidth',4);
    text(45,i,Meaning(i,:),'Color',ColorSet( i,:),'fontsize',15)
    hold on
end;
ax.XLim=[10 70];
ax.YLim=[0 13];
ax.Color=[0.5 0.5 0.5];
ax.XTick=[];
ax.YTick=[];
title('Scoring Color Code');
PathStr
OutFile=strcat(PathStr,'Color.jpg')
saveas(gcf,OutFile)
% get(ax)
% for i =1:12
%     fprintf('Color = %d, Code = %s\n',i,ColorCode(i,:))
%     set(gcf,'Color',ColorSet(i,:))
%     pause
% end;


