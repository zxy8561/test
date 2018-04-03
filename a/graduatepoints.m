%% Graduate Point
%

%% Overview of step 1
% I loaded the 12 images and convert them into double image. 
% For calculcation of surface norm vectors, we need gray scale image, so I
% also created the corresponding gray scale image for each image.
mask = rgb2gray(imread('buddha.mask.png'));
imshow(mask);
mask_logical = logical(mask);


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

img0_g = rgb2gray(img0);
img1_g = rgb2gray(img1);
img2_g = rgb2gray(img2);
img3_g = rgb2gray(img3);
img4_g = rgb2gray(img4);
img5_g = rgb2gray(img5);
img6_g = rgb2gray(img6);
img7_g = rgb2gray(img7);
img8_g = rgb2gray(img8);
img9_g = rgb2gray(img9);
img10_g = rgb2gray(img10);
img11_g = rgb2gray(img11);

[rows, cols] = size(img0(:,:,1));


light = load('lighting.mat');


L = light.L;

i = zeros(12,1);

kp_r_map = zeros(rows, cols);
kp_g_map = zeros(rows, cols);
kp_b_map = zeros(rows, cols);
kp_map = zeros(rows, cols);

p_map = zeros(rows, cols);
q_map = zeros(rows, cols);

N = zeros(rows, cols, 3);
%display(size(N));

%% Overview of step 2?3
% To calculate albedoes, I first created three albedo map (initialized with 0) for each channel and
% another one for grayscale for computing N. For each pixel in the image, I
% calculated g(x,y) by solving equation i(x,y) = L g(x,y), in which i(x,y)
% and L are all knowns (L is directly loaded from lighting.mat file).
%
% N (based on grayscale info) and kp(red, green, blue) could all be
% calculated after we calculated all g(x,y).
%
% After that we need to calculate p and q for each pixel, in this process, I also dealt with the outlier problem (or the NaN
% problem) by setting p/q values to 0, if they are outlier (say if their absolute value are
% above a threshold, 40 in my case)
for row = 1:rows
    for col = 1:cols
        if(mask(row,col)>0)
            for color = 1:3
                i = zeros(12,1);
        % red chanel
                i(1) = img0(row, col,color);
                i(2) = img1(row, col,color);
                i(3) = img2(row, col,color);
                i(4) = img3(row, col,color);
                i(5) = img4(row, col,color);

                i(6) = img5(row, col,color);
                i(7) = img6(row, col,color);
                i(8) = img7(row, col,color);
                i(9) = img8(row, col,color);
                i(10) = img9(row, col,color);
                i(11) = img10(row, col,color);
                i(12) = img11(row, col,color);

%display(i);
        %gxy = zeros(3,1);
                gxy = L \ i;
                %display(gxy);
                if (color ==1)
                    kp_r_map(row,col) = norm(gxy);
                    %display(norm(gxy));
                end
        
                if (color ==2)
                    kp_g_map(row,col) = norm(gxy);
                    %display(norm(gxy));

                end
        
                if (color ==3)
                    kp_b_map(row,col) = norm(gxy);
                    %display(norm(gxy));
                end
            
            end
            
            
            % start to calculate N based on grayscale image
            i = zeros(12,1);
            i(1) = img0_g(row, col);
            i(2) = img1_g(row, col);
            i(3) = img2_g(row, col);
            i(4) = img3_g(row, col);
            i(5) = img4_g(row, col);

            i(6) = img5_g(row, col);
            i(7) = img6_g(row, col);
            i(8) = img7_g(row, col);
            i(9) = img8_g(row, col);
            i(10) = img9_g(row, col);
            i(11) = img10_g(row, col);
            i(12) = img11_g(row, col);
            
            gxy = L \ i;
            kp_map(row, col) = norm(gxy);
            N(row, col, :) = gxy/norm(gxy);
            %display(N(row, col, :));
            
            p = N(row,col,1)/N(row,col,3);
            q = N(row,col,2)/N(row,col,3);
            if (abs(p)<40) 
                p_map(row,col) = p;
            end
            if (abs(q)<40) 
                q_map(row,col) = q;
            end
        end
    end

end



%%
% show the albedo for three chanels
clf
subplot 131, imshow(kp_r_map); title('Albedo-red channel')
subplot 132, imshow(kp_g_map); title('Albedo-green channel')
subplot 133, imshow(kp_b_map); title('Albedo-blue channel')

pause;
%%
% show the Surface normal vectors computed from grayscale images 
% (exressed as p and q) for the budha dataset
clf
quiver(1:5:cols, 1:5:rows, p_map(1:5:end, 1:5:end), q_map(1:5:end, 1:5:end),2);
axis tight ij
pause;

%% Overview of step 4
% Compute depth map using my own integration code, by following the
% instructon on pdf.
depth_own = zeros(rows, cols);
% for first column
for row = 2: rows
    depth_own(rows, 1) = depth_own(rows-1, 1) + q_map(row,1);
end

for row = 1:rows
    for col = 2:cols
        depth_own(row, col) = depth_own(row, col-1) + p_map(row,col);
    end
end

%%
% Show depth map using my own integration code
%
% Comment: since most of the depth numbers are negative, we need to negate
% the depth_own map first before plug into surfl function.
surfl(-depth_own); shading interp; colormap gray; axis tight;
pause;

%% 
% Show depth map using provided refining code


depth = refineDepthMap(N,mask_logical);
surfl(depth); shading interp; colormap gray; axis tight;
pause;

%% Comment

%%
% * Shortcoming of algorithm: it does not take account of impact of shadows
% and inter-reflection. and in real life, this is not practical because
% it doesn't work for shiny things, semi-translucent things. Shadow will
% cause problem because, if a pixel is in shadow of other objects, the
% intensity of this pixel is zero, thus no useful information could be
% extracted for us to get our solution, only when the pixel is completely out of a
% shadow can we calculate correctly.
% The other drawback is that it requires we pre-identify interesting points
% to create the mask.
% 
% * ways to improve in this aspect:
% 1. Use more light sources
% 2. Tackle the shadow problem by: multiply the left hand side and right
% hand side of the equation to solve with a diag matrix with pixel
% intensities accross the 12 images along side the diag line. In this way,
% when we solve the equation, we are treating this problem like we do not
% have the issue of shadowing and solved the problem of have missing
% information.
%
% * Comment on depth integration process:
% The simple integration solution is not perfect, it does not accurately
% estimate depth because a previous error will be accrued over to following
% pixels. And only one direction, in this case, along each row (x direction), the depth
% is integrated (that is why on y direction, we could see the surface is not smooth) . To improve on this aspect, we need to use a more accurate
% integration method which incorporate integration over different
% directions instead of just one direction. (this is might what refinecode
% is doing).
%
% * For my implementation, I would not trust the depth calculated. But I
% would trust result obtained from refined code. 
