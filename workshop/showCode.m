function showCode(codeFile, varargin)
prj = currentProject;

dbtype(fullfile(prj.RootFolder,codeFile), varargin{:});
end