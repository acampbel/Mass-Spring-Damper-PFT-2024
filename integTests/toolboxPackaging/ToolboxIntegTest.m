classdef ToolboxIntegTest < matlab.unittest.TestCase

    methods(TestClassSetup)
        function unloadProjectAndInstallToolbox(testCase)
            import matlab.addons.toolbox.*;
            import matlab.unittest.fixtures.*;

            testCase.applyFixture(SuppressedWarningsFixture('toolboxmanagement_matlab_api:uninstallToolbox:manualCleanupNeeded'));


            prj = currentProject;
            prjRoot = prj.RootFolder;
            testCase.addTeardown(@reload, prj);
            close(prj);
      
            tbx = installToolbox(prjRoot + "/release/Mass-Spring-Damper.mltbx");
            testCase.addTeardown(@uninstallToolbox, tbx);
        end
    end

    methods(Test)
        function smokeTest(~)
            simulateSystem(springMassDamperDesign("criticallydamped", 10));
        end

        function smokeConvec(~)
            convec(3+i,4-i);
        end

        function smokeYprime(testCase)
            testCase.assumeReturnsTrue(@() ispc || ismac, ...
                "GLIBC problem prevents running on Linux");
            yprime(1,1:4);
        end

    end

end
       

            




