classdef MPSEquivalenceTest < matlabtest.compiler.TestCase

    methods(TestClassSetup)
        function filterOnMac(testCase)
            testCase.assumeReturnsTrue(@() ~ismac, ...
                "MPS equivalence tests not supported on the mac");
        end
    end

    properties(TestParameter)
        
        resultsFile = {getBuildResultsFile};
        
        % Can define different runtime inputs for the equivalence test
        damping = struct(...
            "OverDamped", 5e5, ...
            "UnderDamped", 1e4, ...
            "CriticallyDamped", 5.477225575051661e4)
    end
    

    methods (Test)
        function mpsShouldBeEquivalentForDamping(testCase, resultsFile, damping)
            % Validate that MPS execution is equivalent to MATLAB for
            % various damping coefficient designs
            
            % Load the results built in a prior build step
            disp("Load the build results from the ""ctf"" task")
            loadedData = load(resultsFile);
            buildResults = loadedData.buildResults;

            % Execute the runtime inputs (damping) on the server
            disp("Executing design on a local Production Server")
            design.k = 5e5;
            design.c = damping;
            executionResults = testCase.execute(buildResults,{design},"simulateSystem");
            
            % Verify server execution is equivalent to the local results
            disp("Verifying results match MATLAB results")
            testCase.verifyExecutionMatchesMATLAB(executionResults);

        end
    end
end

function resultsFile = getBuildResultsFile
prj = currentProject;
resultsFile = fullfile(prj.RootFolder,...
    "results", computer("arch"), "ctf-build-results.mat");
end