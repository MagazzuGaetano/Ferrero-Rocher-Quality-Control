function errors = checkerrors(im, centers, radius)
%CHECK_ERRORS controllo degli errori

centers = centers * 5;
radius = radius * 5;

[n, m, ~] = size(centers);
if n == 6 && m == 4
    errors = checkrectangle(im, centers, radius);
else
    errors = checksquare(im, centers, radius);
end

end

function errors = checksquare(im, centers, radius)
%CHECKSQUARE controllo per le scatole quadrate

errors = [];
nStamps = 0;
for i = 1 : length(centers)
    if nStamps == 24, break, end

    x = centers(i, 1);
    y = centers(i, 2);
    choco = utils.cropcircle(im, x, y, radius, false);
    if getcode(choco) == 1
        nStamps = nStamps + 1;
    else
        x = centers(i, 1);
        y = centers(i, 2);
        errors = [errors; x y];
    end
end

if  nStamps == 24
    errors = [];
end

end

function errors = checkrectangle(im, centers, radius)
%CHECKRECTANGLE controllo per le scatole rettangolari

[n, m, ~] = size(centers);
grid = zeros(n, m);
for i = 1 : n
    for j = 1 : m
        x = centers(i, j, 1);
        y = centers(i, j, 2);
        choco = utils.cropcircle(im, x, y, radius, false);
        grid(i, j) = getcode(choco);
    end
end

conf1 = [
    2, 2, 2, 2, 2, 2;
    1, 1, 1, 1, 1, 1;
    1, 1, 1, 1, 1, 1;
    3, 3, 3, 3, 3, 3;
];

conf2 = [
    3, 3, 3, 3, 3, 3;
    1, 1, 1, 1, 1, 1;
    1, 1, 1, 1, 1, 1;
    2, 2, 2, 2, 2, 2;
];

p1 = grid == conf1';
p2 = grid == conf2';

if sum(p1 == 0, 'all') <= sum(p2 == 0, 'all')
    grid = p1;
else
    grid = p2;
end

errors = [];
for i = 1 : n
    for j = 1 : m
        if grid(i, j) == 0
            x = centers(i, j, 1);
            y = centers(i, j, 2);
            errors = [errors; x y];
        end
    end
end
end

function out = getcode(choco)
%GETCODE associa un codice ad ogni cioccolatino

chocoType = classification.getchocotype(choco);

if chocoType == "Ferrero Rocher" && existsstamp(choco)
    out = 1;
elseif chocoType == "Ferrero Noir"
    out = 2;
elseif chocoType == "Raffaello"
    out = 3;
else
    out = 4;
end

end

function [out] = existsstamp(im)
%ISSTAMP verifica l'esistenza del bollino
im = imresize(im, [64, 64]); %[293 293]

hsv = rgb2hsv(im);
lab = rgb2lab(im);

S = hsv(:,:,2);
b = lab(:,:,3);
B = im(:,:,3);

b = (b + 128) / 255;

S = S > graythresh(S);
b = b > graythresh(b);
B = B < graythresh(B);
I1 = ~(S | b | B);
I1 = imfill(I1, 'holes');
I = imopen(I1, strel('disk', 3));

if any(I(:))
    I = bwareafilt(I, 1);
    out = sum(I(:)) > 45; % il risultato con area minore ha area 48
else
    out = false;
end

end
