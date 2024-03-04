function plan = buildfile
import matlab.buildtool.tasks.*;

plan = buildplan(localfunctions);
plan.DefaultTasks = "release"; 

%% Enable cleaning derived build outputs
plan("clean") = CleanTask;


%% Lint the code and tests
plan("lint") = CodeIssuesTask(Results="results/code-issues.sarif");


%% Build mex files and place them in toolbox folder
plan("mex_convec") = MexTask("mex/convec.c", "toolbox", Dependencies="setupCompiler");
plan("mex_yprime") = MexTask("mex/yprime.cpp", "toolbox", Dependencies="setupCompiler");
plan("mex") = matlab.buildtool.Task(Dependencies=["mex_convec", "mex_yprime"], ...
    Description="Compile all mex files");


%% Setup the MinGW compiler
%   Ad hoc task, task action defined in setupCompilerTask local function
plan("setupCompiler").Inputs = "buildutils/installMinGW.m";


%% Setup test, example test, and integration test tasks
plan("test") = TestTask("tests", ...
    SourceFiles=["code", "pcode", "mex"], ...
    TestResults="results/test-results.html", ...
    Dependencies="mex", ...
    Description="Run the unit tests.") ...
    .addCodeCoverage("results/coverage/index.html", MetricLevel="mcdc");


%% P-code sensitive code and grab the M1 help to ship with the p-code files
pcodeTask = PcodeTask("pcode","toolbox");
pcodeTask.Inputs = "pcode/**/*.m";
pcodeTask.Outputs = pcodeTask.Inputs.replace(textBoundary("start") + "pcode", "toolbox");
pcodeTask.Actions = [@extractHelp pcodeTask.Actions]; % Add an action to extract help
plan("pcode") = pcodeTask;


%% Generate doc from mlx examples and getting started file
%   Ad hoc task, task action defined in docTask local function
plan("doc").Inputs = ["code/**/*.mlx", "pcode", "mex", "code"];
plan("doc").Outputs = plan("doc").Inputs(1) ...
    .replace(textBoundary("start") + "code","toolbox") ...
    .replace(".mlx" + textBoundary("end"),".html");


%% Move static src files to toolbox for distribution
%   Ad hoc task, task action defined in moveSrcTask local function
plan("moveSrc").Inputs = "code/**/*";
plan("moveSrc").Inputs = plan("moveSrc").Inputs.select(@(p) ~isfolder(p));
plan("moveSrc").Outputs = plan("moveSrc").Inputs.replace(...
    textBoundary("start")+"code","toolbox");


%% Build an mltbx toolbox
%   Ad hoc task, task action defined in toolboxTask local function
plan("toolbox").Dependencies = ["lint","test", "doc", "pcode","moveSrc"];
plan("toolbox").Inputs = ["pcode", "mex", "code", "toolbox"];
plan("toolbox").Outputs = "release/Mass-Spring-Damper.mltbx";


%% Integration tests for toolbox packaging (ensure toolbox works as a mltbx)
plan("tbxIntegTest") = TestTask("integTests/toolboxPackaging",SourceFiles="toolbox", ...
    Description="Run integration tests against packaged toolbox");
plan("tbxIntegTest").Inputs = [plan("toolbox").Outputs, "integTests/toolboxPackaging"];


%% Create the release task - does nothing but depends on other tasks
plan("release") = matlab.buildtool.Task(Dependencies="tbxIntegTest", ...
    Description="Produce a fully qualified toolbox for release");


%% Build a MATLAB Production Server archive
%   Ad hoc task, task action defined in toolboxTask local function
plan("ctf").Dependencies = ["lint","test"];
plan("ctf").Inputs = ["code", "pcode", "buildutils/simulateSystemFunctionSignatures.json"];
plan("ctf").Outputs = [...
    "results/ctf-archive/MassSpringDamperService.ctf", ...
    "results/ctf-build-results.mat", ...
    "results/ctf-archive"];


%% Integration tests - back-to-back equivalence tests for the production server archive
plan("ctfIntegTest") = TestTask("integTests/equivalence",SourceFiles=["code","pcode"], ...
    Description="Run integration tests against CTF archive.");
plan("ctfIntegTest").Inputs = [plan("ctf").Outputs, "integTests/equivalence"];


%% Create the deploy task - does nothing but depends on other tasks
plan("deploy") = matlab.buildtool.Task(Dependencies="ctfIntegTest", ...
    Description="Produce and test a ctf archive to deploy to a MATLAB Production Server");


