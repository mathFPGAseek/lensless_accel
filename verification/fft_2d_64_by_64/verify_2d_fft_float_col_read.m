%--------------------------------------------------------------------------
% file: verify_2d_fft_float.m
% engr: rbd
% date : 10/11/26
% descr: Verify matching output of FPGA HDL after 1d FFT
%--------------------------------------------------------------------------
close all
clear all
clc           
%--------------------------------------------------------------------------
%% Run Vivado FPGA simulator; External tool
%--------------------------------------------------------------------------
disp(' Vivado 2D FFT should have been run ');
%--------------------------------------------------------------------------
%% Check 2-D FFT simulation ( col FFT)
%--------------------------------------------------------------------------
convert_vectors_to_single_col_read; % after COPYING from viv wk "fft_2d_mem_raw_vevtors"

% Generate Xilinx MAT data to be checked
if exist('complex_image_array','var')
    disp(' Generate MAT Xilinx file for 2-D FFT checking');
    save(['./data/fft_float_' ...
        '2d_seq_matrix_fr_viv_sim.mat'],'complex_image_array');
    clearvars;
else
    error('Error: Could not generate MAT Xilinx file for testing');
end


% Generate Matlab model data to be checked against
run_xfft_v9_1_float_mex;

if exist('ImgByCol','var')
    disp(' Generate MAT file for 2-D FFT checking');
    save('./data/fft_float_2d_seq_matrix_fr_matlab.mat','ImgByRow'); %% no fftshift
    close all; clearvars;
else
    error('Error: Could not generate MAT file for testing');
end

% Perform 2-D FFT check (Col FFT)
compare_hdl_sim_2_mat_sim_spec_2d_fft_float; % Checked Data & fftshift (Also reorders Viv vectors)

debug = 1;
