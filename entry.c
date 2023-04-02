#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern char *entry();

static void **to_garbage_collect = NULL;
static void **to_garbage_collect_ptr = NULL;

__attribute__((unused)) extern char *content_join(char *s1, char *s2) {
    char *result = malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(result, s1);
    strcat(result, s2);
    *to_garbage_collect_ptr++ = result;
    return result;
}

__attribute__((unused)) extern char *cast_int_to_content(long x) {
    char *result = malloc(32);
    sprintf(result, "%ld", x);
    *to_garbage_collect_ptr++ = result;
    return result;
}

__attribute__((unused)) extern void **mk_function(void *ptr, long argcount) {
    void **result = malloc(sizeof(void *) * (argcount + 1));
    result[0] = ptr;
    *to_garbage_collect_ptr++ = result;
    return result;
}

int main() {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnusedValue"
    to_garbage_collect = calloc(1024, sizeof(char *));
    to_garbage_collect_ptr = to_garbage_collect;
#pragma clang diagnostic pop

    char *result = entry();
    printf("%s", result);

    to_garbage_collect_ptr = to_garbage_collect;
    while (*to_garbage_collect) {
        free(*to_garbage_collect++);
    }
    free(to_garbage_collect_ptr);

    return 0;
}
