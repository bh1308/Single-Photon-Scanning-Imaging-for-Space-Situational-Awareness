%%  CONNECT TO OPTOTUNE MR-E-2 MIRROR

clear all

port = "COM4";
baud = 256000;

mirror = serialport(port, baud);
configureTerminator(mirror, "CR/LF");
pause(0.1);

%% Handshake
writeline(mirror, "start");
pause(0.01);

%%  MIRROR MOVEMENT FUNCTION (with timing + settling)

function moveMirror(mirror, x, y)
    
    % Normalized limit
    maxDef = tand(16.6)/ tand(50);

    % Clamp maximum angle movement
    x = max(min(x, maxDef), -maxDef);
    y = max(min(y, maxDef), -maxDef);
    
    % Send command
    cmd = sprintf("xy= %0.4f; %0.4f", x, y);
    writeline(mirror, cmd);

    % Datasheet timing constraints
    pause(0.0001);
    pause(0.001);

end

%% PULSE OUTPUT FUNCTION (TO BE REPLACED WITH DAQ)

function sendPulse(~, pulseDuration)
fprintf("Simulated pulse for %.2f seconds\n", pulseDuration);
pause(pulseDuration);
end

%% STAR MAP PIXEL MAPPING FUNCTION

function [i, j] = star_map_array_math(thetha, phi, Nrows, Ncols)

    j = round((thetha + 50) / 100 * (Ncols - 1)) + 1;
    i = round((phi + 50) / 100 * (Nrows - 1)) + 1;

    j = max(1, min(Ncols, j));
    i = max(1, min(Nrows, i));

end

%% SYNTHETIC SCREEN BRIGHTNESS MAP (FOR TESTING WITH NO STAR MAP)

Nrows = 1000;
Ncols = 1000;
screen = zeros(Nrows, Ncols);

% Simulate a bright anomaly at pixel (500, 500)
screen(498:502, 498:502) = 255;   % Test anomaly 1
screen(398:402, 598:602) = 255;   % Test anomaly 2
screen(648:652, 348:352) = 255;   % Test anomaly 3

%% Function to simulate brightness reading
function brightness = readScreenBrightness(theta, phi, screen)
    [i, j] = star_map_array_math(theta, phi, size(screen,1), size(screen, 2));

    % Neighborhood size definition
    window = 2;
    
    row_min = max(1, i - window);
    row_max = min(size(screen, 1), i + window);
    
    col_min = max(1, j - window);
    col_max = min(size(screen, 2), j + window);

    region = screen(row_min:row_max, col_min:col_max);

    % Brightness magnitude = mean of region
    brightness = mean(region(:));
end

%% DUMMY DETECTOR (TO BE REPLACED WUTH REAL SPCM)

detector = []; % No detector hardware connected

%% SCAN PARAMETERS

anomalyMagnitude = 100;       % Anomaly detection threshold
pulseDuration = 0.05;  % 50 ms pulse

R = tand(16.6) / tand(50);

%% SCAN TYPE 1: CIRCULAR SCAN WITH ANOMALY DETECTION

t = linspace(0, 2*pi, 500);
scanX = R * cos(t);
scanY = R * sin(t);

fprintf("Starting circular scan\n");

for k = 1:length(scanX)
    
    moveMirror(mirror, scanX(k), scanY(k));

    brightness = readScreenBrightness(scanY(k), scanX(k), screen);

    if brightness >= anomalyMagnitude
        fprintf("ANOMALY DETECTED at (x=%.3f, y=%.3f\n", scanX(k), scanY(k));

        % Re point mirror to anomaly
        moveMirror(mirror, scanX(k), scanY(k));

        % Send pulse
        sendPulse(detector, pulseDuration);

        fprintf("Pulse sent. ANOMALY CENTRED!\n");
    end
end

moveMirror(mirror, 0, 0);
pause(0.02);

%% SCAN TYPE 2: DIAMETER TO DIAMETER LINE-BY-LINE SCAN

fprintf("Starting diameter to diamter scan\n");

Ny = 50;
Nx = 200;

ys = linspace(R, -R, Ny);
xs = linspace(-R, R, Nx);

for j = 1:length(ys)

    y_line = ys(j);
    
    % Move inside the circle boundary 
    x_valid = xs(abs(xs) <= sqrt(R^2 -y_line^2));

    for k = 1:length(x_valid)

        moveMirror(mirror, x_valid(k), y_line);

        brightness = readScreenBrightness(y_line, x_valid(k), screen);
        
        if brightness >= anomalyMagnitude
            fprintf("ANOMALY DETECTED at (x=%.3f, y=%.3f)\n", x_valid(k), y_line);

            % Re point mirror to anomaly
            moveMirror(mirror, x_valid(k), y_line);

            % Send pulse
            sendPulse(detector, pulseDuration);

            fprintf("Pulse sent. ANOMALY CENTERED!\n")
        end
    end
end

moveMirror(mirror, 0, 0);

clear mirror
clear detector

fprintf("Scan complete.\n");
