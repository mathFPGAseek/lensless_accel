% Create point source
N = 64;
point_src_array_num = zeros(N,N);
%C = num2cell(point_src_array_num);

% replace zeros with characters of zero for binary rep
%{
for k = 1:numel(C)
    if isnumeric(C{k}) && isequal(C{k}, 0)
        C{k} = repmat('0', 1, 32);
    end
end
%}

% Fill in non-zeros; Point source simulation
%{
for row = 29 : 1 :32
    for col = 29 : 1 :32
        C{row,col} = '00111111011111110000000000000000';
    end
end
%}

for row = 29 : 1 :32
    for col = 29 : 1 :32
        point_src_array_num(row,col) = .9961;
    end
end



% file for COE
%fid_point_src_data = fopen('point_src_data.txt', 'wt');


% Write 0ut file
%{
for i = 1 : N
    for j = 1 : N               
        input_sample = C{i,j};        
        fprintf(fid_point_src_data, '%32s \n', input_sample);
    end
end
%}
