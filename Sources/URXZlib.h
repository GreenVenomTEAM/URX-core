#include <stddef.h>
#include <stdint.h>

int urx_gzip_decompress(const uint8_t *input, size_t input_length,
                        uint8_t **output, size_t *output_length);
