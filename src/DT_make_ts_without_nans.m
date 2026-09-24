% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function ts = DT_make_ts_without_nans(values, times)
% This function makes a timetable without nans
% Inputs:
% values: a vector of values
% times: a vector of times
% Outputs:
% ts: a timetable with no nans
% Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025

arguments
    values
    times
end

    whereok = ~isnan(values);
    ts = timetable(values(whereok), RowTimes=seconds(times(whereok)));
    if isempty(ts)
       ts = timetable(0, RowTimes=seconds(0));
    end

end