%% Produce HTML from workshop live scripts to publish to GitHub pages
plan("workshop").Inputs = "workshop/**/*.mlx";
plan("workshop").Outputs = plan("workshop").Inputs. ...
    replace(".mlx",".html"). ...
    replace(textBoundary("start") + "workshop", "results");


end


%% The "doc" task action
function docTask(context)
% Generate doc pages from scripts and examples

mlxFiles = context.Task.Inputs(1).paths;
exportedFiles = context.Task.Outputs.paths;
for idx = 1:numel(mlxFiles)
    disp("Exporting " + mlxFiles(idx) + " to html");
    makeFolder(fileparts(exportedFiles(idx)));
    export(mlxFiles(idx), exportedFiles(idx), Run=true);
end
end


%% The "moveSrc" task action
function moveSrcTask(context)
% Move static source to shipping toolbox folder

inputFiles = context.Task.Inputs.paths;
outputFiles = context.Task.Outputs.paths;

for idx=1:numel(inputFiles)
    fprintf("Copying ""%s"" to ""%s"".\n", inputFiles(idx), outputFiles(idx));
    makeFolder(fileparts(outputFiles(idx)));
    copyfile(inputFiles(idx), outputFiles(idx), "f");
end
end


%% The "toolbox" task action
function toolboxTask(context,version)
% Create an mltbx toolbox package

arguments
    context
    version string = "2.3.13." + string(posixtime(datetime('now')) * 1e6);
end

outputFile = context.Task.Outputs.paths;
disp("Packaging toolbox: " + outputFile);
makeFolder(fileparts(outputFile));

% Create the toolbox packaging options
opts = matlab.addons.toolbox.ToolboxOptions("toolbox", "mathworks--Mass-Spring-Damper-Example",...
    ToolboxName="Mass Spring Damper",...
    ToolboxVersion=version, ...
    OutputFile=outputFile, ...
    ToolboxGettingStartedGuide="toolbox/gettingStarted.mlx" );

% Package the toolbox
matlab.addons.toolbox.packageToolbox(opts);

end


%% The "ctf" task action
function ctfTask(context)
% Create a deployable archive for MATLAB Production Server

ctfArchive = context.Task.Outputs(1).paths;
ctfBuildResults = context.Task.Outputs(2).paths;

% Create the archive options for the build.
[ctfFolder, ctfFile] = fileparts(ctfArchive);
opts = compiler.build.ProductionServerArchiveOptions(...
    ["code/simulateSystem.m", "pcode/springMassDamperDesign.m"], ...
    FunctionSignatures="buildutils/simulateSystemFunctionSignatures.json", ...
    OutputDir=ctfFolder, ...
    ArchiveName=ctfFile, ...
    ObfuscateArchive="on");

% Build the archive
buildResults = compiler.build.productionServerArchive(opts);

save(ctfBuildResults,"buildResults");
end


%% The "workshop" task action
function workshopTask(context)
% Generate html from the workshop mlx files

makeFolder("results");
mlxFiles = context.Task.Inputs.paths;
htmlFiles = context.Task.Outputs.paths;
for idx = 1:numel(mlxFiles)
    disp("Building html from " + mlxFiles(idx))
    export(mlxFiles(idx), htmlFiles(idx), Run=true);
end
end


%% The "setupCompiler" task action
function setupCompilerTask(~)
% Setup MEX compiler
try
    mex("-setup");
    disp("Compiler is detected and properly setup.")
catch
    disp("No compiler detected. Installing compiler.")
    if ispc
        installMinGW
    else
        error("Don't know how to install a compiler for this platform.");
    end
end
end


%% Utility functions
function makeFolder(folder)
% Creates a folder if it doesn't exist
fullFolder = fullfile(pwd, folder);
if exist(fullFolder,"dir")
    return
end
disp("Creating """ + folder + """ folder");
mkdir(fullFolder);
end

function extractHelp(context)
% Extract help text for p-coded m-files from original source

sourceMFiles = context.Task.Inputs.paths;
targetMFiles = context.Task.Outputs.paths;

for idx = 1:numel(sourceMFiles)
    disp("Extracting help text for: " + sourceMFiles(idx));
    helpText = "%" + split(help(sourceMFiles(idx)),newline);
    writelines(helpText,targetMFiles(idx));
    disp("Produced help file in: " + targetMFiles(idx));
end
end
