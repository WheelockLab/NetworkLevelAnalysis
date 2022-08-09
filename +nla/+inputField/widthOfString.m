function w = widthOfString(str, h)
    % Approximate the display width of a given text string
    c_total = strlength(str);
    c1 = count(str, ["i", "j", "l", "I"]);
    c2 = count(str, ["t"]);
    c3 = count(str, ["f", "r", "-", "(", ")", "*"]);
    c4 = count(str, ["a","c","d", "e", "g", "h", "k", "n", "o", "p", "q", "s", "u", "v", "x", "y", "z", "F", "J", "L"]);
    c5 = count(str, ["<", ">", "$", "#", "^W", "%", "@", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]);
    c6 = count(str, ["b", "A", "B", "C", "D", "E", "G", "H", "K", "N", "P", "Q", "R", "S", "T", "U", "V", "X", "Y", "Z", "_"]);
    c7 = count(str, ["m", "w", "M", "O"]);
    c8 = count(str, ["W", "%", "@"]);
    c9 = count(str, [".", " ", ":", ";"]);
    c_unknown = c_total - (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9);
    w_unscaled = ((h / 6.2) * c1) + ((h / 5.5) * c2) + ((h / 4) * c3) + ((h / 2.75) * c4) + ((h / 2.4) * c5) + ((h / 2.1) * c6) + ((h / 1.85) * c7) + ((h / 1.6) * c8) + ((h / 5) * c9) + ((h / 3) * c_unknown);
    w = (w_unscaled * (3/4)) + (c_total / 2) + (h / 10);
end
