function viewPipeline(plan, varargin)

tg = matlab.buildtool.TaskGraph.fromPlan(plan, varargin{:});
oldState = warning("off","MATLAB:structOnObject");
cleaner = onCleanup(@() warning(oldState));
stg = struct(tg);
g = stg.Digraph;
plot(flipedge(g),"ArrowSize",10,NodeFontSize=10,LineWidth=6,MarkerSize=10, ...
    Layout="layered",Direction="right",Interpreter="none");