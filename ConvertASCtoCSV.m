function ConvertASCtoCSV
close all
clc
clear all
format long g
this_user = 'leef';
name='E:\EyeMovementRawData\ASC_FILES\*.asc';
filelist=dir(name);

InPathStr=strcat('E:\EyeMovementRawData\ASC_FILES\');
% 'C:\Users\',this_user,'\Google Drive\EyeMovementRawData\');

for i = 1:length(filelist)
    InFileName = filelist(i).name;
    OutFileName=strrep(InFileName,'asc','csv');
    InFullPath=char(strcat(InPathStr,InFileName));
    OutFullPath=strcat('C:\Users\',this_user,'\Google Drive\EyeMovementRawData\',OutFileName);
    fprintf('\n Input File: %s\n%s\n',InFullPath)
    fprintf('Output File: %s\n%s\n',OutFullPath)
    fid_in=fopen(InFullPath,'r');
    fid_out=fopen(OutFullPath,'w');
    tline = fgets(fid_in);
    updatedString = regexprep(tline, '\t', ',');
    fprintf(fid_out,'%s',updatedString);
    count=0;
    while ischar(tline)
        tline = fgets(fid_in);
        if ischar(tline)
            updatedString = regexprep(tline, '\t', ',');
            fprintf(fid_out,'%s',updatedString);
        end;
        count=count+1;
        if (mod(count,10000)==0),fprintf('file = %d, line = %d\n',i,count),end;
    end
    fclose(fid_in);
    fclose(fid_out);
    data = csvread(OutFullPath,2);
    msec=data(:,1);
    xpos=data(:,8);
    ypos=data(:,9);
    validity=data(:,11);
    pupil=data(:,12);
    msec=msec-msec(1);
    headers='msec,xpos,ypos,pupil,valid';
    fid_out2 = fopen(OutFullPath,'w');
    fprintf(fid_out2,'%s\r\n',headers);
    for j = 1:length(msec)
        if (validity(j) == 4);
            xpos(j)=NaN;
            ypos(j)=NaN;
            pupil(j)=NaN;
        end;
        fprintf(fid_out2,'%15f,%f,%f,%d,%d\n',msec(j),xpos(j),ypos(j),pupil(j),validity(j));
    end;
    fclose(fid_out2);
    clear data msec xpos ypos validity
    fclose all;
%     fprintf('\nDelete Input File: %s\n',FullPath)
%     delete(InFullPath);
end
return
