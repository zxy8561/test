mask = rgb2gray(imread('buddha.mask.png'));
mask_logical = logical(mask);
light = load('lighting.mat');
L = light.L;

img0 = im2double(imread('buddha.0.png'));
img1 = im2double(imread('buddha.1.png'));
img2 = im2double(imread('buddha.2.png'));
img3 = im2double(imread('buddha.3.png'));
img4 = im2double(imread('buddha.4.png'));
img5 = im2double(imread('buddha.5.png'));
img6 = im2double(imread('buddha.6.png'));
img7 = im2double(imread('buddha.7.png'));
img8 = im2double(imread('buddha.8.png'));
img9 = im2double(imread('buddha.9.png'));
img10 = im2double(imread('buddha.10.png'));
img11 = im2double(imread('buddha.11.png'));

imgg0 = rgb2gray(img0);
imgg1 = rgb2gray(img1);
imgg2 = rgb2gray(img2);
imgg3 = rgb2gray(img3);
imgg4 = rgb2gray(img4);
imgg5 = rgb2gray(img5);
imgg6 = rgb2gray(img6);
imgg7 = rgb2gray(img7);
imgg8 = rgb2gray(img8);
imgg9 = rgb2gray(img9);
imgg10 = rgb2gray(img10);
imgg11 = rgb2gray(img11);

rows = size(img0,1);
cols = size(img0,2);

i = zeros(12,1);

red = zeros(rows, cols);
green = zeros(rows, cols);
blue = zeros(rows, cols);

kp = zeros(rows, cols);
p = zeros(rows, cols);
q = zeros(rows, cols);
N = zeros(rows, cols, 3); %RGB

for row = 1:rows
    for col = 1:cols
        if(mask(row,col)>0)
            for color = 1:3 
                % generate i(x,y) for RGB channels
                i = zeros(12,1);
                i(1) = img0(row, col, color);
                i(2) = img1(row, col, color);
                i(3) = img2(row, col, color);
                i(4) = img3(row, col, color);
                i(5) = img4(row, col, color);
                i(6) = img5(row, col, color);
                i(7) = img6(row, col, color);
                i(8) = img7(row, col, color);
                i(9) = img8(row, col, color);
                i(10) = img9(row, col, color);
                i(11) = img10(row, col, color);
                i(12) = img11(row, col, color);

                g = L \ i;
                if (color == 1)
                    red(row,col) = norm(g);
                end
                if (color == 2)
                    green(row,col) = norm(g);
                end
                if (color == 3)
                    blue(row,col) = norm(g);
                end
            
            end
            
            % generate i(x,y) for gray image
            i = zeros(12,1);
            i(1) = imgg0(row, col);
            i(2) = imgg1(row, col);
            i(3) = imgg2(row, col);
            i(4) = imgg3(row, col);
            i(5) = imgg4(row, col);

            i(6) = imgg5(row, col);
            i(7) = imgg6(row, col);
            i(8) = imgg7(row, col);
            i(9) = imgg8(row, col);
            i(10) = imgg9(row, col);
            i(11) = imgg10(row, col);
            i(12) = imgg11(row, col);
            
            % calculate N
            g = L \ i;
            kp(row, col) = norm(g);
            N(row, col, :) = g/kp(row, col);
            
            pi = N(row,col,1)/N(row,col,3);
            qi = N(row,col,2)/N(row,col,3);
            if (abs(pi)<30) 
                p(row,col) = pi;
            end
            if (abs(qi)<30) 
                q(row,col) = qi;
            end
        end
    end

end

clf
subplot 131, imshow(red); title('Red albedo')
subplot 132, imshow(green); title('Green albedo')
subplot 133, imshow(blue); title('Blue albedo')
pause;

clf
quiver(1:5:cols, 1:5:rows, p(1:5:end, 1:5:end), q(1:5:end, 1:5:end),2);
axis tight ij
pause;

depth = zeros(rows, cols);
for row = 2: rows
    depth(rows, 1) = depth(rows-1, 1) + q(row,1);
end
for row = 1:rows
    for col = 2:cols
        depth(row, col) = depth(row, col-1) + p(row,col);
    end
end

surfl(-depth); shading interp; colormap gray; axis tight;
pause;

depth = refineDepthMap(N,mask_logical);
surfl(depth); shading interp; colormap gray; axis tight;
pause;

