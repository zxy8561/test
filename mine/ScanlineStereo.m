tl = double(rgb2gray(imread('tsukuba_l.ppm')));
tr = double(rgb2gray(imread('tsukuba_r.ppm')));
patch_size = 9;

[rows, cols] = size(tl);
disparity = zeros(rows,cols);
disp(rows);
disp(cols);
pause;

for row = (patch_size+1)/2 : rows-(patch_size+1)/2

    c_i_j = zeros(cols,cols);
    cost = zeros(cols,cols);
    
    for i = (patch_size+1)/2 : cols-(patch_size-1)/2
        for j = (patch_size+1)/2 : cols-(patch_size-1)/2
            c_i_j(i,j) = patch_diff(tl, tr, row, i, j, patch_size);
        end
        % initialize
        if i == (patch_size+1)/2
            cost((patch_size+1)/2, i) = c_i_j((patch_size+1)/2, i);
        else
            cost((patch_size+1)/2, i) = c_i_j((patch_size+1)/2, i) + cost((patch_size+1)/2, i-1);
        end
    end
  
    for i = 1+(patch_size+1)/2 : cols-(patch_size-1)/2
        for j = 1+(patch_size+1)/2 : cols-(patch_size-1)/2
            cost(i,j) = min([cost(i-1,j)+c_i_j(i,j), cost(i,j-1)+c_i_j(i,j), cost(i-1,j-1)+c_i_j(i,j)]); 
        end
    end
    
    c = cols-(patch_size-1)/2;
    r = c;
    dis = 0;    
    
    while( c > (patch_size+1)/2 && r > (patch_size+1)/2 ) 
       
        disparity(row, r) = dis;
        
        mcost = min([cost(r,c-1), cost(r-1,c-1), cost(r-1,c)]);
        
        if mcost == cost(r,c-1)
            dis = dis - 1;
            c = c -1;
        elseif mcost == cost(r-1,c)
            dis= dis + 1;
            r = r - 1;
        else
            c = c - 1;
            r = r - 1;
        end 
         
    end     
 end

colormap('jet')
imagesc(disparity);
colorbar
pause;

function [ diff ] = patch_diff(img1, img2, row1, col1, col2, patchsize)
    ps = (patchsize -1)/2;
    patch1 = img1(row1-ps:row1+ps, col1-ps:col1+ps);
    patch2 = img2(row1-ps:row1+ps, col2-ps:col2+ps);
    
    %sum of squared difference
    diff = sum(sum((patch1 - patch2).^2));
    disp(diff);

end

