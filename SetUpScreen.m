function SetUpScreen()
global this_user
close all;
FigHandle=figure(1);
Height=350;Width=500;
if strcmp(this_user,'l_f96');
    myposition=[1400 50 Width Height];
else
    myposition=[10 50 Width Height];
end;
set(FigHandle,'units','pixels','position',myposition);
set(FigHandle,'visible','on');
return