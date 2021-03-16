//
//  Shaders.metal
//  Metal Music Visualizer
//
//  Last Edited by Matthew Maring on 5/17/2020.
//  Copyright © 2020 Matthew Maring. All rights reserved.
//
// This file handles the metal shaders and computes all of the
// updates made to the display based on the audio properties.
// The background, particles, and music are all passed through
// in different buffers, with the music passed into the same kernel
// as the particles to reduce computation time.
//

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>

using namespace metal;

// Particle struct
struct Particle {
    float2 position;
    float2 count;
};

// Music struct
struct Music {
    float2 power;
    float2 params;
};

// Initialize Red RGB
float createRed(float position, float width, float count, float cycle) {
    float red = (position / width) + (count * cycle);
    return red;
}

// Initialize Green RGB
float createGreen(float position, float height, float count, float cycle) {
    float green = (position / height) + (count * cycle);
    return green;
}

// Initialize Blue RGB
float createBlue(float position, float width, float count, float cycle) {
    float blue = (1.0 - position / width) + (count * cycle);
    return blue;
}

// Create the background
kernel void initializeBackground(texture2d<float, access::write> output [[texture(0)]],
                      uint2 id [[thread_position_in_grid]]) {
    //Initialize each color
    float red = 0.0;
    float green = 0.0;
    float blue = 0.0;
    float alpha = 1.0;
    
    //Create the color spectrum
    float4 rgb = float4(red, green, blue, alpha);
    
    //Write the particles
    output.write(rgb, id);
}

