
void dev_trace(const string &in msg) {
#if DEV
    trace('[' + Time::Now + '] ' + msg);
#endif
}
