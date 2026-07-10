function f = cec_eval(X, func_num, year)
%CEC_EVAL Dispatch to the compiled MEX of an IEEE CEC test suite.
%
%   f = cec_eval(X, func_num, year)
%
%   Inputs:
%     X        : D x N matrix (each COLUMN is one individual) — the native
%                convention of the CEC MEX files
%     func_num : function number within the suite
%     year     : 2013 / 2014 / 2015 / 2017 / 2020 / 2022
%   Output:
%     f        : 1 x N RAW function values (f* not subtracted).
%                Error = f - fstar(func_num); see CEC_META.
%
%   Environment (handled by runVariantOnCEC): the folder CEC<year>/ holding
%   the compiled MEX must be on the path, and the current directory must
%   contain 'input_data/', because the MEX loads its shift/rotation data
%   through relative paths. This function is kept thin on purpose so that it
%   does not pay a cd() on every call.

    switch year
        case 2013, f = cec13_func(X, func_num);
        case 2014, f = cec14_func(X, func_num);
        case 2015, f = cec15_func(X, func_num);
        case 2017, f = cec17_func(X, func_num);
        case 2020, f = cec20_func(X, func_num);
        case 2022, f = cec22_test_func(X, func_num);
        otherwise, error('cec_eval:unsupportedYear', 'Unsupported CEC year: %d', year);
    end
    f = reshape(f, 1, []);     % ensure 1 x N
end
