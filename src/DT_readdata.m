% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [expdata,feeddata] = DT_readdata(selecteddata,Media)
%This function loads the experimental data from the generalized formatted data file
% Input:
% rawdata is a table containing the data of the selected experiment with entries defined in headers.xlsx
% Media is a structure containing the media information, including Feed1, Feed2, Feed3, glucose and galactose if applicable
% Output:
% expdata is a structure containing the experimental measurements
% feeddata is a structure containing the feed composition, including 5 feed (Feed1, Feed2, Feed3, glucose and galactose)
% Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
arguments
    selecteddata
    Media
end
%----Load headers----
headerstable = DT_input_schema();
header_list = headerstable.Header;
var_names = headerstable.name;
%----Load experimental data----
data_headers = selecteddata.Properties.VariableNames;
%----Defult temperature data----
T = [37 32]'; % Temperature shift from 37C to 32C
Ttime = [0 120]'; %Temperature shift at time = 120 hour (~DAY5)

% timeseries data time conversion from days to hours
expdata.time = selecteddata.day * 24;
noflow = DT_make_ts_without_nans(zeros(numel(expdata.time),1), expdata.time);
for i = 1:numel(data_headers)
    if ismember(data_headers(i),header_list)
        expdata.(var_names{i}) = DT_make_ts_without_nans(selecteddata.(data_headers{i}), expdata.time);
    else
        expdata.(var_names{i}) = noflow;
    end
end
% pump flowrate unit convert L/day to ml/h
expdata.q1.Var1 = expdata.q1.Var1*1000/24;
expdata.q2.Var1 = expdata.q2.Var1*1000/24;
expdata.q3.Var1 = expdata.q3.Var1*1000/24;
expdata.q4.Var1 = expdata.q4.Var1*1000/24;
expdata.q5.Var1 = expdata.q5.Var1*1000/24;
expdata.q6.Var1 = expdata.q6.Var1*1000/24;
expdata.q7.Var1 = expdata.q7.Var1*1000/24;
%----Load Media data----
Feedlist = fieldnames(Media);
fullfeedlist = ["Feed1","Feed2","Feed3","glucose","galactose"];
feedfile =  '../Data/feedcomp.xlsx';
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
feedcomptable = readtable(feedfile);
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
feeddata = struct();
feedcomp_list = feedcomptable.comp;
feedcomp_names = feedcomptable.name;
nofeed = struct();
for i = 1:numel(feedcomp_list)
    nofeed.(feedcomp_names{i}) = 0;
end
for i = 1:numel(fullfeedlist)
  if ismember(fullfeedlist{i},Feedlist)
    thisfeedcomp = Media.(fullfeedlist{i}).Properties.VariableNames;
    thisfeed = struct();
    for j = 1:numel(feedcomp_list)
      if ismember(feedcomp_list{j},thisfeedcomp)
        thisfeed.(feedcomp_names{j}) = Media.(fullfeedlist{i}).(feedcomp_list{j});
        if isnan(thisfeed.(feedcomp_names{j}))
          thisfeed.(feedcomp_names{j}) = 0;
        end
      else
        thisfeed.(feedcomp_names{j}) = 0;
      end
    end
    feeddata.(fullfeedlist{i})=thisfeed;
  else
    feeddata.(fullfeedlist{i}) = nofeed;
  end
end
feedcomparray = zeros(numel(feedcomp_list),1);
feeddata.BRX = feedcomparray;
for i = 1:numel(feedcomparray)
    feeddata.BRX(i) = expdata.(feedcomp_names{i}).Var1(1);
end
for i = 1:numel(fullfeedlist)
    thisarray = feedcomparray;
    thisfeed = feeddata.(fullfeedlist{i});
    for j = 1:numel(feedcomparray)
      thisarray(j) = thisfeed.(feedcomp_names{j});
    end
    feeddata.(fullfeedlist{i}) = thisarray;
    if sum(thisarray) == 0
        feeddata.(fullfeedlist{i}) = feeddata.BRX;
        feeddata.(fullfeedlist{i})(1) = 0;
    end
end

expdata.Temp = DT_make_ts_without_nans(T,Ttime);
constrain_exrxn(:,1) = feedcomptable.GEMrnxEX1;
constrain_exrxn(:,2) = feedcomptable.GEMrnxEX2;
constrain_exrxn(:,3) = feedcomptable.GEMrnxEX3;
constrain_exrxn(:,4) = num2cell(feedcomptable.constrain);
constrain_exrxn(:,5) = num2cell(feedcomptable.fluxdata);
save('temp_constrain_exrxn.mat','constrain_exrxn');
end