// Create the particles
kernel void initializeParticles(texture2d<float, access::write> output [[texture(0)]],
                       device Particle *particles [[buffer(0)]],
                       device Music *musics [[buffer(1)]],
                       uint id [[thread_position_in_grid]]) {
    // Music
    Music music = musics[0];
    float avgPower = music.power.x;
    float peakPower = music.power.y;
    float intensity = music.params.x;
    
    // Particles/counting
    Particle particle = particles[id];
    int count = particle.count.x;
    int num = particle.count.y;
    
    // Logic constraints
    bool cycle = false;
    int size = 2;
    
    // Particle properties
    float2 position = particle.position;
    
    // Height and Width
    int width = output.get_width();
    int height = output.get_height();
    
    // Counter
    count = count + 1;
    particle.count = float2(count, num);

    // Set parameters to specified particle
    particles[id] = particle;
    
    // Initialize the position
    uint2 pos = uint2(position.x, position.y);
    
    // Initialize red
    float red = createRed(position.x, width, count, 0);
    
    // Initialize green
    float green = createGreen(position.y, height, count, 0);
    
    // Initialize blue
    float blue = createBlue(position.x, width, count, 0);
    
    if (cycle == true) {
        // Initialize red
        red = createRed(position.x, width, count, 0.01);
        // Initialize green
        green = createGreen(position.y, height, count, 0.01);
        // Initialize blue
        blue = createBlue(position.x, width, count, 0.01);
    }
    
    // Initialize alpha
    float alpha = 1.0;
    
    // Create the color spectrum
    float4 rgb = float4(red, green, blue, alpha);
    
    // Seed values for randoms
    int seeds[] = {936, 1456, 1123, 1957, 73, 1560, 214, 1555, 1688, 1564, 2643, 707, 2128, 271, 703, 2817, 871, 911, 1574, 465, 2735, 1202, 2291, 1671, 845, 2957, 1320, 963, 2120, 41, 3412, 208, 761, 2261, 2280, 902, 1329, 958, 337, 2623, 2482, 2374, 1902, 3047, 2038, 19, 594, 2428, 393, 658, 2218, 881, 1772, 208, 465, 1353, 2395, 2160, 2772, 49, 985, 3005, 87, 907, 1380, 788, 2626, 606, 1737, 3541, 894, 3143, 2567, 1469, 2266, 2327, 2810, 3571, 2224, 64, 266, 3155, 976, 1596, 1882, 910, 706, 1823, 2103, 3425, 700, 3420, 2469, 1797, 434, 730, 326, 2127, 2426, 1903, 199, 1771, 511, 236, 2182, 795, 2951, 272, 543, 487, 638, 2114, 3103, 2496, 1340, 358, 449, 787, 523, 630, 2681, 176, 2085, 2857, 2680, 1319, 1701, 2368, 2302, 1621, 193, 2783, 1598, 3021, 4, 2131, 653, 2221, 1395, 2793, 1681, 2123, 690, 2260, 2466, 1219, 219, 1001, 556, 844, 2771, 2825, 2985, 39, 3591, 2224, 9, 178, 1692, 1545, 1166, 1519, 1428, 3338, 1228, 967, 756, 2336, 2488, 1939, 1250, 3207, 1339, 1943, 2659, 140, 3415, 1455, 47, 2833, 3175, 2503, 1103, 1249, 2545, 564, 541, 1508, 1954, 1306, 156, 1196, 281, 766, 3313, 1845, 905, 3398, 830, 3340, 2645, 2053, 2808, 1545, 2411, 1287, 1320, 2533, 156, 1197, 3574, 3255, 725, 714, 44, 1765, 2366, 2636, 2955, 574, 2278, 1384, 3497, 2349, 1079, 172, 3124, 2904, 967, 1314, 981, 1707, 897, 248, 3423, 631, 332, 203, 3065, 2401, 889, 1005, 1031, 468, 1823, 2870, 2587, 2559, 1743, 986, 1190, 903, 2748, 389, 261, 3114, 2784, 517, 2084, 801, 620, 712, 1257, 3167, 1405, 1241, 3261, 1997, 2125, 3093, 1636, 2877, 1403, 942, 1716, 3176, 3265, 781, 1391, 3223, 2123, 3185, 1528, 1809, 2419, 2940, 2625, 324, 1153, 3271, 2470, 2507, 1660, 2904, 1840, 778, 3288, 1752, 1846, 387, 2398, 917, 631, 2166, 839, 1232, 2288, 1749, 424, 1298, 2770, 806, 2636, 1889, 596, 3333, 3366, 1215, 1785, 948, 1942, 1149, 3292, 335, 1922, 403, 1647, 1811, 1915, 1111, 799, 2364, 1900, 3093, 314, 124, 2633, 3121, 728, 2039, 1961, 3035, 2706, 3391, 56, 2106, 914, 70, 2169, 3490, 3223, 1101, 421, 2999, 3052, 2203, 3284, 2641, 1005, 2281, 1898, 721, 1702, 3480, 1213, 2697, 614, 2082, 1252, 418, 1282, 459, 454, 1623, 3082, 2486, 1869, 1655, 3355, 1604, 2839, 3172, 26, 1103, 298, 1388, 1968, 1239, 672, 1276, 3302, 2385, 2902, 3324, 1959, 2715, 1007, 1874, 454, 1154, 2890, 2394, 1484, 143, 2887, 300, 2928, 3054, 1790, 3090, 990, 731, 2650, 2211, 1597, 5, 3166, 370, 1619, 3408, 383, 1979, 2295, 231, 1993, 116, 2349, 2360, 1646, 3365, 450, 1183, 1628, 854, 1003, 199, 1765, 1275, 335, 2206, 2799, 2925, 3580, 2436, 2530, 879, 3419, 841, 3184, 3059, 2552, 2467, 495, 3125, 863, 3110, 1014, 220, 3431, 3430, 2405, 37, 817, 151, 75, 853, 2217, 2760, 272, 3379, 3261, 3371, 628, 1998, 1126, 2076, 2090, 1236, 3085, 3180, 2955, 2013, 1718, 1605, 3359, 1015, 3548, 2715, 3312, 2834, 2054, 978, 1379, 688, 3216, 1296, 2896, 2786, 1853, 3121};
    
    // low power function
    if (avgPower > 50 and avgPower <= 149) {
        int index = count % 480;
        
        for (int i = index; i < index + 20; i++) {
            if (seeds[i] == num) {
                size = 9;
            } else if (i == 0) {
                size = 2;
            }
        }
    }
    // high power functions
    else if (avgPower > 149 and avgPower <= 150) {
        if ((num + count) % 158 == 0) {
            size = 8;
        }
    } else if (avgPower > 150 and avgPower <= 151) {
        if ((3600 - num + count) % 158 == 0) {
            size = 8;
        }
    } else if (avgPower > 151 and avgPower <= 153) {
        if ((num + count) % 79 == 0) {
            size = 9;
        }
    } else if (avgPower > 153 and avgPower <= 155) {
        if ((3600 - num + count) % 79 == 0) {
            size = 9;
        }
    } else if (avgPower > 155 and avgPower <= 157) {
        if ((num + count) % 41 == 0) {
            size = 10;
        }
    } else if (avgPower > 157 and avgPower <= 160) {
        if ((3600 - num + count) % 41 == 0) {
            size = 10;
        }
    }
        
    // draw particle layers
    if (size > 2) {
        for (int x_cor = -(size - 1); x_cor < size; x_cor++) {
            for (int y_cor = -(size - 1); y_cor < size; y_cor++) {
                output.write(rgb, pos + uint2(x_cor, y_cor));
            }
        }
    } else if (size == 2 and intensity == 1.0) {
        for (int i = -10; i <= 10; i++) {
            output.write(rgb, pos + uint2(i, 0));
        }
    }
}

