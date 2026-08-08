% genrate address that combines the bit reversal output of fft with
% the fft shift operation
clc
close all
clear all

N = 64;

pos_addr = 1:1:31;

neg_addr = 32:1:63;

write_addr_num = [ neg_addr 0 pos_addr];

write_addr = num2cell(write_addr_num);


debug = 1;

% file for COE
fid_wr_addr = fopen('wr_addr_vectors_64_by_64.txt', 'wt');

% Create address vectors; combining bit rev and  fft shift
for i = 1 : N
    input_sample = write_addr{i};
    input_sample_fi_num = fi(input_sample,0,8,0);
    input_char_array = input_sample_fi_num.bin;
    fprintf(fid_wr_addr,'%8s \n',input_char_array);
end

debug = 1;

