% rPPG heart rate detection with Haar cascade face detection
% heartbeat('video.mp4')

function heartbeat(input)
    close all;
    % Configuration
    LOW_BPM = 50;
    HIGH_BPM = 180;
    WINDOW_SIZE = 300;
    vid = VideoReader(input);
    fps = vid.FrameRate;
    faceDetector = vision.CascadeObjectDetector('FrontalFaceCART');
    
    % Initialize signal buffer
    signal = [];
    frameCount = 0;
    bpm_history = [];

    % Initialize frame tracking for analysis
    frame_data = struct('frameNum', {}, 'frame', {}, 'face', {}, 'roi', {}, 'bpm', {}, 'display_bpm', {}, 'powerSpectrum', {}, 'freqs', {}, 'numPeaks', {}, 'peakDelta', {});

    % Main processing loop
    while hasFrame(vid)
        frame = readFrame(vid);
        
        frameCount = frameCount + 1;
        
        % Detect face
        bboxes = step(faceDetector, frame);
        if ~isempty(bboxes)
            face = bboxes(1, :);
        else
            face = [];  % or handle the no-face case
        end
        
        % Define ROI (forehead region)
        roi_x = round(face(1) + 0.3 * face(3));
        roi_y = round(face(2) + 0.1 * face(4));
        roi_w = round(0.4 * face(3));
        roi_h = round(0.15 * face(4));
        
        if roi_w > 0 && roi_h > 0
            roi = frame(roi_y:roi_y+roi_h-1, roi_x:roi_x+roi_w-1, :); % Extract ROI
            green_value = mean(roi(:, :, 2), 'all'); % Extract mean green channel value (rPPG signal)
            signal = [signal; green_value]; % Add to signal buffer
            
            % Limit buffer size
            if length(signal) > WINDOW_SIZE
                signal = signal(end-WINDOW_SIZE+1:end);
            end
            
            % Estimate heart rate
            bpm = 0;
            powerSpectrum = [];
            freqs = [];
            numPeaks = 0;
            peakDelta = 0;

            if length(signal) >= WINDOW_SIZE
                [bpm, powerSpectrum, freqs] = estimateHeartRate(signal, fps, LOW_BPM, HIGH_BPM);

                % Analyze power spectrum peaks in valid BPM range
                if ~isempty(powerSpectrum) && ~isempty(freqs)
                    [numPeaks, peakDelta] = analyzePowerSpectrum(powerSpectrum, freqs, LOW_BPM, HIGH_BPM);
                end

                if bpm > 0
                    bpm_history = [bpm_history; bpm];
                    if length(bpm_history) > 10
                        bpm_history = bpm_history(end-9:end);
                    end
                end
            end

            % Calculate smoothed BPM
            display_bpm = 0;
            if ~isempty(bpm_history)
                display_bpm = median(bpm_history(max(1, end-4):end));
            end

            % Store frame data for analysis
            if ~isempty(powerSpectrum)
                frame_data(end+1).frameNum = frameCount;
                frame_data(end).frame = frame;
                frame_data(end).face = face;
                frame_data(end).roi = [roi_x, roi_y, roi_w, roi_h];
                frame_data(end).bpm = bpm;
                frame_data(end).display_bpm = display_bpm;
                frame_data(end).powerSpectrum = powerSpectrum;
                frame_data(end).freqs = freqs;
                frame_data(end).numPeaks = numPeaks;
                frame_data(end).peakDelta = peakDelta;
            end

            displayResults(frame, face, [roi_x, roi_y, roi_w, roi_h], display_bpm, signal, powerSpectrum, freqs, bpm, LOW_BPM, HIGH_BPM, frameCount);
        end
        
        drawnow;
    end

    % Post-processing: Select best frame and save results
    if ~isempty(frame_data)
        fprintf('\n=== Video Processing Complete ===\n');
        fprintf('Total frames analyzed: %d\n', length(frame_data));

        % Extract BPM values for statistics
        all_bpm = [frame_data.bpm];
        avg_bpm = mean(all_bpm(all_bpm > 0));
        std_bpm = std(all_bpm(all_bpm > 0));

        fprintf('Average BPM: %.2f\n', avg_bpm);
        fprintf('Standard Deviation: %.2f\n', std_bpm);

        % Find frame with maximum delta between biggest and second-biggest peaks
        [max_delta, max_idx] = max([frame_data.peakDelta]);
        selected_frame = frame_data(max_idx);
        selection_reason = sprintf('Frame with maximum delta between peaks: %.4f (frame %d)', max_delta, selected_frame.frameNum);
        fprintf('\nNo frames with exactly 1 peak found.\n%s\n', selection_reason);

        % Save results
        saveResults(selected_frame, selection_reason, avg_bpm, std_bpm, all_bpm, LOW_BPM, HIGH_BPM, input);
    else
        fprintf('\nNo frames were processed successfully.\n');
    end
