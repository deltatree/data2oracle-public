#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <stdio.h>
int main(void) {
 xmlParserCtxtPtr c=xmlNewParserCtxt();
 xmlParserInputPtr i=xmlNewStringInputStream(c,BAD_CAST "abc");
 c->instate=XML_PARSER_EOF;
 int r=xmlPushInput(c,i);
 int owned=(c->input==i);
 printf("ret=%d owned=%d\n",r,owned);
 xmlFreeParserCtxt(c);
 return owned && r<0 ? 1:0;
}
