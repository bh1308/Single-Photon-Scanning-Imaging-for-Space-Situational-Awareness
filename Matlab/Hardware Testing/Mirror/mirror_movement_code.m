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

    pause(0.0001);   % 100 microseconds
    pause(0.001);    % 1 millisecond settling
end

%% Pulse output function
function sendPulse(detector, pulseDuration)
    writeline(detector, "PULSE_ON");
    pause(pulseDuration);
    writeline(detector, "PULSE_OFF");
end

%% Dummy detector (replace with real SPCM later)
detector = serialport("COM7", 115200);

%% -----------------------------
% Mirror scanning type 2: Circular scan
%% -----------------------------
t = linspace(0, 2*pi, 500);
R = tand(16.6) / tand(50);

scanX = R * cos(t);
scanY = R * sin(t);

threshold = 200;   % event threshold

for k = 1:length(scanX)

    moveMirror(mirror, scanX(k), scanY(k));

    % TEMP: replace with readSPCM(detector, integrationTime)
    photonCounts = randi([0 300]);

    if photonCounts > threshold
        fprintf("EVENT DETECTED: %d counts\n", photonCounts);
        userChoice = input("Enter 1 to send pulse, 0 to continue: ");
        if userChoice == 1
            sendPulse(detector, 0.05);
        end
    end

end

moveMirror(mirror,0,0)
pause(0.02)

%% -----------------------------
% Diameter-to-diameter line-by-line scan
%% -----------------------------
Ny = 50;
Nx = 200;

ys = linspace(R, -R, Ny);
xs = linspace(-R, R, Nx);

for j = 1:length(ys)

    y_line = ys(j);
    x_valid = xs(abs(xs) <= sqrt(R^2 - y_line^2));

    for k = 1:length(x_valid)

        moveMirror(mirror, x_valid(k), y_line);

        photonCounts = randi([0 300]);

        if photonCounts > threshold
            fprintf("EVENT DETECTED: %d counts\n", photonCounts);
            userChoice = input("Enter 1 to send pulse, 0 to continue: ");
            if userChoice == 1
                sendPulse(detector, 0.05);
            end
        end

    end
end

moveMirror(mirror,0,0)
clear mirror
