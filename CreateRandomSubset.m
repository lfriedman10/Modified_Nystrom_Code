function CreateRandomSubset();
clc
close all
fclose('all');
clear
GoodDataVector=[1:27 29:35 37:49 51:55 57:74 76:81 83:103 106:111 113:123 125:159 161:204 206:323 325:335];
GoodDataVector=GoodDataVector';
len=length(GoodDataVector)
TaskLen=round(len/3)-1;
TaskLen=104;
TEXIndx=randsample(len,TaskLen);
TEXSample=GoodDataVector(TEXIndx);
GoodDataVector(TEXIndx)=[];
len=length(GoodDataVector)
HORIndx=randsample(len,TaskLen);
HORSample=GoodDataVector(HORIndx);
GoodDataVector(HORIndx)=[];
RANSample=GoodDataVector(1:104);
size(TEXSample)
size(HORSample)
size(RANSample)
out=[TEXSample HORSample RANSample];
headers = {'TEX','HOR','RAN'};
csvwrite_with_headers('RandomSamples.csv',out,headers)
csvread('RandomSamples.csv',1,0)



