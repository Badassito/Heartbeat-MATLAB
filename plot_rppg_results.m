% Ground truth mean BPM, Ground truth STD, Estimated mean BPM, Estimated STD
% Each row is one 30-second segment

video_data = {
    % Video 1
    [81.778, 1.595, 69.4036, 19.3596;
77.5408, 1.4408, 75.2532, 23.1843;
74.4641, 0.4545, 51.3697, 12.9255;
77.075, 1.3364, 63.7585, 26.3204;
78.7979, 0.6137, 65.5978, 24.4458;
81.2022, 0.6877, 61.2194, 20.3038;
80.6769, 0.9281, 81.414, 21.7895;
81.4158, 1.0897, 64.6906, 12.9136;
81.5046, 1.0309, 67.2911, 13.6168;
80.5815, 0.2316, 83.7077, 24.5624;
],
    
    % Video 2
    [140.0132, 5.0255, 73.2926, 18.3934;
116.8307, 5.4908, 66.7929, 16.2865;
100.5751, 8.2145, 55.7657, 11.3948;
83.4109, 1.0813, 73.7149, 13.5316;
83.1647, 1.07856, 69.091, 20.3512;
86.4311, 0.6159, 72.2115, 15.1595;
75.5725, 5.3291, 60.2406, 20.8287;
65.2718, 2.2, 98.4048, 23.9659;
],
    
    % Video 3
    [72.5328, 3.0809, 65.1391, 17.0447;
74.0385, 1.5165, 53.0527, 12.8296;
76.75, 1.3024, 78.1605, 13.1832;
82.798, 0.8942, 65.8506, 24.4594;
83.4759, 0.2408, 66.099, 25.4239;
82.6387, 0.4521, 87.3411, 29.0746;
84.4497, 0.6461, 67.0047, 26.6615;
85.5594, 1.2861, 73.1115, 16.9521;
],

    % Video 4
    [89.3468, 3.7204, 68.5723, 1.2679;
75.3414, 3.4685, 69.1319, 8.589;
76.5295, 1.8002, 60.2669, 24.5268;
87.6961, 2.2962, 56.4801, 11.1615;
75.4328, 4.9152, 64.2567, 12.0099;
75.1042, 1.3504, 68.7754, 4.6993;
75.4637, 2.3083, 66.6775, 12.5919;
69.6898, 1.5488, 70.5607, 3.0384;
67.9224, 1.0637, 70.9712, 2.5201;
69.6397, 0.6774, 70.2699, 7.8135;
69.7434, 0.2199, 69.8711, 1.2757;
]
    % Video 5
    [90.872, 5.353, 93.5311, 27.3777;
77.0481, 1.769, 87.0416, 24.7846;
96.4364, 9.0554, 91.6158, 27.4829;
114.7808, 1.2205, 55.1682, 16.0618;
111.9635, 1.1049, 90.3784, 20.7285;
110.9446, 0.1716, 60.9155, 10.2303;
111.2617, 0.2704, 81.2037, 14.1445;
110.5892, 0.2457, 56.0374, 12.029;
110.555, 0.4527, 80.986, 34.8849;
111.2774, 0.3757, 56.2478, 11.8896;
]
    % Video 6
    [90.0732, 3.6906, 57.6532, 12.2437;
88.6246, 1.7877, 58.6993, 12.4482;
88.9598, 0.9969, 62.8527, 13.2858;
86.0076, 4.8145, 53.5611, 11.8593;
87.4311, 5.4665, 59.6781, 19.4398;
91.2768, 0.8128, 59.7511, 23.4077;
87.966, 1.1121, 70.7126, 20.3836;
86.4527, 0.5051, 79.6039, 25.2356;
88.8367, 0.6009, 56.5181, 13.0925;
86.0873, 1.0359, 60.4261, 22.5134;
85.6268, 0.591, 91.3616, 28.3307;
]
};
video_names = {'Subject 002 Trial 003', 'Subject 003 Trial 001', 'Subject 003 Trial 002', 'Subject 004 Trial 001', 'Subject 005 Trial 001', 'Subject 006 Trial 001'}; % Replace with actual IDs

num_videos = length(video_data);
cols = 3;
rows = 2;

figure('Position', [100, 100, 1200, 600]);

for v = 1:num_videos
    data = video_data{v};
    num_segments = size(data, 1);
    x = 1:num_segments;
    
    gt_mean = data(:, 1);
    gt_std = data(:, 2);
    est_mean = data(:, 3);
    est_std = data(:, 4);
    
    subplot(rows, cols, v);
    hold on;
    
    % Shaded error regions
    fill([x, fliplr(x)], ...
         [gt_mean' + gt_std', fliplr(gt_mean' - gt_std')], ...
         [0.2, 0.6, 0.2], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    fill([x, fliplr(x)], ...
         [est_mean' + est_std', fliplr(est_mean' - est_std')], ...
         [0.2, 0.2, 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    % Mean lines
    plot(x, gt_mean, '-o', 'Color', [0.2, 0.6, 0.2], 'LineWidth', 1.5, ...
         'MarkerFaceColor', [0.2, 0.6, 0.2], 'MarkerSize', 5);
    plot(x, est_mean, '-s', 'Color', [0.2, 0.2, 0.8], 'LineWidth', 1.5, ...
         'MarkerFaceColor', [0.2, 0.2, 0.8], 'MarkerSize', 5);
    
    hold off;
    
    xlabel('Segment');
    ylabel('Heart Rate (BPM)');
    title(video_names{v});
    xlim([0.5, num_segments + 0.5]);
    grid on;
    
    if v == 1
        legend('Ground Truth ±1 STD', 'Estimated ±1 STD', ...
               'Ground Truth Mean', 'Estimated Mean', ...
               'Location', 'best');
    end
end

sgtitle('rPPG Heart Rate Estimation vs Ground Truth');

% ============================================================
% SUMMARY STATISTICS
% ============================================================
all_gt = [];
all_est = [];
for v = 1:num_videos
    all_gt = [all_gt; video_data{v}(:, 1)];
    all_est = [all_est; video_data{v}(:, 3)];
end

errors = all_est - all_gt;
abs_errors = abs(errors);

fprintf('\n=== Summary Statistics ===\n');
fprintf('Total segments analyzed: %d\n', length(all_gt));
fprintf('Mean Absolute Error: %.2f BPM\n', mean(abs_errors));
fprintf('RMSE: %.2f BPM\n', sqrt(mean(errors.^2)));
fprintf('Mean Bias: %.2f BPM\n', mean(errors));
fprintf('Within ±5 BPM: %.1f%%\n', 100 * sum(abs_errors <= 5) / length(abs_errors));
fprintf('Within ±10 BPM: %.1f%%\n', 100 * sum(abs_errors <= 10) / length(abs_errors));