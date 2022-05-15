load('H.mat');
fs=20000;
t=0:1/fs:1;
x=0.1.*(cos(2*pi*250*t)+cos(2*pi*4567*t)+cos(2*pi*8321*t));
x=x.';
y=filter(H4,1,x);                    
plot(-fs/2:fs/2,abs(fftshift(fft(x))),-fs/2:fs/2,abs(fftshift(fft(y)))); % Frequency analysis

y_cos = x * 2^11;  %量化
fid = fopen('D:\Workspace\Y52-DSP Algorithm\11\C2\cos1.coe','wt'); % coe文件地址
%写coe文件
fprintf(fid,'memory_initialization_radix = 10;\n');
fprintf(fid,'memory_initialization_vector =\n');
for i=1:length(x)
    if(i==length(x))
       fprintf(fid, '%.0f; \n' , floor(y_cos(i)));
    else  
       fprintf(fid, '%.0f, \n' , floor(y_cos(i)));
    end
end  
       fclose(fid);