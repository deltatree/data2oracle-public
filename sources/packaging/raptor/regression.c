#include <raptor2.h>
#include <stdio.h>
#include <string.h>
int main(void) {
 raptor_stringbuffer *b=raptor_new_stringbuffer();
 unsigned char out[5]={0,0,0,0,77};
 raptor_stringbuffer_append_string(b,(const unsigned char*)"abcd",1);
 int r=raptor_stringbuffer_copy_to_string(b,out,4);
 printf("ret=%d guard=%d\n",r,out[4]);
 raptor_free_stringbuffer(b);
 return r==0 || out[4]!=77;
}
