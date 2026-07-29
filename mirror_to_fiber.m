%% ----------------------------------------------------
% MIRROR SCAN TO DIRECT LIGHT INTO FIBRE
% ----------------------------------------------------

%% Connect to Optotune MR-E-2

clear all

port = "COM4";
baud = 256000;

mirror = serialport(port, baud);
configureTerminator(mirror, "CR/LF");
pause(0.1);

%% Handshake
writeline(mirror, "start");
pause(0.01);

%% Mirror movement function (clamped to ±16.6°)
function moveMirror(mirror, x, y)

    maxDef = tand(16.6) / tand(50);   % normalized limit

    % Clamp commands
    x = max(min(x, maxDef), -maxDef);
    y = max(min(y, maxDef), -maxDef);

    % Send command
    cmd = sprintf("xy= %0.4f; %0.4f", x, y);
    writeline(mirror, cmd);
    pause(0.01);
end

%% ----------------------------------------------------
% RASTER SCAN — DIRECT LIGHT INTO FIBRE
% ----------------------------------------------------

Nx = 50; Ny = 50;
maxDef = tand(16.6) / tand(50);

xs = linspace(-maxDef, maxDef, Nx);
ys = linspace(-maxDef, maxDef, Ny);

[Xgrid, Ygrid] = meshgrid(xs, ys);

scanX = Xgrid(:);
scanY = Ygrid(:);

for k = 1:length(scanX)

    % Move mirror to scan position
    moveMirror(mirror, scanX(k), scanY(k));

    % At this point:
    % The mirror is directing the incoming light
    % from the telescope into the fibre.

    pause(0.01);  % allow settling

end

%% Return mirror to centre
moveMirror(mirror, 0, 0);

clear mirror
