% genrate address that combines the bit reversal output of fft with
% the fft shift operation
clc
close all
clear all

N = 256;

% create bit reversal list
create_rev_list;
clearvars -except bit_rev_num_list N
bit_rev_corr_list = bit_rev_num_list(4:259);

% circshift
write_addr = circshift(bit_rev_corr_list,N/2);

debug = 1;

% file for COE
fid_wr_addr = fopen('wr_addr_vectors.txt', 'wt');

% Create address vectors; combining bit rev and  fft shift
for i = 1 : N
    input_sample = write_addr{i};
    input_sample_fi_num = fi(input_sample,0,8,0);
    input_char_array = input_sample_fi_num.bin;
    fprintf(fid_wr_addr,'%8s \n',input_char_array);
end

debug = 1;

