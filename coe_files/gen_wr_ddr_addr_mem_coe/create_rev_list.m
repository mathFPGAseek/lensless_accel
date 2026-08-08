clc
clear all
close all
% create a list of bit reveresed indexes for FFT
N = 256;


% create a list of binary numbers
bin_list = [];
for i = 1 :256
  k = i-1;
  temp = fi(k,0,8,0); % create fixed point
  temp_bin = temp.bin;
  bin_list{i+1} = temp_bin;
end

% bit reverse each element
bit_rev_list = [];
for j = 2:N+1
    temp_flip = flip(bin_list{j}); 
     bit_rev_list{j+1} = temp_flip;
end

% Create bit rev num list
bit_rev_num_list = [];
for i = 3: N+2
    temp_num = bin2dec(bit_rev_list{i});
    bit_rev_num_list{i+1} = temp_num;
end

debug = 1;

% Put the list into a matrix for viewing
k = 4;
for i = 1 : N/32
    for j = 1 : N/8 
        bit_rev(i,j) = bit_rev_num_list{k};
        k = k+1;
    end
end

debug = 1;
