% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [expdata, feeddata] = DT_generatedata(process, sim_days, perf_rate, perf_start, rec_ratio, rec_start, media_name, brx_vol_mL)
% DT_GENERATEDATA Optimized generation bypassing headers.xlsx and feedcomp.xlsx
% Time output is formatted in DAYS. Flowrates are in L/day.

arguments
    process char
    sim_days (1,1) double
    perf_rate (1,1) double
    perf_start (1,1) double
    rec_ratio (1,1) double
    rec_start (1,1) double
    media_name char
    brx_vol_mL (1,1) double
end
    bleedrate = 0; % Bleed rate setting
%---- 1. Generate Event-Driven Time Vector (in Days) ----
sim_hours = sim_days * 24;
time_hours = [0; sim_hours];

if strcmp(process, 'perfusion') || strcmp(process, 'Spent Media Recycling')
    perf_start_hr = perf_start * 24;
    if perf_start_hr > 0, time_hours = [time_hours; perf_start_hr - 0.1; perf_start_hr]; end
end

if strcmp(process, 'Spent Media Recycling')
    rec_start_hr = rec_start * 24;
    if rec_start_hr > 0, time_hours = [time_hours; rec_start_hr - 0.1; rec_start_hr]; end
end

time_hours = unique(sort(time_hours));
time_hours = time_hours(time_hours >= 0 & time_hours <= sim_hours);
time_days = time_hours / 24;
num_pts = length(time_days);

%---- 2. Load and ONE-TIME Sanitize the Single Source of Truth ----
master_data = readtable('DATA_Simulation.xlsx', 'Sheet', 'Master_Data', 'PreserveVariableNames', true);

% Deep Clean the Master Table (Vectorized for maximum speed)
for col = 1:width(master_data)
    if isnumeric(master_data{:, col})
        % Clean pure numeric arrays
        data = master_data{:, col};
        data(isnan(data)) = 0;
        master_data{:, col} = data;

    elseif iscell(master_data{:, col})
        % Clean mixed cell arrays (text + numbers/blanks)
        data = master_data{:, col};
        nan_idx = cellfun(@(x) isnumeric(x) && any(isnan(x)), data);
        empty_idx = cellfun(@isempty, data);
        data(nan_idx | empty_idx) = {0}; % Instantly forces 0 into bad cells
        master_data{:, col} = data;
    end
end

var_names = master_data.VarName;

%---- 3. Construct Flowrates based on VVD Mass Balance ----
flow_feed = zeros(num_pts, 1);
flow_recycle = zeros(num_pts, 1);
flow_harvest = zeros(num_pts, 1);
flow_bleed = zeros(num_pts, 1);
T_val = zeros(num_pts, 1);

tol = 1e-4;

for k = 1:num_pts
    t_d = time_days(k);

    if (strcmp(process, 'perfusion') || strcmp(process, 'Spent Media Recycling')) && (t_d >= perf_start - tol)
        total_harvest_flow = perf_rate * brx_vol_mL/24;
        total_feed_flow = total_harvest_flow;

        if strcmp(process, 'Spent Media Recycling') && (t_d >= rec_start - tol)
            flow_harvest(k) = total_harvest_flow;
            flow_recycle(k) = total_feed_flow * rec_ratio;
            flow_feed(k)    = total_feed_flow - flow_recycle(k);
        else
            flow_recycle(k) = 0;
            flow_harvest(k) = total_harvest_flow;
            flow_feed(k)    = total_feed_flow;
        end
        flow_bleed(k) = bleedrate * brx_vol_mL/24;
    end
    if flow_feed(k) > 0, T_val(k) = 32; else, T_val(k) = 37; end
end

%---- 4. Populate expdata (Time Series set to DAYS) ----
expdata.time = time_hours;
expdata.Temp = DT_make_ts_without_nans(T_val, time_hours);

for i = 1:height(master_data)
    v_name = var_names{i};
    init_val = master_data.Init_BRX(i);

    % MATLAB indexing quirk: extract number if it's inside a 1x1 cell
    if iscell(init_val), init_val = init_val{1}; end

    val_array = zeros(num_pts, 1);
    val_array(1) = init_val;
    expdata.(v_name) = DT_make_ts_without_nans(val_array, time_hours);
end

% Map flow rates (ml/h)
expdata.q1 = DT_make_ts_without_nans(flow_feed,    time_hours);
expdata.q2 = DT_make_ts_without_nans(flow_harvest, time_hours);
expdata.q3 = DT_make_ts_without_nans(zeros(num_pts,1), time_hours);
expdata.q4 = DT_make_ts_without_nans(flow_bleed,   time_hours);
expdata.q5 = DT_make_ts_without_nans(zeros(num_pts,1), time_hours);
expdata.q6 = DT_make_ts_without_nans(zeros(num_pts,1), time_hours);
expdata.q7 = DT_make_ts_without_nans(flow_recycle, time_hours);

%---- 5. Populate feeddata (Arrays for Simulink Constants) ----
feeddata = struct();
feeddata.BRX = master_data.Init_BRX;

if ismember(media_name, master_data.Properties.VariableNames)
    feeddata.Feed1 = master_data.(media_name);
else
    error('Media Name "%s" not found in Master_Data sheet columns.', media_name);
end

if ismember('GlucoseFeed', master_data.Properties.VariableNames)
    feeddata.glucose = master_data.GlucoseFeed;
else
    feeddata.glucose = zeros(height(master_data), 1);
end

feeddata.Feed2 = zeros(height(master_data), 1);
feeddata.Feed3 = zeros(height(master_data), 1);
feeddata.galactose = zeros(height(master_data), 1);

%---- 6. Save constraints for Genome-Scale Model ----
constrain_exrxn = cell(height(master_data), 5);
constrain_exrxn(:,1) = master_data.GEMrnxEX1;
constrain_exrxn(:,2) = master_data.GEMrnxEX2;
constrain_exrxn(:,3) = master_data.GEMrnxEX3;

% Directly map constraints (Guaranteed clean from Step 2)
constrain_exrxn(:,4) = num2cell(master_data.constrain);
constrain_exrxn(:,5) = num2cell(master_data.fluxdata);

save('temp_constrain_exrxn.mat','constrain_exrxn');

end
