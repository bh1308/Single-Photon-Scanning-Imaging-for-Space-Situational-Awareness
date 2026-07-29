function [i, j] = star_map_array_math(theta, phi, Nrows, Ncols)

    % Convert angle to star map pixel index
    j = round( (theta + 50) / 100 * (Ncols - 1) ) + 1;   % column
    i = round( (phi   + 50) / 100 * (Nrows - 1) ) + 1;   % row

    % Clamp to valid pixel range
    j = max(1, min(Ncols, j));
    i = max(1, min(Nrows, i));

    % --- Compute max reachable pixel ---
    theta_max = 16.6;
    phi_max   = 16.6;

    j_max = round( (theta_max + 50) / 100 * (Ncols - 1) ) + 1;
    i_max = round( (phi_max   + 50) / 100 * (Nrows - 1) ) + 1;

    j_max = max(1, min(Ncols, j_max));
    i_max = max(1, min(Nrows, i_max));

    % --- Compute min reachable pixel ---
    theta_min = -16.6;
    phi_min   = -16.6;

    j_min = round( (theta_min + 50) / 100 * (Ncols - 1) ) + 1;
    i_min = round( (phi_min   + 50) / 100 * (Nrows - 1) ) + 1;

    j_min = max(1, min(Ncols, j_min));
    i_min = max(1, min(Nrows, i_min));

    % --- Print results ---
    fprintf("Max reachable pixel:   (i_max = %d, j_max = %d)\n", i_max, j_max);
    fprintf("Min reachable pixel:   (i_min = %d, j_min = %d)\n", i_min, j_min);
end

% TO CALL: 
% theta = 16.6; phi = -16.6; Nrows = 1000; Ncols = 1000; [i, j] = star_map_array_math(theta, phi, Nrows, Ncols)
