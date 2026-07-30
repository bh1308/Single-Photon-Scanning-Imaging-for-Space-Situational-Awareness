%% ============================================================
%  CONNECT TO OPTOTUNE MR-E-2 MIRROR
%% ============================================================

clear all

port = "COM4";
baud = 256000;

mirror = serialport(port, baud);
configureTerminator(mirror, "CR/LF");
pause(0.1);

%% Handshake
writeline(mirror, "start");
pause(0.01);


%% ============================================================
%  MIRROR MOVEMENT FUNCTION (with timing + settling)
%% ============================================================
function moveMirror(mirror, x, y)

    % Normalised limit
    maxDef = tand(16.6) / tand(50);

    % Clamp commands
    x = max(min(x, maxDef), -maxDef);
    y = max(min(y, maxDef), -maxDef);

    % Send command
    cmd = sprintf("xy= %0.4f; %0.4f", x, y);
    writeline(mirror, cmd);

    % Datasheet timing constraints
    pause(0.0001);   % 100 microseconds minimum command spacing
    pause(0.001);    % 1 millisecond settling time
end


%% ============================================================
%  PULSE OUTPUT FUNCTION (replace with DAQ later)
%% ============================================================

% function sendPulse(detector, pulseDuration)
%     writeline(detector, "PULSE_ON");
%     pause(pulseDuration);
%     writeline(detector, "PULSE_OFF");
% end

function sendPulse(~, pulseDuration)
fprintf("Simulated pulse for %.2f seconds\n", pulseDuration);
pause(pulseDuration);
end

%% ============================================================
%  STAR MAP PIXEL MAPPING FUNCTION
%% ============================================================
function [i, j] = star_map_array_math(theta, phi, Nrows, Ncols)

    j = round( (theta + 50) / 100 * (Ncols - 1) ) + 1;
    i = round( (phi   + 50) / 100 * (Nrows - 1) ) + 1;

    j = max(1, min(Ncols, j));
    i = max(1, min(Nrows, i));
end


%% ============================================================
%  SYNTHETIC SCREEN BRIGHTNESS MAP (TESTING WITHOUT HARDWARE)
%% ============================================================

Nrows = 1000; 
Ncols = 1000;
screen = zeros(Nrows, Ncols);

% Simulate a bright anomaly at pixel (500, 500)
screen(500, 500) = 255;   % CENTER of reachable region

% You can add more anomalies if you want:
% screen(200, 800) = 255;

%% Function to simulate brightness reading
function brightness = readScreenBrightness(theta, phi, screen)
    [i, j] = star_map_array_math(theta, phi, size(screen,1), size(screen,2));
    brightness = screen(i, j);
end


%% Dummy detector (replace with real SPCM later)
% detector = serialport("COM7", 115200);
detector = [];   % No detector hardware connected


%% ============================================================
%  SCAN PARAMETERS
%% ============================================================

threshold = 200;     % anomaly detection threshold
pulseDuration = 0.05; % 50 ms pulse

R = tand(16.6) / tand(50);


%% ============================================================
%  SCAN TYPE 2: CIRCULAR SCAN WITH ANOMALY DETECTION
%% ============================================================

t = linspace(0, 2*pi, 500);
scanX = R * cos(t);
scanY = R * sin(t);

fprintf("Starting circular scan\n");

for k = 1:length(scanX)

    moveMirror(mirror, scanX(k), scanY(k));

    brightness = readScreenBrightness(scanY(k), scanX(k), screen);

    if brightness > threshold
        fprintf("ANOMALY DETECTED at (x=%.3f, y=%.3f)\n", scanX(k), scanY(k));

        % Re-point mirror to anomaly
        moveMirror(mirror, scanX(k), scanY(k));

        % Send pulse
        sendPulse(detector, pulseDuration);

        fprintf("Pulse sent. Anomaly centred.\n");
    end
end

moveMirror(mirror, 0, 0);
pause(0.02);


%% ============================================================
%  SCAN TYPE 3: DIAMETER-TO-DIAMETER LINE-BY-LINE SCAN
%% ============================================================

fprintf("Starting diameter-to-diameter scan\n");

Ny = 50;
Nx = 200;

ys = linspace(R, -R, Ny);
xs = linspace(-R, R, Nx);

for j = 1:length(ys)

    y_line = ys(j);

    % Only move inside the circle boundary
    x_valid = xs(abs(xs) <= sqrt(R^2 - y_line^2));

    for k = 1:length(x_valid)

        moveMirror(mirror, x_valid(k), y_line);

        brightness = readScreenBrightness(y_line, x_valid(k), screen);

        if brightness > threshold
            fprintf("ANOMALY DETECTED at (x=%.3f, y=%.3f)\n", x_valid(k), y_line);

            % Re-point mirror to anomaly
            moveMirror(mirror, x_valid(k), y_line);

            % Send pulse
            sendPulse(detector, pulseDuration);

            fprintf("Pulse sent. Anomaly centred.\n");
        end
    end
end

moveMirror(mirror, 0, 0);

clear mirror
clear detector

fprintf("Scan complete.\n");
