% genrate address for reading along columns from memory
clc
close all
clear all

N = 64;

addr_list = {};
% sequence
for i = 1 : N
    temp = (i -1) *64; 
    read_addr{i}  = temp;
end

debug = 1;

% file for COE
fid_read_addr = fopen('read_addr_vectors_64_by_64.txt', 'wt');

% Create read address vectors;
for i = 1 : N
    input_sample = read_addr{i};
    input_sample_fi_num = fi(input_sample,0,16,0);
    input_char_array = input_sample_fi_num.bin;
    fprintf(fid_read_addr,'%16s \n',input_char_array);
end

debug = 1;

