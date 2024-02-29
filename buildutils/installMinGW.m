function installMinGW

if ~ispc
    return
end

mkdir("c:\mpm");
websave("c:\mpm\mpm.exe", "https://www.mathworks.com/mpm/win64/mpm");

destination = matlabroot;
destinationPath = ['""""', destination, '""""'];
cmd = "powershell Start-Process -Wait -Verb runas -ArgumentList 'install --release=" + matlabRelease().Release + " --destination=" + destinationPath + " --release-status Prerelease --products MATLAB_Support_for_MinGW-w64_C/C++_Compiler' C:\mpm\mpm.exe";
system(cmd);
rmdir("c:\mpm\","s")


envs = string(fileread(fullfile(matlabshared.supportpkg.getSupportPackageRoot,"envVariableList")));
lines = split(envs, newline);
mingwLine = lines(startsWith(lines, "MW_MINGW64_LOC"));

setenv("MW_MINGW64_LOC",extractBetween(mingwLine,"|","|"));