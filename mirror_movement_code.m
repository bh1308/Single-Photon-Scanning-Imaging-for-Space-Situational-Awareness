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

%% Mirror movement function
function moveMirror(mirror,x,y)

    maxDef = tand(16.6) / tand(50);

    x = max(min(x, maxDef), -maxDef);
    y = max(min(y, maxDef), -maxDef);

    cmd = sprintf("xy= %0.4f; %0.4f",x,y);
    writeline(mirror, cmd)
    pause(0.01);
end

%% Mirror scanning type 1

% Raster scan: moves left, right and then down one row
% Moves quite slow roughly completed scan in 45 seconds

Nx = 50; Ny = 50;
maxDef = tand(16.6) / tand(50);

xs = linspace(-maxDef, maxDef, Nx);
ys = linspace(-maxDef, maxDef, Ny);

[Xgrid, Ygrid] = meshgrid(xs, ys);

scanX = Xgrid(:);
scanY = Ygrid(:);

for k = 1:length(scanX)
    moveMirror(mirror, scanX(k), scanY(k));
end

moveMirror(mirror,0,0)

clear mirror

% % Mirror scanning type 2
% % Circular scan: moves around a circle of radius r
% % Moves very fast roughly completed scan in 10 seconds
% 
% t = linspace(0, 2*pi, 500);
% R = tand(16.6) / tand(50);
% 
% scanX = R * cos(t);
% scanY = R * sin(t);
% 
% for k = 1:length(scanX)
%     moveMirror(mirror, scanX(k), scanY(k));
% end
% 
% moveMirror(mirror,0,0)
% 
% clear mirror
