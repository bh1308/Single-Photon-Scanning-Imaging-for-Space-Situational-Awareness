%% ----------------------------------------------------
% CONNECT TO MIRROR
% ----------------------------------------------------
clear all

port = "COM4";              % Generic port
baud = 256000;

mirror = serialport(port, baud);
configureTerminator(mirror, "CR/LF");
pause(0.1);

%% Handshake
writeline(mirror, "start");
pause(0.01);


%% ----------------------------------------------------
% MIRROR MOVEMENT FUNCTION (CLAMPED TO ±16.6°)
% ----------------------------------------------------
function moveMirror(mirror, x, y)

    maxDef = tand(16.6) / tand(50);   % Normalized limit

    % Clamp commands
    x = max(min(x, maxDef), -maxDef);
    y = max(min(y, maxDef), -maxDef);

    % Send command
    cmd = sprintf("xy= %0.4f; %0.4f", x, y);
    writeline(mirror, cmd);
    pause(0.01);
end


%% ----------------------------------------------------
% SINGLE-PHOTON ACQUISITION FUNCTION
% ----------------------------------------------------
% Reads photon counts from the SPCM for a given
% integration time (in milliseconds).
% ----------------------------------------------------
function photonCounts = readSPCM(detector, integrationTime_ms)

    flush(detector);                 % Clear buffer
    writeline(detector, "READ");     % Trigger detector
    pause(integrationTime_ms/1000);  % Wait for integration

    data = readline(detector);       % Read photon count
    photonCounts = str2double(data); % Convert to number
end


%% ----------------------------------------------------
% CONNECT TO SPCM DETECTOR
% ----------------------------------------------------
detector = serialport("COM7", 115200);   % Generic port + baud
configureTerminator(detector, "LF");


%% ----------------------------------------------------
% RASTER SCAN + PHOTON ACQUISITION
% ----------------------------------------------------
% This creates the full set of mirror positions to be 
% scanned
% ----------------------------------------------------

Nx = 50; Ny = 50;                 % Scan resolution
integrationTime_ms = 50;          % Detector integration time

Nrows = 1000; Ncols = 1000;       % Star map size
photonImage = zeros(Nrows, Ncols);

maxDef = tand(16.6) / tand(50);

xs = linspace(-maxDef, maxDef, Nx);
ys = linspace(-maxDef, maxDef, Ny);

[Xgrid, Ygrid] = meshgrid(xs, ys);

scanX = Xgrid(:);
scanY = Ygrid(:);

for k = 1:length(scanX)

    % Move mirror to scan position
    moveMirror(mirror, scanX(k), scanY(k));

    % Convert mirror angles to star-map pixel indices
    [i, j] = star_map_array_math(scanY(k), scanX(k), Nrows, Ncols);

    % Acquire photon count
    photonCounts = readSPCM(detector, integrationTime_ms);

    % Store in image
    photonImage(i, j) = photonCounts;

end

%% Return mirror to centre
moveMirror(mirror, 0, 0);

clear mirror
clear detector
