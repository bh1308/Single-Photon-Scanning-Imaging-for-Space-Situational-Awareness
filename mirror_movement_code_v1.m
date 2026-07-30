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
    pause(0.0001);
    pause(0.001);
end

% %% Mirror scanning type 1
% 
% % Raster scan: moves left, right and then down one row
% % Moves quite slow roughly completed scan in 45 seconds
% 
% Nx = 50; Ny = 50;
% maxDef = tand(16.6) / tand(50);
% 
% xs = linspace(-maxDef, maxDef, Nx);
% ys = linspace(-maxDef, maxDef, Ny);
% 
% [Xgrid, Ygrid] = meshgrid(xs, ys);
% 
% scanX = Xgrid(:);
% scanY = Ygrid(:);
% 
% for k = 1:length(scanX)
%     moveMirror(mirror, scanX(k), scanY(k));
% end
% 
% moveMirror(mirror,0,0)
% 
% clear mirror


% Mirror scanning type 2
% Circular scan: moves around a circle of radius r
% Moves very fast roughly completed scan in 10 seconds

t = linspace(0, 2*pi, 500);
R = tand(16.6) / tand(50);

scanX = R * cos(t);
scanY = R * sin(t);

for k = 1:length(scanX)
    moveMirror(mirror, scanX(k), scanY(k));
end

moveMirror(mirror,0,0)

pause(0.02)  % 100 MILLISECONDS MINIMUM

Ny = 50;                     
Nx = 200;                    

ys = linspace(R, -R, Ny);    
xs = linspace(-R, R, Nx);    

for j = 1:length(ys)

    y_line = ys(j);

    % For each y, compute valid x positions inside the circle
    % Circle equation: x^2 + y^2 <= R^2
    x_valid = xs(abs(xs) <= sqrt(R^2 - y_line^2));

    for k = 1:length(x_valid)
        moveMirror(mirror, x_valid(k), y_line);
    end

end

moveMirror(mirror,0,0)

clear mirror

% NEEDS TO ACCEPT INPUT AND SEND A PULSE 