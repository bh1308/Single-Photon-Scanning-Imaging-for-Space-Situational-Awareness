% Parameters
H = 200; W = 300;           % Star map size (pixels)
Nstars = 20;                % Number of stars (illuminated pixels)
starAmp = 1;                % Peak amplitude of a star
psfSigma = 2;               % PSF std dev (pixels) representing FoV blur
apertureRadius = 5;         % Aperture radius (pixels) of SPC collection
spcRows = 10; spcCols = 15; % SPC frame size (number of scan positions)

% 1) Make star map (sparse bright pixels with small random jitter)
rng(0);
starMap = zeros(H,W);
idx = randperm(H*W, Nstars);
starMap(idx) = starAmp;

% Optionally give tiny finite size to stars (not strictly single pixels)
starMap = imgaussfilt(starMap, 0.5);

% 2) PSF (Gaussian) models FoV blur from mirror pointing
psfSize = ceil(psfSigma*6);
psf = fspecial('gaussian', psfSize, psfSigma); % sums to 1

% 3) Convolve star map with PSF -> blurred irradiance on sensor
irradiance = conv2(starMap, psf, 'same');

% 4) Aperture kernel: models how much each mirror pointing integrates
aperture = fspecial('disk', apertureRadius) > 0; % binary disk
% normalize if you want average rather than sum:
% aperture = aperture / sum(aperture(:));

% 5) Precompute integrated signal for every pixel center by convolving
integratedMap = conv2(irradiance, aperture, 'same');

% 6) Define SPC scan grid (mirror scan positions) across the star map
% evenly spaced centers in image coordinates
xCenters = linspace(1, W, spcCols);
yCenters = linspace(1, H, spcRows);
[XC, YC] = meshgrid(xCenters, yCenters);

% 7) Sample the integratedMap at the scan centers to form SPC frame
spcFrame = interp2(1:W, 1:H, integratedMap, XC, YC, 'linear', 0);

% Visualization
figure;
subplot(1,3,1); imagesc(starMap); axis image off; title('Star Map');
subplot(1,3,2); imagesc(irradiance); axis image off; title('Blurred Irradiance');
subplot(1,3,3); imagesc(spcFrame); axis image; colorbar; title('SPC Frame');
