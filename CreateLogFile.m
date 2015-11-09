function [logname]=CreateLogFile(PathStr,message)
logname = sprintf('%s-Log-%s',message,datestr(now,31));
logname=strrep(logname,' ','-');
logname=strrep(logname,':','-');
logname=[PathStr logname '.txt'];
diary(logname)

diary(logname)
fprintf('Diary File Name = %s\n',logname)
return
