function openFile(codeFile, varargin)
prj = currentProject;

if nargin > 1
    opentoline(fullfile(prj.RootFolder,codeFile), str2double(varargin{1}));
else
    open(fullfile(prj.RootFolder,codeFile));
end