end

function displayResults(frame, face, roi, display_bpm, signal, powerSpectrum, freqs, bpm, low_bpm, high_bpm, frameCount)
    % Display video with overlays
    subplot(3, 1, 1);
    imshow(frame);
    hold on;
    
    % Draw stuff
    rectangle('Position', face, 'EdgeColor', 'b', 'LineWidth', 2); % face box
    rectangle('Position', roi, 'EdgeColor', 'g', 'LineWidth', 2); % Draw ROI
    text(10, 30, sprintf('Heart Rate: %.1f BPM', display_bpm), 'Color', 'green', 'FontSize', 16, 'FontWeight', 'bold', 'BackgroundColor', 'black'); % Display BPM
    text(10, 70, sprintf('Frame: %d', frameCount), 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black'); % Frame counter
    
    hold off;
    
    % Signal plot
    subplot(3, 1, 2);
    if length(signal) > 1
        plot(signal, 'g', 'LineWidth', 2);
        title('rPPG Green Channel Signal');
        xlabel('Frame');
        ylabel('Intensity');
        grid on;
        xlim([0, length(signal)]);
    end
    
    % Power spectrum
    subplot(3, 1, 3);
    if ~isempty(powerSpectrum) && ~isempty(freqs)
        plot(freqs, powerSpectrum, 'b', 'LineWidth', 1.5);
        hold on;

        peak_idx = find(abs(freqs - bpm) < 0.5, 1);
        if ~isempty(peak_idx)
            plot(bpm, powerSpectrum(peak_idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        end
        hold off;
        title('Frequency Spectrum (FFT)');
        xlabel('Heart Rate (BPM)');
        ylabel('Power');
        xlim([low_bpm-10, high_bpm+10]);
        grid on;
    end
end

function [bpm, powerSpectrum, freqs] = estimateHeartRate(signal, fps, low_bpm, high_bpm) % Heart rate estimation using FFT

    % 1. Detrend
    signal_detrend = detrend(signal);

    % 3. Bandpass filter
    low_hz = low_bpm / 60;
    high_hz = high_bpm / 60;
    [b, a] = cheby2(4, 40, [low_hz, high_hz] / (fps/2), 'bandpass');
    signal_filtered = filtfilt(b, a, signal_detrend);

    % 4. Apply Hamming window
    hamming_window = hamming(length(signal_filtered));
    signal_windowed = signal_filtered .* hamming_window;

    % 5. FFT with zero-padding
    nfft = 2^nextpow2(length(signal_windowed) * 4);
    Y = fft(signal_windowed, nfft);
    L = length(signal_windowed);

    % 6. Power spectrum
    P2 = abs(Y/L);
    P1 = P2(1:floor(nfft/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);

    % 7. Frequency vector in BPM
    f = fps * (0:floor(nfft/2)) / nfft;
    bpm_values = f * 60;

    % 8. Find peak in valid range
    valid_idx = (bpm_values >= low_bpm) & (bpm_values <= high_bpm);

    powerSpectrum = P1;
    freqs = bpm_values;

    if sum(valid_idx) > 0
        valid_power = P1(valid_idx);
        valid_bpm = bpm_values(valid_idx);

        [~, max_idx] = max(valid_power);
        bpm = valid_bpm(max_idx);
    else
        bpm = 0;
    end
end

function [numPeaks, peakDelta] = analyzePowerSpectrum(powerSpectrum, freqs, low_bpm, high_bpm)
    % Analyze power spectrum in the valid BPM range
    % Returns: number of peaks (local maxima) and delta between top 2 peaks

    % Extract valid range
    valid_idx = (freqs >= low_bpm) & (freqs <= high_bpm);
    valid_power = powerSpectrum(valid_idx);

    if length(valid_power) < 3
        numPeaks = 0;
        peakDelta = 0;
        return;
    end

    % Find local maxima (peaks where derivative changes from + to -)
    % A peak is where slope goes from positive to negative
    derivative = diff(valid_power);

    % Find zero crossings in derivative (sign changes from + to -)
    % This indicates local maxima
    sign_changes = derivative(1:end-1) > 0 & derivative(2:end) < 0;
    peak_indices = find(sign_changes) + 1; % +1 because diff shifts indices

    numPeaks = length(peak_indices);

    % Calculate delta between biggest and second-biggest peaks
    if numPeaks >= 2
        peak_values = valid_power(peak_indices);
        sorted_peaks = sort(peak_values, 'descend');
        peakDelta = sorted_peaks(1) - sorted_peaks(2);
    elseif numPeaks == 1
        % Only one peak, delta is the peak value itself
        peakDelta = valid_power(peak_indices(1));
    else
        % No peaks found, use max value
        peakDelta = max(valid_power);
    end
end

function saveResults(selected_frame, selection_reason, avg_bpm, std_bpm, all_bpm, low_bpm, high_bpm, video_filename)
    % Save selected frame, figure, and analysis results

    % Create output directory with timestamp
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    [~, video_name, ~] = fileparts(video_filename);
    output_dir = sprintf('heartbeat_analysis_%s_%s', video_name, timestamp);
    mkdir(output_dir);

    fprintf('\nSaving results to: %s\n', output_dir);

    % 1. Save the frame image
    frame_filename = fullfile(output_dir, 'selected_frame.png');
    imwrite(selected_frame.frame, frame_filename);
    fprintf('Saved frame image: %s\n', frame_filename);

    % 2. Save the figure/graph
    fig_save = figure('Name', 'Selected Frame Analysis', 'Position', [100, 100, 900, 900], 'Visible', 'off');

    % Top: Frame with overlays
    subplot(3, 1, 1);
    imshow(selected_frame.frame);
    hold on;
    rectangle('Position', selected_frame.face, 'EdgeColor', 'b', 'LineWidth', 2);
    rectangle('Position', selected_frame.roi, 'EdgeColor', 'g', 'LineWidth', 2);
    text(10, 30, sprintf('Heart Rate: %.1f BPM', selected_frame.display_bpm), ...
         'Color', 'green', 'FontSize', 16, 'FontWeight', 'bold', 'BackgroundColor', 'black');
    text(10, 70, sprintf('Frame: %d', selected_frame.frameNum), ...
         'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    title('Selected Frame');
    hold off;

    % Middle: BPM over time
    subplot(3, 1, 2);
    plot(all_bpm, 'b-', 'LineWidth', 1.5);
    hold on;
    yline(avg_bpm, 'r--', 'LineWidth', 2);
    yline(avg_bpm + std_bpm, 'r:', 'LineWidth', 1);
    yline(avg_bpm - std_bpm, 'r:', 'LineWidth', 1);
    hold off;
    title(sprintf('BPM Over Time (Mean: %.1f, StdDev: %.1f)', avg_bpm, std_bpm));
    xlabel('Frame Index');
    ylabel('BPM');
    legend('BPM', 'Mean', '+/- Std Dev', 'Location', 'best');
    grid on;

    % Bottom: Power spectrum of selected frame
    subplot(3, 1, 3);
    plot(selected_frame.freqs, selected_frame.powerSpectrum, 'b', 'LineWidth', 1.5);
    hold on;
    peak_idx = find(abs(selected_frame.freqs - selected_frame.bpm) < 0.5, 1);
    if ~isempty(peak_idx)
        plot(selected_frame.bpm, selected_frame.powerSpectrum(peak_idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    end
    hold off;
    title(sprintf('Power Spectrum (Peaks: %d, Peak Delta: %.4f)', selected_frame.numPeaks, selected_frame.peakDelta));
    xlabel('Heart Rate (BPM)');
    ylabel('Power');
    xlim([low_bpm-10, high_bpm+10]);
    grid on;

    % Save figure
    figure_filename = fullfile(output_dir, 'analysis_figure.png');
    saveas(fig_save, figure_filename);
    fprintf('Saved analysis figure: %s\n', figure_filename);
    close(fig_save);

    % 3. Save text file with exact values
    text_filename = fullfile(output_dir, 'analysis_results.txt');
    fid = fopen(text_filename, 'w');

    fprintf(fid, '=== Heart Rate Analysis Results ===\n\n');
    fprintf(fid, 'Video: %s\n', video_filename);
    fprintf(fid, 'Analysis Date: %s\n\n', datestr(now));

    fprintf(fid, '--- BPM Statistics ---\n');
    fprintf(fid, 'Average BPM: %.4f\n', avg_bpm);
    fprintf(fid, 'Standard Deviation: %.4f\n', std_bpm);
    fprintf(fid, 'Minimum BPM: %.4f\n', min(all_bpm(all_bpm > 0)));
    fprintf(fid, 'Maximum BPM: %.4f\n\n', max(all_bpm(all_bpm > 0)));

    fprintf(fid, '--- Selected Frame Details ---\n');
    fprintf(fid, 'Frame Number: %d\n', selected_frame.frameNum);
    fprintf(fid, 'Selection Reason: %s\n', selection_reason);
    fprintf(fid, 'Detected BPM: %.4f\n', selected_frame.bpm);
    fprintf(fid, 'Smoothed Display BPM: %.4f\n', selected_frame.display_bpm);
    fprintf(fid, 'Number of Peaks in Range: %d\n', selected_frame.numPeaks);
    fprintf(fid, 'Peak Delta: %.6f\n\n', selected_frame.peakDelta);

    fprintf(fid, '--- ROI (Region of Interest) ---\n');
    fprintf(fid, 'X: %d, Y: %d, Width: %d, Height: %d\n\n', ...
            selected_frame.roi(1), selected_frame.roi(2), selected_frame.roi(3), selected_frame.roi(4));

    fprintf(fid, '--- Face Bounding Box ---\n');
    fprintf(fid, 'X: %d, Y: %d, Width: %d, Height: %d\n\n', ...
            selected_frame.face(1), selected_frame.face(2), selected_frame.face(3), selected_frame.face(4));

    % Save power spectrum data
    fprintf(fid, '--- Power Spectrum Data (Valid BPM Range: %.1f - %.1f) ---\n', low_bpm, high_bpm);
    valid_idx = (selected_frame.freqs >= low_bpm) & (selected_frame.freqs <= high_bpm);
    valid_freqs = selected_frame.freqs(valid_idx);
    valid_power = selected_frame.powerSpectrum(valid_idx);

    fprintf(fid, 'BPM\tPower\n');
    for i = 1:length(valid_freqs)
        fprintf(fid, '%.4f\t%.8f\n', valid_freqs(i), valid_power(i));
    end

    fclose(fid);
    fprintf('Saved analysis results: %s\n', text_filename);

    fprintf('\n=== All results saved successfully ===\n');
end