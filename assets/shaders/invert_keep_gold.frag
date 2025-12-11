#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec4 color = texture(uTexture, uv);

    // 透明像素直接跳过
    if (color.a < 0.01) {
        fragColor = color;
        return;
    }

    // 判断是否为金黄色系：
    // 1. 红色通道高 (R > 0.7)
    // 2. 绿色通道中等 (G > 0.5 且 G < R)
    // 3. 蓝色通道低 (B < 0.2)
    bool isGold = color.r > 0.7 &&
                  color.g > 0.5 &&
                  color.g < color.r &&
                  color.b < 0.2;

    if (isGold) {
        // 保留金黄色
        fragColor = color;
    } else {
        // 反色，保留原始透明度
        fragColor = vec4(1.0 - color.rgb, color.a);
    }
}
