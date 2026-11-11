function f = ref2005_objective(x, ~)
%REF2005_OBJECTIVE Counting objective used by REF2005_RUN.
global REF2005 %#ok<GVMIS>
if REF2005.n >= REF2005.budget
    error('ref2005:budget', 'ref2005 budget reached');
end
f = REF2005.fun(x(:));
REF2005.n = REF2005.n + 1;
if f < REF2005.best
    REF2005.best = f;
end
end
