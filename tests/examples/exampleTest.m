classdef exampleTest < matlab.unittest.TestCase

    properties(TestParameter)
        example = {"gettingStarted", "BuildPlanDetails"}
    end

    methods(TestClassSetup)
        function suppressOpenGLWarning(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture("MATLAB:hg:AutoSoftwareOpenGL"));
        end
    end

    methods(Test)
        function exampleRunsWithoutWarningTest(testCase, example)

            fig = figure;
            testCase.addTeardown(@close, fig);

            testCase.verifyWarningFree(@() runDocExample(example));
        end
    end
end
function runDocExample(example) %#ok<INUSD> Run via evalc
[log, ex] = evalc("runAndCaptureOutputEvenWithErrors(example)");
if ~isempty(ex)
    fprintf("%s",log);
    rethrow(ex);
end

end

function ex = runAndCaptureOutputEvenWithErrors(example)
ex = MException.empty;
try
    feval(example);
catch ex
end
end

