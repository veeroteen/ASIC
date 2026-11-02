#include <iostream>

extern "C" void __stdcall CompressString(
    const char* input,
    char* output,
    unsigned int outputSize
);

#pragma comment(linker, "/alternatename:_CompressString@12=__CompressString@12@0")

int main()
{
    char input[128];
    char output[128];

    std::cout << "Enter string: ";
    std::cin.getline(input, sizeof(input));

    CompressString(input, output, sizeof(output));

    std::cout << "Compressed string: " << output << '\n';

    return 0;
}