#include "URXZlib.h"
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#define URX_MAX_OUTPUT (32u * 1024u * 1024u)

int urx_gzip_decompress(const uint8_t *input, size_t input_length,
                        uint8_t **output, size_t *output_length) {
    if (!input || !output || !output_length) return Z_STREAM_ERROR;

    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    int result = inflateInit2(&stream, 15 + 16);
    if (result != Z_OK) return result;

    size_t capacity = 64u * 1024u;
    uint8_t *buffer = (uint8_t *)malloc(capacity);
    if (!buffer) {
        inflateEnd(&stream);
        return Z_MEM_ERROR;
    }

    stream.next_in = (Bytef *)input;
    stream.avail_in = (uInt)input_length;
    size_t produced = 0;

    do {
        if (produced == capacity) {
            if (capacity >= URX_MAX_OUTPUT) {
                free(buffer);
                inflateEnd(&stream);
                return Z_MEM_ERROR;
            }
            size_t next_capacity = capacity * 2;
            if (next_capacity > URX_MAX_OUTPUT) next_capacity = URX_MAX_OUTPUT;
            uint8_t *next = (uint8_t *)realloc(buffer, next_capacity);
            if (!next) {
                free(buffer);
                inflateEnd(&stream);
                return Z_MEM_ERROR;
            }
            buffer = next;
            capacity = next_capacity;
        }

        stream.next_out = buffer + produced;
        stream.avail_out = (uInt)(capacity - produced);
        result = inflate(&stream, Z_NO_FLUSH);
        produced = capacity - stream.avail_out;
    } while (result == Z_OK);

    inflateEnd(&stream);
    if (result != Z_STREAM_END) {
        free(buffer);
        return result;
    }

    *output = buffer;
    *output_length = produced;
    return Z_OK;
}
