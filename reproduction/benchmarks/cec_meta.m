function M = cec_meta(year)
%CEC_META Metadata for the IEEE CEC test suites (centralized in one place).
%
%   M = cec_meta(year)   with year in {2013, 2014, 2015, 2017, 2020, 2022}
%
%   Returns a struct M with:
%     M.year      : suite year
%     M.func_name : name of the MEX entry point (e.g. 'cec17_func')
%     M.nFunc     : number of functions in the suite
%     M.funcs     : list of valid function numbers
%     M.validDims : dimensions supported by the shift/rotation data
%     M.fstar     : vector of optima f* per function; error = f - fstar
%     M.runs      : number of runs in the competition protocol
%     M.lb, M.ub  : bounds (all CEC suites use [-100, 100])
%
%   NOTE: f* differs between years. CEC2013 uses the bias sequence
%   -1400..+1400 (NOT 100*i); CEC2014/2015/2017 use f* = 100*i.

    M.year = year; M.lb = -100; M.ub = 100;
    switch year
        case 2013
            M.func_name = 'cec13_func';
            M.nFunc = 28; M.funcs = 1:28;
            M.validDims = [2 5 10 20 30 40 50 60 70 80 90 100];
            M.fstar = [(-1500 + 100*(1:14)), (100*(15:28) - 1400)];
            M.runs = 51;
        case 2014
            M.func_name = 'cec14_func';
            M.nFunc = 30; M.funcs = 1:30;
            M.validDims = [2 10 20 30 50 100];
            M.fstar = 100*(1:30);
            M.runs = 51;
        case 2015
            M.func_name = 'cec15_func';
            M.nFunc = 15; M.funcs = 1:15;
            M.validDims = [2 10 30 50 100];
            M.fstar = 100*(1:15);
            M.runs = 51;
        case 2017
            M.func_name = 'cec17_func';
            % F2 was withdrawn by the organizers -> 29 functions [1 3:30]
            M.nFunc = 30; M.funcs = [1 3:30];
            M.validDims = [2 10 30 50 100];
            M.fstar = 100*(1:30);
            M.runs = 51;
        case 2020
            M.func_name = 'cec20_func';
            M.nFunc = 10; M.funcs = 1:10;
            M.validDims = [2 5 10 15 20];   % this MEX defines D <= 20 only
            M.fstar = [100 1100 700 1900 1700 1600 2100 2200 2400 2500];
            M.runs = 30;
        case 2022
            M.func_name = 'cec22_test_func';
            M.nFunc = 12; M.funcs = 1:12;
            M.validDims = [2 10 20];
            M.fstar = [300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
            M.runs = 30;
        otherwise
            error('cec_meta:unsupportedYear', 'Unsupported CEC year: %d', year);
    end
end
